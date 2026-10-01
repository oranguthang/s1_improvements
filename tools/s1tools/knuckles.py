"""Import Sonic 3 & Knuckles Knuckles into the Sonic 1 player frame layout."""

from __future__ import annotations

import argparse
from pathlib import Path

from s1tools.codecs.kosinski import encode_moduled
from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.common import get_root, get_source, write_outputs
from s1tools.shared_palette import life_icon
from s1tools.tails import emit_frames, frame, raw_table

BASE = "General/Sprites/Knuckles/"
# Shared player line: red body/shoes, orange cuffs and green shoe panels.
COLOURS = (0, 6, 12, 12, 13, 8, 12, 13, 14, 15, 10, 11, 7, 7, 9, 1)
GLIDE = 0x75
FALL = 0x7A
SLIDE = 0x7C
CLIMB = 0x7E
LEDGE = 0x84
FRAME_COUNT = 0x8B


def frame_plan() -> list[tuple[int, int, int]]:
    """S3K frame ID and origin adjustment for each S1 frame."""
    plan = [(0x56, 0, 0)] * FRAME_COUNT

    def assign(index: int, source: int, dx: int = 0, dy: int = 0) -> None:
        plan[index] = (source, dx, dy)

    assign(0, 0)
    for index, source in enumerate((0x56, 0xD2, 0xD3, 0xD5, 0xD6), 1):
        assign(index, source)
    for group in range(4):
        for step, source in enumerate((1, 2, 4, 5, 6, 8)):
            assign(6 + group * 6 + step, source + group * 8)
        for step in range(4):
            assign(0x1E + group * 4 + step, 0x21 + group * 4 + step)
            assign(0x5E + group * 4 + step, 0x21 + group * 4 + step)
    for index, source in enumerate((0x96, 0x97, 0x9A, 0x98, 0x99), 0x2E):
        assign(index, source)
    for index in range(0x33, 0x37):
        assign(index, 0xCE + index - 0x33)
    for index, source in (
        (0x37, 0xB1),
        (0x38, 0xB3),
        (0x39, 0x9B),
        (0x3A, 0xB2),
        (0x3B, 0xB4),
        (0x3C, 0x86),
        (0x3D, 0x87),
        (0x3E, 0x88),
        (0x3F, 0x89),
        (0x40, 0x9F),
        (0x41, 0x9D),
        (0x42, 0x9E),
        (0x43, 0xAF),
        (0x44, 0xAE),
        (0x49, 0x8F),
        (0x4A, 0x8E),
        (0x4B, 0x91),
        (0x4C, 0x91),
        (0x4D, 0x91),
        (0x53, 0xB5),
        (0x54, 0xB6),
        (0x55, 0x8C),
        (0x56, 0xB0),
        (0x57, 0x8D),
        (0x73, 1),
        (0x74, 5),
    ):
        assign(index, source)
    for step in range(4):
        assign(0x45 + step, 0x92 + step)
    for step in range(5):
        assign(0x4E + step, 0x86 + step)
    for step in range(6):
        assign(0x58 + step, (0x9A, 0x96, 0x97, 0x98, 0x99, 0x9A)[step])
    for step in range(5):
        assign(0x6E + step, 0x86 + step)
        assign(GLIDE + step, 0xC0 + step)
    for step in range(2):
        assign(FALL + step, 0xCA + step)
        assign(SLIDE + step, 0xCC + step)
    for step in range(6):
        assign(CLIMB + step, 0xB7 + step)
    for step in range(3):
        assign(LEDGE + step, 0xBD + step)
    for step in range(4):
        assign(0x87 + step, 0xB1 + step)
    return plan


def expected_outputs(source: Path) -> dict[Path, bytes]:
    root = get_root()
    art = (source / (BASE + "Art/Knuckles.bin")).read_bytes()
    maps = raw_table(source / (BASE + "Map - Knuckles.asm"))
    cues = raw_table(source / (BASE + "DPLC - Knuckles.asm"))
    frames = []
    for source_id, dx, dy in frame_plan():
        data, pieces = frame(art, maps, cues, source_id, COLOURS)
        frames.append((data, [(x + dx, y + dy, *rest) for x, y, *rest in pieces]))
    packed, mappings, dplc = emit_frames("Knuckles", frames)
    icon = nemesis_decode((source / "General/Sprites/HUD Icon/Knuckles Life Icon.bin").read_bytes())
    return {
        root / "artunc/Knuckles.unc": packed,
        root / "_maps/Knuckles.asm": mappings,
        root / "_maps/Knuckles - Dynamic Gfx Script.asm": dplc,
        root / "artkosm/HUD - Knuckles Life Counter Icon.kosm": encode_moduled(
            life_icon(icon, COLOURS)
        ),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write converted resources")
    args = parser.parse_args(argv)
    write_outputs(expected_outputs(get_source("sk")), apply=args.apply)
    return 0
