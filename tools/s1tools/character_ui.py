"""Adapt shared title-card colours, S3K signpost portraits and S2 continue icons for solo players."""

from __future__ import annotations

import argparse
from pathlib import Path

from s1tools import knuckles, tails
from s1tools.codecs.kosinski import decode_moduled, encode_moduled
from s1tools.codecs.nemesis import decode, encode_with_table
from s1tools.common import get_root, get_source, write_outputs

SIGN_BASE = "General/Sprites/Signpost/"
GRAY = {1: 9, 2: 9, 3: 8, 4: 8, 5: 7}


def title_card(raw: bytes) -> bytes:
    """Recolour only the large and bonus ovals, retaining letters and numbers."""
    if len(raw) != 128 * 32:
        raise ValueError("Expected the original 128-tile Sonic 1 title card")
    result = bytearray(raw)
    for position in range(0x6E * 32, 0x80 * 32):
        byte = raw[position]
        result[position] = GRAY.get(byte >> 4, byte >> 4) << 4 | GRAY.get(byte & 15, byte & 15)
    return bytes(result)


# Extended title card font by Selbi, RobiWanKenobi and others (see CREDITS.md):
# A-Z, the act numbers, a-z, "Act", the oval, then "BONU" and the small oval.
EXTENDED_CARDS = "sonicretro/S1-ExtendedTitleCards/Title Cards Extended.unc"
EXTENDED_OVAL = (ord("z") - ord("A") + 1) * 4 + 2 * 3
EXTENDED_SMALL_OVAL = EXTENDED_OVAL + 16 + 8


def extended_title_cards(raw: bytes) -> bytes:
    """Append gray copies of both ovals for level cards; results keep the originals."""
    if len(raw) != (EXTENDED_SMALL_OVAL + 2) * 32:
        raise ValueError("Unexpected extended title card layout")
    gray = title_card_tiles(raw[EXTENDED_OVAL * 32 : (EXTENDED_OVAL + 16) * 32])
    small = title_card_tiles(raw[EXTENDED_SMALL_OVAL * 32 :])
    return raw + gray + small


# 16x16 credits font from "Use Plane Mappings for Credits in Sonic 1": a blank
# glyph, then A-Z, all drawn in colour 6. The original credits font supplies
# the "2" of "YU 2" (tiles $36-$39): its digit is colour 1 inside a shaded
# frame, so only those pixels are kept, in the font's colour.
CREDITS_FONT = "sonicretro/Credits-16x16.nem"
CREDITS_TWO = 0x36


def credits_text_font(font: bytes, original: bytes) -> bytes:
    if len(font) != 27 * 4 * 32:
        raise ValueError("Expected a blank glyph and A-Z in the credits font")
    two = original[CREDITS_TWO * 32 : (CREDITS_TWO + 4) * 32]
    flat = bytes((6 if b >> 4 == 1 else 0) << 4 | (6 if b & 15 == 1 else 0) for b in two)
    return font + flat


def title_card_tiles(raw: bytes) -> bytes:
    return bytes(GRAY.get(b >> 4, b >> 4) << 4 | GRAY.get(b & 15, b & 15) for b in raw)


def sign_portrait(source: Path, frame: int, colours: tuple[int, ...]) -> bytes:
    """S3K end-sign DPLC stores tile counts in the low nibble, unlike players."""
    art = (source / (SIGN_BASE + "End Signs.bin")).read_bytes()
    maps = tails.raw_table(source / (SIGN_BASE + "Map - End Signs.asm"))
    cues = tails.raw_table(source / (SIGN_BASE + "DPLC - End Signs.asm"))
    record = maps[1][maps[0][frame]]
    # The two 3x4 pieces match S1's front face exactly, including the origins.
    if record != bytes.fromhex("0002 f00b0000ffe8 f00b000c0000"):
        raise ValueError("S3K portrait no longer matches the Sonic 1 signpost face")
    cue = cues[1][cues[0][frame]]
    count = int.from_bytes(cue[:2], "big") + 1
    if len(cue) != 2 + count * 2:
        raise ValueError("Invalid end-sign DPLC")
    tiles = bytearray()
    for position in range(count):
        word = int.from_bytes(cue[2 + position * 2 : 4 + position * 2], "big")
        start, length = (word >> 4) * 32, ((word & 15) + 1) * 32
        chunk = art[start : start + length]
        if len(chunk) != length:
            raise ValueError("End-sign DPLC exceeds source graphics")
        tiles.extend(chunk)
    if len(tiles) != 24 * 32:
        raise ValueError("Expected a 24-tile signpost portrait")
    return bytes(colours[byte >> 4] << 4 | colours[byte & 15] for byte in tiles)


def monitor_portrait(source: Path, name: str, colours: tuple[int, ...]) -> bytes:
    """Reuse the four-tile S3K life portrait, with the S1 monitor white backdrop."""
    raw = decode((source / f"General/Sprites/HUD Icon/{name} Life Icon.bin").read_bytes())
    if len(raw) != 12 * 32:
        raise ValueError("Expected a four-tile face and eight-tile lives label")
    lookup = (6, *colours[1:])
    return bytes(lookup[b >> 4] << 4 | lookup[b & 15] for b in raw[: 4 * 32])


# Sonic 2's continue icons (Tails' from Sonic 2, Knuckles' from Knuckles in
# Sonic 2) have Sonic 1's mini Sonic tile layout: two 2x3 frames. On the
# Special Stage results line 1 also colours the emeralds, so these icons use
# line 2, whose slots 7-F are free there (slot 1 is black).
CONTINUE_ICON_SLOTS = 9
CONTINUE_ICON_FIRST_SLOT = 7
# Knuckles uses ten colours besides black: fold the rarest ones together.
KNUCKLES_ICON_MERGES = {0x9: 0x8, 0xC: 0x3, 0xE: 0xA, 0xF: 0xB, 0x2: 0xD}


def continue_icon(art: bytes, palette: bytes, merges: dict[int, int]) -> tuple[bytes, bytes]:
    """Return the icon's tiles in palette line 2 and the colours for slots 7-F."""
    if len(art) != 12 * 32 or len(palette) < 32:
        raise ValueError("Expected a 12-tile continue icon and a 16-colour palette")
    used = sorted({merges.get(n, n) for byte in art for n in (byte >> 4, byte & 15)} - {0, 1})
    if len(used) > CONTINUE_ICON_SLOTS:
        raise ValueError(f"Continue icon needs {len(used)} colours, line 2 has {CONTINUE_ICON_SLOTS}")
    lookup = list(range(16))
    for slot, index in enumerate(used):
        lookup[index] = CONTINUE_ICON_FIRST_SLOT + slot
    for index, target in merges.items():
        lookup[index] = lookup[target]
    tiles = bytes(lookup[b >> 4] << 4 | lookup[b & 15] for b in art)
    colours = b"".join(palette[i * 2 : i * 2 + 2] for i in used)
    return tiles, colours.ljust(CONTINUE_ICON_SLOTS * 2, b"\0")


def expected_outputs() -> dict[Path, bytes]:
    root, source, sk = get_root(), get_source("s1"), get_source("sk")
    extras = get_source("sonicretro")
    extended = (extras / EXTENDED_CARDS.split("/", 1)[1]).read_bytes()
    credits_font = decode((extras / CREDITS_FONT.split("/", 1)[1]).read_bytes())
    credits_original = decode((source / "artnem/Ending - Credits.nem").read_bytes())
    template = (source / "artnem/Title Cards.nem").read_bytes()
    raw = title_card(decode(template))
    if decode_moduled((source / "artkosm/Title Cards.kosm").read_bytes()) != decode(template):
        raise ValueError("Title-card source formats differ")
    s2, kis2 = get_source("s2"), get_source("kis2")
    tails_icon, tails_icon_colours = continue_icon(
        decode((s2 / "art/nemesis/Tails continue.nem").read_bytes()),
        (s2 / "art/palettes/SonicAndTails.bin").read_bytes(),
        {},
    )
    knuckles_icon, knuckles_icon_colours = continue_icon(
        decode((kis2 / "art/nemesis/Knuckles continue.nem").read_bytes()),
        (kis2 / "art/palettes/SonicAndTails.bin").read_bytes(),
        KNUCKLES_ICON_MERGES,
    )
    return {
        root / "artkosm/Continue Icon - Tails.kosm": encode_moduled(tails_icon),
        root / "palette/Continue Icon - Tails.bin": tails_icon_colours,
        root / "artkosm/Continue Icon - Knuckles.kosm": encode_moduled(knuckles_icon),
        root / "palette/Continue Icon - Knuckles.bin": knuckles_icon_colours,
        root / "artkosm/Monitor - Tails 1UP.kosm": encode_moduled(
            monitor_portrait(sk, "Tails", tails.COLOURS)
        ),
        root / "artkosm/Monitor - Knuckles 1UP.kosm": encode_moduled(
            monitor_portrait(sk, "Knuckles", knuckles.COLOURS)
        ),
        root / "artnem/Title Cards.nem": encode_with_table(template, raw),
        root / "artkosm/Title Cards.kosm": encode_moduled(raw),
        root / "artunc/Title Cards Extended.unc": extended_title_cards(extended),
        root / "artkosm/Credits - Text Font.kosm": encode_moduled(
            credits_text_font(credits_font, credits_original)
        ),
        root / "artkosm/Signpost - Tails Portrait.kosm": encode_moduled(
            sign_portrait(sk, 1, tails.COLOURS)
        ),
        root / "artkosm/Signpost - Knuckles Portrait.kosm": encode_moduled(
            sign_portrait(sk, 2, knuckles.COLOURS)
        ),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write title cards and portraits")
    args = parser.parse_args(argv)
    write_outputs(expected_outputs(), apply=args.apply)
    return 0
