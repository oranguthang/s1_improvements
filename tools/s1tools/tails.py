"""Import Sonic 2 Tails into the Sonic 1 player frame layout."""

from __future__ import annotations

import argparse
import re
import struct
from pathlib import Path

from s1tools.codecs.kosinski import encode_moduled
from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.common import get_root, get_source, write_outputs
from s1tools.shared_palette import life_icon, player_palettes
from s1tools.sprites import parse_number

# The selected solo player's fur uses protected colours 2..5.
COLOURS = (0, 6, 5, 4, 2, 9, 12, 13, 5, 4, 10, 11, 7, 8, 9, 1)
# Player art moves S3K's dark orange (11) to the free protected slot 3, so the
# Super cycle can brighten it as S3K does without touching shared skin colour 11.
PLAYER_COLOURS = (*COLOURS[:11], 3, *COLOURS[12:])
# S2's fur is drawn with slots 14, 15 and 11; the solo S1 ramp is protected.
S2_COLOURS = tuple({14: 5, 15: 4, 11: 3}.get(index, index) for index in range(16))

TRANSFORM_FRAME_FIRST = 151
WALK8 = TRANSFORM_FRAME_FIRST + 3
VICTORY = WALK8 + 4 * 8
IDLE = VICTORY + 2
TIRED_SWIM = IDLE + 3
CARRY = TIRED_SWIM + 3
CARRY_UP = CARRY + 2
SWIM_CARRY = CARRY_UP + 2
CARRY_TIRED = SWIM_CARRY + 2
FRAME_COUNT = CARRY_TIRED + 2
BODY_TILES_WITH_TAIL = 16
# Keep the S1 tail animation indices, using S2's rotor, swish and four
# directional sets. S2 shares the same DPLC table between body and tails.
TAIL_SOURCES = (
    0,
    *range(0x81, 0x85),
    *range(0x49, 0x59),
    0,
    0,
    0,
    0,
    0,
    *range(0x87, 0x8B),
    *range(0x87, 0x8B),
    *range(9, 14),
    0x5E,
    0x5F,
    *range(0x81, 0x85),
)
TAIL_FRAMES = len(TAIL_SOURCES)


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


def s2_frames(source: Path) -> list[tuple[bytes, list[tuple[int, ...]], tuple[int, ...]]]:
    """Unpack the six checked-in source resources in their Sonic 2 ROM order."""
    art = b"".join(
        (source / "art/uncompressed" / name).read_bytes()
        for name in ("Tails's art.bin", "Tails poses.bin")
    )
    mapping, dplc = (
        "\n".join(
            (source / "mappings" / kind / name).read_text(encoding="utf-8-sig")
            for name in ("Tails.asm", "Tails poses.asm")
        )
        for kind in ("sprite", "spriteDPLC")
    )

    def records(text: str, header: str, macro: str) -> list[list[tuple[int, ...]]]:
        bodies = re.findall(rf"^(\w+):[ \t]*{header}\b(.*?)(?=^\1_End\b)", text, re.M | re.S)
        by_label = {
            label: [
                tuple(parse_number(arg) for arg in line.split(","))
                for line in re.findall(rf"^[ \t]*{macro}[ \t]+([^;\n]+)", body, re.M)
            ]
            for label, body in bodies
        }
        return [by_label[label] for label in re.findall(r"mappingsTableEntry\.w\s+(\w+)", text)]

    result = []
    for pieces, cues in zip(
        records(mapping, "spriteHeader", "spritePiece"),
        records(dplc, "dplcHeader", "dplcEntry"),
        strict=True,
    ):
        if any(start + count > len(art) // 32 for count, start in cues):
            raise ValueError("Sonic 2 Tails DPLC exceeds its source art")
        data = b"".join(art[start * 32 : (start + count) * 32] for count, start in cues)
        if any(tile + width * height > len(data) // 32 for _, _, width, height, tile, *_ in pieces):
            raise ValueError("Sonic 2 Tails mapping exceeds its loaded tiles")
        data = bytes((S2_COLOURS[b >> 4] << 4) | S2_COLOURS[b & 15] for b in data)
        result.append((data, pieces, tuple(count for count, _ in cues)))
    return result


def frame_plan() -> list[tuple[int, int, int]]:
    """Sonic 2 frame and origin correction for each Sonic 1 body ID."""
    plan = [(1, 0, 4)] * FRAME_COUNT

    def put(start, sources, dx=0, dy=4):
        for index, source in enumerate(sources, start):
            plan[index] = (source, dx, dy)

    put(0, (0,), dy=0)
    put(1, (1, 2, 3, 5, 4))
    for heading, (dx, dy) in enumerate(((0, 4), (-3, 3), (-4, 0), (-3, -3))):
        walk = tuple(0xE + heading * 8 + index for index in (2, 3, 4, 5, 6, 7, 0, 1))
        run = range(0x2E + heading * 6, 0x32 + heading * 6)
        put(6 + heading * 6, (walk[index] for index in (0, 1, 3, 4, 5, 7)), dx, dy)
        put(WALK8 + heading * 8, walk, dx, dy)
        put(0x1E + heading * 4, run, dx, dy)
        put(0x5E + heading * 4, run, dx, dy)
    put(0x2E, (0x48, 0x47, 0x46, 0x48, 0x47), dy=0)
    put(0x33, (0x78, 0x79, 0x7A, 0x7B))
    put(0x37, (0x67, 0x68, 0x5B, 0x69, 0x6A, 0x6E, 0x6F, 0x71, 0x73, 0x59, 0x6C, 0x6D, 2, 3))
    put(0x45, range(0x63, 0x67))
    put(
        0x49,
        (0x6B, 0x74, 0x5D, 0x5D, 0x5D, 0x75, 0x76, 0x77, 0x48, 0x47, 0x70, 0x72, 0x5D, 0x74, 0x5C),
    )
    put(0x58, (0x60, 0x61, 0x62, 0x60, 0x61, 0x62))
    put(0x6E, (0x59, 0x5A, 0x59, 0x5A, 0x59))
    put(0x73, (0xE, 0x12))
    # Airborne grip frames retain the exact Sonic 2 origins.
    put(0x75, (0x8B,) * 4, dy=0)
    put(0x79, range(0x92, 0x97), dx=-3, dy=-4)
    put(0x7E, (0x8E, 0x8F), dy=0)
    put(0x80, (1,) * 5 + (4,) * 5 + (0x5B,) * 5)
    put(0x8F, (0x69, 0x69, 0x6A, 0x6A) * 2)
    put(TRANSFORM_FRAME_FIRST, range(0x9E, 0xA1))
    put(VICTORY, (0x9C, 0x9D))
    put(IDLE, (6, 7, 8))
    put(TIRED_SWIM, range(0x99, 0x9C), dx=-3, dy=-4)
    put(CARRY, (0x8C,) * 2, dy=0)
    put(CARRY_UP, (0x8D,) * 2, dy=0)
    put(SWIM_CARRY, (0x97, 0x98), dy=0)
    put(CARRY_TIRED, (0x90, 0x91), dy=0)
    return plan


def emit_frames(
    name: str,
    frames: list[tuple[bytes, list[tuple[int, ...]]]],
    runs: list[tuple[int, ...]] | None = None,
) -> tuple[bytes, bytes, bytes]:
    """Pack S1 mappings and DPLC, reusing whole frames or source runs."""
    packed, seen = bytearray(), {}
    source = "Sonic 2" if name.startswith("Tails") else "S3K"
    maps = [
        f"; {source} {name}, repacked for the S1 player frame IDs.",
        f"{name}Map_internal: mappingsTable",
    ]
    cues = [f"{name}DPLC_internal: mappingsTable"]
    for index in range(len(frames)):
        maps.append(f"\tmappingsTableEntry.w {name}Map_{index:02X}")
        cues.append(f"\tmappingsTableEntry.w {name}PLC_{index:02X}")
    for index, (data, pieces) in enumerate(frames):
        if len(data) // 32 > 32:
            raise ValueError(f"Frame {index:02X} exceeds the player VRAM slot")
        maps.extend(["", f"{name}Map_{index:02X}: spriteHeader"])
        for x, y, *rest in pieces:
            maps.append("\tspritePiece " + ", ".join(map(str, (x, y, *rest))))
        maps.append(f"{name}Map_{index:02X}_End")
        cues.extend(["", f"{name}PLC_{index:02X}: dplcHeader"])
        counts = runs[index] if runs is not None else (len(data) // 32,)
        offset = 0
        for length in counts:
            chunk = data[offset : offset + length * 32]
            offset += length * 32
            if chunk not in seen:
                seen[chunk] = len(packed) // 32
                packed.extend(chunk)
            start = seen[chunk]
            while length:
                count = min(length, 16)
                if start > 0xFFF:
                    raise ValueError(f"{name} art exceeds the 12-bit DPLC source range")
                cues.append(f"\tdplcEntry {count}, ${start:X}")
                start += count
                length -= count
        cues.append(f"{name}PLC_{index:02X}_End")
    maps += ["", "\teven", ""]
    cues += ["", "\teven", ""]
    return bytes(packed), "\n".join(maps).encode("ascii"), "\n".join(cues).encode("ascii")


# In the Special Stage, Tails' fur (slots 2-5) is drawn from palette line 1,
# the orange blocks' line (see s1tools.special_stage).
SS_FUR = {2: 2, 3: 3, 4: 4, 5: 5}
SS_LINE = 1
# The rolling tails (frames 5-$14) follow the ball there.
SS_TAIL_FRAMES = range(5, 0x15)


def anim_script(path: Path, label: str) -> list[int]:
    """Bytes of one S3K animation script, across its dc.b lines."""
    text = path.read_text(encoding="utf-8-sig")
    body = re.search(rf"^{label}:(.*?)(?=^\w+:|\Z)", text, re.M | re.S)[1]
    return [
        number(value)
        for line in re.findall(r"dc\.b\s+([^;\n]+)", body)
        for value in line.split(",")
    ]


def translate_script(name: str, values: list[int], frames: dict[int, int]) -> bytes:
    """An S3K animation script with its frame IDs replaced by S1 ones."""
    out = [values[0]]
    index = 1
    while index < len(values):
        value = values[index]
        if value >= 0xFA:
            out.append(value)
            if value in (0xFE, 0xFD):  # afBack and afChange take one argument
                index += 1
                out.append(values[index])
        else:
            out.append(frames[value])
        index += 1
    lines = ["; S3K's script translated to the S1 frame IDs by s1tools.", f"{name}:"]
    for start in range(0, len(out), 16):
        lines.append("\tdc.b " + ", ".join(f"${v:02X}" for v in out[start : start + 16]))
    lines += ["\teven", ""]
    return "\n".join(lines).encode("ascii")


def wait_script() -> bytes:
    # TailsAni_Wait in Sonic 2, using the same blink and yawn sequence.
    frames = {1: 1, 2: 2, 3: 3, 5: 4, 6: IDLE, 7: IDLE + 1, 8: IDLE + 2}
    values = [
        7,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        3,
        2,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        3,
        2,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        6,
        7,
        8,
        7,
        8,
        7,
        8,
        7,
        8,
        7,
        8,
        6,
        0xFE,
        0x1C,
    ]
    return translate_script("TailsAni_Wait", values, frames).replace(
        b"S3K's script", b"Sonic 2's script"
    )


def expected_outputs(source: Path) -> dict[Path, bytes]:
    root = get_root()
    imported = s2_frames(source)

    def positioned(source_id, dx, dy):
        data, pieces, _ = imported[source_id]
        return data, [(x + dx, y + dy, *rest) for x, y, *rest in pieces]

    plan = frame_plan()
    frames = [positioned(*entry) for entry in plan]
    tail_frames = [
        positioned(source_id, 0, 0 if 5 <= index <= 0x14 or 0x27 <= index <= 0x28 else 4)
        for index, source_id in enumerate(TAIL_SOURCES)
    ]
    if any(len(data) > (32 - BODY_TILES_WITH_TAIL) * 32 for data, _ in tail_frames):
        raise ValueError("Sonic 2 Tails tail frame exceeds the tail slot")
    flight = [0x75, 0x7E, 0x7F, CARRY, CARRY_UP, CARRY_TIRED, CARRY_TIRED + 1]
    if any(len(frames[index][0]) > BODY_TILES_WITH_TAIL * 32 for index in flight):
        raise ValueError("Sonic 2 Tails flight body overlaps the tail slot")
    from s1tools.special_stage import ROLL_FRAMES, layered_assets

    art, mappings, cues = emit_frames(
        "Tails", frames, [imported[source_id][2] for source_id, _, _ in plan]
    )
    mappings = (
        f"fr_TailsTransform equ ${TRANSFORM_FRAME_FIRST:X}\nfr_TailsWalk equ ${WALK8:X}\n"
        f"fr_TailsVictory equ ${VICTORY:X}\nfr_TailsSwimTired equ ${TIRED_SWIM:X}\n"
        f"fr_TailsCarry equ ${CARRY:X}\nfr_TailsCarryUp equ ${CARRY_UP:X}\n"
        f"fr_TailsSwimCarry equ ${SWIM_CARRY:X}\nfr_TailsCarryTired equ ${CARRY_TIRED:X}\n\n"
    ).encode("ascii") + mappings
    tail_art, tail_mappings, tail_cues = emit_frames(
        "TailsTail", tail_frames, [imported[source_id][2] for source_id in TAIL_SOURCES]
    )
    ss_art, ss_mappings, ss_cues, ss_tiles = layered_assets(
        "TailsSS", frames, ROLL_FRAMES, SS_FUR, SS_LINE, (frames[0x75],)
    )
    ss_tail = list(
        layered_assets(
            "TailsTailSS",
            tail_frames,
            SS_TAIL_FRAMES,
            SS_FUR,
            SS_LINE,
            tuple(tail_frames[0x27:0x29]),
        )
    )
    ss_mappings = f"fr_TailsSSReturn equ ${ROLL_FRAMES.stop:X}\n\n".encode() + ss_mappings
    # The Special Stage tails take the player slot's last tiles, after the ball.
    if ss_tiles + ss_tail[3] > 32:
        raise ValueError("Tails' Special Stage ball and tails exceed the player VRAM slot")
    ss_tail[1] = (
        f"TailsTailSS_Tiles equ {ss_tail[3]}\nfr_TailsTailSSReturn equ ${SS_TAIL_FRAMES.stop:X}\n\n"
    ).encode("ascii") + ss_tail[1]
    outputs = {
        root / "artunc/Tails.unc": art,
        root / "_maps/Tails.asm": mappings,
        root / "_maps/Tails - Dynamic Gfx Script.asm": cues,
        root / "_anim/Tails - Wait.asm": wait_script(),
        root / "artunc/Tails Tail.unc": tail_art,
        root / "_maps/Tails Tail.asm": tail_mappings,
        root / "_maps/Tails Tail - Dynamic Gfx Script.asm": tail_cues,
        root / "artunc/Tails SS.unc": ss_art,
        root / "_maps/Tails SS.asm": ss_mappings,
        root / "_maps/Tails SS - Dynamic Gfx Script.asm": ss_cues,
        root / "artunc/Tails Tail SS.unc": ss_tail[0],
        root / "_maps/Tails Tail SS.asm": ss_tail[1],
        root / "_maps/Tails Tail SS - Dynamic Gfx Script.asm": ss_tail[2],
    }
    icon = nemesis_decode(
        (get_source("sk") / "General/Sprites/HUD Icon/Tails Life Icon.bin").read_bytes()
    )
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
    write_outputs(expected_outputs(get_source("s2")), apply=args.apply)
    return 0
