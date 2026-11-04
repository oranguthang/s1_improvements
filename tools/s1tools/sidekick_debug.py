"""A shared 19-glyph debug font avoids overwriting companion DPLC tiles."""

from pathlib import Path


def debug_outputs(root: Path, shared_transform) -> dict[Path, bytes]:
    art = (root / "artunc/Level Select & Debug Text.unc").read_bytes()
    glyphs = list(range(10)) + list(range(17, 23)) + [ord(c) - ord("0") for c in "SPR"]
    font = shared_transform(b"".join(art[i * 32 : (i + 1) * 32] for i in glyphs))
    assert len(font) == 19 * 32
    entries = []
    for y, xbase in [(0, 0), (8, 0), (0, 32), (8, 32)]:
        entries.extend((xbase + i * 8, y, 0x541) for i in range(4))
    entries.extend(
        [(0, 16, 0x551), (8, 16, 0x552), (16, 16, 0x55A), (48, 16, 0x541), (56, 16, 0x541)]
    )
    source = [
        "; 21 one-tile pieces share 19 resident glyphs.",
        "Map_SidekickDebugTemplate: mappingsTable",
        "        mappingsTableEntry.w .frame",
        ".frame: spriteHeader",
    ]
    for x, y, t in entries:
        source.append(f"        spritePiece {x},{y},1,1,${t:X},0,0,0,1")
    source += [".frame_End", "        even", "Map_SidekickDebugTemplate_End:"]
    return {
        root / "artunc/Sidekick Debug Font.unc": font,
        root / "_inc/Sidekick Debug Assets.asm": ("\n".join(source) + "\n").encode(),
    }
