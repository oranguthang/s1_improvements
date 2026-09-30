"""Reusable sonlvl transformations for Sonic 1 resources."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import uuid
from collections import Counter
from pathlib import Path

from s1tools.codecs.kosinski import decode_moduled as kosinski_decode_moduled
from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.common import get_root, project_files

sync_ROOT = get_root()
sync_INI_ROOT = Path("Utility Project Files/SonLVL INI Files")
sync_SECTIONS = {
    f"{sync_zone} Zone Act {sync_act}": (sync_number, sync_act - 1)
    for sync_number, sync_zone in enumerate(
        ("Green Hill", "Labyrinth", "Marble", "Star Light", "Spring Yard")
    )
    for sync_act in (1, 2, 3)
}
sync_SECTIONS.update(
    {
        "Scrap Brain Zone Act 1": (5, 0),
        "Scrap Brain Zone Act 2": (5, 1),
        "Scrap Brain Zone Act 3": (1, 3),
        "Final Zone": (5, 2),
    }
)


def sync_revision_source(source, revision):
    """Select only Revision branches; unrelated assembler conditions keep both arms."""
    stack = []
    output = []
    for line in source.splitlines():
        code = line.split(";", 1)[0].strip()
        if re.match("^if\\s", code, re.I):
            match = re.fullmatch("if\\s+Revision\\s*([=<>]+)\\s*(\\d+)", code, re.I)
            choice = None
            if match:
                op, value = match.groups()
                value = int(value)
                choice = {
                    "=": revision == value,
                    "<>": revision != value,
                    "<": revision < value,
                    ">": revision > value,
                }[op]
            stack.append([choice, False])
            continue
        if code.lower() == "else" and stack:
            stack[-1][1] = True
            continue
        if code.lower() == "endif" and stack:
            stack.pop()
            continue
        if all((choice is None or choice != other for choice, other in stack)):
            output.append(line)
    return "\n".join(output)


def sync_file_symbols(source):
    result = {}
    label = None
    for line in source.splitlines():
        code = line.split(";", 1)[0]
        match = re.match("^([A-Za-z_]\\w*):", code)
        if match:
            label = match[1]
        match = re.search('\\bbinclude(?:EndMarker)?\\s+"([^"]+)"', code)
        if match and label:
            result[label] = match[1]
    return result


def sync_header_fields(root):
    source = (root / "_inc/LevelHeaders.asm").read_text()
    return {
        m[1]: [field.strip() for field in m[2].split(",")]
        for m in re.finditer("^(Header_\\w+):\\s*lhead\\s+([^;\\n]+)", source, re.M)
    }


def sync_resources(root, revision):
    source = sync_revision_source((root / "sonic.asm").read_text(), revision)
    palettes = (root / "_inc/Palette Index.asm").read_text()
    files = sync_file_symbols(source + "\n" + palettes)
    pal_labels = dict(re.findall("(palid_\\w+):\\s*makePalEntry\\s+(\\w+)", palettes))
    plcs = (root / "_inc/Pattern Load Cues.asm").read_text()
    headers = sync_header_fields(root)
    index_source = (
        (root / "_inc/LevelHeaders.asm")
        .read_text()
        .split("LevelHeaderIndex:")[1]
        .split("LevelHeaderIndex_end:")[0]
    )
    index = [
        item.strip()
        for line in re.findall("^\\s*dc.l\\s+([^;\\n]+)", index_source, re.M)
        for item in line.split(",")
    ]
    if len(index) != 28:
        raise ValueError("Expected seven zones with four resource slots each")

    def path(label):
        value = files[label]
        if not (root / value).is_file():
            raise ValueError(f"Missing asset: {value}")
        return "../../" + value

    result = {}
    for section, (zone, act) in sync_SECTIONS.items():
        header = index[zone * 4 + act]
        main, _, blocks, chunks, collision, palette, water, sonicwater, _ = headers[header]
        match = re.search(
            "^" + re.escape(main) + ":\\s*plcheader\\b(.*?)^" + re.escape(main) + "_end:",
            plcs,
            re.M | re.S,
        )
        if not match:
            raise ValueError(f"Missing main PLC: {main}")
        art = re.findall("plcm\\s+(\\w+),\\s*ArtTile_Level([^;\\n]*)", match[1])
        if not art:
            raise ValueError(f"No level art in {main}")
        tilefiles = []
        cursor = 0
        for label, offset in art:
            offset = offset.strip().lstrip("+").replace("$", "0x")
            if offset and (
                not re.fullmatch(
                    "(?:0x[0-9A-Fa-f]+|\\d+)(?:\\s*\\+\\s*(?:0x[0-9A-Fa-f]+|\\d+))*", offset
                )
            ):
                raise ValueError(f"Unsupported level VRAM expression: {offset}")
            target = sum(int(item.strip(), 0) for item in offset.split("+")) if offset else 0
            if target != cursor:
                raise ValueError(
                    f"{main}: non-contiguous level tiles; configure their SonLVL offsets explicitly"
                )
            tilefiles.append(path(label))
            cursor += int.from_bytes((root / files[label]).read_bytes()[:2], "big") // 32
        values = {
            "tiles": "|".join(tilefiles),
            "blocks": path(blocks),
            "chunks": path(chunks),
            "colind": path(collision),
            "palette": path("Pal_Sonic") + ":0:0:16|" + path(pal_labels[palette]) + ":0:16:48",
        }
        if water != "0":
            values["palette2"] = (
                "Water|"
                + path(pal_labels[sonicwater])
                + ":0:0:16|"
                + path(pal_labels[water])
                + ":16:16:48"
            )
        result[section] = values
    return result


def sync_sync(root, write=False):
    differences = []
    count = 0
    for revision in (0, 1):
        ini = root / sync_INI_ROOT / f"SonLVL.rev0{revision}.ini"
        wanted = sync_resources(root, revision)
        source = ini.read_text()
        lines = source.splitlines(keepends=True)
        section = None
        seen = set()
        replacement = []
        for line in lines:
            match = re.match("^\\[([^\\]]+)\\]", line)
            if match:
                section = match[1]
            if section in wanted:
                key = line.partition("=")[0]
                if key in wanted[section]:
                    seen.add((section, key))
                    value = wanted[section][key]
                    if line.partition("=")[2].rstrip("\r\n") != value:
                        differences.append(f"{ini.name}: {section}: {key}")
                        line = key + "=" + value + "\n"
            replacement.append(line)
        for section, values in wanted.items():
            for key in values:
                if (section, key) not in seen:
                    raise ValueError(f"{ini.name}: missing {section}/{key}; add the field first")
        count += len(wanted)
        if write and "".join(replacement) != source:
            ini.write_text("".join(replacement))
    return (count, differences)


def sync_main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=sync_ROOT)
    parser.add_argument(
        "--write",
        action="store_true",
        help="update only resource fields, preserving layouts/objects/rings and other options",
    )
    args = parser.parse_args()
    try:
        count, differences = sync_sync(args.root.resolve(), args.write)
    except (ValueError, KeyError) as error:
        parser.exit(1, str(error) + "\n")
    if differences:
        print(("Updated" if args.write else "Out of sync") + ":\n" + "\n".join(differences))
        if not args.write:
            return 1
    else:
        print(f"PASS: {count} act resource sections across both SonLVL revisions")
    return 0


roundtrip_ROOT = get_root()
roundtrip_TMP = roundtrip_ROOT / "tmp"


def roundtrip_object_records(data: bytes, record_size: int) -> Counter[bytes]:
    if len(data) % record_size or len(data) < record_size:
        raise ValueError(f"invalid {record_size}-byte objpos length")
    rows = [data[i : i + record_size] for i in range(0, len(data), record_size)]
    if rows[-1] != (b"\xff" * 4 if record_size == 4 else b"\xff\xff" + bytes(4)):
        raise ValueError("invalid objpos terminator")
    return Counter(rows)


def roundtrip_semantic_equal(rel: Path, before: bytes, after: bytes) -> str | None:
    if before == after:
        return "byte-identical"
    if rel.parts[0] == "objpos" and rel.suffix.lower() == ".bin":
        record_size = 4 if rel.parts[1] == "Rings" else 6
        if roundtrip_object_records(before, record_size) == roundtrip_object_records(
            after, record_size
        ):
            return "same object records (reordered)"
    if rel.suffix.lower() == ".nem":
        if nemesis_decode(before) == nemesis_decode(after):
            return "same Nemesis pixels (recompressed)"
    if rel.suffix.lower() == ".kosm":
        try:
            saved_pixels = kosinski_decode_moduled(after)
        except ValueError:
            if len(after) % 2 or not after.endswith(b"\x00"):
                raise
            saved_pixels = kosinski_decode_moduled(after[:-1])
        if kosinski_decode_moduled(before) == saved_pixels:
            return "same KosM pixels (recompressed)"
    return None


def roundtrip_ps_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def roundtrip_main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--api", type=Path, required=True, help="path to SonLVLAPI.dll")
    args = parser.parse_args()
    if os.name != "nt":
        parser.error("SonLVLAPI round trip requires Windows")
    api = args.api.resolve(strict=True)
    ps51 = Path(os.environ["SystemRoot"]) / "System32/WindowsPowerShell/v1.0/powershell.exe"
    if not ps51.is_file():
        parser.error(f"Windows PowerShell 5.1 missing: {ps51}")
    roundtrip_TMP.mkdir(exist_ok=True)
    stamp = uuid.uuid4().hex
    test_root = (roundtrip_TMP / f"sonlvl-roundtrip-{stamp}").resolve()
    if roundtrip_TMP.resolve() not in test_root.parents or test_root.exists():
        raise RuntimeError("unsafe or occupied test directory")
    project = test_root / "project"
    tracked = project_files(roundtrip_ROOT)
    baseline: dict[Path, bytes] = {}
    for rel in tracked:
        source = roundtrip_ROOT / rel
        destination = project / rel
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        baseline[rel] = source.read_bytes()
    ps_script = r"""
$ErrorActionPreference = 'Stop'
[Reflection.Assembly]::LoadFrom(API_PATH) | Out-Null
$project = PROJECT_PATH
$total = 0
$failed = 0
foreach ($revision in @('rev00', 'rev01')) {
    $ini = Join-Path $project ('Utility Project Files\SonLVL INI Files\SonLVL.' + $revision + '.ini')
    [SonicRetro.SonLVL.API.LevelData]::LoadGame($ini)
    $sections = Get-Content -LiteralPath $ini | Where-Object { $_ -match '^\[(.+)\]$' } | ForEach-Object { $_.Trim('[', ']') }
    foreach ($name in $sections) {
        $total++
        try {
            [SonicRetro.SonLVL.API.LevelData]::LoadLevel($name, $true)
            [SonicRetro.SonLVL.API.LevelData]::SaveLevel()
        } catch {
            $failed++
            Write-Output ('FAIL ' + $revision + ' ' + $name + ': ' + $_.Exception.Message)
        }
    }
}
Write-Output ('SUMMARY total=' + $total + ' failed=' + $failed)
if ($failed -gt 0) { exit 1 }
"""
    ps_script = ps_script.replace("API_PATH", roundtrip_ps_quote(str(api)))
    ps_script = ps_script.replace("PROJECT_PATH", roundtrip_ps_quote(str(project)))
    probe = test_root / "roundtrip.ps1"
    probe.write_text(ps_script, encoding="utf-8-sig")
    result = subprocess.run(
        [str(ps51), "-NoProfile", "-NonInteractive", "-File", str(probe)],
        cwd=roundtrip_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    print(result.stdout.strip())
    if result.stderr.strip():
        print(result.stderr.strip(), file=sys.stderr)
    semantic_changes = []
    failures = []
    for rel, original in baseline.items():
        saved_path = project / rel
        if not saved_path.is_file():
            failures.append(f"{rel.as_posix()}: missing after save")
            continue
        saved = saved_path.read_bytes()
        try:
            verdict = roundtrip_semantic_equal(rel, original, saved)
        except (ValueError, IndexError) as exc:
            verdict = None
            failures.append(f"{rel.as_posix()}: invalid saved data ({exc})")
        if verdict is None:
            failures.append(f"{rel.as_posix()}: content changed")
        elif verdict != "byte-identical":
            semantic_changes.append(f"{rel.as_posix()}: {verdict}")
    for item in semantic_changes:
        print("EQUIVALENT", item)
    for item in failures:
        print("FAIL", item)
    print(
        f"Files: {len(tracked)} checked, {len(semantic_changes)} equivalent rewrites, {len(failures)} changes"
    )
    print(f"Isolated copy: {test_root}")
    return 1 if result.returncode or failures or "SUMMARY total=" not in result.stdout else 0
