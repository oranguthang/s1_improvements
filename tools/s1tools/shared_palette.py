"""Reindex player-line graphics for Sonic, Tails and Knuckles to share colours."""

from __future__ import annotations

import argparse
from pathlib import Path

from s1tools.codecs.kosinski import decode_moduled, encode_moduled
from s1tools.codecs.nemesis import decode, encode_with_table
from s1tools.common import get_root, get_source, load_data, write_outputs

LEGACY = {8: 7, 14: 13, 15: 14}


def remap_art(path: str, raw: bytes) -> bytes:
    """Remap only audited player-line tiles; other palette lines stay intact."""
    asset = load_data("shared_player_palette.json")["assets"].get(path)
    if asset is None:
        return raw
    output = bytearray(raw)
    lookup = {int(k): v for k, v in asset.get("colours", LEGACY).items()}
    for start, end in asset["ranges"]:
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


def expected_outputs() -> dict[Path, bytes]:
    source, root = get_source("shared"), get_root()
    config = load_data("shared_player_palette.json")
    outputs = {}
    for name, asset in config["assets"].items():
        data = (source / asset["source"]).read_bytes()
        suffix = Path(name).suffix
        raw = (
            decode(data)
            if suffix == ".nem"
            else decode_moduled(data)
            if suffix == ".kosm"
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
        for index, colour in (
            (8, asset["green"]),
            (14, asset["orange"][0]),
            (15, asset["orange"][1]),
        ):
            data[index * 2 : index * 2 + 2] = colour.to_bytes(2, "big")
        outputs[root / name] = bytes(data)
    return outputs


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write palettes and reindexed art")
    args = parser.parse_args(argv)
    write_outputs(expected_outputs(), apply=args.apply)
    return 0
