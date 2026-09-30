"""Reusable player transformations for Sonic 1 resources."""

from __future__ import annotations

import argparse
import hashlib
import io
import math
import re
from functools import lru_cache
from pathlib import Path

from PIL import Image

from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.common import get_root, get_source
from s1tools.palettes import water_DEFAULT as palettes_water_DEFAULT
from s1tools.palettes import water_expected_outputs as palettes_water_expected_outputs
from s1tools.sprites import decode_tiles as sprites_decode_tiles
from s1tools.sprites import parse_mappings as sprites_parse_mappings
from s1tools.sprites import parse_number as sprites_parse_number

super_SOURCE_NAME = "Sonic 2 player art"
super_SOURCE_FILES = {
    "art": (
        "art/uncompressed/Sonic's art.bin",
        "75ee80865f4d01f8695ceecabea4e99282cab09ed883d72981ce06e64647c502",
    ),
    "mappings": (
        "mappings/sprite/Sonic.asm",
        "97871fa285558e851e9a10b17d91d1f8a02521b32306b0d8f6699a5f67ff7149",
    ),
    "dplc": (
        "mappings/spriteDPLC/Sonic.asm",
        "6ed4c5181035a3179bb269127e1662809dfa57078f27d2e68002f1c2e828f332",
    ),
    "palette": (
        "art/palettes/Super Sonic transformation.bin",
        "56bdbd6517d193b87001bd9da7b932306e7a1f4437044de066ff6d654c5509df",
    ),
    "stars_art": (
        "art/nemesis/Super Sonic stars.nem",
        "a9d9ffe9da2ba22fdcf79315f254c064940678453da855e40db3ba9bc9ab2f02",
    ),
    "stars_map": (
        "mappings/sprite/obj7E.asm",
        "db836ac61baff038663b55baeb9bb71cc592433b70804e1bfeb658d469d92370",
    ),
    "transform_sfx": (
        "sound/sfx/DF - Super Transform.asm",
        "ef57ff22658d0492b6fbd703dc262d52728e82ff3c4197a49bc8a9bf309ecb5a",
    ),
}
super_USED_FRAMES = set([0, 11, 12, 17, 18])
super_USED_FRAMES.update(range(61, 72))
super_USED_FRAMES.update(range(78, 95))
super_USED_FRAMES.update(range(107, 200))
super_USED_FRAMES.update(range(210, 214))
super_FRAME_COUNT = 214


def super_sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def super_parse_int(value: str) -> int:
    value = value.strip()
    return int(value[1:], 16) if value.startswith("$") else int(value, 10)


def super_read_sources(source: Path) -> dict[str, bytes]:
    result: dict[str, bytes] = {}
    for key, (relative, expected_hash) in super_SOURCE_FILES.items():
        data = (source / relative).read_bytes()
        actual_hash = super_sha256(data)
        if actual_hash != expected_hash:
            raise SystemExit(
                f"Unexpected {relative} SHA-256: {actual_hash}; expected {expected_hash} from {super_SOURCE_NAME}"
            )
        result[key] = data
    return result


def super_table_targets(text: str, pattern: str) -> list[str]:
    targets: list[str] = []
    for line in text.splitlines():
        match = re.search(pattern, line)
        if match:
            targets.append(match.group(1))
            if len(targets) == super_FRAME_COUNT:
                break
    if len(targets) != super_FRAME_COUNT:
        raise SystemExit(f"Expected {super_FRAME_COUNT} table entries, found {len(targets)}")
    return targets


def super_mapping_pieces(text: str, label: str) -> list[str]:
    lines = text.splitlines()
    start = next((i for i, line in enumerate(lines) if re.match(f"^{re.escape(label)}:\\s*", line)))
    header = next(i for i in range(start, len(lines)) if "spriteHeader" in lines[i])
    pieces: list[str] = []
    for line in lines[header + 1 :]:
        if "spritePiece" in line:
            pieces.append(line.strip())
        elif re.match("^\\S+_End\\s*$", line.strip()):
            break
    return pieces


def super_dplc_entries(text: str, frame: int) -> list[tuple[int, int]]:
    lines = text.splitlines()
    label = f".frame{frame}"
    start = next((i for i, line in enumerate(lines) if re.match(f"^{re.escape(label)}:\\s*", line)))
    header = next(i for i in range(start, len(lines)) if "dplcHeader" in lines[i])
    entries: list[tuple[int, int]] = []
    for line in lines[header + 1 :]:
        match = re.search("dplcEntry\\s+([^,]+),\\s*([^;\\s]+)", line)
        if match:
            entries.append((super_parse_int(match.group(1)), super_parse_int(match.group(2))))
        elif re.match("^\\.frame\\d+_End\\s*$", line.strip()):
            break
    return entries


def super_emit_player_assets(sources: dict[str, bytes]) -> tuple[bytes, bytes, bytes]:
    mapping_text = sources["mappings"].decode("utf-8-sig")
    dplc_text = sources["dplc"].decode("utf-8-sig")
    mapping_targets = super_table_targets(mapping_text, "mappingsTableEntry\\.w\\s+(\\S+)")
    source_art = sources["art"]
    mapping_lines = [
        "; Sonic 2 player mappings and dynamic graphics",
        "SuperSonicMap_internal:\tmappingsTable",
    ]
    dplc_lines = [
        "; Sonic 2 player mappings and dynamic graphics",
        "SuperSonicDynPLC_internal:\tmappingsTable",
    ]
    for frame in range(super_FRAME_COUNT):
        target = frame if frame in super_USED_FRAMES else 0
        mapping_lines.append(f"\tmappingsTableEntry.w\tSuperMap_Frame{target:03X}")
        dplc_lines.append(f"\tmappingsTableEntry.w\tSuperPLC_Frame{target:03X}")
    packed_art = bytearray()
    packed_frames: dict[bytes, int] = {}
    frame_dplc: dict[int, list[tuple[int, int]]] = {}
    for frame in sorted(super_USED_FRAMES):
        frame_art = bytearray()
        for count, source_tile in super_dplc_entries(dplc_text, frame):
            begin = source_tile * 32
            end = begin + count * 32
            if end > len(source_art):
                raise SystemExit(f"Frame ${frame:02X} references art through ${end:X} past EOF")
            frame_art.extend(source_art[begin:end])
        frame_bytes = bytes(frame_art)
        if frame_bytes in packed_frames:
            packed_start = packed_frames[frame_bytes]
        else:
            packed_start = len(packed_art) // 32
            packed_frames[frame_bytes] = packed_start
            packed_art.extend(frame_bytes)
        rewritten: list[tuple[int, int]] = []
        remaining = len(frame_bytes) // 32
        source_tile = packed_start
        while remaining:
            count = min(remaining, 16)
            rewritten.append((count, source_tile))
            remaining -= count
            source_tile += count
        frame_dplc[frame] = rewritten
    for frame in sorted(super_USED_FRAMES):
        mapping_lines.append("")
        mapping_lines.append(f"SuperMap_Frame{frame:03X}:\tspriteHeader")
        mapping_lines.extend(
            "\t" + piece for piece in super_mapping_pieces(mapping_text, mapping_targets[frame])
        )
        mapping_lines.append(f"SuperMap_Frame{frame:03X}_End")
        dplc_lines.append("")
        dplc_lines.append(f"SuperPLC_Frame{frame:03X}:\tdplcHeader")
        for count, source_tile in frame_dplc[frame]:
            count_text = f"${count:X}" if count >= 10 else str(count)
            source_text = f"${source_tile:X}" if source_tile >= 10 else str(source_tile)
            dplc_lines.append(f"\tdplcEntry\t{count_text}, {source_text}")
        dplc_lines.append(f"SuperPLC_Frame{frame:03X}_End")
    mapping_lines.extend(["", "\teven", ""])
    dplc_lines.extend(["", "\teven", ""])
    return (
        bytes(packed_art),
        "\n".join(mapping_lines).encode("ascii"),
        "\n".join(dplc_lines).encode("ascii"),
    )


def super_expected_outputs(root: Path, source: Path) -> dict[Path, bytes]:
    sources = super_read_sources(source)
    art, mappings, dplc = super_emit_player_assets(sources)
    mappings = mappings.replace(
        b"\n\nSuperMap_Frame000:",
        b'\n\n\tinclude "_maps/Super Sonic - Figure8 Map Entries.asm"\n\tinclude "_maps/Sonic - Air Poses Map Entries.asm"\n\nSuperMap_Frame000:',
    )
    mappings += b'\n\tinclude "_maps/Super Sonic - Figure8 Map.asm"\n'
    dplc = dplc.replace(
        b"\n\nSuperPLC_Frame000:",
        b'\n\n\tinclude "_maps/Super Sonic - Figure8 DPLC Entries.asm"\n\tinclude "_maps/Sonic - Air Poses DPLC Entries.asm"\n\nSuperPLC_Frame000:',
    )
    dplc += b'\n\tinclude "_maps/Super Sonic - Figure8 DPLC.asm"\n'
    star_map = (
        sources["stars_map"]
        .decode("utf-8-sig")
        .replace("Map_obj7E", "Map_SuperSonicStars_internal")
    )
    dry_palette = sources["palette"]
    transform_sfx = (
        sources["transform_sfx"]
        .decode("utf-8-sig")
        .replace("smpsHeaderStartSong 2", "smpsHeaderStartSong 1", 1)
    )
    outputs: dict[Path, bytes] = {
        root / "artunc/Super Sonic.unc": art,
        root / "_maps/Super Sonic.asm": mappings,
        root / "_maps/Super Sonic - Dynamic Gfx Script.asm": dplc,
        root / "palette/Cycle - Super Sonic.bin": dry_palette,
        root / "artunc/Super Sonic Stars.unc": nemesis_decode(sources["stars_art"]),
        root / "_maps/Super Sonic Stars.asm": star_map.encode("ascii"),
        root / "sound/sfx/SndA2 - Super Transform.asm": transform_sfx.encode("ascii"),
    }
    outputs.update(palettes_water_expected_outputs(palettes_water_DEFAULT))
    return outputs


figure8_ROOT = get_root()
figure8_CD_SOURCE = "Sonic CD player art"
figure8_CD_FILES = ("Art.bin", "Mappings.asm", "DPLCs.asm")
figure8_CD_HASHES = {
    "Art.bin": "5160ff8ea26ed050cd3f41aaf1689d4e05a58cf15f090c0ca910932e7f629955",
    "Mappings.asm": "604a1a7c475579abea7e4b856b2c61d02ae1ff9d2897bc8d93180734cb79ecdb",
    "DPLCs.asm": "4b8cb37eb0666f1102762b2682a6d80acfd9cdc7488982e14cfa600df10189cc",
}


def figure8_digest(data):
    return hashlib.sha256(data).hexdigest()


def figure8_raw_blocks(path, base):
    text = path.read_text(encoding="utf-8")
    targets = re.findall("dc.w\\s+(\\w+)-" + re.escape(base), text)
    blocks = {}
    for label, body in re.findall("^(\\w+):([^:]*?)(?=^\\w+:|\\Z)", text, re.M | re.S):
        out = bytearray()
        for line in body.splitlines():
            m = re.search("dc\\.([bw])\\s+([^;]+)", line)
            if m:
                for token in m[2].strip().split(","):
                    try:
                        v = sprites_parse_number(token)
                    except ValueError:
                        continue
                    out.extend(v.to_bytes(1 if m[1] == "b" else 2, "big"))
        blocks[label] = bytes(out)
    return (targets, blocks)


def figure8_pixels(art, pieces):
    tiles = sprites_decode_tiles(art)
    out = {}
    for x, y, w, h, t, xf, yf in pieces:
        assert t + w * h <= len(tiles)
        for px in range(w * 8):
            for py in range(h * 8):
                sx = w * 8 - 1 - px if xf else px
                sy = h * 8 - 1 - py if yf else py
                val = tiles[t + sx // 8 * h + sy // 8][sy % 8][sx % 8]
                if val:
                    out[x + px, y + py] = val
    return out


def figure8_cd_frames(source, frame_ids=None):
    if frame_ids is None:
        frame_ids = range(148, 164)
    mt, mb = figure8_raw_blocks(source / "CD-Mappings.asm", ".Map")
    dt, db = figure8_raw_blocks(source / "CD-DPLCs.asm", ".DPLCs")
    a = (source / "CD-Art.bin").read_bytes()
    out = []
    for fr in frame_ids:
        m, d = (mb[mt[fr]], db[dt[fr]])
        art = b""
        pieces = []
        for i in range(int.from_bytes(d[:2], "big")):
            v = int.from_bytes(d[2 + i * 2 : 4 + i * 2], "big")
            pos = (v & 4095) * 32
            size = ((v >> 12) + 1) * 32
            assert pos + size <= len(a)
            art += a[pos : pos + size]
        for i in range(m[0]):
            y, size, t, x = (
                m[1 + i * 5],
                m[2 + i * 5],
                int.from_bytes(m[3 + i * 5 : 5 + i * 5], "big"),
                m[5 + i * 5],
            )
            pieces.append(
                (
                    x - 256 if x >= 128 else x,
                    y - 256 if y >= 128 else y,
                    (size >> 2) + 1,
                    (size & 3) + 1,
                    t & 2047,
                    bool(t & 2048),
                    bool(t & 4096),
                )
            )
        assert len(art) <= 32 * 32
        out.append((art, pieces, figure8_pixels(art, pieces)))
    return out


def figure8_super_frame(fr):
    name = "Super Sonic"
    mt, maps = sprites_parse_mappings(figure8_ROOT / "_maps" / f"{name}.asm")
    text = (figure8_ROOT / "_maps" / f"{name} - Dynamic Gfx Script.asm").read_text()
    dt = re.findall("mappingsTableEntry.w\\s+(\\S+)", text)
    label = dt[fr]
    body = text.split(label + ":", 1)[1].split(label + "_End", 1)[0]
    a = (figure8_ROOT / "artunc" / f"{name}.unc").read_bytes()
    art = b""
    for n, t in re.findall("dplcEntry\\s+([^,]+),\\s*([^;\\s]+)", body):
        n, t = (sprites_parse_number(n), sprites_parse_number(t))
        art += a[t * 32 : (t + n) * 32]
    return figure8_pixels(
        art,
        [(p.x, p.y, p.width_tiles, p.height_tiles, p.tile, p.xflip, p.yflip) for p in maps[mt[fr]]],
    )


def figure8_pack(frame):
    x0 = min((x for x, y in frame)) // 8 * 8
    y0 = min((y for x, y in frame)) // 8 * 8
    w = (max((x for x, y in frame)) - x0) // 8 + 1
    h = (max((y for x, y in frame)) - y0) // 8 + 1
    occupied = 0
    for x, y in frame:
        occupied |= 1 << (y - y0) // 8 * w + (x - x0) // 8
    candidates = {}
    for i in range(w * h):
        x, y = (i % w, i // w)
        cs = []
        for rw in range(1, min(4, w - x) + 1):
            for rh in range(1, min(4, h - y) + 1):
                mask = sum(1 << yy * w + xx for xx in range(x, x + rw) for yy in range(y, y + rh))
                cs.append((mask, rw, rh))
        candidates[i] = cs

    @lru_cache(None)
    def solve(left, budget):
        if not left:
            return (0, 0, ())
        if left.bit_count() > budget:
            return None
        i = (left & -left).bit_length() - 1
        best = None
        for mask, rw, rh in candidates[i]:
            cost = rw * rh
            if cost > budget or mask & (occupied ^ left):
                continue
            tail = solve(left & ~mask, budget - cost)
            if tail is None:
                continue
            result = (tail[0] + 1, tail[1] + cost, ((i % w, i // w, rw, rh),) + tail[2])
            if best is None or result[:2] < best[:2]:
                best = result
        return best

    solution = solve(occupied, 32)
    assert solution, (w, h, occupied.bit_count())
    art = bytearray()
    pieces = []
    for tx, ty, rw, rh in solution[2]:
        start = len(art) // 32
        x = x0 + tx * 8
        y = y0 + ty * 8
        for xx in range(rw):
            for yy in range(rh):
                for py in range(8):
                    for px in range(0, 8, 2):
                        hi = frame.get((x + xx * 8 + px, y + yy * 8 + py), 0)
                        lo = frame.get((x + xx * 8 + px + 1, y + yy * 8 + py), 0)
                        art.append(hi * 16 + lo)
        pieces.append((x, y, rw, rh, start, False, False))
    assert figure8_pixels(art, pieces) == frame
    assert len(pieces) <= 8 and len(art) <= 1024
    return (bytes(art), pieces)


def figure8_assets(source):
    normal = figure8_cd_frames(source)
    superframes = []
    for i, (_art, _pieces, pix) in enumerate(normal):
        angle = i // 4 * math.pi / 4

        def depth(x, y, angle=angle):
            return x * math.sin(angle) + y * math.cos(angle)

        body = figure8_super_frame(181 + i // 4 + (4 if i % 2 else 0))
        frame = {pos: v for pos, v in body.items() if depth(*pos) < 2}
        frame.update({pos: v for pos, v in pix.items() if depth(*pos) >= 2})
        superframes.append((*figure8_pack(frame), frame))
    outputs = {}
    for form, frames, _base, _artlabel in [
        ("Sonic", normal, 94, "Art_Sonic"),
        ("Super Sonic", superframes, 214, "Art_SuperSonic"),
    ]:
        offset = len((figure8_ROOT / "artunc" / f"{form}.unc").read_bytes()) // 32
        packed = bytearray()
        maps = []
        dplcs = []
        entries = []
        de = []
        tag = "Super" if form.startswith("Super") else "Sonic"
        for i, (art, pieces, _pix) in enumerate(frames):
            label = f"{tag}Figure8_{i:02X}"
            entries.append(f"\tmappingsTableEntry.w {label}")
            de.append(f"\tmappingsTableEntry.w {label}_PLC")
            maps.append(f"{label}: spriteHeader")
            dx = round(3 * math.sin(i // 4 * math.pi / 4))
            dy = round(3 * math.cos(i // 4 * math.pi / 4))
            for x, y, w, h, t, xf, yf in pieces:
                maps.append(
                    f"\tspritePiece {x + dx}, {y + dy}, {w}, {h}, {t}, {int(xf)}, {int(yf)}, 0, 0"
                )
            maps.extend([label + "_End", ""])
            dplcs.append(label + "_PLC: dplcHeader")
            count = len(art) // 32
            tile = offset + len(packed) // 32
            assert tile + count <= 4096
            while count:
                n = min(count, 16)
                dplcs.append(f"\tdplcEntry {n}, ${tile:X}")
                tile += n
                count -= n
            dplcs.extend([label + "_PLC_End", ""])
            packed.extend(art)
        for name, lines in [
            ("Map", maps),
            ("DPLC", dplcs),
            ("Map Entries", entries),
            ("DPLC Entries", de),
        ]:
            outputs[figure8_ROOT / "_maps" / f"{form} - Figure8 {name}.asm"] = (
                "; Figure-eight player mappings and dynamic graphics\n"
                + "\n".join(lines)
                + "\n\teven\n"
            ).encode("ascii")
        outputs[figure8_ROOT / "artunc" / f"{form} Figure8.unc"] = bytes(packed)
    return (outputs, normal, superframes)


air_FALL_URL = "https://info.sonicretro.org/images/3/33/Fall_Sprites.zip"
air_FALL_HASHES = {
    "Fall.png": "9110d90d556fb6b19cb28ff09724f9e33d998386e603caa4b59a129bc811b9a8",
    "Fall1.png": "fe992220009e96212d67bbb23319757d6f6e7834052e5b66e7c40f8d172a44a9",
}
air_COLORS = [
    (153, 217, 234),
    (0, 0, 0),
    (32, 36, 144),
    (72, 72, 176),
    (104, 108, 216),
    (144, 144, 248),
    (248, 252, 248),
    (176, 180, 176),
    (144, 144, 144),
    (72, 72, 72),
    (248, 180, 144),
    (176, 108, 72),
    (248, 0, 0),
    (144, 0, 0),
]


def air_falling(source):
    frames = []
    for n in ("Fall.png", "Fall1.png"):
        raw = (source / n).read_bytes()
        assert figure8_digest(raw) == air_FALL_HASHES[n]
        im = Image.open(io.BytesIO(raw)).convert("RGB")
        pix = {}
        for y in range(im.height):
            for x in range(im.width):
                v = air_COLORS.index(im.getpixel((x, y)))
                if v:
                    pix[x - 22 - (2 if n == "Fall1.png" else 0), y - 29] = v
        art, pieces = figure8_pack(pix)
        frames.append((art, pieces, pix))
    return frames


def air_assets(source):
    for n, sha in figure8_CD_HASHES.items():
        assert figure8_digest((source / ("CD-" + n)).read_bytes()) == sha, n
    frames = figure8_cd_frames(source, [50, 144, 145, 146, 147]) + air_falling(source)
    offset = (
        sum(
            len((figure8_ROOT / "artunc" / n).read_bytes())
            for n in ("Sonic.unc", "Sonic Figure8.unc")
        )
        // 32
    )
    packed = bytearray()
    maps = []
    dplcs = []
    entries = []
    de = []
    for i, (art, pieces, _pix) in enumerate(frames):
        label = "SonicAirPose" + str(i)
        entries.append("\tmappingsTableEntry.w " + label)
        de.append("\tmappingsTableEntry.w " + label + "_PLC")
        maps.append(label + ": spriteHeader")
        for x, y, w, h, t, xf, yf in pieces:
            maps.append(f"\tspritePiece {x}, {y}, {w}, {h}, {t}, {int(xf)}, {int(yf)}, 0, 0")
        maps.extend([label + "_End", ""])
        dplcs.append(label + "_PLC: dplcHeader")
        count = len(art) // 32
        tile = offset + len(packed) // 32
        assert count <= 32 and len(pieces) <= 8 and (tile + count <= 4096)
        while count:
            n = min(count, 16)
            dplcs.append(f"\tdplcEntry {n}, ${tile:X}")
            tile += n
            count -= n
        dplcs.extend([label + "_PLC_End", ""])
        packed.extend(art)
    outputs = {figure8_ROOT / "artunc/Sonic Air Poses.unc": bytes(packed)}
    for name, lines in [
        ("Map", maps),
        ("DPLC", dplcs),
        ("Map Entries", entries),
        ("DPLC Entries", de),
    ]:
        outputs[figure8_ROOT / "_maps" / ("Sonic - Air Poses " + name + ".asm")] = (
            "; Shared spring and falling player poses\n" + "\n".join(lines) + "\n\teven\n"
        ).encode("ascii")
    return (outputs, frames)


def run_import(kind: str) -> None:
    """Regenerate indexed player resources from checked source files."""
    from s1tools.common import write_outputs

    parser = argparse.ArgumentParser(description=run_import.__doc__)
    parser.add_argument("--source", type=Path, help="override this import source directory")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    source = args.source or get_source("s2" if kind == "super" else "cd")
    if kind == "super":
        outputs = super_expected_outputs(get_root(), source)
    else:
        for name, expected in figure8_CD_HASHES.items():
            if figure8_digest((source / ("CD-" + name)).read_bytes()) != expected:
                raise ValueError(f"Source checksum mismatch: {name}")
        outputs = (figure8_assets(source) if kind == "figure8" else air_assets(source))[0]
    write_outputs(outputs, apply=args.apply)


def super_main() -> None:
    run_import("super")


def figure8_main() -> None:
    run_import("figure8")


def air_main() -> None:
    run_import("air")
