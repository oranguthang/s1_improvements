"""Generate the companion art and combined player-line palette resources.

Paired gameplay keeps the leader's four fur colours and gives Tails two
independent orange colours. Shared middle grey 8 folds into grey 7 and the
darkest shoe red E into D in audited player-line tiles only. Solo assets
remain the source of truth. Special Stages use their existing layered art.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from s1tools.codecs.kosinski import decode_moduled, encode_moduled
from s1tools.common import get_root, load_data, write_outputs

SHARED = {8: 7, 14: 13}
TAILS = {2: 11, 3: 11, 4: 8, 5: 14, 8: 7, 14: 13}


def recolour(data: bytes, colours: dict[int, int]) -> bytes:
    lookup = tuple(colours.get(i, i) for i in range(16))
    return bytes(lookup[b >> 4] << 4 | lookup[b & 15] for b in data)


def source_labels(root: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for path in [
        root / "sonic.asm",
        *sorted((root / "_inc").glob("*.asm")),
        *sorted((root / "_incObj").glob("*.asm")),
    ]:
        for label, asset in re.findall(
            r'^([\w]+):\s*(?:binclude|bincludeEndMarker)\s+"([^"]+)"',
            path.read_text(),
            re.M | re.I,
        ):
            result.setdefault(asset, []).append(label)
    return result


def palette_outputs(root: Path) -> tuple[dict[Path, bytes], list[str], list[str]]:
    outputs: dict[Path, bytes] = {}
    entries: list[str] = []
    data: list[str] = []
    for leader in ("Sonic", "Knuckles"):
        for prefix in ("", "Super "):
            for suffix, short in (
                ("", ""),
                (" - LZ Underwater", "Water"),
                (" - SBZ3 Underwater", "SBZ3Water"),
            ):
                name = prefix + leader + suffix
                token = prefix.replace(" ", "") + leader + short
                path = root / f"palette/Sidekick - {name}.bin"
                source_path = root / f"palette/{name}.bin"
                if source_path.exists():
                    original = bytearray(source_path.read_bytes())
                else:
                    label = "Pal_" + token
                    text = (root / "_inc/Palette Index.asm").read_text()
                    record = re.search(
                        r"^" + label + r":(.*?)^" + label + r"_end:", text, re.M | re.S
                    )
                    if record is None:
                        raise ValueError(f"Missing palette {name}")
                    original = bytearray(
                        b"".join(
                            int(v, 16).to_bytes(2, "big")
                            for v in re.findall(r"\$([0-9A-Fa-f]+)", record[1])
                        )
                    )
                if prefix:
                    normal = (root / f"palette/{leader}{suffix}.bin").read_bytes()
                    original[14:16] = normal[14:16]  # shared grey must stay stable
                tails = (root / f"palette/Tails{suffix}.bin").read_bytes()
                original[16:18] = tails[8:10]
                original[28:30] = tails[10:12]
                outputs[path] = bytes(original)
                entries.append(
                    f"palid_Sidekick{token}: makePalEntry Pal_Sidekick{token},v_palette_line_1"
                )
                data += [
                    f'Pal_Sidekick{token}: bincludeEndMarker "{path.relative_to(root).as_posix()}"',
                    "        even",
                ]
    return outputs, entries, data


def descriptors(root: Path, raw_remaps: dict[str, str]) -> str:
    text = (root / "_inc/Character Assets.asm").read_text()
    lines = [
        "; Combined palette descriptors retain all original physics/animation data.",
        "CharacterAssets_Paired:",
        "        dc.l CharacterAssets_PairedSonic,CharacterAssets_PairedSuperSonic",
        "        dc.l CharacterAssets_Tails,CharacterAssets_SuperTails",
        "        dc.l CharacterAssets_PairedKnuckles,CharacterAssets_PairedSuperKnuckles",
    ]
    substitutions = {
        "Pal_Sonic": "Pal_SidekickSonic",
        "Pal_LZSonWater": "Pal_SidekickSonicWater",
        "Pal_SBZ3SonWat": "Pal_SidekickSonicSBZ3Water",
        "palid_Sonic": "palid_SidekickSonic",
        "palid_LZSonWater": "palid_SidekickSonicWater",
        "palid_SBZ3SonWat": "palid_SidekickSonicSBZ3Water",
    }
    for leader in ("Sonic", "Knuckles"):
        for prefix in ("", "Super"):
            token = prefix + leader
            label = "CharacterAssets_" + token
            record = re.search(r"^" + label + r":\n(.*?)(?=^\w+:|\Z)", text, re.M | re.S)
            if record is None:
                raise ValueError(f"Missing source descriptor {label}")
            lines.append(f"CharacterAssets_Paired{token}:")
            for source in record[1].splitlines():
                if not re.match(r"\s*dc\.[lb]\s", source):
                    continue
                if token == "Sonic":
                    for old, new in substitutions.items():
                        source = re.sub(r"\b" + old + r"\b", new, source)
                else:
                    for base in ("Pal_", "palid_"):
                        for suffix in ("", "Water", "SBZ3Water"):
                            old = base + token + suffix
                            new = base + "Sidekick" + token + suffix
                            source = re.sub(r"\b" + old + r"\b", new, source)
                for old, new in raw_remaps.items():
                    source = re.sub(r"\b" + old + r"\b", new, source)
                lines.append(source)
    return "\n".join(lines) + "\n"


def banked_art(symbol: str, path: Path, length: int) -> list[str]:
    if length > 0x20000:
        raise ValueError(f"{path.name} exceeds a DMA bank")
    return [
        "        align $20",
        f"{symbol}_BeforeAlign:",
        f"        if (({symbol}_BeforeAlign&$1FFFF)+{length})>$20000",
        "        align $20000",
        "        endif",
        f'{symbol}: binclude "{path.as_posix()}"',
        f"{symbol}_End:",
    ]


def generate() -> dict[Path, bytes]:
    root = get_root()
    outputs, palette_index, palette_data = palette_outputs(root)
    from s1tools.player_carry import carry_outputs

    outputs.update(carry_outputs(root))
    from s1tools.sidekick_effects import effects_outputs

    outputs.update(effects_outputs(root, lambda data: recolour(data, SHARED)))
    from s1tools.sidekick_dust import dust_outputs

    outputs.update(dust_outputs(root))
    from s1tools.sidekick_platform import platform_outputs

    outputs.update(platform_outputs(root, lambda data: recolour(data, SHARED)))
    from s1tools.sidekick_stage import stage_outputs

    outputs.update(stage_outputs(root, lambda data: recolour(data, SHARED)))
    from s1tools.sidekick_debug import debug_outputs

    outputs.update(debug_outputs(root, lambda data: recolour(data, SHARED)))
    labels = source_labels(root)
    masks = {
        path: asset["ranges"]
        for path, asset in load_data("shared_player_palette.json")["assets"].items()
        if path.startswith(("artkosm/", "artunc/")) and (root / path).is_file()
    }
    # Current generated character sheets can have extra appended poses. These
    # sheets have no alternate palette-line tiles; their whole range is owned.
    for path in (root / "artunc").glob("*.unc"):
        if path.name.startswith(("Sonic", "Super Sonic", "Knuckles", "Super Knuckles")):
            masks[path.relative_to(root).as_posix()] = [[0, len(path.read_bytes()) // 32]]
    manifest = root / "tools/data/sidekick_palette.json"
    if manifest.exists():
        audited = json.loads(manifest.read_text())
        for path, ranges in audited["additional_masks"].items():
            masks.setdefault(path, []).extend(ranges)
        for path, override in audited["audited_overrides"].items():
            masks[path] = override["ranges"]

    compressed: list[tuple[str, str]] = []
    raw: list[tuple[str, str, int]] = []
    raw_assets: dict[str, Path] = {}
    asset_lines = ["; Generated by python -m s1tools.sidekick --apply."]
    for path, ranges in sorted(masks.items()):
        if path not in labels:
            continue
        original = (root / path).read_bytes()
        source = decode_moduled(original) if path.endswith(".kosm") else original
        changed = bytearray(source)
        for start, end in ranges:
            if not 0 <= start <= end <= len(source) // 32:
                raise ValueError(f"Player-line mask outside {path}: {start}..{end}")
            changed[start * 32 : end * 32] = recolour(source[start * 32 : end * 32], SHARED)
        if changed == source:
            continue
        target = root / Path(path).parent / "sidekick" / Path(path).name
        packed = encode_moduled(bytes(changed)) if path.endswith(".kosm") else bytes(changed)
        outputs[target] = packed
        token = f"SidekickAsset_{len(compressed) + len(raw):02X}"
        if path.endswith(".kosm"):
            asset_lines += [
                "        even",
                f'{token}: binclude "{target.relative_to(root).as_posix()}"',
            ]
            compressed.extend((label, token) for label in labels[path])
        else:
            if len(packed) > 0x20000:
                raise ValueError(f"Raw companion palette copy is bigger than a DMA bank: {path}")
            raw_assets[token] = target
            raw.extend((label, token, len(source)) for label in labels[path])

    # Player DPLCs index across these concatenated sheets. Replacing just
    # the base sheet breaks every appended pose (spring, figure-eight, carry).
    player_remaps = {old: new for old, new, _ in raw}
    raw_symbols = {path: symbol for symbol, path in raw_assets.items()}
    aliases = []
    for name, token, sheets in [
        (
            "Sonic",
            "Art_SidekickSonicCombined",
            (
                "Sonic.unc",
                "Sonic Figure8.unc",
                "Sonic Air Poses.unc",
                "Sonic Victory.unc",
                "Sonic Carry.unc",
            ),
        ),
        (
            "Super Sonic",
            "Art_SidekickSuperSonicCombined",
            ("Super Sonic.unc", "Super Sonic Figure8.unc"),
        ),
    ]:
        data = recolour(
            b"".join(
                (
                    outputs[root / "artunc" / sheet]
                    if root / "artunc" / sheet in outputs
                    else (root / "artunc" / sheet).read_bytes()
                )
                for sheet in sheets
            ),
            SHARED,
        )
        if len(data) > 0x20000:
            raise ValueError(f"Combined {name} art exceeds one DMA bank")
        target = root / f"artunc/sidekick/{name} Combined.unc"
        outputs[target] = data
        # These two sheets fill the tails of banks before the solo player
        # art. They keep their own bank guard if an earlier asset grows.
        source = [asset_lines[0], *banked_art(token, target.relative_to(root), len(data))]
        outputs[root / f"_inc/Sidekick {name} Art.asm"] = ("\n".join(source) + "\n").encode()
        offset = 0
        for sheet in sheets:
            part_path = root / "artunc/sidekick" / sheet
            part = outputs.get(part_path)
            if part is None:
                offset += (root / "artunc" / sheet).stat().st_size
                continue
            if data[offset : offset + len(part)] != part:
                raise ValueError(f"Combined art does not match the DMA variant for {sheet}")
            symbol = raw_symbols[part_path]
            aliases.append(f"{symbol} equ {token}+${offset:X}")
            del raw_assets[symbol]
            offset += len(part)
        player_remaps["Art_" + name.replace(" ", "")] = token

    for name in ("Tails", "Tails Tail"):
        target = root / f"artunc/Sidekick {name}.unc"
        outputs[target] = recolour((root / f"artunc/{name}.unc").read_bytes(), TAILS)
        raw_assets["Art_Sidekick" + name.replace(" ", "")] = target

    # Knuckles fits in the bank left by the compressed assets. Group the
    # companion body and tail immediately after it, before the smaller art.
    large_sheets = (player_remaps["Art_Knuckles"], "Art_SidekickTails", "Art_SidekickTailsTail")
    order = (*large_sheets, *(symbol for symbol in raw_assets if symbol not in large_sheets))
    for symbol in order:
        path = raw_assets[symbol]
        asset_lines.extend(banked_art(symbol, path.relative_to(root), len(outputs[path])))
    asset_lines += [*aliases, "        even", "Sidekick_PLCVariants:"]
    for old, new in compressed:
        asset_lines += [f"        ifdef {old}", f"        dc.l {old},{new}", "        endif"]
    asset_lines += ["        dc.l 0,0", "Sidekick_DMAVariants:"]
    for old, new, length in raw:
        asset_lines += [
            f"        ifdef {old}",
            f"        dc.l {old},{old}+{length},{new}",
            "        endif",
        ]
    asset_lines += [
        "        dc.l 0,0,0",
        *palette_data,
        descriptors(root, player_remaps).rstrip("\n"),
    ]
    outputs[root / "_inc/Sidekick Assets.asm"] = ("\n".join(asset_lines) + "\n").encode()
    outputs[root / "_inc/Sidekick Palette Index.asm"] = ("\n".join(palette_index) + "\n").encode()
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    outputs = generate()
    write_outputs(outputs, apply=args.apply)
    print(f"{'Generated' if args.apply else 'Verified'} {len(outputs)} companion resources")


if __name__ == "__main__":
    main()
