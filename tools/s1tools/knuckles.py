"""Import Sonic 3 & Knuckles Knuckles into the Sonic 1 player frame layout."""

from __future__ import annotations

import argparse
from pathlib import Path

from s1tools.codecs.kosinski import encode_moduled
from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.common import get_root, get_source, write_outputs
from s1tools.shared_palette import life_icon, player_palettes
from s1tools.tails import emit_frames, frame, raw_table

BASE = "General/Sprites/Knuckles/"
# Fur owns the protected 2..5 ramp; shoes retain stable red/orange/green.
COLOURS = (0, 6, 5, 4, 2, 8, 12, 13, 14, 15, 10, 11, 7, 7, 9, 1)
GLIDE = 0x75
FALL = 0x7A
SLIDE = 0x7C
CLIMB = 0x7E
LEDGE = 0x84
FRAME_COUNT = 0x93


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
        assign(index, 0x86 + index - 0x33)
    for index, source in (
        (0x37, 0x9D),
        (0x38, 0x9E),
        (0x39, 0x9B),
        (0x3A, 0x9F),
        (0x3B, 0xA0),
        (0x3C, 0xAE),
        (0x3D, 0xAF),
        (0x3E, 0xAE),
        (0x3F, 0xAF),
        (0x40, 0x8E),
        (0x41, 0xB1),
        (0x42, 0xB2),
        (0x43, 1),
        (0x44, 2),
        (0x49, 0x91),
        (0x4A, 0xB0),
        (0x4B, 0xAC),
        (0x4C, 0xAD),
        (0x4D, 0xAB),
        (0x53, 0xAE),
        (0x54, 0xAF),
        (0x55, 0x8D),
        (0x56, 0xB0),
        (0x57, 0x8C),
        (0x73, 1),
        (0x74, 5),
    ):
        assign(index, source)
    for step in range(4):
        assign(0x45 + step, 0xCE + step)
    for step in range(5):
        assign(0x4E + step, 0x86 + step)
    for step in range(6):
        assign(0x58 + step, 0x86 + step)
    for step in range(5):
        assign(0x6E + step, 0x8E)
        assign(GLIDE + step, 0xC0 + step)
    for step in range(2):
        assign(FALL + step, 0xCA + step)
        assign(SLIDE + step, 0xCC + step)
    for step in range(6):
        assign(CLIMB + step, 0xB7 + step)
    for step in range(3):
        assign(LEDGE + step, 0xBD + step)
    for step in range(12):
        assign(0x87 + step, 0x9F + step)
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
    outputs = {
        root / "artunc/Knuckles.unc": packed,
        root / "_maps/Knuckles.asm": mappings,
        root / "_maps/Knuckles - Dynamic Gfx Script.asm": dplc,
        root / "artkosm/HUD - Knuckles Life Counter Icon.kosm": encode_moduled(
            life_icon(icon, COLOURS)
        ),
    }
    outputs.update(
        player_palettes(
            "Knuckles",
            (0x0206, 0x020A, 0x020C, 0x064E),
            (0x0024, 0x0246, 0x0468, 0x068A),
            (0x0426, 0x0648, 0x086A, 0x0CAE),
        )
    )
    return outputs


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write converted resources")
    args = parser.parse_args(argv)
    write_outputs(expected_outputs(get_source("sk")), apply=args.apply)
    return 0
