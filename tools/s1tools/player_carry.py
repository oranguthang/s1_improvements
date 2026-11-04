"""Sonic 2's upright Hang2 frames for the Sonic 1 companion carry pose."""

import re
from pathlib import Path

from s1tools.common import get_source
from s1tools.player import super_dplc_entries, super_mapping_pieces, super_table_targets
from s1tools.tails import emit_frames

S2_FRAMES = (0x6B, 0x6C)


def carry_outputs(root: Path) -> dict[Path, bytes]:
    source = get_source("s2")
    art = (source / "art/uncompressed/Sonic's art.bin").read_bytes()
    maps = (source / "mappings/sprite/Sonic.asm").read_text(encoding="utf-8-sig")
    cues = (source / "mappings/spriteDPLC/Sonic.asm").read_text(encoding="utf-8-sig")
    targets = super_table_targets(maps, r"mappingsTableEntry\.w\s+(\S+)")
    from s1tools.sprites import parse_number

    frames = []
    for frame_id in S2_FRAMES:
        data = b"".join(
            art[tile * 32 : (tile + count) * 32]
            for count, tile in super_dplc_entries(cues, frame_id)
        )
        pieces = []
        for line in super_mapping_pieces(maps, targets[frame_id]):
            pieces.append(
                tuple(
                    parse_number(v)
                    for v in line.split("spritePiece", 1)[1].split(";")[0].split(",")
                )
            )
        frames.append((data, pieces))
    packed, mapping, dplc = emit_frames("SonicCarry", frames)
    start = (
        sum(
            len((root / "artunc" / name).read_bytes())
            for name in (
                "Sonic.unc",
                "Sonic Figure8.unc",
                "Sonic Air Poses.unc",
                "Sonic Victory.unc",
            )
        )
        // 32
    )
    mapping = mapping.decode()
    mapping = mapping[mapping.index("SonicCarryMap_00:") :]
    dplc = dplc.decode()
    dplc = dplc[dplc.index("SonicCarryPLC_00:") :]
    dplc = re.sub(
        r"(dplcEntry\s+[^,]+,\s*)\$([0-9A-F]+)",
        lambda m: m[1] + f"${int(m[2], 16) + start:X}",
        dplc,
    )
    outputs = {root / "artunc/Sonic Carry.unc": packed}
    for kind, body, stem in [("Map", mapping, "SonicCarryMap"), ("DPLC", dplc, "SonicCarryPLC")]:
        prefix = "; Generated from Sonic 2 Hang2 frames $6B/$6C.\n"
        entries = (
            "".join(f"        mappingsTableEntry.w {stem}_{i:02X}\n" for i in range(2))
            + "        even\n"
        )
        outputs[root / f"_maps/Sonic - Carry {kind}.asm"] = (prefix + body).encode()
        outputs[root / f"_maps/Sonic - Carry {kind} Entries.asm"] = (prefix + entries).encode()
    return outputs
