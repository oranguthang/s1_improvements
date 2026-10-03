"""Reindex player-line graphics for Sonic, Tails and Knuckles to share colours."""

from __future__ import annotations

import argparse
from pathlib import Path

from s1tools.codecs.kosinski import decode_moduled, encode_moduled
from s1tools.codecs.nemesis import decode, encode_with_table
from s1tools.common import get_root, get_source, load_data, write_outputs


def remap_art(path: str, raw: bytes) -> bytes:
    """Remap only audited player-line tiles; other palette lines stay intact."""
    asset = load_data("shared_player_palette.json")["assets"].get(path)
    if asset is None:
        return raw
    output = bytearray(raw)
    rules = [{"tiles": tiles, "colours": asset.get("colours", {})} for tiles in asset["ranges"]]
    rules.extend(asset.get("colour_overrides", []))
    for rule in rules:
        lookup = {int(k): v for k, v in rule["colours"].items()}
        start, end = rule["tiles"]
        if not 0 <= start <= end <= len(raw) // 32:
            raise ValueError(f"Shared palette tile range outside {path}")
        for position in range(start * 32, end * 32):
            if "text_tiles" in asset and position >= asset["text_tiles"] * 32:
                lookup = {15: 12}  # original HUD text uses yellow, separate from the face
            byte = raw[position]
            output[position] = lookup.get(byte >> 4, byte >> 4) << 4 | lookup.get(
                byte & 15, byte & 15
            )
    return bytes(output)


def life_icon(raw: bytes, colours: tuple[int, ...]) -> bytes:
    """S3K faces use the player line, while the name/count use the HUD line."""
    if len(raw) != 12 * 32:
        raise ValueError("Expected a four-tile face and eight-tile lives label")
    face = bytes((colours[b >> 4] << 4) | colours[b & 15] for b in raw[:128])
    text = {0: 0, 1: 6, 5: 12, 14: 9, 15: 1}
    if any(n not in text for b in raw[128:] for n in (b >> 4, b & 15)):
        raise ValueError("Unexpected S3K lives-label colour")
    return face + bytes((text[b >> 4] << 4) | text[b & 15] for b in raw[128:])


def player_palettes(
    name: str,
    dry: tuple[int, ...],
    water: tuple[int, ...],
    sbz3: tuple[int, ...],
) -> dict[Path, bytes]:
    """Replace only the selected solo player's protected colour slots."""
    root = get_root()
    outputs = {}
    for suffix, ramp in (("", dry), (" - LZ Underwater", water), (" - SBZ3 Underwater", sbz3)):
        if len(ramp) != 4 or any(word & ~0xEEE for word in ramp):
            raise ValueError("Expected four Mega Drive colour words")
        data = bytearray((root / f"palette/Sonic{suffix}.bin").read_bytes())
        data[4:12] = b"".join(word.to_bytes(2, "big") for word in ramp)
        outputs[root / f"palette/{name}{suffix}.bin"] = bytes(data)
    return outputs


def expected_outputs() -> dict[Path, bytes]:
    source, root = get_source("shared"), get_root()
    config = load_data("shared_player_palette.json")
    outputs = {}
    sources = {"shared": source}
    for name, asset in config["assets"].items():
        group = asset.get("source_group", "shared")
        if group not in sources:
            sources[group] = get_source(group)
        data = (sources[group] / asset["source"]).read_bytes()
        suffix = Path(name).suffix
        input_suffix = Path(asset["source"]).suffix
        raw = (
            decode(data)
            if input_suffix == ".nem"
            else decode_moduled(data)
            if input_suffix == ".kosm"
            else data
        )
        changed = remap_art(name, raw)
        packed = (
            encode_with_table(data, changed)
            if suffix == ".nem"
            else encode_moduled(changed)
            if suffix == ".kosm"
            else changed
        )
        outputs[root / name] = packed
    for name, asset in config["palettes"].items():
        data = bytearray((source / asset["source"]).read_bytes())
        # Colour 0 of a line is never drawn by tiles; the water edge uses it.
        for index, word in asset.get("colours", {}).items():
            data[int(index) * 2 : int(index) * 2 + 2] = int(word, 16).to_bytes(2, "big")
        outputs[root / name] = bytes(data)
    return outputs


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write palettes and reindexed art")
    args = parser.parse_args(argv)
    write_outputs(expected_outputs(), apply=args.apply)
    return 0
