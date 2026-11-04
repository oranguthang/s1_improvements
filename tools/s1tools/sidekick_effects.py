"""Lossless packing of companion-mode stars and point captions.

Visible star pixels retain their geometry; blank star tiles are omitted.
Three DMA runs use the inactive shield slot and the two small VRAM gaps.
Point captions share identical trailing zero tiles to free four star tiles.
"""

from collections.abc import Callable
from pathlib import Path

from s1tools.codecs.kosinski import decode_moduled, encode_moduled


def effects_outputs(root: Path, shared_transform: Callable[[bytes], bytes]) -> dict[Path, bytes]:
    outputs: dict[Path, bytes] = {}
    stars = (root / "artunc/Invincibility Stars S2.unc").read_bytes()
    tiles = [stars[i : i + 32] for i in range(0, len(stars), 32)]
    small = [i for i in range(18) if any(tiles[i])]
    assert len(small) == 16
    dest = dict(zip(small, range(0x541, 0x551), strict=True))
    dest.update(
        {19: 0x57E, 23: 0x551, 24: 0x552, 26: 0x55A, 27: 0x55B, 28: 0x55C, 29: 0x55D, 31: 0x57F}
    )
    assert len(dest) == 24 and all(any(tiles[i]) == (i in dest) for i in range(34))
    order = sorted(dest, key=lambda i: dest[i])
    outputs[root / "artunc/Sidekick Invincibility Stars.unc"] = shared_transform(
        b"".join(tiles[i] for i in order)
    )
    source = [
        "; Lossless paired effects: generated from the original star/points sheets.",
        "; 24 nonempty star tiles. The shield slot is free during invincibility.",
        "Map_InvStarsS2_Paired: mappingsTable",
    ]
    for i in range(9):
        source.append(f"        mappingsTableEntry.w .frame{i}")
    pieces = [
        [],
        [(-4, -8, 1, 1, 0)],
        [(-4, -8, 1, 1, 2)],
        [(-4, -8, 1, 2, 4)],
        [(-4, -8, 1, 2, 6)],
        [(-4, -8, 1, 2, 8)],
        [(-8, -8, 2, 2, 10)],
        [(-8, -8, 2, 2, 14)],
        [(-16, -8, 1, 1, 19), (-8, -8, 1, 2, 23), (0, -16, 1, 4, 26), (8, -8, 1, 1, 31)],
    ]
    for i, frame in enumerate(pieces):
        source.append(f".frame{i}: spriteHeader")
        for x, y, w, h, t in frame:
            assert [dest[n] for n in range(t, t + w * h)] == list(range(dest[t], dest[t] + w * h))
            source.append(f"        spritePiece {x},{y},{w},{h},${dest[t]:X},0,0,0,0")
        source.append(f".frame{i}_End")
    source += ["        even", "Sidekick_StarsDMAs:"]
    offset = 0
    ranges = []
    for i in order:
        if ranges and ranges[-1][1] + ranges[-1][2] == dest[i]:
            ranges[-1][2] += 1
        else:
            ranges.append([offset, dest[i], 1])
        offset += 32
    for offset, d, n in ranges:
        source.append(f"        dc.w {offset},${d * 32:X},{n * 16}")
    source += ["Sidekick_StarsDMAs_End:", "        even"]
    assert len(ranges) == 3  # 18 shield tiles, 4 after points, 2 after the body.

    points = decode_moduled((root / "artkosm/Points.kosm").read_bytes())
    pt = [points[i : i + 32] for i in range(0, len(points), 32)]
    unique = []
    index = []
    for t in pt:
        if t not in unique:
            unique.append(t)
        index.append(unique.index(t))
    assert len(unique) == 7
    out = root / "artkosm/sidekick/Points Compact.kosm"
    outputs[out] = encode_moduled(b"".join(unique))
    source += [
        'KosM_SidekickPointsCompact: binclude "artkosm/sidekick/Points Compact.kosm"',
        "        even",
        "Map_Points_Paired: mappingsTable",
    ]
    for i in range(7):
        source.append(f"        mappingsTableEntry.w .points{i}")
    # Two short captions share their second tile, so split just those captions.
    frames = [
        [(-8, 0, 2)],
        [(-8, 2, 1), (0, 1, 1)],
        [(-8, 4, 1), (0, 1, 1)],
        [(-8, 6, 3)],
        [(-4, 6, 1)],
        [(-12, 6, 3), (1, 7, 2)],
        [(-12, 6, 3), (6, 7, 2)],
    ]
    for f, items in enumerate(frames):
        source.append(f".points{f}: spriteHeader")
        for x, t, w in items:
            assert index[t : t + w] == list(range(index[t], index[t] + w))
            source.append(f"        spritePiece {x},-4,{w},1,{index[t]},0,0,0,0")
        source.append(f".points{f}_End")
    source += ["        even"]
    outputs[root / "_inc/Sidekick Effects Assets.asm"] = ("\n".join(source) + "\n").encode()

    return outputs
