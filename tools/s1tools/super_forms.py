"""Super Tails and Super Knuckles palettes adapted from Sonic 3 & Knuckles.

The steady cycles are PalCycle_SuperTails and PalCycle_SuperHyperKnuckles from
https://github.com/sonicretro/skdisasm, written to the Sonic 1 protected player
slots 2-5. Each table has the Super Sonic layout: six transformation frames
from the normal palette, followed by ten steady frames. The underwater cycles
apply the colour change that turns the character's dry palette into its
approved Labyrinth or Scrap Brain Act 3 palette.

The Super Flicky art and mappings are converted from S3K's Super Tails birds.
"""

from __future__ import annotations

import argparse
import math
import struct
from pathlib import Path

from s1tools.codecs.kosinski import decode_moduled
from s1tools.common import get_root, get_source, write_outputs
from s1tools.tails import PLAYER_COLOURS

# S3K colour order per frame: Tails writes indices 8, 9 and 11; Knuckles 2, 3 and 4.
S3K_SUPER_TAILS = (
    (0x0AE, 0x08E, 0x46A),
    (0x4CE, 0x2AE, 0x46A),
    (0x8CE, 0x4CE, 0x46C),
    (0xAEE, 0x8CE, 0x48E),
    (0x8CE, 0x4CE, 0x46C),
    (0x4CE, 0x2AE, 0x46A),
)
S3K_SUPER_KNUCKLES = (
    (0xA6E, 0x64E, 0x428),
    (0xC8E, 0x86E, 0x64A),
    (0xEAE, 0xA8E, 0x86C),
    (0xECE, 0xCAE, 0xA8E),
    (0xEEE, 0xECE, 0xCAE),
    (0xECE, 0xCAE, 0xA8E),
    (0xEAE, 0xA8E, 0x86C),
    (0xC8E, 0x86E, 0x64A),
    (0xA6E, 0x64E, 0x428),
    (0x84E, 0x40C, 0x206),
)
# Obj_SuperTailsBirds draws its blue shades 2-4 with the Super Sonic cycle;
# here they follow Super Tails' cycling slots 5, 4 and 3 instead.
FLICKY_COLOURS = (*PLAYER_COLOURS[:2], 5, 4, 3, *PLAYER_COLOURS[5:])
FLICKY_ART = "General/Sprites/Tails/Art/Super Tails birds.bin"
FLICKY_MAP = "General/Sprites/Tails/Map - Super Tails birds.asm"
FADE_FRAMES = 6
STEADY_FRAMES = 10
ZONES = ("", " - LZ Underwater", " - SBZ3 Underwater")


def words(data: bytes) -> list[int]:
    return list(struct.unpack(f">{len(data) // 2}H", data))


def pack(colours: list[int] | tuple[int, ...]) -> bytes:
    return struct.pack(f">{len(colours)}H", *colours)


def _linear(channel: float) -> float:
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def oklab(word: int) -> tuple[float, float, float]:
    r, g, b = (_linear(((word >> shift) & 0xE) / 14) for shift in (0, 4, 8))
    lms = (
        0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b,
        0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b,
        0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b,
    )
    long, medium, short = (math.copysign(abs(v) ** (1 / 3), v) for v in lms)
    return (
        0.2104542553 * long + 0.7936177850 * medium - 0.0040720468 * short,
        1.9779984951 * long - 2.4285922050 * medium + 0.4505937099 * short,
        0.0259040371 * long + 0.7827717662 * medium - 0.8086757660 * short,
    )


MD_COLOURS = [
    b << 8 | g << 4 | r for b in range(0, 16, 2) for g in range(0, 16, 2) for r in range(0, 16, 2)
]
MD_LABS = {word: oklab(word) for word in MD_COLOURS}


def nearest(target: tuple[float, float, float]) -> int:
    return min(MD_COLOURS, key=lambda word: math.dist(MD_LABS[word], target))


def _solve(rows: list[list[float]], values: list[float]) -> list[float]:
    size = len(rows[0])
    matrix = [
        [sum(r[i] * r[j] for r in rows) for j in range(size)]
        + [sum(r[i] * v for r, v in zip(rows, values, strict=True))]
        for i in range(size)
    ]
    for i in range(size):
        pivot = max(range(i, size), key=lambda k: abs(matrix[k][i]))
        matrix[i], matrix[pivot] = matrix[pivot], matrix[i]
        for k in range(size):
            if k != i:
                factor = matrix[k][i] / matrix[i][i]
                matrix[k] = [a - factor * b for a, b in zip(matrix[k], matrix[i], strict=True)]
    return [matrix[i][size] / matrix[i][i] for i in range(size)]


def water_transform(pairs: list[tuple[int, int]]):
    """Fit lightness and a rotation/scale of chroma that map dry to wet colours."""
    dry = [oklab(a) for a, _ in pairs]
    wet = [oklab(b) for _, b in pairs]
    gain, offset = _solve([[d[0], 1] for d in dry], [w[0] for w in wet])
    rows, values = [], []
    for d, w in zip(dry, wet, strict=True):
        rows += [[d[1], -d[2], 1, 0], [d[2], d[1], 0, 1]]
        values += [w[1], w[2]]
    c, s, oa, ob = _solve(rows, values)

    def convert(word: int) -> int:
        light, a, b = oklab(word)
        return nearest((gain * light + offset, c * a - s * b + oa, s * a + c * b + ob))

    return convert


def lerp_colour(start: int, end: int, t: float) -> int:
    a, b = oklab(start), oklab(end)
    return nearest(tuple(x + (y - x) * t for x, y in zip(a, b, strict=True)))


def steady_frames(name: str, normal: list[int]) -> list[list[int]]:
    """Map the S3K cycle to slots 2-5, padding a short cycle with its last frame."""
    if name == "Tails":
        frames = [[normal[0], c2, c1, c0] for c0, c1, c2 in S3K_SUPER_TAILS]
    else:
        frames = [[c2, normal[1], c1, c0] for c0, c1, c2 in S3K_SUPER_KNUCKLES]
    return frames + [frames[-1]] * (STEADY_FRAMES - len(frames))


def cycles(root: Path, name: str) -> dict[str, list[list[int]]]:
    normal = {zone: words((root / f"palette/{name}{zone}.bin").read_bytes())[2:6] for zone in ZONES}
    dry_steady = steady_frames(name, normal[""])
    result = {}
    for zone in ZONES:
        if zone:
            convert = water_transform(list(zip(normal[""], normal[zone], strict=True)))
            steady = [
                [
                    wet if colour == dry else convert(colour)
                    for colour, dry, wet in zip(frame, normal[""], normal[zone], strict=True)
                ]
                for frame in dry_steady
            ]
        else:
            steady = dry_steady
        fade = [
            [
                lerp_colour(a, b, step / FADE_FRAMES)
                for a, b in zip(normal[zone], steady[0], strict=True)
            ]
            for step in range(FADE_FRAMES)
        ]
        result[zone] = fade + steady
    return result


def decode_padded(blob: bytes) -> bytes:
    """S3K pads its last KosM module to a 16-byte boundary."""
    for padding in range(16):
        if not any(blob[len(blob) - padding :]):
            try:
                return decode_moduled(blob[: len(blob) - padding])
            except ValueError:
                continue
    raise ValueError("unrecognised KosM padding")


def flicky_mappings(text: str) -> bytes:
    """Convert S3K's three single-piece frames to Sonic 1 mapping macros."""
    frames = []
    for line in text.splitlines():
        if "dc.b" in line:
            y, size, _, tile, _, x = (
                int(v.strip().replace("$", "0x"), 16) for v in line.split("dc.b")[1].split(",")
            )
            frames.append(
                (
                    x - 256 if x > 127 else x,
                    y - 256 if y > 127 else y,
                    (size >> 2) + 1,
                    (size & 3) + 1,
                    tile,
                )
            )
    lines = [
        "; Generated by s1tools player super-forms from S3K's Super Tails birds.",
        "Map_SuperTailsFlickies_internal:\tmappingsTable",
    ]
    lines += [
        f"\tmappingsTableEntry.w\tMap_SuperTailsFlickies_internal_{i}" for i in range(len(frames))
    ]
    for i, (x, y, w, h, tile) in enumerate(frames):
        lines += ["", f"Map_SuperTailsFlickies_internal_{i}:\tspriteHeader"]
        lines.append(f"\tspritePiece\t{x}, {y}, {w}, {h}, {tile}, 0, 0, 0, 0")
        lines.append(f"Map_SuperTailsFlickies_internal_{i}_End")
    lines += ["", "\teven", ""]
    return "\n".join(lines).encode("ascii")


def expected_outputs() -> dict[Path, bytes]:
    root = get_root()
    outputs = {}
    source = get_source("sk")
    art = decode_padded((source / FLICKY_ART).read_bytes())
    outputs[root / "artunc/Super Tails Flickies.unc"] = bytes(
        (FLICKY_COLOURS[b >> 4] << 4) | FLICKY_COLOURS[b & 15] for b in art
    )
    outputs[root / "_maps/Super Tails Flickies.asm"] = flicky_mappings(
        (source / FLICKY_MAP).read_text()
    )
    for name in ("Tails", "Knuckles"):
        for zone, frames in cycles(root, name).items():
            suffix = zone.replace(" - ", " ") if zone else ""
            outputs[root / f"palette/Cycle - Super {name}{suffix}.bin"] = pack(
                [colour for frame in frames for colour in frame]
            )
            # The static Super palette is the first steady frame on the normal line.
            line = words((root / f"palette/{name}{zone}.bin").read_bytes())
            line[2:6] = frames[FADE_FRAMES]
            outputs[root / f"palette/Super {name}{zone}.bin"] = pack(line)
    return outputs


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write the resources")
    args = parser.parse_args(argv)
    write_outputs(expected_outputs(), apply=args.apply)
    return 0
