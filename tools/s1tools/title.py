"""Reusable title transformations for Sonic 1 resources."""

from __future__ import annotations

import argparse
import hashlib
import re
import struct
import zipfile
import zlib
from dataclasses import dataclass, field
from pathlib import Path

from s1tools.codecs.enigma import decode as enigma_decode
from s1tools.codecs.enigma import decode_bytes as enigma_decode_bytes
from s1tools.codecs.enigma import entry_histogram as enigma_entry_histogram
from s1tools.codecs.kosinski import decode as kosinski_decode
from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.codecs.nemesis import encode_with_table as nemesis_encode_with_table
from s1tools.codecs.nemesis import parse_header as nemesis_parse_header
from s1tools.common import get_root, get_source

compare_ROOT = get_root()
compare_ZIP_PATH = get_source("title.zip")
compare_OUT = compare_ROOT / "tmp/title_compare"
compare_FILES = {
    "bg_art": "artnem/8x8 - Title.nem",
    "emblem_art": "artnem/Title Screen Foreground.nem",
    "psb_art": "artnem/Title Screen PSB.nem",
    "bg_layout": "levels/titlebg.bin",
    "blocks": "map16/Title.eni",
    "chunks": "map256/Title.kos",
    "emblem_map": "tilemaps/Title Screen.eni",
}
compare_CURRENT_BLOCKS_RAW = "map16/Title.bin"
compare_CURRENT_CHUNKS_RAW = "map256/Title.bin"
compare_TILE = 32
compare_PLANE_W, compare_PLANE_H = (64, 32)
compare_CHUNK_BYTES = 512
compare_MAX_CHUNKS = 82
compare_MAX_ROM_CHUNKS = 128
compare_LAYOUT_W, compare_LAYOUT_H = (64, 8)
compare_TRANSPARENT = 0
compare_UNKNOWN = 255
compare_UNDRAWN = None
compare_PSB_CURRENT = [
    (0, 0, 4, 1, 0),
    (32, 0, 1, 1, 3),
    (48, 0, 1, 1, 3),
    (56, 0, 4, 1, 4),
    (96, 0, 3, 1, 8),
    (120, 0, 3, 1, 11),
]
compare_PSB_GUIDE = [
    (-64, 0, 4, 1, 0),
    (-32, 0, 4, 1, 4),
    (0, 0, 4, 1, 8),
    (32, 0, 4, 1, 12),
    (64, 0, 2, 1, 16),
]
(
    compare_LEGACY_FOREGROUND,
    compare_LEGACY_SONIC,
    compare_LEGACY_TRADEMARK,
    compare_LEGACY_PRESS_START,
) = (512, 768, 1296, 1298)
compare_PSB_X_CURRENT = 88
compare_PSB_X_GUIDE = 88 + 64
compare_PSB_Y = 176
compare_PSB_MAPS = compare_ROOT / "_maps/Press Start and TM.asm"
compare_PSB_OBJECT = compare_ROOT / "_incObj/0E, 0F Title Screen - Sonic, Press Start, TM.asm"


class compare_Constants:
    """Evaluates 'name: equ expression' lines from _Constants.asm on demand."""

    def __init__(self, text: str):
        self.expressions = {
            m.group(1): m.group(2).strip()
            for m in re.finditer("^(\\w+):\\s+equ\\s+([^;\\n]+)", text, re.M)
        }
        self.values: dict[str, int] = {}

    def __getitem__(self, name: str) -> int:
        if name not in self.values:
            expression = self.expressions.get(name)
            if expression is None:
                raise KeyError(f"Missing constant {name}")
            python = re.sub("\\$([0-9A-Fa-f]+)", "0x\\1", expression)
            if not re.fullmatch("[\\w\\s+\\-*/()]+", python):
                raise ValueError(f"Unsupported expression for {name}: {expression}")
            names = {
                n: self[n]
                for n in re.findall("\\b[A-Za-z_]\\w*\\b", python)
                if not n.startswith("0x")
            }
            self.values[name] = int(eval(python, {"__builtins__": {}}, names))
        return self.values[name]


def compare_asm_number(text: str) -> int:
    text = text.strip()
    sign = -1 if text.startswith("-") else 1
    text = text.lstrip("-")
    return sign * (int(text[1:], 16) if text.startswith("$") else int(text))


def compare_repo_psb_pieces() -> list[tuple[int, int, int, int, int]]:
    """'.psb' sprite pieces (x, y, width, height, tile) from _maps/Press Start and TM.asm."""
    block = re.search(
        "^\\.psb:.*?$(.*?)^\\.psb_End", compare_PSB_MAPS.read_text(encoding="utf-8"), re.M | re.S
    )
    if not block:
        raise ValueError("No .psb frame in Press Start and TM.asm")
    pieces = []
    for line in block.group(1).splitlines():
        match = re.match("\\s*spritePiece\\s+([^;]+)", line)
        if match:
            pieces.append(tuple(compare_asm_number(v) for v in match.group(1).split(",")[:5]))
    return pieces


def compare_repo_psb_position() -> tuple[int, int]:
    """Screen X/Y of "PRESS START" from PSB_Main (FixBugs branch, plus any addi.w to obX)."""
    text = compare_PSB_OBJECT.read_text(encoding="utf-8")
    body = re.search("^PSB_Main:(.*?)^PSB_Exit:", text, re.M | re.S).group(1)
    x = re.search("if\\s+FixBugs.*?move\\.w\\s+#\\$80\\+\\$([0-9A-Fa-f]+),obX\\(a0\\)", body, re.S)
    y = re.search("move\\.w\\s+#\\$80\\+\\$([0-9A-Fa-f]+),obScreenY\\(a0\\)", body)
    extra = sum(int(v, 16) for v in re.findall("addi\\.w\\s+#\\$([0-9A-Fa-f]+),obX\\(a0\\)", body))
    return (int(x.group(1), 16) + extra, int(y.group(1), 16))


@dataclass
class compare_TitleModel:
    """How the game draws the current title: VRAM addresses, emblem placement, PSB sprite."""

    state: str
    foreground: int
    sonic: int
    trademark: int
    press_start: int
    emblem_base: int
    width: int
    height: int
    origin: tuple[int, int]
    psb_pieces: list
    psb_x: int
    psb_y: int


def compare_current_title_model(cells: int, constants_text: str) -> compare_TitleModel | None:
    if cells == 34 * 22:
        return compare_TitleModel(
            "pre-import (34x22 absolute)",
            compare_LEGACY_FOREGROUND,
            compare_LEGACY_SONIC,
            compare_LEGACY_TRADEMARK,
            compare_LEGACY_PRESS_START,
            0,
            34,
            22,
            (4, 4),
            compare_PSB_CURRENT,
            compare_PSB_X_CURRENT,
            compare_PSB_Y,
        )
    if cells == 40 * 28:
        const = compare_Constants(constants_text)
        fg = const["ArtTile_Title_Foreground"]
        x, y = compare_repo_psb_position()
        return compare_TitleModel(
            "imported (40x28 relative)",
            fg,
            const["ArtTile_Title_Sonic"],
            const["ArtTile_Title_Trademark"],
            const["ArtTile_Title_PressStart"],
            fg,
            40,
            28,
            (0, 0),
            compare_repo_psb_pieces(),
            x,
            y,
        )
    return None


def compare_enigma_words(blob: bytes, base: int) -> list[int]:
    """Exact EniDec output (see enigma_codec)."""
    return enigma_decode(blob, base)


def compare_raw_words(blob: bytes) -> list[int]:
    """Big-endian 16-bit words of a raw (uncompressed) file."""
    if len(blob) % 2:
        raise ValueError("raw word file has an odd length")
    return [int.from_bytes(blob[i : i + 2], "big") for i in range(0, len(blob), 2)]


def compare_current_block_words() -> tuple[list[int], str]:
    """Current title blocks as the game uses them: raw .bin if present, else the Enigma file."""
    raw = compare_ROOT / compare_CURRENT_BLOCKS_RAW
    if raw.exists():
        return (compare_raw_words(raw.read_bytes()), compare_CURRENT_BLOCKS_RAW)
    return (
        compare_enigma_words((compare_ROOT / compare_FILES["blocks"]).read_bytes(), 0),
        compare_FILES["blocks"],
    )


def compare_current_chunk_bytes() -> tuple[bytes, str]:
    """Current title chunks as the game uses them: raw .bin if present, else the Kosinski file."""
    raw = compare_ROOT / compare_CURRENT_CHUNKS_RAW
    if raw.exists():
        return (raw.read_bytes(), compare_CURRENT_CHUNKS_RAW)
    return (
        kosinski_decode((compare_ROOT / compare_FILES["chunks"]).read_bytes()),
        compare_FILES["chunks"],
    )


def compare_enigma_words_gallery(blob: bytes) -> list[int]:
    """Words as the former gallery decoder produced them, only for the decoder cross-check."""
    return enigma_decode(blob, legacy_literal_as_incremental=True)


@dataclass
class compare_Vram:
    name: str
    tiles: dict[int, bytes] = field(default_factory=dict)
    cache: dict[int, bytes] = field(default_factory=dict)

    def load(self, base: int, raw: bytes) -> None:
        for index in range(len(raw) // compare_TILE):
            self.tiles[base + index] = raw[index * compare_TILE : (index + 1) * compare_TILE]

    def cell(self, word: int) -> bytes:
        """64 pixel codes: (line << 4) | index, TRANSPARENT, or UNKNOWN."""
        cached = self.cache.get(word)
        if cached is not None:
            return cached
        data = self.tiles.get(word & 2047)
        if data is None:
            result = bytes([compare_UNKNOWN]) * 64
        else:
            line = word >> 13 & 3
            out = bytearray(64)
            for y in range(8):
                source = data[(7 - y if word & 4096 else y) * 4 :][:4]
                pixels = [n for b in source for n in (b >> 4, b & 15)]
                if word & 2048:
                    pixels.reverse()
                for x, value in enumerate(pixels):
                    out[y * 8 + x] = line << 4 | value if value else compare_TRANSPARENT
            result = bytes(out)
        self.cache[word] = result
        return result


def compare_read_palette() -> list[tuple[int, int, int]]:
    raw = (compare_ROOT / "palette/Title Screen.bin").read_bytes()
    colours = []
    for i in range(0, len(raw), 2):
        word = int.from_bytes(raw[i : i + 2], "big")
        colours.append(tuple((word >> shift & 14) * 255 // 14 for shift in (0, 4, 8)))
    while len(colours) < 64:
        colours.append((0, 0, 0))
    return colours


def compare_backdrop_code() -> int:
    return 2 << 4 | 0


@dataclass
class compare_Background:
    width: int
    height: int
    cells: list[list[int | None]]
    notes: list[str]


def compare_build_background(
    layout: bytes,
    chunks: bytes,
    blocks: list[int],
    label: str,
    max_chunks: int = compare_MAX_CHUNKS,
) -> compare_Background:
    """max_chunks: $52 when chunks are decompressed to v_256x256, $80 when read from ROM."""
    notes = []
    width, height = (layout[0] + 1, layout[1] + 1)
    if width > compare_LAYOUT_W or height > compare_LAYOUT_H:
        notes.append(
            f"{label}: layout {width}x{height} exceeds the ${compare_LAYOUT_W:X}x{compare_LAYOUT_H} RAM layout"
        )
    width, height = (min(width, compare_LAYOUT_W), min(height, compare_LAYOUT_H))
    stored_width = layout[0] + 1
    ids = [[layout[2 + row * stored_width + col] for col in range(width)] for row in range(height)]
    chunk_count = len(chunks) // compare_CHUNK_BYTES
    if chunk_count > max_chunks:
        notes.append(
            f"{label}: {chunk_count} chunks exceed the addressable ${max_chunks:X}; later chunks are not used"
        )
    usable = min(chunk_count, max_chunks)
    cells: list[list[int | None]] = [[compare_UNDRAWN] * (width * 32) for _ in range(height * 32)]
    bad_chunks, bad_blocks = (set(), set())
    for row in range(height):
        for col in range(width):
            chunk_id = ids[row][col]
            if chunk_id == 0:
                continue
            index = chunk_id - 1 & 127
            for by in range(16):
                for bx in range(16):
                    top, left = (row * 32 + by * 2, col * 32 + bx * 2)
                    if index >= usable:
                        bad_chunks.add(chunk_id)
                        words = [2047] * 4
                    else:
                        entry = int.from_bytes(
                            chunks[index * compare_CHUNK_BYTES + (by * 16 + bx) * 2 :][:2], "big"
                        )
                        block = entry & 1023
                        if block * 4 + 3 >= len(blocks):
                            bad_blocks.add(block)
                            words = [2047] * 4
                        else:
                            words = blocks[block * 4 : block * 4 + 4]
                            if entry & 2048:
                                words = [
                                    words[1] ^ 2048,
                                    words[0] ^ 2048,
                                    words[3] ^ 2048,
                                    words[2] ^ 2048,
                                ]
                            if entry & 4096:
                                words = [
                                    words[2] ^ 4096,
                                    words[3] ^ 4096,
                                    words[0] ^ 4096,
                                    words[1] ^ 4096,
                                ]
                    cells[top][left], cells[top][left + 1] = (words[0], words[1])
                    cells[top + 1][left], cells[top + 1][left + 1] = (words[2], words[3])
    if bad_chunks:
        notes.append(f"{label}: chunk IDs beyond loaded chunks: {sorted(bad_chunks)}")
    if bad_blocks:
        notes.append(f"{label}: block IDs beyond loaded blocks: {sorted(bad_blocks)[:16]}")
    return compare_Background(width, height, cells, notes)


def compare_write_png(path: Path, width: int, rows: list[bytes]) -> None:

    def chunk(kind: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 4294967295)
        )

    raw = b"".join(b"\x00" + row for row in rows)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, len(rows), 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 6))
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def compare_to_rgb(code: int, palette: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    if code == compare_UNKNOWN:
        return (255, 0, 255)
    if code == compare_TRANSPARENT:
        code = compare_backdrop_code()
    return palette[(code >> 4 & 3) * 16 + (code & 15)]


def compare_grid_images(
    grid_a: list[list[bytes]], grid_b: list[list[bytes]], palette, scale: int = 1
):
    """Build RGB rows for A, B and a diff image from two equal-sized cell grids."""
    rows_a, rows_b, rows_d = ([], [], [])
    for cells_a, cells_b in zip(grid_a, grid_b, strict=False):
        for y in range(0, 8, scale):
            line_a, line_b, line_d = (bytearray(), bytearray(), bytearray())
            for cell_a, cell_b in zip(cells_a, cells_b, strict=False):
                for x in range(0, 8, scale):
                    a, b = (cell_a[y * 8 + x], cell_b[y * 8 + x])
                    rgb_a, rgb_b = (compare_to_rgb(a, palette), compare_to_rgb(b, palette))
                    line_a += bytes(rgb_a)
                    line_b += bytes(rgb_b)
                    if compare_UNKNOWN in (a, b):
                        line_d += b"\xff\xff\x00"
                    elif a != b:
                        line_d += b"\xff\x00\x00"
                    else:
                        line_d += bytes(c // 3 for c in rgb_a)
            rows_a.append(bytes(line_a))
            rows_b.append(bytes(line_b))
            rows_d.append(bytes(line_d))
    return (rows_a, rows_b, rows_d)


def compare_read_archive(path: Path) -> tuple[dict[str, bytes], str]:
    with zipfile.ZipFile(path) as archive:
        names = [n for n in archive.namelist() if not n.endswith("/")]
        folder = [n for n in names if "original" in n.lower() and "256" in n]
        found, missing = ({}, [])
        for key, relative in compare_FILES.items():
            matches = [
                n for n in folder if n.replace("\\", "/").lower().endswith("/" + relative.lower())
            ]
            if len(matches) != 1:
                missing.append(f"{relative} ({len(matches)} matches)")
                continue
            found[key] = archive.read(matches[0])
        if missing:
            raise ValueError(
                "Archive entries not found in the Original 256x256 folder: "
                + ", ".join(missing)
                + "\nEntries:\n  "
                + "\n  ".join(names)
            )
        return (found, "\n".join(sorted(folder)))


def compare_sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()[:16]


def compare_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--zip", type=Path, default=compare_ZIP_PATH)
    parser.add_argument(
        "--zip-bg-tiles",
        type=lambda v: int(v, 0),
        default=None,
        help="Title_Background_Tiles for the archive (archive emblem art tile); default: max($105, archive background tile count), as the guide requires",
    )
    parser.add_argument(
        "--bg-scale", type=int, default=0, help="background preview pixel step (0 = auto)"
    )
    args = parser.parse_args(argv)
    compare_OUT.mkdir(parents=True, exist_ok=True)
    report: list[str] = []
    say = report.append
    palette = compare_read_palette()
    constants = (compare_ROOT / "_Constants.asm").read_text(encoding="utf-8")
    current = {key: (compare_ROOT / rel).read_bytes() for key, rel in compare_FILES.items()}
    archive, listing = compare_read_archive(args.zip)
    say(f"Archive: {args.zip} (sha256 {compare_sha(args.zip.read_bytes())})")
    say("Archive folder entries:\n  " + listing.replace("\n", "\n  "))
    say("\n== 1. File hashes (sha256 prefix): current vs archive ==")
    for key, relative in compare_FILES.items():
        same = current[key] == archive[key]
        say(
            f"  {relative:34} {compare_sha(current[key])} {compare_sha(archive[key])} {('IDENTICAL' if same else 'different')}"
        )
    if (compare_ROOT / compare_CURRENT_BLOCKS_RAW).exists():
        same = compare_raw_words(
            (compare_ROOT / compare_CURRENT_BLOCKS_RAW).read_bytes()
        ) == compare_enigma_words(archive["blocks"], 0)
        say(
            f"  {compare_CURRENT_BLOCKS_RAW:34} vs decoded archive {compare_FILES['blocks']}: {('IDENTICAL' if same else 'different')}"
        )
    if (compare_ROOT / compare_CURRENT_CHUNKS_RAW).exists():
        same = (compare_ROOT / compare_CURRENT_CHUNKS_RAW).read_bytes() == kosinski_decode(
            archive["chunks"]
        )
        say(
            f"  {compare_CURRENT_CHUNKS_RAW:34} vs decoded archive {compare_FILES['chunks']}: {('IDENTICAL' if same else 'different')}"
        )
    art_cur = {k: nemesis_decode(current[k]) for k in ("bg_art", "emblem_art", "psb_art")}
    art_zip = {k: nemesis_decode(archive[k]) for k in ("bg_art", "emblem_art", "psb_art")}
    sonic = nemesis_decode((compare_ROOT / "artnem/Title Screen Sonic.nem").read_bytes())
    tm = nemesis_decode((compare_ROOT / "artnem/Title Screen TM.nem").read_bytes())

    def count(raw):
        return len(raw) // compare_TILE

    say(
        "\nTile counts (current / archive): "
        + ", ".join(f"{k} ${count(art_cur[k]):X}/${count(art_zip[k]):X}" for k in art_cur)
    )
    say(
        "Nemesis XOR mode (current / archive): "
        + ", ".join(
            f"{k} {nemesis_parse_header(current[k]).xor}/{nemesis_parse_header(archive[k]).xor}"
            for k in art_cur
        )
    )
    say("\n== 0. Enigma decoder check (exact EniDec model vs old gallery decoder) ==")
    for key in ("emblem_map", "blocks"):
        for label, blob in (("current", current[key]), ("archive", archive[key])):
            exact = compare_enigma_words(blob, 0)
            old = compare_enigma_words_gallery(blob)
            differ = sum((a != b for a, b in zip(exact, old, strict=False))) + abs(
                len(exact) - len(old)
            )
            say(
                f"  {compare_FILES[key]:26} {label:7}: {len(exact)} words, entries {enigma_entry_histogram(blob)}; old decoder differs in {differ} words; first 8 exact {[f'{w:04X}' for w in exact[:8]]}"
            )
    model = compare_current_title_model(
        len(compare_enigma_words(current["emblem_map"], 0)), constants
    )
    if model is None:
        model = compare_current_title_model(34 * 22, constants)
        model.state = "UNKNOWN tilemap size (pre-import model assumed)"
    say(
        f"\nCurrent title state: {model.state}; emblem ${model.foreground:X}, Sonic ${model.sonic:X}, TM ${model.trademark:X}, PRESS START ${model.press_start:X}; PSB sprite at screen X ${model.psb_x:X}, Y ${model.psb_y:X}"
    )
    fg_base, sonic_base, tm_base, psb_base = (
        model.foreground,
        model.sonic,
        model.trademark,
        model.press_start,
    )
    vram_cur = compare_Vram("current")
    vram_cur.load(fg_base, art_cur["emblem_art"])
    vram_cur.load(sonic_base, sonic)
    vram_cur.load(tm_base, tm)
    vram_cur.load(psb_base, art_cur["psb_art"])
    vram_cur.load(0, art_cur["bg_art"])
    zip_fg = (
        args.zip_bg_tiles if args.zip_bg_tiles is not None else max(261, count(art_zip["bg_art"]))
    )
    zip_sonic = zip_fg + count(art_zip["emblem_art"])
    zip_psb = zip_sonic + count(sonic)
    zip_tm = zip_psb + count(art_zip["psb_art"])
    vram_zip = compare_Vram("archive")
    vram_zip.load(zip_fg, art_zip["emblem_art"])
    vram_zip.load(zip_sonic, sonic)
    vram_zip.load(zip_tm, tm)
    vram_zip.load(zip_psb, art_zip["psb_art"])
    vram_zip.load(0, art_zip["bg_art"])
    say(
        f"\nArchive VRAM by guide constants: background $0-${count(art_zip['bg_art']) - 1:X}, emblem ${zip_fg:X}, Sonic ${zip_sonic:X}, PSB ${zip_psb:X}, TM ${zip_tm:X}-${zip_tm + count(tm) - 1:X}"
    )
    if count(art_zip["bg_art"]) > zip_fg:
        say(
            f"  WARNING: archive background art (${count(art_zip['bg_art']):X} tiles) overwrites its emblem at ${zip_fg:X}"
        )
    if zip_tm + count(tm) > 1664:
        say("  WARNING: archive layout overlaps the level select font at $680")
    verdict = {}
    say("\n== 2. Emblem (plane A, 64x32 cells, per pixel + priority) ==")
    plane_cur = [[0] * compare_PLANE_W for _ in range(compare_PLANE_H)]
    plane_zip = [[0] * compare_PLANE_W for _ in range(compare_PLANE_H)]
    words_cur = compare_enigma_words(current["emblem_map"], model.emblem_base)
    words_zip = compare_enigma_words(archive["emblem_map"], zip_fg)
    say(
        f"  current tilemap {len(words_cur)} cells ({model.width}x{model.height} at {model.origin[0]},{model.origin[1]}, base ${model.emblem_base:X}); archive tilemap {len(words_zip)} cells (40x28 at 0,0, base ${zip_fg:X})"
    )
    for label, words, low, high in (
        ("current", words_cur, fg_base, fg_base + count(art_cur["emblem_art"])),
        ("archive", words_zip, zip_fg, zip_fg + count(art_zip["emblem_art"])),
    ):
        tiles = [w & 2047 for w in words]
        outside = sorted({t for t in tiles if t and (not low <= t < high)})
        say(
            f"  {label}: tiles ${min(tiles):X}-${max(tiles):X}, tile-0 cells {tiles.count(0)}, refs outside emblem art ${low:X}-${high - 1:X}: "
            + (
                ", ".join(f"${t:X}" for t in outside[:24]) + (" ..." if len(outside) > 24 else "")
                if outside
                else "none"
            )
        )
    if len(words_cur) != model.width * model.height or len(words_zip) != 40 * 28:
        say("  ERROR: unexpected tilemap size; emblem comparison skipped")
        verdict["emblem"] = "error"
    else:
        ox, oy = model.origin
        for i, word in enumerate(words_cur):
            plane_cur[oy + i // model.width][ox + i % model.width] = word
        for i, word in enumerate(words_zip):
            plane_zip[i // 40][i % 40] = word
        grid_cur = [[vram_cur.cell(w) for w in row] for row in plane_cur]
        grid_zip = [[vram_zip.cell(w) for w in row] for row in plane_zip]
        differing, unknown, priority = ([], [], [])
        for y in range(compare_PLANE_H):
            for x in range(compare_PLANE_W):
                a, b = (grid_cur[y][x], grid_zip[y][x])
                if compare_UNKNOWN in a or compare_UNKNOWN in b:
                    unknown.append((x, y))
                elif a != b:
                    differing.append((x, y))
                if (plane_cur[y][x] ^ plane_zip[y][x]) & 32768 and (any(a) or any(b)):
                    priority.append((x, y))
        current_ranges = (
            ("emblem", fg_base, fg_base + count(art_cur["emblem_art"])),
            ("Sonic tile", sonic_base, sonic_base + count(sonic)),
            ("TM tile", tm_base, tm_base + count(tm)),
            ("PSB tile", psb_base, psb_base + count(art_cur["psb_art"])),
            ("background", 0, count(art_cur["bg_art"])),
        )

        def describe(cells):
            parts = []
            for x, y in cells:
                tile = plane_cur[y][x] & 2047
                kind = next(
                    (name for name, low, high in current_ranges if low <= tile < high), "unloaded"
                )
                parts.append(
                    f"({x},{y}) cur ${plane_cur[y][x]:04X} [{kind}] zip ${plane_zip[y][x]:04X}"
                )
            return parts

        say(f"  cells with different pixels: {len(differing)}")
        for line in describe(differing)[:80]:
            say("    " + line)
        say(f"  cells involving unloaded VRAM (UNVERIFIED): {len(unknown)}")
        for line in describe(unknown)[:40]:
            say("    " + line)
        say(f"  non-empty cells with different priority bit: {len(priority)}")
        for line in describe(priority)[:40]:
            say("    " + line)

        def visible(rows):
            return [r[:40] for r in rows[:28]]

        a, b, d = compare_grid_images(visible(grid_cur), visible(grid_zip), palette)
        compare_write_png(compare_OUT / "emblem_current.png", 320, a)
        compare_write_png(compare_OUT / "emblem_archive.png", 320, b)
        compare_write_png(compare_OUT / "emblem_diff.png", 320, d)
        verdict["emblem"] = (
            "IDENTICAL"
            if not differing and (not unknown) and (not priority)
            else "DIFFERENT"
            if differing or priority
            else "UNVERIFIED"
        )
        say(f"  verdict: {verdict['emblem']} (previews: 40x28 cells from plane origin)")
    say("\n== 3. Background (plane B) in layout coordinates ==")
    blocks_cur, blocks_source = compare_current_block_words()
    blocks_zip = compare_enigma_words(archive["blocks"], 0)
    chunks_cur, chunks_source = compare_current_chunk_bytes()
    chunks_zip = kosinski_decode(archive["chunks"])
    say(f"  current blocks from {blocks_source}, chunks from {chunks_source}")
    say(
        f"  current: {len(blocks_cur) // 4} blocks, {len(chunks_cur) // compare_CHUNK_BYTES} chunks, layout {current['bg_layout'][0] + 1}x{current['bg_layout'][1] + 1}"
    )
    say(
        f"  archive: {len(blocks_zip) // 4} blocks, {len(chunks_zip) // compare_CHUNK_BYTES} chunks, layout {archive['bg_layout'][0] + 1}x{archive['bg_layout'][1] + 1}"
    )
    bg_cur = compare_build_background(
        current["bg_layout"],
        chunks_cur,
        blocks_cur,
        "current",
        compare_MAX_ROM_CHUNKS
        if chunks_source == compare_CURRENT_CHUNKS_RAW
        else compare_MAX_CHUNKS,
    )
    bg_zip = compare_build_background(archive["bg_layout"], chunks_zip, blocks_zip, "archive")
    for note in bg_cur.notes + bg_zip.notes:
        say("  NOTE: " + note)
    width = max(bg_cur.width, bg_zip.width) * 32
    height = max(bg_cur.height, bg_zip.height) * 32

    def cell_at(bg: compare_Background, vram: compare_Vram, x: int, y: int):
        if y >= len(bg.cells) or x >= len(bg.cells[0]):
            return (None, None)
        word = bg.cells[y][x]
        return (word, None if word is None else vram.cell(word))

    differing = unknown = undrawn_mismatch = priority = 0
    bbox = [width, height, -1, -1]
    grid_a, grid_b = ([], [])
    stale = bytes([compare_UNKNOWN]) * 64
    for y in range(height):
        row_a, row_b = ([], [])
        for x in range(width):
            word_a, a = cell_at(bg_cur, vram_cur, x, y)
            word_b, b = cell_at(bg_zip, vram_zip, x, y)
            if a is None and b is None:
                row_a.append(stale)
                row_b.append(stale)
                continue
            if a is None or b is None:
                undrawn_mismatch += 1
                bad = True
            elif compare_UNKNOWN in a or compare_UNKNOWN in b:
                unknown += 1
                bad = True
            else:
                bad = a != b
                differing += bad
                if (word_a ^ word_b) & 32768 and (any(a) or any(b)):
                    priority += 1
                    bad = True
            if bad:
                bbox = [min(bbox[0], x), min(bbox[1], y), max(bbox[2], x), max(bbox[3], y)]
            row_a.append(a if a is not None else stale)
            row_b.append(b if b is not None else stale)
        grid_a.append(row_a)
        grid_b.append(row_b)
    say(f"  compared {width}x{height} cells")
    say(f"  cells with different pixels: {differing}")
    say(f"  cells with different priority: {priority}")
    say(
        f"  cells drawn in one version but chunk 0 (undrawn, stale plane) in the other: {undrawn_mismatch}"
    )
    say(f"  cells involving unloaded VRAM or broken chunk/block refs (UNVERIFIED): {unknown}")
    if bbox[2] >= 0:
        say(
            f"  differences within cells x {bbox[0]}-{bbox[2]}, y {bbox[1]}-{bbox[3]} (pixels {bbox[0] * 8}-{bbox[2] * 8 + 7}, {bbox[1] * 8}-{bbox[3] * 8 + 7})"
        )
    scale = args.bg_scale or (4 if width * 8 > 8192 else 2 if width * 8 > 4096 else 1)
    a, b, d = compare_grid_images(grid_a, grid_b, palette, scale)
    compare_write_png(compare_OUT / "bg_current.png", width * 8 // scale, a)
    compare_write_png(compare_OUT / "bg_archive.png", width * 8 // scale, b)
    compare_write_png(compare_OUT / "bg_diff.png", width * 8 // scale, d)
    if differing or priority or undrawn_mismatch:
        verdict["background"] = "DIFFERENT"
    elif unknown:
        verdict["background"] = "UNVERIFIED"
    else:
        verdict["background"] = "IDENTICAL"
    say(f"  verdict: {verdict['background']} (previews 1:{scale}; magenta = undrawn/unknown)")
    say("\n== 4. PRESS START sprite (screen pixels) ==")

    def sprite(
        vram: compare_Vram, base: int, pieces, screen_x: int, screen_y: int
    ) -> dict[tuple[int, int], int]:
        pixels = {}
        for px, py, w, h, tile in pieces:
            for col in range(w):
                for row in range(h):
                    cell = vram.cell(base + tile + col * h + row)
                    for i, code in enumerate(cell):
                        if code != compare_TRANSPARENT:
                            pixels[
                                screen_x + px + col * 8 + i % 8, screen_y + py + row * 8 + i // 8
                            ] = code
        return pixels

    say(
        f"  current: {len(model.psb_pieces)} pieces at screen X ${model.psb_x:X}, Y ${model.psb_y:X} (art ${psb_base:X}); archive: guide mapping at X ${compare_PSB_X_GUIDE:X}, Y ${compare_PSB_Y:X} (art ${zip_psb:X})"
    )
    psb_cur = sprite(vram_cur, psb_base, model.psb_pieces, model.psb_x, model.psb_y)
    psb_zip = sprite(vram_zip, zip_psb, compare_PSB_GUIDE, compare_PSB_X_GUIDE, compare_PSB_Y)
    mismatch = [p for p in set(psb_cur) | set(psb_zip) if psb_cur.get(p) != psb_zip.get(p)]
    unknown_psb = [
        p
        for p in set(psb_cur) | set(psb_zip)
        if compare_UNKNOWN in (psb_cur.get(p), psb_zip.get(p))
    ]
    say(
        f"  opaque pixels: current {len(psb_cur)}, archive {len(psb_zip)}; differing {len(mismatch)}, unknown {len(unknown_psb)}"
    )
    xs = [p[0] for p in set(psb_cur) | set(psb_zip)] or [0]
    ys = [p[1] for p in set(psb_cur) | set(psb_zip)] or [compare_PSB_Y]
    left, right = (min(xs), max(xs))
    top, bottom = (min(ys), max(ys))
    rows = []
    for version in (psb_cur, psb_zip):
        for y in range(top, bottom + 1):
            rows.append(
                b"".join(
                    bytes(compare_to_rgb(version.get((x, y), compare_TRANSPARENT), palette))
                    for x in range(left, right + 1)
                )
            )
    for y in range(top, bottom + 1):
        rows.append(
            b"".join(
                b"\xff\x00\x00" if psb_cur.get((x, y)) != psb_zip.get((x, y)) else b"   "
                for x in range(left, right + 1)
            )
        )
    compare_write_png(compare_OUT / "psb_compare.png", right - left + 1, rows)
    verdict["press_start"] = (
        "IDENTICAL" if not mismatch else "UNVERIFIED" if unknown_psb else "DIFFERENT"
    )
    say(f"  verdict: {verdict['press_start']} (psb_compare.png rows: current, archive, diff)")
    say("\n== Summary ==")
    for key, value in verdict.items():
        say(f"  {key}: {value}")
    say(
        "\nProven by this script: per-pixel equality (colour indices) and priority bits of the emblem plane,\nthe background layout image, and the PRESS START sprite, from the actual decompressed data.\nNot proven here: the guide's code changes themselves (constants, loader, PSB object X), sprite\npriority interplay with big Sonic and the masking sprites, and anything drawn from unloaded VRAM."
    )
    text = "\n".join(report)
    (compare_OUT / "report.txt").write_text(text + "\n", encoding="utf-8")
    html = [
        "<!doctype html><meta charset=utf-8><title>Title vs S1TitleFixed</title>",
        "<style>body{background:#222;color:#ddd;font-family:monospace}img{image-rendering:pixelated;border:1px solid #555;margin:4px}pre{white-space:pre-wrap}</style>",
        "<h1>Title screen: current vs S1TitleFixed.zip</h1>",
        "<h2>Emblem (current / archive / diff)</h2>",
        "<img src=emblem_current.png width=640><img src=emblem_archive.png width=640><img src=emblem_diff.png width=640>",
        "<h2>PRESS START</h2><img src=psb_compare.png style='width:40em'>",
        "<h2>Background (current / archive / diff)</h2>",
        "<img src=bg_current.png style='max-width:100%'><br><img src=bg_archive.png style='max-width:100%'><br><img src=bg_diff.png style='max-width:100%'>",
        "<p>Diff: red = different pixels, yellow = unloaded VRAM, dim = identical. Magenta = undrawn/unknown.</p>",
        "<h2>Report</h2><pre>" + text.replace("&", "&amp;").replace("<", "&lt;") + "</pre>",
    ]
    (compare_OUT / "index.html").write_text("\n".join(html), encoding="utf-8")
    print(text)
    print(
        f"\nWrote {compare_OUT.relative_to(compare_ROOT)}/report.txt, index.html and PNG previews"
    )
    return 0 if all(v == "IDENTICAL" for v in verdict.values()) else 2


import_ROOT = get_root()
import_CONSTANTS = import_ROOT / "_Constants.asm"
import_TITLE_FG = import_ROOT / "levels/titlefg.bin"
import_EMPTY_LAYOUT = b"\x00\x00\x00"
import_TITLE_BLOCKS_BIN = import_ROOT / compare_CURRENT_BLOCKS_RAW
import_TITLE_CHUNKS_BIN = import_ROOT / compare_CURRENT_CHUNKS_RAW
import_TILE = 32
import_MIN_BACKGROUND_TILES = 262
import_MAX_BLOCKS = 1024
import_SONIC_TEAM_FONT = 166


def import_constant(text: str, name: str) -> int:
    match = re.search(f"^{name}:\\s+equ\\s+(\\$?)([0-9A-Fa-f]+)\\b", text, re.M)
    if not match:
        raise ValueError(f"Missing numeric constant {name} in _Constants.asm")
    return int(match.group(2), 16 if match.group(1) else 10)


def import_tiles(blob: bytes) -> int:
    return nemesis_parse_header(blob).tiles


def import_sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def import_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--zip", type=Path, default=compare_ZIP_PATH)
    parser.add_argument(
        "--write", action="store_true", help="write the archive files after all checks pass"
    )
    args = parser.parse_args(argv)
    archive, _ = compare_read_archive(args.zip)
    targets = {key: import_ROOT / relative for key, relative in compare_FILES.items()}
    imported = {key: targets[key].read_bytes() == archive[key] for key in targets}
    problems: list[str] = []
    fg_empty = import_TITLE_FG.read_bytes() == import_EMPTY_LAYOUT
    blocks_raw = enigma_decode_bytes(archive["blocks"])
    blocks_bin_ok = (
        import_TITLE_BLOCKS_BIN.exists() and import_TITLE_BLOCKS_BIN.read_bytes() == blocks_raw
    )
    chunks_raw = kosinski_decode(archive["chunks"])
    chunks_bin_ok = (
        import_TITLE_CHUNKS_BIN.exists() and import_TITLE_CHUNKS_BIN.read_bytes() == chunks_raw
    )
    print("Files (current == archive):")
    for key, _path in targets.items():
        print(f"  {compare_FILES[key]:34} {('already imported' if imported[key] else 'differs')}")
    print(
        f"  {import_TITLE_FG.relative_to(import_ROOT).as_posix():34} {('empty 1x1 layout' if fg_empty else 'not the empty 1x1 layout')}"
    )
    print(
        f"  {import_TITLE_BLOCKS_BIN.relative_to(import_ROOT).as_posix():34} {('matches decoded archive blocks' if blocks_bin_ok else 'differs from decoded archive blocks')}"
    )
    if all(imported.values()) and (not fg_empty) and (not args.write):
        problems.append(
            "archive files are imported but levels/titlefg.bin is not the empty 1x1 layout (rerun with --write)"
        )
    print(
        f"  {import_TITLE_CHUNKS_BIN.relative_to(import_ROOT).as_posix():34} {('matches decoded archive chunks' if chunks_bin_ok else 'differs from decoded archive chunks')}"
    )
    if all(imported.values()) and (not blocks_bin_ok) and (not args.write):
        problems.append(
            f"archive files are imported but {import_TITLE_BLOCKS_BIN.name} does not match them (rerun with --write)"
        )
    if all(imported.values()) and (not chunks_bin_ok) and (not args.write):
        problems.append(
            f"archive files are imported but {import_TITLE_CHUNKS_BIN.relative_to(import_ROOT).as_posix()} does not match them (rerun with --write)"
        )
    if all(imported.values()):
        print("\n1. All files already imported; equivalence proof not repeated.")
    else:
        print("\n1. Running the resource tools ...")
        result = compare_main(["--zip", str(args.zip)])
        if result != 0:
            problems.append("title_compare_fixed.py did not report IDENTICAL for everything")
        else:
            print("   -> IDENTICAL (emblem, background, PRESS START)")
    text = import_CONSTANTS.read_text(encoding="utf-8")
    counts = {
        "Title_Background_Tiles": import_tiles(archive["bg_art"]),
        "Title_Foreground_Tiles": import_tiles(archive["emblem_art"]),
        "Title_Sonic_Tiles": import_tiles(
            (import_ROOT / "artnem/Title Screen Sonic.nem").read_bytes()
        ),
        "Title_PSB_Tiles": import_tiles(archive["psb_art"]),
        "Title_TM_Tiles": import_tiles((import_ROOT / "artnem/Title Screen TM.nem").read_bytes()),
    }
    print("\n2. Tile counts (art / constant):")
    values = {}
    for name, actual in counts.items():
        value = import_constant(text, name)
        values[name] = value
        if name == "Title_Background_Tiles":
            ok = actual <= value and value >= import_MIN_BACKGROUND_TILES
            note = f"art ${actual:X} must fit, constant must be >= ${import_MIN_BACKGROUND_TILES:X}"
        else:
            ok = actual == value
            note = "must match"
        print(f"   {name}: ${actual:X} / ${value:X} ({('ok' if ok else 'MISMATCH')}; {note})")
        if not ok:
            problems.append(f"{name} does not match the archive art")
    foreground = values["Title_Background_Tiles"]
    sonic = foreground + values["Title_Foreground_Tiles"]
    press_start = sonic + values["Title_Sonic_Tiles"]
    trademark = press_start + values["Title_PSB_Tiles"]
    font = import_constant(text, "ArtTile_Level_Select_Font")
    japanese = import_tiles((import_ROOT / "artnem/Hidden Japanese Credits.nem").read_bytes())
    team_font = import_tiles((import_ROOT / "artnem/Ending - Credits.nem").read_bytes())
    print(
        f"\n3. VRAM: background $0-${counts['Title_Background_Tiles'] - 1:X}, emblem ${foreground:X}, Sonic ${sonic:X}, PRESS START ${press_start:X}, TM ${trademark:X}-${trademark + values['Title_TM_Tiles'] - 1:X}, level select font ${font:X}"
    )
    print(
        f"   during the STP screen: Japanese credits $0-${japanese - 1:X}, STP font ${import_SONIC_TEAM_FONT:X}-${import_SONIC_TEAM_FONT + team_font - 1:X}"
    )
    for label, end in (
        ("Japanese credits", japanese),
        ("STP font", import_SONIC_TEAM_FONT + team_font),
    ):
        if end > foreground:
            problems.append(
                f"{label} end at ${end:X}, overwritten while the emblem loads at ${foreground:X}"
            )
    if trademark + values["Title_TM_Tiles"] > font:
        problems.append("TM ends past the level select font")
    words = enigma_decode(archive["emblem_map"], foreground)
    emblem_end = foreground + values["Title_Foreground_Tiles"]
    outside = sorted({w & 2047 for w in words if not foreground <= w & 2047 < emblem_end})
    blocks = len(blocks_raw) // 8
    chunks = len(chunks_raw) // compare_CHUNK_BYTES
    print(
        f"\n4. Emblem tilemap: {len(words)} cells (expected 1120), refs outside ${foreground:X}-${emblem_end - 1:X}: {', '.join(f'${t:X}' for t in outside) or 'none'}"
    )
    print(
        f"   background: {blocks} blocks (max ${import_MAX_BLOCKS:X}), {chunks} chunks (max ${compare_MAX_ROM_CHUNKS:X})"
    )
    if len(words) != 40 * 28:
        problems.append("emblem tilemap is not 40x28")
    if outside:
        problems.append("emblem tilemap points outside the emblem art")
    if (
        blocks > import_MAX_BLOCKS
        or chunks > compare_MAX_ROM_CHUNKS
        or len(chunks_raw) % compare_CHUNK_BYTES
    ):
        problems.append(
            "background blocks exceed the $3FF block IDs, or chunks exceed the $7F index mask or are not whole $200-byte chunks"
        )
    if problems:
        print("\nNOT IMPORTING:\n  " + "\n  ".join(problems))
        return 1
    if not args.write:
        print("\nAll checks passed. Rerun with --write to import.")
        return 0
    for key, path in targets.items():
        path.write_bytes(archive[key])
    import_TITLE_FG.write_bytes(import_EMPTY_LAYOUT)
    import_TITLE_BLOCKS_BIN.write_bytes(blocks_raw)
    import_TITLE_CHUNKS_BIN.write_bytes(chunks_raw)
    for key, path in targets.items():
        if import_sha(path.read_bytes()) != import_sha(archive[key]):
            raise SystemExit(f"Write check failed for {path}")
    if import_TITLE_FG.read_bytes() != import_EMPTY_LAYOUT:
        raise SystemExit(f"Write check failed for {import_TITLE_FG}")
    if import_TITLE_BLOCKS_BIN.read_bytes() != blocks_raw:
        raise SystemExit(f"Write check failed for {import_TITLE_BLOCKS_BIN}")
    if import_TITLE_CHUNKS_BIN.read_bytes() != chunks_raw:
        raise SystemExit(f"Write check failed for {import_TITLE_CHUNKS_BIN}")
    print("\nImported:")
    for key in targets:
        print(f"  {compare_FILES[key]}  sha256 {import_sha(archive[key])}")
    print(f"  {import_TITLE_FG.relative_to(import_ROOT).as_posix()}  empty 1x1 layout")
    print(
        f"  {import_TITLE_BLOCKS_BIN.relative_to(import_ROOT).as_posix()}  raw blocks decoded from the archive, sha256 {import_sha(blocks_raw)}"
    )
    print(
        f"  {import_TITLE_CHUNKS_BIN.relative_to(import_ROOT).as_posix()}  raw chunks decoded from the archive, sha256 {import_sha(chunks_raw)}"
    )
    return 0


audit_ROOT = get_root()
audit_CONSTANTS = audit_ROOT / "_Constants.asm"
audit_EMBLEM_MAP = audit_ROOT / "tilemaps/Title Screen.eni"
audit_PSB_MAPS = audit_ROOT / "_maps/Press Start and TM.asm"
audit_SONPLN = audit_ROOT / "Utility Project Files/SonPLN.ini"
audit_SONLVL = [
    audit_ROOT / "Utility Project Files/SonLVL INI Files" / audit_name
    for audit_name in ("SonLVL.rev00.ini", "SonLVL.rev01.ini")
]
audit_TILE = 32
audit_ART = {
    "background": "artnem/8x8 - Title.nem",
    "emblem": "artnem/Title Screen Foreground.nem",
    "sonic": "artnem/Title Screen Sonic.nem",
    "psb": "artnem/Title Screen PSB.nem",
    "tm": "artnem/Title Screen TM.nem",
    "japanese": "artnem/Hidden Japanese Credits.nem",
    "stp_font": "artnem/Ending - Credits.nem",
}
audit_STATES = {34 * 22: ("legacy", 34, 22), 40 * 28: ("fullscreen", 40, 28)}
audit_failures: list[str] = []


def audit_check(ok: bool, message: str) -> None:
    print(f"  {('ok  ' if ok else 'FAIL')} {message}")
    if not ok:
        audit_failures.append(message)


class audit_Constants:
    """Evaluates 'name: equ expression' lines from _Constants.asm on demand."""

    def __init__(self, text: str):
        self.expressions = {
            m.group(1): m.group(2).strip()
            for m in re.finditer("^(\\w+):\\s+equ\\s+([^;\\n]+)", text, re.M)
        }
        self.values: dict[str, int] = {}

    def __getitem__(self, name: str) -> int:
        if name not in self.values:
            expression = self.expressions.get(name)
            if expression is None:
                raise KeyError(f"Missing constant {name}")
            python = re.sub("\\$([0-9A-Fa-f]+)", "0x\\1", expression)
            if not re.fullmatch("[\\w\\s+\\-*/()]+", python):
                raise ValueError(f"Unsupported expression for {name}: {expression}")
            names = {
                n: self[n]
                for n in re.findall("\\b[A-Za-z_]\\w*\\b", python)
                if not n.startswith("0x")
            }
            self.values[name] = int(eval(python, {"__builtins__": {}}, names))
        return self.values[name]


def audit_nem_tiles(relative: str) -> int:
    return nemesis_parse_header((audit_ROOT / relative).read_bytes()).tiles


def audit_number(text: str) -> int:
    text = text.strip()
    sign = -1 if text.startswith("-") else 1
    text = text.lstrip("-")
    return sign * (int(text[1:], 16) if text.startswith("$") else int(text))


def audit_psb_pieces() -> list[tuple[int, int, int, int, int]]:
    source = audit_PSB_MAPS.read_text(encoding="utf-8")
    block = re.search("^\\.psb:.*?$(.*?)^\\.psb_End", source, re.M | re.S)
    if not block:
        raise ValueError("No .psb frame in Press Start and TM.asm")
    pieces = []
    for line in block.group(1).splitlines():
        match = re.match("\\s*spritePiece\\s+([^;]+)", line)
        if match:
            x, y, w, h, tile = (audit_number(v) for v in match.group(1).split(",")[:5])
            pieces.append((x, y, w, h, tile))
    return pieces


def audit_ini_section(path: Path, name: str) -> dict[str, str] | None:
    section, found = (None, None)
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            if section == name:
                found = {}
            continue
        if section == name and "=" in line and (found is not None):
            key, value = line.split("=", 1)
            found[key] = value
    return found


def audit_config_file(ini: Path, value: str) -> Path:
    return (ini.parent / value.split(":")[0]).resolve()


def audit_main() -> int:
    const = audit_Constants(audit_CONSTANTS.read_text(encoding="utf-8"))
    counts = {key: audit_nem_tiles(path) for key, path in audit_ART.items()}
    raw = {
        key: nemesis_decode((audit_ROOT / audit_ART[key]).read_bytes())
        for key in ("background", "emblem")
    }
    words_base0 = enigma_decode(audit_EMBLEM_MAP.read_bytes())
    state = audit_STATES.get(len(words_base0))
    print(
        f"Emblem tilemap: {len(words_base0)} cells -> state: {(state[0] if state else 'UNKNOWN')}"
    )
    if not state:
        print("  FAIL unknown emblem tilemap size")
        return 1
    state_name, width, height = state
    fg = const["ArtTile_Title_Foreground"]
    ranges = {
        "emblem": (fg, fg + counts["emblem"]),
        "big Sonic": (const["ArtTile_Title_Sonic"], const["ArtTile_Title_Sonic"] + counts["sonic"]),
        "PRESS START": (
            const["ArtTile_Title_PressStart"],
            const["ArtTile_Title_PressStart"] + counts["psb"],
        ),
        "TM": (const["ArtTile_Title_Trademark"], const["ArtTile_Title_Trademark"] + counts["tm"]),
    }
    font = const["ArtTile_Level_Select_Font"]
    stp_font = const["ArtTile_Sonic_Team_Font"]
    print("\n1. Tile counts (art / constant):")
    audit_check(
        counts["background"] <= const["Title_Background_Tiles"],
        f"background ${counts['background']:X} fits Title_Background_Tiles ${const['Title_Background_Tiles']:X}",
    )
    for key, name in (
        ("emblem", "Title_Foreground_Tiles"),
        ("sonic", "Title_Sonic_Tiles"),
        ("psb", "Title_PSB_Tiles"),
        ("tm", "Title_TM_Tiles"),
    ):
        audit_check(
            counts[key] == const[name], f"{key} ${counts[key]:X} == {name} ${const[name]:X}"
        )
    print("\n2. VRAM layout:")
    print(
        "  "
        + ", ".join((f"{label} ${a:X}-${b - 1:X}" for label, (a, b) in ranges.items()))
        + f", background $0-${counts['background'] - 1:X}, level select font ${font:X}"
    )
    audit_check(
        counts["background"] <= fg,
        "background art ends before the emblem (loaded last, must not overwrite it)",
    )
    audit_check(
        counts["japanese"] <= fg,
        f"hidden Japanese credits $0-${counts['japanese'] - 1:X} end before the emblem",
    )
    audit_check(
        stp_font + counts["stp_font"] <= fg,
        f"STP font ${stp_font:X}-${stp_font + counts['stp_font'] - 1:X} ends before the emblem",
    )
    items = list(ranges.items())
    for i, (label_a, (a0, a1)) in enumerate(items):
        for label_b, (b0, b1) in items[i + 1 :]:
            audit_check(a1 <= b0 or b1 <= a0, f"{label_a} and {label_b} do not overlap")
    audit_check(
        max((end for _, end in ranges.values())) <= font,
        "title graphics end before the level select font",
    )
    menu_lo = const["ArtTile_Title_Menu"]
    menu_hi = menu_lo + const["Title_Menu_Tiles"]
    audit_check(
        max((end for _, end in ranges.values())) <= menu_lo, "title art ends before menu tiles"
    )
    audit_check(
        menu_hi <= const["vram_fg"] // audit_TILE,
        f"menu ${menu_lo:X}-${menu_hi - 1:X} ends before FG name table",
    )
    print(f"\n3. Emblem tilemap ({state_name}, {width}x{height}):")
    base = 0 if state_name == "legacy" else fg
    words = enigma_decode(audit_EMBLEM_MAP.read_bytes(), base)
    emblem_lo, emblem_hi = ranges["emblem"]
    blank_bg = not any(raw["background"][:audit_TILE])

    def allowed(t):
        return emblem_lo <= t < emblem_hi or (state_name == "legacy" and t == 0)

    outside = sorted({w & 2047 for w in words if not allowed(w & 2047)})
    tile0 = sum(1 for w in words if w & 2047 == 0)
    audit_check(
        not outside,
        f"tiles only in emblem art ${emblem_lo:X}-${emblem_hi - 1:X}"
        + (" or tile 0" if state_name == "legacy" else "")
        + ("" if not outside else "; outside: " + ", ".join(f"${t:X}" for t in outside[:24])),
    )
    if state_name == "legacy" and tile0:
        audit_check(blank_bg, f"{tile0} cells use tile 0, which is blank in the background art")
    psb_lo, psb_hi = ranges["PRESS START"]
    audit_check(
        not any(psb_lo <= w & 2047 < psb_hi for w in words),
        "tilemap does not use the PRESS START art",
    )
    blank_cells = sum(
        1
        for w in words
        if emblem_lo <= w & 2047 < emblem_hi
        and (not any(raw["emblem"][((w & 2047) - emblem_lo) * audit_TILE :][:audit_TILE]))
    )
    print(f"  info: {blank_cells} cells use blank emblem tiles, {tile0} cells use tile 0")
    grid = []
    for y in range(height):
        row = ""
        for x in range(width):
            tile = words[y * width + x] & 2047
            if tile == 0:
                row += "."
            elif emblem_lo <= tile < emblem_hi:
                row += (
                    "_"
                    if not any(raw["emblem"][(tile - emblem_lo) * audit_TILE :][:audit_TILE])
                    else "e"
                )
            else:
                row += "!"
        grid.append(row)
    print("  grid (e emblem, _ blank emblem tile, . tile 0, ! outside):")
    for y, row in enumerate(grid):
        print(f"   {y:2d} {row}")
    print("\n4. PRESS START:")
    pieces = audit_psb_pieces()
    end = max((tile + w * h for _, _, w, h, tile in pieces))
    audit_check(
        end <= counts["psb"],
        f".psb mappings use tiles 0-${end - 1:X} of the PSB art (${counts['psb']:X} tiles)",
    )
    audit_check(
        psb_lo >= emblem_hi or psb_hi <= emblem_lo,
        "PRESS START art is separate from the emblem art",
    )
    print("\n5. Editor configs:")
    emblem_entry = audit_ini_section(audit_SONPLN, "Title Screen\\\\Foreground Emblem")
    audit_check(emblem_entry is not None, "SonPLN.ini has [Title Screen\\\\Foreground Emblem]")
    if emblem_entry:
        tiles_value = emblem_entry.get("tiles", "")
        if state_name == "legacy":
            audit_check(
                tiles_value.startswith("dummy|")
                and tiles_value.endswith(f":0x{fg * audit_TILE:X}"),
                f"SonPLN tiles use the absolute offset (dummy ... :0x{fg * audit_TILE:X}): {tiles_value}",
            )
        else:
            audit_check(
                "dummy" not in tiles_value
                and audit_config_file(audit_SONPLN, tiles_value)
                == (audit_ROOT / "artkosm/Title Screen Foreground.kosm").resolve(),
                f"SonPLN tiles are the emblem art without offset: {tiles_value}",
            )
        audit_check(
            audit_config_file(audit_SONPLN, emblem_entry.get("mappings", ""))
            == audit_EMBLEM_MAP.resolve(),
            f"SonPLN mappings: {emblem_entry.get('mappings')}",
        )
        audit_check(
            (emblem_entry.get("width"), emblem_entry.get("height")) == (str(width), str(height)),
            f"SonPLN size {emblem_entry.get('width')}x{emblem_entry.get('height')} == {width}x{height}",
        )
    expected = {
        "tiles": "artkosm/8x8 - Title.kosm",
        "blocks": "map16/Title.bin",
        "chunks": "map256/Title.bin",
        "fglayout": "levels/titlefg.bin",
        "bglayout": "levels/titlebg.bin",
        "palette": "palette/Title Screen.bin",
    }
    for ini in audit_SONLVL:
        header = ini.read_text(encoding="utf-8").split("\n[", 1)[0]
        audit_check(
            re.search("^blockcmp=Uncompressed\\s*$", header, re.M) is not None,
            f"{ini.name} declares blockcmp=Uncompressed",
        )
        audit_check(
            re.search("^chunkcmp=Uncompressed\\s*$", header, re.M) is not None,
            f"{ini.name} declares chunkcmp=Uncompressed",
        )
        entry = audit_ini_section(ini, "Title Screen background")
        audit_check(entry is not None, f"{ini.name} has [Title Screen background]")
        if not entry:
            continue
        for key, relative in expected.items():
            value = entry.get(key, "")
            path = audit_config_file(ini, value) if value else None
            audit_check(
                path == (audit_ROOT / relative).resolve() and path.is_file(),
                f"{ini.name} {key}={value}",
            )
    fg_layout = (audit_ROOT / "levels/titlefg.bin").read_bytes()
    print(
        f"  info: levels/titlefg.bin is {fg_layout[0] + 1}x{fg_layout[1] + 1} chunks ({len(fg_layout)} bytes)"
    )
    print(
        "\nResult: "
        + ("all checks passed" if not audit_failures else f"{len(audit_failures)} check(s) failed")
    )
    return 1 if audit_failures else 0


prompt_ROOT = get_root()
prompt_FOREGROUND = prompt_ROOT / "artnem/Title Screen Foreground.nem"
prompt_PSB = prompt_ROOT / "artnem/Title Screen PSB.nem"
prompt_TILE = 32
prompt_FOREGROUND_TILES = 254
prompt_PSB_FIRST = 240
prompt_PSB_TILES = 14


def prompt_encode(template: bytes, raw: bytes) -> bytes:
    """Encode with the template's code table and a new tile count, then round-trip."""
    patched = (len(raw) // prompt_TILE).to_bytes(2, "big") + template[2:]
    blob = nemesis_encode_with_table(patched, raw)
    if nemesis_parse_header(blob).tiles != prompt_PSB_TILES or nemesis_decode(blob) != raw:
        raise ValueError("Nemesis round trip failed")
    return blob


def prompt_main(argv: list[str]) -> int:
    """Extract the fourteen prompt tiles from the original title artwork."""
    parser = argparse.ArgumentParser(description=prompt_main.__doc__)
    parser.add_argument("--source", type=Path, help="original foreground Nemesis file")
    parser.add_argument("--output-file", type=Path, help="write the extracted legacy prompt here")
    args = parser.parse_args(argv)
    source = args.source or get_source("s1") / "artnem/Title Screen Foreground.nem"
    original = source.read_bytes()
    raw = nemesis_decode(original)
    if len(raw) != prompt_FOREGROUND_TILES * prompt_TILE:
        raise ValueError("Expected the original 254-tile title foreground")
    tiles = raw[
        prompt_PSB_FIRST * prompt_TILE : (prompt_PSB_FIRST + prompt_PSB_TILES) * prompt_TILE
    ]
    result = prompt_encode(original, tiles)
    if args.output_file:
        if args.output_file.exists():
            raise ValueError("Output already exists")
        args.output_file.parent.mkdir(parents=True, exist_ok=True)
        args.output_file.write_bytes(result)
    print(f"Extracted {len(tiles) // 32} legacy prompt tiles; lossless encoding verified")
    return 0
