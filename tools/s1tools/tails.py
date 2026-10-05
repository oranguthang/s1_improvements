"""Import Sonic 3 & Knuckles Tails into the Sonic 1 player frame layout."""

from __future__ import annotations

import argparse
import re
import struct
from pathlib import Path

from s1tools.codecs.kosinski import encode_moduled
from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.common import get_root, get_source, write_outputs
from s1tools.shared_palette import life_icon, player_palettes

BASE = "General/Sprites/Tails/"
# The selected solo player's fur uses protected colours 2..5.
COLOURS = (0, 6, 5, 4, 2, 9, 12, 13, 5, 4, 10, 11, 7, 8, 9, 1)
# Player art moves S3K's dark orange (11) to the free protected slot 3, so the
# Super cycle can brighten it as S3K does without touching shared skin colour 11.
PLAYER_COLOURS = (*COLOURS[:11], 3, *COLOURS[12:])
# S3K's Super transformation frames $EB-$ED follow the gameplay frames.
TRANSFORM_FRAME_FIRST = 151
# All eight S3K walk frames for each of the four floor orientations.
WALK8 = TRANSFORM_FRAME_FIRST + 3
# S3K's extra sheet pose $E7: Tails faces the camera with both arms raised.
# The tails object shows nothing for this pose.
VICTORY = WALK8 + 4 * 8
FRAME_COUNT = VICTORY + 1
# S3K reads body frames from $D1 onward from a separate extra sheet.
EXTRA_BODY_FIRST = 0xD1
# The tails are a separate object, as in S3K (Obj_Tails_Tail), drawn from the
# second half of the player VRAM slot. Body frames that show them must fit the
# first half. Tail frames are S3K's own, shifted down like the body frames
# that show them: 1-4 spin dash, 5-$14 rolling headings (no shift), 4 pixels
# for the rest.
TAIL_FRAMES = 0x2D
BODY_TILES_WITH_TAIL = 16


def number(value: str) -> int:
    return int(value.strip().replace("$", "0x"), 0)


def raw_table(path: Path) -> tuple[list[str], dict[str, bytes]]:
    """Read the numeric dc.w/dc.b tables used by the S3K disassembly."""
    table: list[str] = []
    records: dict[str, bytearray] = {}
    current: str | None = None
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        line = line.split(";", 1)[0].strip()
        match = re.match(r"dc\.w\s+(\w+)-\w+$", line)
        if match:
            table.append(match[1])
            continue
        if ":" in line:
            current, line = line.split(":", 1)
            records[current] = bytearray()
            line = line.strip()
        match = re.match(r"dc\.([bw])\s+(.+)", line)
        if match and current:
            size = 1 if match[1] == "b" else 2
            for value in match[2].split(","):
                records[current].extend(number(value).to_bytes(size, "big"))
    return table, {label: bytes(data) for label, data in records.items()}


def remap_art(data: bytes) -> bytes:
    return bytes((COLOURS[b >> 4] << 4) | COLOURS[b & 15] for b in data)


def frame(
    art: bytes,
    maps: tuple[list[str], dict[str, bytes]],
    cues: tuple[list[str], dict[str, bytes]],
    index: int,
    colours: tuple[int, ...] | None = None,
) -> tuple[bytes, list[tuple[int, ...]]]:
    cue = cues[1][cues[0][index]]
    count = int.from_bytes(cue[:2], "big")
    if len(cue) != 2 + count * 2:
        raise ValueError(f"Invalid DPLC frame {index}")
    tiles = bytearray()
    for position in range(count):
        word = int.from_bytes(cue[2 + position * 2 : 4 + position * 2], "big")
        offset, length = (word & 0xFFF) * 32, ((word >> 12) + 1) * 32
        chunk = art[offset : offset + length]
        if len(chunk) != length:
            raise ValueError(f"DPLC frame {index} exceeds its art")
        tiles.extend(chunk)
    record = maps[1][maps[0][index]]
    count = int.from_bytes(record[:2], "big")
    if len(record) != 2 + count * 6:
        raise ValueError(f"Invalid mapping frame {index}")
    pieces = []
    for position in range(count):
        y, shape, attributes, x = struct.unpack_from(">bBHh", record, 2 + position * 6)
        width, height, tile = (shape >> 2) + 1, (shape & 3) + 1, attributes & 0x7FF
        if tile + width * height > len(tiles) // 32 or attributes & 0x6000:
            raise ValueError(f"Invalid tiles/palette in mapping frame {index}")
        pieces.append(
            (
                x,
                y,
                width,
                height,
                tile,
                (attributes >> 11) & 1,
                (attributes >> 12) & 1,
                0,
                (attributes >> 15) & 1,
            )
        )
    lookup = COLOURS if colours is None else colours
    return bytes((lookup[b >> 4] << 4) | lookup[b & 15] for b in tiles), pieces


def frame_plan() -> list[tuple[int, int, int, int]]:
    """Body ID, optional tail ID, and origin adjustment for each S1 frame."""
    plan = [(0xAD, 0x22, 0, 4)] * FRAME_COUNT

    def assign(index: int, body: int, tail: int = 0, dx: int = 0, dy: int = 4) -> None:
        plan[index] = (body, tail, dx, dy)

    assign(0, 0, dy=0)
    for index, body, tail in (
        (1, 0xAD, 0x22),
        (2, 0xAF, 0x23),
        (3, 0xAE, 0x24),
        (4, 0xB1, 0x25),
        (5, 0xB0, 0x26),
    ):
        assign(index, body, tail)
    offsets = ((0, 4), (-3, 3), (-4, 0), (-3, -3))
    # Six evenly spaced samples from the original eight-frame walk cycle.
    for group, (dx, dy) in enumerate(offsets):
        for step, source in enumerate((1, 2, 4, 5, 6, 8)):
            assign(6 + group * 6 + step, source + group * 8, dx=dx, dy=dy)
        for step in range(4):
            assign(0x1E + group * 4 + step, 0x21 + group * 4 + step, dx=dx, dy=dy)
            assign(0x5E + group * 4 + step, 0x21 + group * 4 + step, dx=dx, dy=dy)
    for step in range(5):
        assign(0x2E + step, 0x96 + step % 3, 5 + step % 4, dy=0)
    for index in range(0x33, 0x37):
        assign(index, 0x82 + index - 0x33)
    for index, body, tail in (
        (0x37, 0x8E, 0x1A),
        (0x38, 0x8F, 0x1B),
        (0x39, 0x99, 0x22),
        (0x3A, 0x9A, 0x29),
        (0x3B, 0x9B, 0x2B),
        (0x3C, 0xB5, 0),
        (0x3D, 0xB6, 0),
        (0x3E, 0xB7, 0),
        (0x3F, 0xB8, 0),
        (0x40, 0x8B, 0),
        (0x41, 0x9D, 0),
        (0x42, 0x9E, 0),
        (0x43, 1, 0),
        (0x44, 2, 0),
        (0x49, 0x91, 0),
        (0x4A, 0x9F, 0),
        (0x4B, 0x9C, 0),
        (0x4C, 0x9C, 0),
        (0x4D, 0x9C, 0),
        (0x53, 0xB9, 0),
        (0x54, 0xBA, 0),
        (0x55, 0x89, 0),
        (0x56, 0x9F, 0),
        (0x57, 0x8A, 0),
    ):
        assign(index, body, tail)
    for step in range(4):
        assign(0x45 + step, 0xA9 + step, 0x1E + step)
    for step in range(5):
        assign(0x4E + step, 0x82 + min(step, 3))
    for step in range(6):
        assign(0x58 + step, 0x86 + step % 3, 1 + step % 4, dy=5)
    for step in range(5):
        assign(0x6E + step, 0x8B + step % 2)
    # CB/CC are death poses in S3K, not a spring descent animation.
    assign(0x73, 1)
    assign(0x74, 5)
    assign(0x75, 0xA0, 0x27)  # fly/hover
    assign(0x76, 0xA0, 0x28)
    assign(0x77, 0xA1, 0x27)  # ascending
    assign(0x78, 0xA1, 0x28)
    for step in range(5):
        assign(0x79 + step, 0xBD + step)  # swimming, tails included in body art
    assign(0x7E, 0xA3, 0x27)  # exhausted flight
    assign(0x7F, 0xA4, 0x28)
    for step in range(5):
        assign(0x80 + step, 0xAD, 0x22 + step)
        assign(0x85 + step, 0xB0, 0x22 + step)
        assign(0x8A + step, 0x99, 0x22 + step)
    # The balance and hanging tail cycle is the counterpart of the restored
    # S2 tails animation. Pack it with both alternating balance body poses.
    for step in range(8):
        assign(0x8F + step, 0x9A + (step // 2) % 2, 0x29 + step % 4)
    for step in range(3):
        assign(TRANSFORM_FRAME_FIRST + step, 0xEB + step)
    assign(VICTORY, 0xE7)
    for group, (dx, dy) in enumerate(offsets):
        for step in range(8):
            assign(WALK8 + group * 8 + step, 1 + group * 8 + step, dx=dx, dy=dy)
    return plan


def tail_shift(index: int) -> int:
    if 1 <= index <= 4:
        return 5
    return 0 if 5 <= index <= 0x14 else 4


def emit_frames(
    name: str, frames: list[tuple[bytes, list[tuple[int, ...]]]]
) -> tuple[bytes, bytes, bytes]:
    """Pack complete frames into a bounded S1 mapping/DPLC stream."""
    packed, seen = bytearray(), {}
    maps = [
        f"; S3K {name}, repacked for the S1 player frame IDs.",
        f"{name}Map_internal: mappingsTable",
    ]
    cues = [f"{name}DPLC_internal: mappingsTable"]
    for index in range(len(frames)):
        maps.append(f"\tmappingsTableEntry.w {name}Map_{index:02X}")
        cues.append(f"\tmappingsTableEntry.w {name}PLC_{index:02X}")
    for index, (data, pieces) in enumerate(frames):
        if len(data) // 32 > 32:
            raise ValueError(f"Frame {index:02X} exceeds the player VRAM slot")
        if data not in seen:
            seen[data] = len(packed) // 32
            packed.extend(data)
        start = seen[data]
        maps.extend(["", f"{name}Map_{index:02X}: spriteHeader"])
        for x, y, *rest in pieces:
            maps.append("\tspritePiece " + ", ".join(map(str, (x, y, *rest))))
        maps.append(f"{name}Map_{index:02X}_End")
        cues.extend(["", f"{name}PLC_{index:02X}: dplcHeader"])
        remaining = len(data) // 32
        while remaining:
            count = min(remaining, 16)
            if start > 0xFFF:
                raise ValueError(f"{name} art exceeds the 12-bit DPLC source range")
            cues.append(f"\tdplcEntry {count}, ${start:X}")
            start += count
            remaining -= count
        cues.append(f"{name}PLC_{index:02X}_End")
    maps += ["", "\teven", ""]
    cues += ["", "\teven", ""]
    return bytes(packed), "\n".join(maps).encode("ascii"), "\n".join(cues).encode("ascii")


# The Special Stage keeps its own blue in palette line 0 (walls, glass, GOAL,
# the blue emerald), so the rolling frames there use separately coloured
# tiles. Tails' ball is drawn on line 1, whose yellow-wall ramp the stage
# replaces with his orange (SSLine1_Tails); the peach muzzle takes the
# lightest orange there.
SS_BALL_FRAMES = range(0x2E, 0x33)
SS_BALL_COLOURS = {10: 5}


def ss_ball_art(
    packed: bytes, frames: list[tuple[bytes, list[tuple[int, ...]]]], remap: dict[int, int]
) -> tuple[bytes, int]:
    """Recoloured copy of the tiles of the rolling frames and their first tile."""
    spans = []
    for index in SS_BALL_FRAMES:
        data = frames[index][0]
        start = next(
            tile
            for tile in range(len(packed) // 32)
            if packed[tile * 32 : tile * 32 + len(data)] == data
        )
        spans.append((start, start + len(data) // 32))
    first = min(start for start, _ in spans)
    last = max(end for _, end in spans)
    art = bytes(
        remap.get(b >> 4, b >> 4) << 4 | remap.get(b & 15, b & 15)
        for b in packed[first * 32 : last * 32]
    )
    return art, first


def expected_outputs(source: Path) -> dict[Path, bytes]:
    root = get_root()
    body = (source / (BASE + "Art/Tails.bin")).read_bytes()
    extra = (source / (BASE + "Art/Tails Extra.bin")).read_bytes()
    tail = (source / (BASE + "Art/Tails tails.bin")).read_bytes()
    body_maps = raw_table(source / (BASE + "Map - Tails.asm"))
    body_cues = raw_table(source / (BASE + "DPLC - Tails.asm"))
    tail_maps = raw_table(source / (BASE + "Map - Tails tails.asm"))
    tail_cues = raw_table(source / (BASE + "DPLC - Tails tails.asm"))
    frames = []
    for body_id, tail_id, dx, dy in frame_plan():
        sheet = extra if body_id >= EXTRA_BODY_FIRST else body
        data, pieces = frame(sheet, body_maps, body_cues, body_id, PLAYER_COLOURS)
        if tail_id and len(data) // 32 > BODY_TILES_WITH_TAIL:
            raise ValueError(f"Body frame {body_id:02X} would overlap the tails art")
        frames.append((data, [(x + dx, y + dy, *rest) for x, y, *rest in pieces]))
    tail_frames = []
    for index in range(TAIL_FRAMES):
        data, pieces = frame(tail, tail_maps, tail_cues, index, PLAYER_COLOURS)
        if len(data) // 32 > 32 - BODY_TILES_WITH_TAIL:
            raise ValueError(f"Tail frame {index:02X} exceeds the tails art slot")
        shift = tail_shift(index)
        tail_frames.append((data, [(x, y + shift, *rest) for x, y, *rest in pieces]))
    art, mappings, cues = emit_frames("Tails", frames)
    ball_art, ball_first = ss_ball_art(art, frames, SS_BALL_COLOURS)
    mappings = (
        f"fr_TailsTransform equ ${TRANSFORM_FRAME_FIRST:X}\nfr_TailsWalk equ ${WALK8:X}\n"
        f"fr_TailsVictory equ ${VICTORY:X}\n"
        f"TailsSSBall_FirstTile equ ${ball_first:X}\n\n"
    ).encode("ascii") + mappings
    tail_art, tail_mappings, tail_cues = emit_frames("TailsTail", tail_frames)
    outputs = {
        root / "artunc/Tails.unc": art,
        root / "_maps/Tails.asm": mappings,
        root / "_maps/Tails - Dynamic Gfx Script.asm": cues,
        root / "artunc/Tails Tail.unc": tail_art,
        root / "artunc/Tails SS Ball.unc": ball_art,
        root / "_maps/Tails Tail.asm": tail_mappings,
        root / "_maps/Tails Tail - Dynamic Gfx Script.asm": tail_cues,
    }
    icon = nemesis_decode((source / "General/Sprites/HUD Icon/Tails Life Icon.bin").read_bytes())
    outputs[root / "artkosm/HUD - Tails Life Counter Icon.kosm"] = encode_moduled(
        life_icon(icon, COLOURS)
    )
    outputs.update(
        player_palettes(
            "Tails",
            (0x0468, 0x046A, 0x008E, 0x00AE),
            (0x0244, 0x0266, 0x0488, 0x06AA),
            (0x0446, 0x086C, 0x068C, 0x08AE),
        )
    )
    return outputs


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write converted resources")
    args = parser.parse_args(argv)
    write_outputs(expected_outputs(get_source("sk")), apply=args.apply)
    return 0
