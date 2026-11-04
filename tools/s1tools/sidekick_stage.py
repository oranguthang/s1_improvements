"""Separate line-0 consumers that share scenery art with other palette lines."""

from pathlib import Path

from s1tools.codecs.kosinski import decode_moduled, encode_moduled

SYZ_SHARED = (397, 403, 412, 414, 419, 420)
SYZ_EXTRA_FIRST = 0x372
BOSS_CHAIN_FIRST = 0x3E8


def stage_outputs(root: Path, shared_transform) -> dict[Path, bytes]:
    raw = decode_moduled((root / "artkosm/8x8 - SYZ.kosm").read_bytes())
    assert len(raw) // 32 == SYZ_EXTRA_FIRST
    tiles = [raw[t * 32 : t * 32 + 32] for t in SYZ_SHARED]
    stage = raw + shared_transform(b"".join(tiles))
    blocks = bytearray((root / "map16/SYZ.bin").read_bytes())
    remap = {t: SYZ_EXTRA_FIRST + i for i, t in enumerate(SYZ_SHARED)}
    for i in range(0, len(blocks), 2):
        word = int.from_bytes(blocks[i : i + 2], "big")
        if (word >> 13 & 3) == 0 and (word & 0x7FF) in remap:
            blocks[i : i + 2] = ((word & 0xF800) | remap[word & 0x7FF]).to_bytes(2, "big")
    swing = decode_moduled((root / "artkosm/GHZ Swinging Platform.kosm").read_bytes())
    chain = shared_transform(swing[: 4 * 32])
    source = """; Palette-specific copies. Original scenery tiles keep their colours.
KosM_SidekickSYZ: binclude "artkosm/sidekick/8x8 - SYZ Paired.kosm"
        even
Blk16_SidekickSYZ: binclude "map16/sidekick/SYZ.bin"
        even
KosM_SidekickBossChain: binclude "artkosm/sidekick/GHZ Boss Chain.kosm"
        even
PLC_SidekickBossChain: plcheader
        plcm KosM_SidekickBossChain,$3E8
PLC_SidekickBossChain_end:
"""
    return {
        root / "artkosm/sidekick/8x8 - SYZ Paired.kosm": encode_moduled(stage),
        root / "map16/sidekick/SYZ.bin": bytes(blocks),
        root / "artkosm/sidekick/GHZ Boss Chain.kosm": encode_moduled(chain),
        root / "_inc/Sidekick Stage Assets.asm": source.encode(),
    }
