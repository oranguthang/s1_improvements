"""Special Stage player frames drawn in two palette layers.

In the Special Stage, palette line 0 keeps the stage's blue blocks, so the
player's fur colours (line 0 slots 2-5 in levels) are not available there.
Each frame is split in two: the details (outline, white, greys, skin, shoes)
stay on line 0, whose shared colours match the level palettes, and the fur is
drawn from the character's own block line (orange line 1 for Tails, red
line 2 for Knuckles), whose slots 2-5 hold that character's ramp.
"""

from __future__ import annotations

from s1tools.player import figure8_pack
from s1tools.tails import emit_frames

# Rolling frames, the only ones the Special Stage player shows.
ROLL_FRAMES = range(0x2E, 0x33)
# Palette line 1 and 2 slots 2-5 in palette/Special Stage.bin.
TAILS_RAMP = (0x0026, 0x004A, 0x008E, 0x00AE)
KNUCKLES_RAMP = (0x0204, 0x0208, 0x020C, 0x064E)


def frame_pixels(data: bytes, pieces: list[tuple[int, ...]]) -> dict[tuple[int, int], int]:
    """Pixel colour indices of a mapping frame, keyed by position."""
    pixels = {}
    for x, y, width, height, tile, xflip, yflip, *_ in pieces:
        for column in range(width):
            for row in range(height):
                start = (tile + column * height + row) * 32
                for py in range(8):
                    for px in range(8):
                        byte = data[start + py * 4 + px // 2]
                        value = byte >> 4 if px % 2 == 0 else byte & 15
                        if value:
                            dx = (width - 1 - column if xflip else column) * 8
                            dx += 7 - px if xflip else px
                            dy = (height - 1 - row if yflip else row) * 8
                            dy += 7 - py if yflip else py
                            pixels[x + dx, y + dy] = value
    return pixels


def layered_frame(
    data: bytes, pieces: list[tuple[int, ...]], fur: dict[int, int], line: int
) -> tuple[bytes, list[tuple[int, ...]]]:
    """Split one frame into a line 0 detail layer and a fur layer on `line`."""
    pixels = frame_pixels(data, pieces)
    layers = (
        ({p: v for p, v in pixels.items() if v not in fur}, 0),
        ({p: fur[v] for p, v in pixels.items() if v in fur}, line),
    )
    tiles = bytearray()
    result = []
    for layer, palette in layers:
        if not layer:
            continue
        art, packed = figure8_pack(layer)
        base = len(tiles) // 32
        tiles.extend(art)
        result.extend(
            (x, y, w, h, t + base, int(xf), int(yf), palette, 0) for x, y, w, h, t, xf, yf in packed
        )
    if len(tiles) // 32 > 32:
        raise ValueError("A layered Special Stage frame exceeds the player VRAM slot")
    return bytes(tiles), result


def layered_assets(
    name: str,
    frames: list[tuple[bytes, list[tuple[int, ...]]]],
    used: range,
    fur: dict[int, int],
    line: int,
) -> tuple[bytes, bytes, bytes, int]:
    """Art, mappings and DPLC with blank frames below the used range, and the
    largest frame's tile count."""
    out = [
        layered_frame(*frames[index], fur, line) if index in used else (b"", [])
        for index in range(used.stop)
    ]
    return (*emit_frames(name, out), max(len(data) // 32 for data, _ in out))
