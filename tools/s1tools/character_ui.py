"""Adapt shared title-card colours and S3K signpost portraits for solo players."""

from __future__ import annotations

import argparse
from pathlib import Path

from s1tools import knuckles, tails
from s1tools.codecs.kosinski import decode_moduled, encode_moduled
from s1tools.codecs.nemesis import decode, encode_with_table
from s1tools.common import get_root, get_source, write_outputs

SIGN_BASE = "General/Sprites/Signpost/"
GRAY = {1: 9, 2: 9, 3: 8, 4: 8, 5: 7}


def title_card(raw: bytes) -> bytes:
    """Recolour only the large and bonus ovals, retaining letters and numbers."""
    if len(raw) != 128 * 32:
        raise ValueError("Expected the original 128-tile Sonic 1 title card")
    result = bytearray(raw)
    for position in range(0x6E * 32, 0x80 * 32):
        byte = raw[position]
        result[position] = GRAY.get(byte >> 4, byte >> 4) << 4 | GRAY.get(byte & 15, byte & 15)
    return bytes(result)


def sign_portrait(source: Path, frame: int, colours: tuple[int, ...]) -> bytes:
    """S3K end-sign DPLC stores tile counts in the low nibble, unlike players."""
    art = (source / (SIGN_BASE + "End Signs.bin")).read_bytes()
    maps = tails.raw_table(source / (SIGN_BASE + "Map - End Signs.asm"))
    cues = tails.raw_table(source / (SIGN_BASE + "DPLC - End Signs.asm"))
    record = maps[1][maps[0][frame]]
    # The two 3x4 pieces match S1's front face exactly, including the origins.
    if record != bytes.fromhex("0002 f00b0000ffe8 f00b000c0000"):
        raise ValueError("S3K portrait no longer matches the Sonic 1 signpost face")
    cue = cues[1][cues[0][frame]]
    count = int.from_bytes(cue[:2], "big") + 1
    if len(cue) != 2 + count * 2:
        raise ValueError("Invalid end-sign DPLC")
    tiles = bytearray()
    for position in range(count):
        word = int.from_bytes(cue[2 + position * 2 : 4 + position * 2], "big")
        start, length = (word >> 4) * 32, ((word & 15) + 1) * 32
        chunk = art[start : start + length]
        if len(chunk) != length:
            raise ValueError("End-sign DPLC exceeds source graphics")
        tiles.extend(chunk)
    if len(tiles) != 24 * 32:
        raise ValueError("Expected a 24-tile signpost portrait")
    return bytes(colours[byte >> 4] << 4 | colours[byte & 15] for byte in tiles)


def monitor_portrait(source: Path, name: str, colours: tuple[int, ...]) -> bytes:
    """Reuse the four-tile S3K life portrait, with the S1 monitor white backdrop."""
    raw = decode((source / f"General/Sprites/HUD Icon/{name} Life Icon.bin").read_bytes())
    if len(raw) != 12 * 32:
        raise ValueError("Expected a four-tile face and eight-tile lives label")
    lookup = (6, *colours[1:])
    return bytes(lookup[b >> 4] << 4 | lookup[b & 15] for b in raw[: 4 * 32])


def expected_outputs() -> dict[Path, bytes]:
    root, source, sk = get_root(), get_source("s1"), get_source("sk")
    template = (source / "artnem/Title Cards.nem").read_bytes()
    raw = title_card(decode(template))
    if decode_moduled((source / "artkosm/Title Cards.kosm").read_bytes()) != decode(template):
        raise ValueError("Title-card source formats differ")
    return {
        root / "artkosm/Monitor - Tails 1UP.kosm": encode_moduled(
            monitor_portrait(sk, "Tails", tails.COLOURS)
        ),
        root / "artkosm/Monitor - Knuckles 1UP.kosm": encode_moduled(
            monitor_portrait(sk, "Knuckles", knuckles.COLOURS)
        ),
        root / "artnem/Title Cards.nem": encode_with_table(template, raw),
        root / "artkosm/Title Cards.kosm": encode_moduled(raw),
        root / "artkosm/Signpost - Tails Portrait.kosm": encode_moduled(
            sign_portrait(sk, 1, tails.COLOURS)
        ),
        root / "artkosm/Signpost - Knuckles Portrait.kosm": encode_moduled(
            sign_portrait(sk, 2, knuckles.COLOURS)
        ),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write title cards and portraits")
    args = parser.parse_args(argv)
    write_outputs(expected_outputs(), apply=args.apply)
    return 0
