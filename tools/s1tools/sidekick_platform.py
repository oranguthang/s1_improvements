"""Losslessly omit six empty SBZ spinning-platform tiles in paired mode."""

import re
from pathlib import Path

from s1tools.codecs.kosinski import decode_moduled, encode_moduled
from s1tools.sidekick_dust import split_piece


def platform_outputs(root: Path, shared_transform) -> dict[Path, bytes]:
    raw = decode_moduled((root / "artkosm/SBZ Spinning Platform.kosm").read_bytes())
    tiles = [raw[i : i + 32] for i in range(0, len(raw), 32)]
    mapping = []
    kept = []
    for tile in tiles:
        if not any(tile):
            mapping.append(None)
        else:
            mapping.append(len(kept))
            kept.append(tile)
    assert len(kept) == 42 and len(tiles) == 48
    text = (root / "_maps/SBZ Spinning Platforms.asm").read_text()
    entries = re.findall(r"mappingsTableEntry\.w\s+(\.\w+)", text)
    out = [
        "; Empty source tiles omitted; all visible platform pixels retained.",
        'KosM_SidekickSpinPlatform: binclude "artkosm/sidekick/SBZ Spinning Platform Compact.kosm"',
        "        even",
        "Map_SidekickSpinPlatform: mappingsTable",
    ]
    for label in entries:
        out.append("        mappingsTableEntry.w " + label)
    for label in entries:
        frame = text.split(label + ":", 1)[1].split(label + "_End", 1)[0]
        out.append(label + ": spriteHeader")
        for source in re.findall(r"spritePiece\s+([^;\n]+)", frame):
            values = [int(v.strip().replace("$", "0x"), 0) for v in source.split(",")]
            x, y, w, h, t, xf, yf, pal, priority = values
            for nx, ny, nw, nh, nt in split_piece(mapping, (x, y, w, h, t)):
                if xf:
                    nx = x + w * 8 - (nx - x) - nw * 8
                if yf:
                    ny = y + h * 8 - (ny - y) - nh * 8
                out.append(
                    f"        spritePiece {nx},{ny},{nw},{nh},{nt},{xf},{yf},{pal},{priority}"
                )
        out.append(label + "_End")
    out.append("        even")
    return {
        root / "artkosm/sidekick/SBZ Spinning Platform Compact.kosm": encode_moduled(
            shared_transform(b"".join(kept))
        ),
        root / "_inc/Sidekick Platform Assets.asm": ("\n".join(out) + "\n").encode(),
    }
