"""Import Sonic 1 mobile ending poses into the Mega Drive ending sequence."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from s1tools.codecs.kosinski import decode_moduled, encode_moduled
from s1tools.codecs.nemesis import decode
from s1tools.common import get_root, get_source, write_outputs

ENDING_TILES = 0x524 - 0x3E1  # Retain even the unused Revision 0 Eggman slot.
# Exact sheet colours mapped into the solo player's shared 16-colour line.
COMMON_COLOURS = {
    (255, 0, 255): 0,
    (0, 0, 0): 1,
    (8, 0, 0): 1,
    (32, 0, 0): 1,
    (0, 32, 32): 1,
    (32, 64, 64): 9,
    (96, 96, 160): 8,
    (160, 160, 224): 7,
    (224, 224, 224): 6,
    (255, 255, 255): 6,
    (160, 160, 160): 7,
    (128, 128, 128): 8,
    (64, 64, 64): 9,
    (224, 160, 128): 10,
    (160, 96, 64): 11,
    (224, 0, 0): 12,
    (128, 0, 0): 13,
}
TAILS_COLOURS = {
    **COMMON_COLOURS,
    (192, 96, 0): 2,
    (224, 128, 0): 4,
    (224, 160, 0): 5,
    # The mobile portrait adds cool highlights; quantize them to shared grays.
    (192, 224, 224): 6,
    (160, 192, 224): 7,
}
KNUCKLES_COLOURS = {
    **COMMON_COLOURS,
    (96, 0, 32): 2,
    (0, 128, 0): 3,
    (192, 0, 32): 4,
    (224, 64, 96): 5,
    (32, 64, 32): 9,
    (224, 128, 0): 15,
    (224, 160, 0): 15,
}
# Hold, glowing gems, look up, look right/left, crouch, near jump, final pose.
# Bounds exclude sheet separators; origins retain the S1 floor and leap heights.
POSES = {
    "Tails": (
        (0, 217, 27, 251),
        (28, 217, 58, 251),
        (87, 219, 118, 251),
        (119, 217, 144, 251),
        (145, 217, 170, 251),
        (0, 253, 24, 284),
        (0, 350, 32, 385),
        (33, 289, 144, 385),
    ),
    "Knuckles": (
        (232, 23, 255, 64),
        (256, 23, 284, 64),
        (285, 24, 330, 64),
        (331, 23, 364, 64),
        (365, 23, 398, 64),
        (468, 23, 495, 64),
        (264, 68, 296, 107),
        (311, 68, 375, 172),
    ),
}
# Sparkles enlarge the glowing crop without moving the underlying body.
# Register it to the holding pose, rather than centering its full crop bounds.
GLOW_OFFSETS = {"Tails": (-1, 0), "Knuckles": (-2, 0)}


def mobile_frames(sheet: Image.Image, name: str) -> list[Image.Image]:
    colours = TAILS_COLOURS if name == "Tails" else KNUCKLES_COLOURS
    frames = []
    for index, bounds in enumerate(POSES[name]):
        crop = sheet.crop(bounds)
        pose = Image.new("P", crop.size)
        for y in range(crop.height):
            for x in range(crop.width):
                colour = crop.getpixel((x, y))
                if colour not in colours:
                    raise ValueError(f"Unknown {name} ending colour {colour} at {index}:{x},{y}")
                pose.putpixel((x, y), colours[colour])
        image = Image.new("P", (256, 256))
        bottom = 148 if index < 6 else 128 if index == 6 else 136
        dx, dy = GLOW_OFFSETS[name] if index == 1 else (0, 0)
        image.paste(pose, (128 - pose.width // 2 + dx, bottom - pose.height + dy))
        frames.append(image)
    return frames


def emit(name: str, frames: list[Image.Image]) -> tuple[bytes, bytes]:
    """Pack static ending art, bounded by its dedicated VRAM allocation."""
    art, seen = bytearray(), {}
    label = f"Map_E{name}"
    maps = [
        f"; Sonic 1 mobile {name} poses adapted to the eight S1 ending frames.",
        f"{label}_internal: mappingsTable",
    ]
    maps += [f"\tmappingsTableEntry.w .frame{i}" for i in range(len(frames))]
    for index, image in enumerate(frames):
        maps += ["", f".frame{index}: spriteHeader"]
        bounds = image.getbbox()
        if bounds:
            left, top, right, bottom = bounds
            left, top = left // 8 * 8, top // 8 * 8
            right, bottom = (right + 7) // 8 * 8, (bottom + 7) // 8 * 8
            for x in range(left, right, 8 if index < 6 else 32):
                for y in range(top, bottom, 32):
                    width, height = min(8 if index < 6 else 32, right - x), min(32, bottom - y)
                    block = image.crop((x, y, x + width, y + height))
                    if not block.getbbox():
                        continue
                    bx, by, br, bb = block.getbbox()
                    bx, by = bx // 8 * 8, by // 8 * 8
                    br, bb = (br + 7) // 8 * 8, (bb + 7) // 8 * 8
                    block = block.crop((bx, by, br, bb))
                    width, height = block.size
                    packed = bytearray()
                    for tx in range(0, width, 8):
                        for ty in range(0, height, 8):
                            for py in range(8):
                                for px in range(0, 8, 2):
                                    packed.append(
                                        block.getpixel((tx + px, ty + py)) << 4
                                        | block.getpixel((tx + px + 1, ty + py))
                                    )
                    key = bytes(packed)
                    if key not in seen:
                        # Reuse tile-aligned sequences and shared suffixes across poses.
                        start = next(
                            (i for i in range(0, len(art), 32) if art[i : i + len(key)] == key),
                            None,
                        )
                        if start is None:
                            overlap = next(
                                (
                                    n
                                    for n in range(min(len(art), len(key)), 0, -32)
                                    if art[-n:] == key[:n]
                                ),
                                0,
                            )
                            start = len(art) - overlap
                            art.extend(key[overlap:])
                        seen[key] = start // 32
                    maps.append(
                        f"\tspritePiece {x + bx - 128}, {y + by - 128}, {width // 8}, "
                        f"{height // 8}, ${seen[key]:X}, 0, 0, 0, 0"
                    )
        maps.append(f".frame{index}_End")
    if len(art) // 32 > ENDING_TILES:
        raise ValueError(f"{name}: {len(art) // 32} ending tiles exceed {ENDING_TILES}")
    maps += ["", "\teven", ""]
    return bytes(art), "\n".join(maps).encode("ascii")


def expected_outputs() -> dict[Path, bytes]:
    root = get_root()
    sheet = Image.open(get_source("mobile") / "ending.png").convert("RGB")
    outputs = {}
    for name in POSES:
        packed, mapping = emit(name, mobile_frames(sheet, name))
        outputs[root / f"artkosm/Ending - {name}.kosm"] = encode_moduled(packed)
        outputs[root / f"_maps/Ending Sequence {name}.asm"] = mapping
    # The blue gem always uses the sky ramp; non-Sonic logos also use it.
    # The remaining five emeralds keep their original colours and palette lines.
    blue = {2: 1, 3: 2, 4: 3, 5: 4}
    logo = decode((get_source("s1") / "artnem/Ending - StH Logo.nem").read_bytes())
    outputs[root / "artkosm/Ending - Shared Logo.kosm"] = encode_moduled(
        bytes(blue.get(b >> 4, b >> 4) << 4 | blue.get(b & 15, b & 15) for b in logo)
    )
    gems = bytearray(
        decode_moduled((get_source("shared") / "artkosm/Ending - Emeralds.kosm").read_bytes())
    )
    for i in range(4 * 32, 8 * 32):
        b = gems[i]
        gems[i] = blue.get(b >> 4, b >> 4) << 4 | blue.get(b & 15, b & 15)
    outputs[root / "artkosm/Ending - Shared Emeralds.kosm"] = encode_moduled(bytes(gems))
    return outputs


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write ending graphics and mappings")
    args = parser.parse_args(argv)
    write_outputs(expected_outputs(), apply=args.apply)
    return 0
