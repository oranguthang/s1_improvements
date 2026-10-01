"""Reusable palettes transformations for Sonic 1 resources."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import sys
from dataclasses import dataclass
from pathlib import Path

from s1tools.codecs.enigma import decode as enigma_decode
from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.codecs.nemesis import encode_with_table as nemesis_encode_with_table
from s1tools.common import get_root, get_source, load_data
from s1tools.shared_palette import remap_art as shared_remap_art
from s1tools.sprites import parse_mappings as sprites_parse_mappings

water_ROOT = get_root()
water_DEFAULT = "ice"
water_NORMAL_FILES = {
    "lz": "palette/Sonic - LZ Underwater.bin",
    "sbz3": "palette/Sonic - SBZ3 Underwater.bin",
}
water_OUTPUT_FILES = {
    "lz": "palette/Cycle - Super Sonic LZ Underwater.bin",
    "sbz3": "palette/Cycle - Super Sonic SBZ3 Underwater.bin",
}
water_PRESETS = {
    "contrast": {
        "title": "High contrast",
        "description": "Aquamarine in Labyrinth and lilac in Scrap Brain 3.",
        "lz": (1160, 1706, 2252, 2798),
        "sbz3": (2120, 2666, 3212, 3758),
    },
    "gold": {
        "title": "Warm gold",
        "description": "Amber tones with less blue.",
        "lz": (616, 1162, 1708, 2254),
        "sbz3": (1130, 1676, 2222, 2766),
    },
    "ice": {
        "title": "Ice",
        "description": "Blue highlights with a cool glow.",
        "lz": (2114, 2660, 3206, 3752),
        "sbz3": (2630, 3176, 3722, 3756),
    },
    "pearl": {
        "title": "Pearl",
        "description": "Neutral light shades for varied backgrounds.",
        "lz": (1092, 1638, 2184, 2730),
        "sbz3": (1094, 1640, 2186, 2732),
    },
}
water_ICE_MASKS = (0, 1, 3, 7, 15, 14, 12, 13, 9, 8)
water_DEFAULT_ICE_VARIANT = "rose_pulse"
water_LZ_DEFAULT_CYCLE = "blue_pulse"
water_LZ_BLUE_STATIC_ROWS = (
    (544, 1090, 1634, 2180),
    (1090, 1636, 2180, 2694),
    (1604, 2148, 2182, 2728),
    (1636, 2182, 2726, 3240),
    (2150, 2694, 2728, 3274),
    (2696, 3240, 3274, 3788),
) + ((2696, 3240, 3274, 3788),) * 10
water_LZ_BLUE_PULSE_ROWS = water_LZ_BLUE_STATIC_ROWS[:6] + (
    (2696, 3240, 3274, 3788),
    (2696, 3242, 3274, 3788),
    (2698, 3242, 3274, 3788),
    (2698, 3242, 3274, 3788),
    (2698, 3242, 3274, 3788),
    (2698, 3242, 3274, 3788),
    (2698, 3242, 3274, 3788),
    (2698, 3242, 3274, 3788),
    (2696, 3242, 3274, 3788),
    (2696, 3240, 3274, 3788),
)
water_SBZ3_ROSE_CYCLE = tuple(
    tuple(water_colour & ~15 | min((water_colour & 14) + 2, 14) for water_colour in water_row)
    for water_row in water_LZ_BLUE_PULSE_ROWS[6:]
)
water_ARZ_SHADOWS = (3752, 3752, 3752, 3786, 3788, 3788, 3788, 3788, 3786, 3752)
water_ARZ_LIGHT = 3788
water_ICE_VARIANTS = {
    "soft": (((3, 4, 2),), ((2, 4, 2),), ((3, 0, 2),), ((2, 0, 2),)),
    "medium": (((3, 4, 2),), ((2, 4, 2), (1, 4, 2)), ((3, 0, 2),), ((2, 0, 2), (1, 0, 2))),
    "medium_highlight_fixed": (((1, 4, 2),), ((2, 4, 2),), ((1, 0, 2),), ((2, 0, 4),)),
    "medium_highlight_red": (((1, 4, 2),), ((2, 4, 2),), ((3, 0, 2),), ((2, 0, 2), (1, 0, 2))),
    "medium_highlight_green": (((3, 4, 2),), ((2, 4, 2), (1, 4, 2)), ((1, 0, 2),), ((2, 0, 4),)),
    "medium_highlight_dim": (((3, 4, -2),), ((2, 4, 2), (1, 4, 2)), ((1, 0, 2),), ((2, 0, 4),)),
    "strong": (((3, 4, 4),), ((2, 4, 4), (1, 4, 2)), ((3, 0, 4),), ((2, 0, 4), (1, 0, 2))),
}
water_PULSE = (0, 1, 2, 2, 2, 2, 1, 0, 0, 0)


def water_words(data: bytes) -> tuple[int, ...]:
    if len(data) % 2:
        raise ValueError("Odd palette byte count")
    return struct.unpack(">" + "H" * (len(data) // 2), data)


def water_pack(colours: tuple[int, ...] | list[int]) -> bytes:
    return struct.pack(">" + "H" * len(colours), *colours)


def water_normal_colours(zone: str) -> tuple[int, ...]:
    data = (water_ROOT / water_NORMAL_FILES[zone]).read_bytes()
    if len(data) != 32:
        raise ValueError("Expected one 16-colour Sonic palette")
    return water_words(data)[2:6]


def water_interpolate(start: int, end: int, step: int) -> int:
    value = 0
    for shift in (0, 4, 8):
        a = start >> shift & 14
        b = end >> shift & 14
        channel = (a // 2 * (5 - step) + b // 2 * step + 2) // 5 * 2
        value |= channel << shift
    return value


def water_brighten_highlight(colour: int) -> int:
    green = min((colour >> 4 & 14) + 2, 14)
    return colour & ~240 | green << 4


def water_pulsed_colours(target: tuple[int, ...], pulse: int) -> tuple[int, ...]:
    colours = list(target)
    if pulse >= 1:
        colours[3] = water_brighten_highlight(colours[3])
    if pulse >= 2:
        colours[2] = water_brighten_highlight(colours[2])
    return tuple(colours)


def water_ice_cycle(target: tuple[int, ...], variant: str) -> tuple[tuple[int, ...], ...]:
    effects = water_ICE_VARIANTS[variant]
    result = []
    for mask in water_ICE_MASKS:
        colours = list(target)
        for bit, changes in enumerate(effects):
            if mask & 1 << bit:
                for index, shift, increment in changes:
                    channel = max(0, min((colours[index] >> shift & 14) + increment, 14))
                    colours[index] = colours[index] & ~(15 << shift) | channel << shift
        result.append(tuple(colours))
    assert len(result) == len(set(result)) == 10
    assert result[0] == target
    return tuple(result)


def water_aquatic_ruin_lz_cycle() -> tuple[tuple[int, ...], ...]:

    def shift(colour: int) -> int:
        blue = colour >> 8 & 14
        green = (colour >> 4 & 14) - 2
        red = (colour & 14) - 4
        return blue << 8 | green << 4 | red

    light = shift(water_ARZ_LIGHT)
    return tuple((shift(shadow), light, light, light) for shadow in water_ARZ_SHADOWS)


def water_legacy_colour(colour: int, zone: str) -> int:
    blue, green, red = (colour >> 8 & 14, colour >> 4 & 14, colour & 14)
    if zone == "lz":
        return green << 8 | green << 4 | red // 4 * 2
    return min(blue + 2, 14) << 8 | green << 4 | min(red + 4, 14)


def water_frames(
    zone: str, preset: str, dry_cycle: bytes | None = None, ice_variant: str | None = None
) -> tuple[tuple[int, ...], ...]:
    if preset == "legacy":
        if dry_cycle is None or len(dry_cycle) != 16 * 8:
            raise ValueError("Legacy preview needs Sonic 2's 16-frame dry cycle")
        source = water_words(dry_cycle)
        return tuple(
            tuple(water_legacy_colour(source[frame * 4 + index], zone) for index in range(4))
            for frame in range(16)
        )
    normal = water_normal_colours(zone)
    target = water_PRESETS[preset][zone]
    if preset == "ice":
        variant = ice_variant or (
            water_LZ_DEFAULT_CYCLE if zone == "lz" else water_DEFAULT_ICE_VARIANT
        )
        if variant == "blue_pulse":
            if zone != "lz":
                raise ValueError("Blue-grey pulse is only defined for Labyrinth")
            if water_LZ_BLUE_PULSE_ROWS[0] != normal:
                raise ValueError(
                    "Blue-grey transformation does not start from the normal underwater palette"
                )
            return water_LZ_BLUE_PULSE_ROWS
        if variant == "blue_static":
            if zone != "lz":
                raise ValueError("Blue-grey cycle is only defined for Labyrinth")
            if water_LZ_BLUE_STATIC_ROWS[0] != normal:
                raise ValueError(
                    "Blue-grey transformation does not start from the normal underwater palette"
                )
            return water_LZ_BLUE_STATIC_ROWS
        if variant == "rose_pulse":
            if zone != "sbz3":
                raise ValueError("Rose-grey pulse is only defined for Scrap Brain 3")
            cycle = water_SBZ3_ROSE_CYCLE
            target = cycle[0]
        elif variant == "aquatic_ruin":
            if zone != "lz":
                raise ValueError("Aquatic Ruin cycle is only adapted for Labyrinth")
            cycle = water_aquatic_ruin_lz_cycle()
            target = cycle[0]
        else:
            cycle = water_ice_cycle(target, variant)
    result = [
        tuple(water_interpolate(normal[index], target[index], step) for index in range(4))
        for step in range(6)
    ]
    if preset == "ice":
        result.extend(cycle)
    else:
        result.extend(water_pulsed_colours(target, pulse) for pulse in water_PULSE)
    assert len(result) == 16
    assert result[0] == normal and result[5] == target
    for frame in result:
        assert all(colour & 61713 == 0 for colour in frame)
        if not (preset == "ice" and zone == "lz" and (variant == "aquatic_ruin")):
            assert len(set(frame)) == 4
    return tuple(result)


def water_expected_outputs(preset: str = water_DEFAULT) -> dict[Path, bytes]:
    return {
        water_ROOT / water_OUTPUT_FILES[zone]: b"".join(
            water_pack(frame) for frame in water_frames(zone, preset)
        )
        for zone in water_NORMAL_FILES
    }


def water_main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for path, data in water_expected_outputs().items():
        if args.apply:
            path.write_bytes(data)
            print("wrote", path.relative_to(water_ROOT))
        elif not path.exists() or path.read_bytes() != data:
            raise SystemExit(f"Palette differs: {path.relative_to(water_ROOT)}")
    if args.check:
        print("Underwater Super Sonic palettes match", water_DEFAULT)


badnik_ROOT = get_root()
badnik_REPORT_DIR = badnik_ROOT / "tmp/badnik_remap"
badnik_FORBIDDEN = frozenset((2, 3, 4, 5))


def badnik_digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def badnik_palette_words(path: Path) -> list[int]:
    blob = path.read_bytes()
    if len(blob) != 32:
        raise ValueError(f"Expected one palette line in {path}")
    return [int.from_bytes(blob[i : i + 2], "big") for i in range(0, 32, 2)]


def badnik_asm_palette(label: str) -> list[int]:
    source = (badnik_ROOT / "_inc/Palette Index.asm").read_text(encoding="utf-8")
    match = re.search(f"^{label}:\\s*(.*?)(?=^\\w+:|\\Z)", source, re.M | re.S)
    if not match:
        raise ValueError(f"Missing {label} palette")
    words = [int(value, 16) for value in re.findall("\\$([0-9a-fA-F]{4})", match[1])]
    if len(words) != 16:
        raise ValueError(f"Expected 16 colors in {label}, got {len(words)}")
    return words


def badnik_rgb(word: int) -> str:
    return f"#{(word & 14) * 16:02x}{(word >> 4 & 14) * 16:02x}{(word >> 8 & 14) * 16:02x}"


def badnik_display_rgb(word: int) -> tuple[int, int, int]:
    return tuple(
        round(channel * 255 / 14) for channel in (word & 14, word >> 4 & 14, word >> 8 & 14)
    )


def badnik_palette_contract() -> tuple[list[int], list[int], list[int]]:
    normal = badnik_palette_words(badnik_ROOT / "palette/Sonic.bin")
    water = badnik_palette_words(badnik_ROOT / "palette/Sonic - LZ Underwater.bin")
    super_dry = badnik_asm_palette("Pal_SuperSonic")
    super_water = badnik_asm_palette("Pal_SuperSonicWater")
    code = (badnik_ROOT / "_incObj/01 Sonic.asm").read_text(encoding="utf-8")
    routine = code.split("Sonic_RefreshPalettes:\n", 1)[-1].split(
        "; End of function Sonic_RefreshPalettes", 1
    )[0]
    # Resource descriptors now select the palettes; the copy still covers only
    # the four fur colours. Audit both selection and destination ranges.
    routine = re.sub(r"\s+", "", routine)
    if not all(
        fragment in routine
        for fragment in (
            "GetPlayer1Assets_Current",
            "CharacterAsset_Palette(a3)",
            "CharacterAsset_WaterPalette(a3)",
            "CharacterAsset_SBZ3Palette(a3)",
            "(v_palette+4)",
            "(v_palette_water+4)",
        )
    ):
        raise ValueError("Super Sonic palette copy has changed; re-audit forbidden indices")
    if routine.count("move.l4(a1),(a2)+") != 2 or routine.count("move.l8(a1),(a2)") != 2:
        raise ValueError("Super Sonic palette copy length has changed")
    assets = (badnik_ROOT / "_inc/Character Assets.asm").read_text(encoding="utf-8")
    for label, palettes in (
        ("CharacterAssets_Sonic", "Pal_Sonic,Pal_LZSonWater,Pal_SBZ3SonWat"),
        (
            "CharacterAssets_SuperSonic",
            "Pal_SuperSonic,Pal_SuperSonicWater,Pal_SuperSonicSBZ3Water",
        ),
    ):
        descriptor = assets.split(label + ":", 1)[-1].split("\nCharacterAssets_", 1)[0]
        if "dc.l" + palettes not in re.sub(r"\s+", "", descriptor):
            raise ValueError(f"{label} palette sources have changed; re-audit forbidden indices")
    if not all(normal[i] != super_dry[i] and water[i] != super_water[i] for i in badnik_FORBIDDEN):
        raise ValueError("A forbidden color no longer changes; re-audit palette contract")
    return (normal, water, super_dry)


def badnik_used_tiles(mapping_path: Path) -> tuple[list[str], dict, set[int]]:
    frames, pieces = sprites_parse_mappings(mapping_path)
    if not frames or not pieces:
        raise ValueError(f"No mappings in {mapping_path}")
    tiles = {
        piece.tile + offset
        for frame in pieces.values()
        for piece in frame
        for offset in range(piece.width_tiles * piece.height_tiles)
    }
    return (frames, pieces, tiles)


def badnik_remap_asset(
    asset: dict,
    region: dict,
    normal: list[int],
    water: list[int],
    super_dry: list[int],
    baseline: str,
) -> tuple[dict, bytes, bytes, bytes, list[str], dict, list[tuple[Path, bytes]]]:
    badnik_ROOT / asset["art"]
    runtime_lines = (badnik_ROOT / asset["runtime_source"]).read_text(encoding="utf-8").splitlines()
    runtime_tiles = asset.get("runtime_tiles", [asset.get("runtime_tile")])
    runtime_tiles = [tile for tile in runtime_tiles if tile]
    line_zero_initializers = [
        line
        for line in runtime_lines
        if "move.w" in line
        and any(f"#{tile}" in line for tile in runtime_tiles)
        and ("obGfx(a0)" in line)
        and ("Tile_Pal2" not in line)
    ]
    expected_initializers = asset.get("runtime_line0_initializers", 1)
    if len(line_zero_initializers) != expected_initializers:
        raise ValueError(f"Runtime palette line 0 could not be confirmed for {asset['art']}")
    original = (get_source("s1") / asset["art"]).read_bytes()
    if badnik_digest(original) != asset["sha256"]:
        raise ValueError(f"Baseline hash mismatch: {asset['art']}")
    raw = nemesis_decode(original)
    frame_names, frames, selected = badnik_used_tiles(badnik_ROOT / asset["mapping"])
    protected = set()
    if "protected_mapping" in asset:
        _, _, protected = badnik_used_tiles(badnik_ROOT / asset["protected_mapping"])
    if selected & protected:
        raise ValueError(
            f"Shared selected/protected tiles in {asset['art']}: {sorted(selected & protected)}"
        )
    if not selected or max(selected | protected) >= len(raw) // 32:
        raise ValueError(f"Mapping tile outside {asset['art']}")
    destination_indices = {
        badnik_rgb(word): index
        for index, word in enumerate(normal)
        if index != 0 and index not in badnik_FORBIDDEN
    }
    rgb_mapping = asset.get("palette_mapping", region["mapping"])
    lookup = {}
    for index in badnik_FORBIDDEN:
        source_rgb = badnik_rgb(normal[index])
        if source_rgb not in rgb_mapping:
            raise ValueError(f"No RGB choice for index {index} in {asset['region']}")
        destination_rgb = rgb_mapping[source_rgb].lower()
        if destination_rgb not in destination_indices:
            raise ValueError(f"Destination {destination_rgb} is absent from Sonic's stable palette")
        target = destination_indices[destination_rgb]
        if target in badnik_FORBIDDEN or target == 0:
            raise ValueError(f"Destination {target} changes with Super Sonic")
        lookup[index] = target
    changed = bytearray(raw)
    changed_pixels = 0
    for tile in sorted(selected):
        for offset in range(tile * 32, (tile + 1) * 32):
            before = changed[offset]
            high = lookup.get(before >> 4, before >> 4)
            low = lookup.get(before & 15, before & 15)
            changed[offset] = high << 4 | low
            changed_pixels += (high != before >> 4) + (low != before & 15)
    if not changed_pixels:
        raise ValueError(f"No affected pixels in {asset['art']}")
    for tile in selected:
        piece = changed[tile * 32 : (tile + 1) * 32]
        if any(byte >> 4 in badnik_FORBIDDEN or byte & 15 in badnik_FORBIDDEN for byte in piece):
            raise ValueError(f"Forbidden index remains in selected tile {tile}")
    for tile in protected | set(range(len(raw) // 32)) - selected:
        if changed[tile * 32 : (tile + 1) * 32] != raw[tile * 32 : (tile + 1) * 32]:
            raise ValueError(f"Protected tile {tile} changed in {asset['art']}")
    changed = bytearray(shared_remap_art(asset["art"], bytes(changed)))
    packed = nemesis_encode_with_table(original, bytes(changed))
    if nemesis_decode(packed) != changed:
        raise ValueError(f"Nemesis round trip failed for {asset['art']}")
    if len(changed) != len(raw):
        raise ValueError("Tile geometry changed")
    summary = {
        "region": asset["region"],
        "art": asset["art"],
        "object": asset["object"],
        "runtime_source": asset["runtime_source"],
        "runtime_palette_line": 0,
        "tiles": len(raw) // 32,
        "selected_tiles": len(selected),
        "protected_tiles": len(protected),
        "changed_pixels": changed_pixels,
        "index_map": {str(src): dst for src, dst in sorted(lookup.items())},
        "source_sha256": badnik_digest(original),
        "output_sha256": badnik_digest(packed),
        "packed_before": len(original),
        "packed_after": len(packed),
    }
    extra_outputs = []
    if "protected_copy" in asset:
        copy = asset["protected_copy"]
        start = copy["source_first_tile"]
        count = copy["tile_count"]
        protected_raw = raw[start * 32 : (start + count) * 32]
        if len(protected_raw) != count * 32:
            raise ValueError(f"Protected tile range exceeds {asset['art']}")
        template = count.to_bytes(2, "big") + original[2:]
        protected_packed = nemesis_encode_with_table(template, protected_raw)
        if nemesis_decode(protected_packed) != protected_raw:
            raise ValueError(f"Protected copy round trip failed for {asset['art']}")
        protected_path = badnik_ROOT / copy["art"]
        extra_outputs.append((protected_path, protected_packed))
        summary["protected_copy"] = {
            "art": copy["art"],
            "source_first_tile": start,
            "tiles": count,
            "packed_size": len(protected_packed),
            "sha256": badnik_digest(protected_packed),
        }
    return (summary, original, bytes(changed), packed, frame_names, frames, extra_outputs)


object_ROOT = get_root()
object_REPORT = object_ROOT / "tmp/badnik_remap/object_validation.json"
object_FORBIDDEN = frozenset((2, 3, 4, 5))


def object_digest(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


def object_remap_asset(
    asset: dict, maps: dict[str, dict[str, int]], baseline: str
) -> tuple[bytes, bytes, dict]:
    source = (get_source("s1") / asset["art"]).read_bytes()
    if object_digest(source) != asset["sha256"]:
        raise ValueError(f"Baseline hash mismatch: {asset['art']}")
    raw = nemesis_decode(source)
    output = bytearray(raw)
    covered = set()
    rule_reports = []
    for rule in asset["rules"]:
        start, end = rule["tiles"]
        if not 0 <= start < end <= len(raw) // 32:
            raise ValueError(f"Invalid tile range in {asset['art']}: {start}..{end}")
        tiles = set(range(start, end))
        if covered & tiles:
            raise ValueError(f"Overlapping remap rules in {asset['art']}")
        covered |= tiles
        mapping = {int(source_index): target for source_index, target in maps[rule["map"]].items()}
        if (
            set(mapping) != object_FORBIDDEN
            or 0 in mapping.values()
            or set(mapping.values()) & object_FORBIDDEN
        ):
            raise ValueError(f"Unsafe palette map: {rule['map']}")
        changed = 0
        for tile in tiles:
            for offset in range(tile * 32, (tile + 1) * 32):
                before = output[offset]
                high = mapping.get(before >> 4, before >> 4)
                low = mapping.get(before & 15, before & 15)
                output[offset] = high << 4 | low
                changed += (high != before >> 4) + (low != before & 15)
        if not changed:
            raise ValueError(f"Rule changes no pixels: {asset['art']} / {rule['name']}")
        rule_reports.append({**rule, "changed_pixels": changed, "index_map": mapping})
    for tile in covered:
        tile_data = output[tile * 32 : (tile + 1) * 32]
        if any(index in object_FORBIDDEN for byte in tile_data for index in (byte >> 4, byte & 15)):
            raise ValueError(f"Forbidden index remains in remapped tile {tile}: {asset['art']}")
    for tile in set(range(len(raw) // 32)) - covered:
        if output[tile * 32 : (tile + 1) * 32] != raw[tile * 32 : (tile + 1) * 32]:
            raise ValueError(f"Unselected tile changed: {asset['art']} / {tile}")
    output = bytearray(shared_remap_art(asset["art"], bytes(output)))
    packed = nemesis_encode_with_table(source, bytes(output))
    if nemesis_decode(packed) != output:
        raise ValueError(f"Nemesis round trip failed: {asset['art']}")
    return (
        source,
        packed,
        {
            "art": asset["art"],
            "tiles": len(raw) // 32,
            "source_sha256": object_digest(source),
            "output_sha256": object_digest(packed),
            "packed_before": len(source),
            "packed_after": len(packed),
            "changed_pixels": sum(rule["changed_pixels"] for rule in rule_reports),
            "rules": rule_reports,
        },
    )


def object_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--apply", action="store_true")
    action.add_argument("--verify", action="store_true")
    args = parser.parse_args(argv)
    config = load_data("palette_remaps.json")["objects"]
    results = []
    summaries = []
    for asset in config["assets"]:
        source, packed, summary = object_remap_asset(asset, config["maps"], "source files")
        path = object_ROOT / asset["art"]
        current = path.read_bytes() if path.exists() else source
        if args.verify:
            if current != packed:
                raise ValueError(f"Current art differs from the selected remap: {asset['art']}")
        elif args.apply:
            if current not in (source, packed):
                raise ValueError(f"Protect unexpected changes before applying: {asset['art']}")
        elif current != source:
            raise ValueError(f"Audit requires baseline art: {asset['art']}")
        results.append((path, packed))
        summaries.append(summary)
    if args.apply:
        for path, packed in results:
            temporary = path.with_suffix(path.suffix + ".new")
            temporary.write_bytes(packed)
            if nemesis_decode(temporary.read_bytes()) != nemesis_decode(packed):
                raise ValueError(f"Staged art failed validation: {path.relative_to(object_ROOT)}")
            temporary.replace(path)
    report = {
        "mode": "applied" if args.apply else "verified" if args.verify else "audit",
        "source_set": "source files",
        "assets": summaries,
    }
    object_REPORT.parent.mkdir(parents=True, exist_ok=True)
    object_REPORT.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(
        f"{report['mode']}: {len(summaries)} assets, {sum(x['changed_pixels'] for x in summaries)} pixels"
    )
    for summary in summaries:
        print(
            f"  {summary['art']}: {summary['changed_pixels']} pixels, {summary['packed_before']} -> {summary['packed_after']} bytes"
        )
    return 0


bubbles_ROOT = get_root()
bubbles_ART_PATH = bubbles_ROOT / "artnem/LZ Bubbles & Countdown.nem"
bubbles_BUBBLE_RANGES = ((0, 44), (104, 116))
bubbles_GREY = {2: 9, 3: 7, 4: 7, 5: 6}


def bubbles_main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--apply", action="store_true")
    group.add_argument("--check", action="store_true")
    args = parser.parse_args()
    compressed = bubbles_ART_PATH.read_bytes()
    art = bytearray(nemesis_decode(compressed))
    if len(art) != 116 * 32:
        raise ValueError("Unexpected LZ bubble tile count")
    changed = 0
    for first, last in bubbles_BUBBLE_RANGES:
        for offset in range(first * 32, last * 32):
            value = art[offset]
            replacement = bubbles_GREY.get(value >> 4, value >> 4) << 4 | bubbles_GREY.get(
                value & 15, value & 15
            )
            if replacement != value:
                art[offset] = replacement
                changed += 1
    if args.check:
        if changed:
            raise SystemExit(f"LZ bubbles still contain {changed} Sonic palette bytes")
        print("Verified LZ bubbles and bubbler are grey")
        return
    if not changed:
        print("LZ bubbles are already grey")
        return
    output = nemesis_encode_with_table(compressed, bytes(art))
    if nemesis_decode(output) != bytes(art):
        raise ValueError("LZ bubble Nemesis round trip failed")
    bubbles_ART_PATH.write_bytes(output)
    print(f"Recoloured LZ bubbles and bubbler ({changed} bytes)")


platform_ROOT = get_root()
platform_ART_PATH = platform_ROOT / "artnem/SBZ Spinning Platform.nem"
platform_RED = {2: 13, 4: 12}


def platform_main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--apply", action="store_true")
    group.add_argument("--check", action="store_true")
    args = parser.parse_args()
    compressed = platform_ART_PATH.read_bytes()
    art = bytearray(nemesis_decode(compressed))
    if len(art) != 48 * 32:
        raise ValueError("Unexpected SBZ spinning platform tile count")
    changed = 0
    for offset, value in enumerate(art):
        if value >> 4 in (3, 5) or value & 15 in (3, 5):
            raise ValueError("Unexpected blue shade in SBZ spinning platform")
        replacement = platform_RED.get(value >> 4, value >> 4) << 4 | platform_RED.get(
            value & 15, value & 15
        )
        if replacement != value:
            art[offset] = replacement
            changed += 1
    if args.check:
        if changed:
            raise SystemExit(f"SBZ spinning platforms still contain {changed} blue bytes")
        print("Verified SBZ spinning platform undersides are red")
        return
    if not changed:
        print("SBZ spinning platform undersides are already red")
        return
    output = nemesis_encode_with_table(compressed, bytes(art))
    if nemesis_decode(output) != bytes(art):
        raise ValueError("SBZ spinning platform Nemesis round trip failed")
    platform_ART_PATH.write_bytes(output)
    print(f"Recoloured SBZ spinning platform undersides ({changed} bytes)")


seesaw_ROOT = get_root()
seesaw_ART_PATH = seesaw_ROOT / "artnem/SLZ Seesaw.nem"
seesaw_PIVOT_TILES = {*range(14, 20), 22, *range(41, 44)}
seesaw_GREY = {2: 9, 3: 7, 4: 7, 5: 6}


def seesaw_main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--apply", action="store_true")
    group.add_argument("--check", action="store_true")
    args = parser.parse_args()
    compressed = seesaw_ART_PATH.read_bytes()
    art = bytearray(nemesis_decode(compressed))
    if len(art) != 44 * 32:
        raise ValueError("Unexpected SLZ seesaw tile count")
    changed = 0
    for tile in range(len(art) // 32):
        for offset in range(tile * 32, (tile + 1) * 32):
            value = art[offset]
            if tile not in seesaw_PIVOT_TILES:
                if value >> 4 in seesaw_GREY or value & 15 in seesaw_GREY:
                    raise ValueError(f"Unexpected Sonic-palette pixels in tile ${tile:02X}")
                continue
            replacement = seesaw_GREY.get(value >> 4, value >> 4) << 4 | seesaw_GREY.get(
                value & 15, value & 15
            )
            if replacement != value:
                art[offset] = replacement
                changed += 1
    if args.check:
        if changed:
            raise SystemExit(f"SLZ seesaw pivot still contains {changed} Sonic-palette bytes")
        print("Verified SLZ seesaw pivot uses stable greys")
        return
    if not changed:
        print("SLZ seesaw pivot is already grey")
        return
    output = nemesis_encode_with_table(compressed, bytes(art))
    if nemesis_decode(output) != bytes(art):
        raise ValueError("SLZ seesaw Nemesis round trip failed")
    seesaw_ART_PATH.write_bytes(output)
    print(f"Recoloured SLZ seesaw pivot ({changed} bytes)")


button_ROOT = get_root()
button_ART_PATH = button_ROOT / "artnem/Switch.nem"
button_FIRST_TILE = 4
button_TILE_COUNT = 8
button_GREY = {2: 9, 3: 7, 4: 7, 5: 6}


def button_main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--apply", action="store_true", help="recolour the original art")
    group.add_argument("--check", action="store_true", help="verify the original art is recoloured")
    args = parser.parse_args()
    compressed = button_ART_PATH.read_bytes()
    art = bytearray(nemesis_decode(compressed))
    if len(art) != 12 * 32:
        raise ValueError("Unexpected switch art size")
    original_red_tiles = bytes(art[: button_FIRST_TILE * 32])
    changed = 0
    for offset in range(button_FIRST_TILE * 32, (button_FIRST_TILE + button_TILE_COUNT) * 32):
        value = art[offset]
        replacement = button_GREY.get(value >> 4, value >> 4) << 4 | button_GREY.get(
            value & 15, value & 15
        )
        if replacement != value:
            art[offset] = replacement
            changed += 1
    if args.check:
        if changed:
            raise SystemExit(f"Switch art still has {changed} Sonic-dependent bytes")
        print("Verified original switch art is grey")
        return
    if not changed:
        print("Original switch art is already grey")
        return
    output = nemesis_encode_with_table(compressed, bytes(art))
    if (
        nemesis_decode(output) != bytes(art)
        or bytes(art[: button_FIRST_TILE * 32]) != original_red_tiles
    ):
        raise ValueError("Switch Nemesis round trip changed protected red tiles")
    button_ART_PATH.write_bytes(output)
    print(f"Recoloured original switch art ({changed} bytes)")


searchlight_ROOT = get_root()
searchlight_ART_PATH = searchlight_ROOT / "artnem/8x8 - SYZ.nem"
searchlight_FIRST_TILE = 49
searchlight_TILE_COUNT = 24
searchlight_GREY = {2: 9, 3: 7, 4: 7, 5: 6}


def searchlight_main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--apply", action="store_true", help="recolour the primary art")
    group.add_argument("--check", action="store_true", help="verify the primary art is recoloured")
    args = parser.parse_args()
    compressed = searchlight_ART_PATH.read_bytes()
    art = bytearray(nemesis_decode(compressed))
    if len(art) != 882 * 32:
        raise ValueError("Unexpected SYZ primary art size")
    changed = 0
    for offset in range(
        searchlight_FIRST_TILE * 32, (searchlight_FIRST_TILE + searchlight_TILE_COUNT) * 32
    ):
        value = art[offset]
        replacement = searchlight_GREY.get(value >> 4, value >> 4) << 4 | searchlight_GREY.get(
            value & 15, value & 15
        )
        if replacement != value:
            art[offset] = replacement
            changed += 1
    if args.check:
        if changed:
            raise SystemExit(f"SYZ light still has {changed} Sonic-dependent bytes")
        print("Verified rotating light in original SYZ art is grey")
        return
    if not changed:
        print("Original SYZ light art is already grey")
        return
    output = nemesis_encode_with_table(compressed, bytes(art))
    if nemesis_decode(output) != bytes(art):
        raise ValueError("SYZ primary art Nemesis round trip failed")
    searchlight_ART_PATH.write_bytes(output)
    print(f"Recoloured original SYZ light art ({changed} bytes)")


column_ROOT = get_root()
column_ART_PATH = column_ROOT / "artnem/8x8 - SYZ.nem"
column_MAP_PATH = column_ROOT / "map16/SYZ.bin"
column_LEGACY_MAP_PATH = column_ROOT / "map16/SYZ.eni"
column_COLUMN_PIECES = {
    122: (1, (1, 3)),
    132: (1, (1, 3)),
    133: (1, (0, 2)),
    300: (0, (0, 1, 2, 3)),
    301: (0, (0, 1, 2, 3)),
    307: (0, (0, 1, 2, 3)),
    308: (0, (0, 1, 2, 3)),
}
column_GREY = {2: 9, 3: 8, 4: 7, 5: 6}


def column_raw_words(path: Path) -> list[int]:
    blob = path.read_bytes()
    if len(blob) % 8:
        raise ValueError(f"{path.name} is not a whole number of 8-byte blocks")
    return [int.from_bytes(blob[i : i + 2], "big") for i in range(0, len(blob), 2)]


def column_selected_tiles(art: bytes, legacy: bool = False) -> set[int]:
    if legacy:
        if not column_LEGACY_MAP_PATH.exists():
            raise ValueError(f"{column_LEGACY_MAP_PATH.name} not found")
        words = enigma_decode(
            column_LEGACY_MAP_PATH.read_bytes(), legacy_literal_as_incremental=True
        )
    else:
        words = column_raw_words(column_MAP_PATH)
    tiles = set()
    for block, (expected_palette, pieces) in column_COLUMN_PIECES.items():
        for piece in pieces:
            word = words[block * 4 + piece]
            if word >> 13 & 3 != expected_palette:
                raise ValueError(
                    f"Expected palette {expected_palette} at block ${block:03X}, piece {piece}"
                )
            tile = word & 2047
            if any(art[tile * 32 : (tile + 1) * 32]):
                tiles.add(tile)
    if max(tiles) >= len(art) // 32:
        raise ValueError("Selected tile is beyond SYZ art")
    return tiles


def column_main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--apply", action="store_true", help="update the Nemesis art")
    group.add_argument(
        "--check", action="store_true", help="verify that all selected pixels are grey"
    )
    args = parser.parse_args()
    compressed = column_ART_PATH.read_bytes()
    art = bytearray(nemesis_decode(compressed))
    if len(art) // 32 != 882:
        raise ValueError(f"Unexpected SYZ tile count: {len(art) // 32}")
    tiles = column_selected_tiles(art)
    if column_LEGACY_MAP_PATH.exists():
        same = enigma_decode(column_LEGACY_MAP_PATH.read_bytes()) == column_raw_words(
            column_MAP_PATH
        )
        print(
            f"{column_MAP_PATH.name} {('matches' if same else 'DIFFERS FROM')} the exact decode of {column_LEGACY_MAP_PATH.name}"
        )
    try:
        legacy_tiles = column_selected_tiles(art, legacy=True)
    except ValueError as error:
        legacy_tiles = None
        print(f"Old decoder selection failed: {error}")

    def hex_list(values):
        return ", ".join(f"${t:03X}" for t in sorted(values))

    print(f"Selected tiles (exact decoder): {hex_list(tiles)}")
    if legacy_tiles != tiles:
        print(
            "Old decoder selected different tiles: "
            + ("n/a" if legacy_tiles is None else hex_list(legacy_tiles))
        )
    else:
        print("Old decoder selected the same tiles")
    changed = 0
    words = column_raw_words(column_MAP_PATH)
    player_tiles = {word & 2047 for word in words if (word >> 13 & 3) == 0}
    for tile in tiles:
        grey = {**column_GREY, 3: 7} if tile in player_tiles else column_GREY
        for offset in range(tile * 32, (tile + 1) * 32):
            value = art[offset]
            high = grey.get(value >> 4, value >> 4)
            low = grey.get(value & 15, value & 15)
            replacement = high << 4 | low
            if replacement != value:
                art[offset] = replacement
                changed += 1
    if args.check:
        if changed:
            raise SystemExit(f"SYZ still has {changed} bytes with Sonic-dependent colours")
        print(f"Verified {len(tiles)} SYZ cap and shaft tiles")
        return
    if not changed:
        print(f"Already recoloured: {len(tiles)} SYZ cap and shaft tiles")
        return
    if legacy_tiles != tiles:
        raise SystemExit(
            "Refusing to apply: the tile selection differs from the one used for the committed recolour. Review the selection before changing the art."
        )
    output = nemesis_encode_with_table(compressed, bytes(art))
    if nemesis_decode(output) != bytes(art):
        raise ValueError("SYZ Nemesis round trip failed")
    column_ART_PATH.write_bytes(output)
    print(f"Recoloured {len(tiles)} SYZ cap and shaft tiles ({changed} bytes)")


audit_ROOT = get_root()
audit_SOURCE_INDICES = (2, 3, 4, 5)
audit_SAFE_TARGET_ORDER = (12, 13, 14, 15, 10, 11, 8, 9, 7, 6)
audit_MERGE_WARM_MAP = {2: 6, 3: 7, 4: 8, 5: 9}
audit_ASSET_USERS = {
    "artnem/Signpost.nem": ["Signpost"],
    "artnem/Prison Capsule.nem": ["Prison Capsule"],
    "artnem/Lamppost.nem": ["Lamppost"],
    "artnem/Animal Rabbit.nem": ["Animal Rabbit"],
    "artnem/Animal Chicken.nem": ["Animal Chicken"],
    "artnem/Animal Penguin.nem": ["Animal Penguin"],
    "artnem/Animal Seal.nem": ["Animal Seal"],
    "artnem/Animal Pig.nem": ["Animal Pig"],
    "artnem/Animal Flicky.nem": ["Animal Flicky"],
    "artnem/Animal Squirrel.nem": ["Animal Squirrel"],
    "artnem/Enemy Crabmeat.nem": ["Crabmeat"],
    "artnem/Enemy Buzz Bomber.nem": ["Buzz Bomber"],
    "artnem/Enemy Chopper.nem": ["Chopper"],
    "artnem/Enemy Burrobot.nem": ["Burrobot"],
    "artnem/Enemy Motobug.nem": ["Moto Bug"],
    "artnem/Enemy Newtron.nem": ["Newtron (palette 0 variant)"],
    "artnem/Enemy Basaran.nem": ["Basaran"],
    "artnem/Enemy Roller.nem": ["Roller"],
    "artnem/Enemy Bomb.nem": ["Bomb"],
    "artnem/Enemy Orbinaut.nem": ["Orbinaut (LZ/SBZ variants)"],
    "artnem/LZ Gargoyle & Fireball.nem": ["LZ Gargoyle fire variant"],
    "artnem/SBZ Electrocuter.nem": ["Electrocuter"],
    "artnem/Spikes.nem": ["Spikes"],
    "artnem/Spring Horizontal.nem": ["Spring Horizontal"],
    "artnem/Spring Vertical.nem": ["Spring Vertical"],
    "artnem/SBZ Spinning Platform.nem": ["SBZ Spinning Platform"],
    "artnem/Boss - Main.nem": ["Eggman body"],
    "artnem/Boss - Weapons.nem": ["Eggman weapons / seat"],
    "artnem/Boss - Eggman in SBZ2 & FZ.nem": ["Eggman SBZ2/FZ body"],
    "artnem/Boss - Final Zone.nem": ["Final Zone boss"],
    "artnem/Boss - Eggman after FZ Fight.nem": ["Eggman after FZ fight"],
}


@dataclass
class audit_Report:
    asset: str
    users: list[str]
    used_indices: list[int]
    source_indices: list[int]
    is_candidate: bool
    free_stable_indices: list[int]
    direct_map: dict[int, int]
    merge_warm_map: dict[int, int]
    merge_warm_collisions: list[int]


def audit_decode_nemesis(path: Path) -> set[int]:
    data = nemesis_decode(path.read_bytes())
    used: set[int] = set()
    for byte in data:
        used.add(byte >> 4 & 15)
        used.add(byte & 15)
    return used


def audit_build_report(asset: str, users: list[str]) -> audit_Report:
    used = audit_decode_nemesis(audit_ROOT / asset)
    source_used = sorted(set(used) & set(audit_SOURCE_INDICES))
    free_stable = [index for index in audit_SAFE_TARGET_ORDER if index not in used]
    direct_map: dict[int, int] = {}
    if len(free_stable) >= len(source_used):
        direct_map = {
            src: dst for src, dst in zip(source_used, free_stable[: len(source_used)], strict=False)
        }
    merge_warm_map = {src: audit_MERGE_WARM_MAP[src] for src in source_used}
    merge_warm_collisions = sorted(set(merge_warm_map.values()) & used)
    return audit_Report(
        asset=asset,
        users=users,
        used_indices=sorted(used),
        source_indices=source_used,
        is_candidate=bool(source_used),
        free_stable_indices=free_stable,
        direct_map=direct_map,
        merge_warm_map=merge_warm_map,
        merge_warm_collisions=merge_warm_collisions,
    )


def audit_build_reports() -> list[audit_Report]:
    return [audit_build_report(asset, users) for asset, users in audit_ASSET_USERS.items()]


def audit_report_as_json(reports: list[audit_Report]) -> str:
    return json.dumps([report.__dict__ for report in reports], indent=2)


def audit_report_as_text(reports: list[audit_Report]) -> str:
    lines = []
    for report in reports:
        lines.append(f"{report.asset}")
        lines.append(f"  users: {', '.join(report.users)}")
        lines.append(f"  used: {report.used_indices}")
        lines.append(f"  uses_2_5: {report.source_indices}")
        lines.append(f"  candidate: {('yes' if report.is_candidate else 'no')}")
        if report.direct_map:
            lines.append(f"  direct_map: {report.direct_map}")
        else:
            lines.append("  direct_map: none")
        lines.append(f"  merge_warm_map: {report.merge_warm_map}")
        if report.merge_warm_collisions:
            lines.append(f"  merge_warm_collisions: {report.merge_warm_collisions}")
        else:
            lines.append("  merge_warm_collisions: none")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def audit_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="emit JSON instead of text")
    args = parser.parse_args(argv)
    reports = audit_build_reports()
    if args.json:
        sys.stdout.write(audit_report_as_json(reports))
        sys.stdout.write("\n")
    else:
        sys.stdout.write(audit_report_as_text(reports))
    return 0


def remap_parse_mapping(text: str) -> dict[int, int]:
    mapping: dict[int, int] = {}
    for pair in text.split(","):
        left, right = pair.split(":", 1)
        src = int(left.strip(), 0)
        dst = int(right.strip(), 0)
        if not (0 <= src <= 15 and 0 <= dst <= 15):
            raise ValueError(f"invalid nibble mapping {src}:{dst}")
        mapping[src] = dst
    return mapping


def remap_remap_raw_bytes(data: bytes, mapping: dict[int, int]) -> bytes:
    output = bytearray(len(data))
    for i, byte in enumerate(data):
        hi = byte >> 4 & 15
        lo = byte & 15
        hi = mapping.get(hi, hi)
        lo = mapping.get(lo, lo)
        output[i] = hi << 4 | lo
    return bytes(output)


def remap_used_indices(data: bytes) -> list[int]:
    used = set()
    for byte in data:
        used.add(byte >> 4 & 15)
        used.add(byte & 15)
    return sorted(used)


def remap_default_output_path(input_path: Path, strategy: str) -> Path:
    return input_path.with_suffix(f".{strategy}.nem")


def remap_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("asset", help="Path to input .nem file, relative to repo root or absolute")
    parser.add_argument("--strategy", choices=("direct", "merge_warm", "custom"), default="direct")
    parser.add_argument(
        "--map", dest="custom_map", help="Explicit nibble map, e.g. 2:12,3:13,4:14,5:15"
    )
    parser.add_argument("--output", help="Output .nem path")
    parser.add_argument("--in-place", action="store_true", help="Overwrite the input asset")
    parser.add_argument(
        "--dry-run", action="store_true", help="Do not write output, only print analysis"
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON summary")
    parser.add_argument("--apply", action="store_true", help="write the remapped output")
    args = parser.parse_args(argv)
    input_path = Path(args.asset)
    if not input_path.is_absolute():
        input_path = audit_ROOT / input_path
    input_path = input_path.resolve()
    report = audit_build_report(
        str(input_path.relative_to(audit_ROOT)).replace("\\", "/"), [input_path.stem]
    )
    if args.strategy == "custom":
        if not args.custom_map:
            raise SystemExit("--map is required with --strategy custom")
        mapping = remap_parse_mapping(args.custom_map)
    elif args.strategy == "direct":
        if not report.direct_map:
            raise SystemExit(f"No direct_map available for {input_path}")
        mapping = report.direct_map
    else:
        if not report.merge_warm_map:
            raise SystemExit(f"No merge_warm_map available for {input_path}")
        mapping = report.merge_warm_map
    source_bytes = input_path.read_bytes()
    raw_before = nemesis_decode(source_bytes)
    raw_after = remap_remap_raw_bytes(raw_before, mapping)
    nem_after = nemesis_encode_with_table(source_bytes, raw_after)
    summary = {
        "asset": str(input_path.relative_to(audit_ROOT)).replace("\\", "/"),
        "strategy": args.strategy,
        "mapping": mapping,
        "before_used": remap_used_indices(raw_before),
        "after_used": remap_used_indices(raw_after),
        "raw_size": len(raw_before),
        "nem_size_before": len(source_bytes),
        "nem_size_after": len(nem_after),
    }
    if args.apply and not args.dry_run:
        if args.in_place:
            output_path = input_path
        else:
            output_path = (
                Path(args.output)
                if args.output
                else remap_default_output_path(input_path, args.strategy)
            )
            if not output_path.is_absolute():
                output_path = audit_ROOT / output_path
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_bytes(nem_after)
        summary["output"] = str(output_path.relative_to(audit_ROOT)).replace("\\", "/")
    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(f"asset: {summary['asset']}")
        print(f"strategy: {summary['strategy']}")
        print(f"mapping: {summary['mapping']}")
        print(f"before_used: {summary['before_used']}")
        print(f"after_used:  {summary['after_used']}")
        print(
            f"sizes: raw={summary['raw_size']} nem_before={summary['nem_size_before']} nem_after={summary['nem_size_after']}"
        )
        if "output" in summary:
            print(f"output: {summary['output']}")
    return 0


def badnik_main(argv: list[str]) -> int:
    """Reproduce selected enemy remaps from checked original graphics."""
    from s1tools.common import write_outputs

    parser = argparse.ArgumentParser(description=badnik_main.__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--verify", action="store_true")
    args = parser.parse_args(argv)
    data = load_data("palette_remaps.json")
    regions = {r["id"]: r for r in data["rgb"]["regions"]}
    normal, water, super_dry = badnik_palette_contract()
    outputs = {}
    for asset in data["badniks"]["assets"]:
        summary, source, raw, packed, names, frames, extra = badnik_remap_asset(
            asset, regions[asset["region"]], normal, water, super_dry, "checked source"
        )
        path = get_root() / asset["art"]
        if args.apply and path.exists() and path.read_bytes() not in (source, packed):
            raise ValueError(f"Protect changed resource before applying: {path}")
        outputs[path] = packed
        outputs.update(extra)
        print(f"{asset['art']}: {summary['changed_pixels']} changed pixels")
    write_outputs(outputs, apply=args.apply)
    return 0


def preview_main() -> None:
    """Render a portable palette-cycle viewer from explicit palette files."""
    import html

    parser = argparse.ArgumentParser(description=preview_main.__doc__)
    parser.add_argument(
        "--palette", type=Path, required=True, help="one 16-colour Mega Drive palette line"
    )
    parser.add_argument(
        "--cycle", type=Path, required=True, help="four-word rows for Sonic indices 2-5"
    )
    parser.add_argument("--output-file", type=Path, required=True)
    args = parser.parse_args()
    normal = water_words(args.palette.read_bytes())
    cycle = water_words(args.cycle.read_bytes())
    if len(normal) != 16 or not cycle or len(cycle) % 4:
        parser.error("Expected a 16-colour palette and complete four-colour cycle rows")
    frames = []
    for i in range(0, len(cycle), 4):
        row = list(normal)
        row[2:6] = cycle[i : i + 4]
        frames.append([badnik_display_rgb(x) for x in row])
    encoded = json.dumps(frames)
    page = (
        '<!doctype html><html lang="en"><meta charset="utf-8"><title>Palette cycle</title><style>body{background:#181818;color:white;font:18px system-ui}#colours{display:flex}i{width:48px;height:96px;display:block}</style><h1>'
        + html.escape(args.cycle.stem)
        + '</h1><div id="colours"></div><p id="frame"></p><button id="pause">Pause</button><input id="step" type="range" min="0" max="'
        + str(len(frames) - 1)
        + '" value="0"><script>const frames='
        + encoded
        + ';let n=0,playing=true;function draw(){document.querySelector("#colours").innerHTML=frames[n].map(x=>`<i style="background:rgb(${x})"></i>`).join("");document.querySelector("#frame").textContent=`Frame ${n+1}/${frames.length}`;document.querySelector("#step").value=n}document.querySelector("#pause").onclick=()=>playing=!playing;document.querySelector("#step").oninput=e=>{playing=false;n=Number(e.target.value);draw()};setInterval(()=>{if(playing){n=(n+1)%frames.length;draw()}},133);draw()</script></html>'
    )
    if args.output_file.exists():
        parser.error("Output already exists")
    args.output_file.parent.mkdir(parents=True, exist_ok=True)
    args.output_file.write_text(page, encoding="utf8")
