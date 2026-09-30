"""Reusable art transformations for Sonic 1 resources."""

from __future__ import annotations

import argparse
from pathlib import Path

from s1tools.codecs.kosinski import decode_moduled as kosinski_decode_moduled
from s1tools.codecs.kosinski import encode_moduled as kosinski_encode_moduled
from s1tools.codecs.nemesis import decode as nemesis_decode
from s1tools.common import get_root

convert_ROOT = get_root()
convert_SOURCE = convert_ROOT / "artnem"
convert_DESTINATION = convert_ROOT / "artkosm"
convert_MODULE_SIZE = 4096
convert_MAX_DISTANCE = 8192
convert_MAX_MATCH = 256
convert_MAX_CANDIDATES = 96


def convert_main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--output-dir", type=Path, help="write a preview directory")
    mode.add_argument("--apply", action="store_true", help="create artkosm")
    parser.add_argument("--limit", type=int, help="convert the first N files for a preview")
    args = parser.parse_args()
    files = sorted(convert_SOURCE.glob("*.nem"))
    if not files:
        parser.error("artnem is empty")
    if args.limit is not None:
        if args.limit < 1:
            parser.error("--limit must be positive")
        files = files[: args.limit]
    output = convert_DESTINATION if args.apply else args.output_dir.resolve()
    if args.apply and output.exists():
        parser.error("artkosm already exists; refusing to overwrite generated art")
    if output.exists() and any(output.iterdir()):
        parser.error(f"output directory is not empty: {output}")
    plans = []
    for source in files:
        raw = nemesis_decode(source.read_bytes())
        plans.append((source.stem + ".kosm", kosinski_encode_moduled(raw), len(raw)))
    output.mkdir(parents=True, exist_ok=True)
    for name, encoded, _ in plans:
        (output / name).write_bytes(encoded)
    raw_total = sum((size for _, _, size in plans))
    compressed_total = sum((len(blob) for _, blob, _ in plans))
    print(f"{len(plans)} files: {raw_total} raw bytes -> {compressed_total} KosM bytes")
    print(f"Output: {output}")
    return 0


rings_ROOT = get_root()
rings_KOSM = rings_ROOT / "artkosm" / "Rings.kosm"
rings_NEM = rings_ROOT / "artnem" / "Rings.nem"
rings_FRAMES = rings_ROOT / "artunc" / "Ring Frames.unc"
rings_SPARKLES = rings_ROOT / "artkosm" / "Ring Sparkles.kosm"
rings_TILE_SIZE = 32
rings_SHEET_TILES = 14


def rings_tile_pixels(tile: bytes) -> list[list[int]]:
    rows = []
    for y in range(8):
        row = []
        for byte in tile[y * 4 : y * 4 + 4]:
            row.extend((byte >> 4, byte & 15))
        rows.append(row)
    return rows


def rings_piece_to_image(tiles: list[bytes], width: int, height: int) -> list[list[int]]:
    """VDP sprite pieces store tiles column by column."""
    image = [[0] * (width * 8) for _ in range(height * 8)]
    for column in range(width):
        for row in range(height):
            pixels = rings_tile_pixels(tiles[column * height + row])
            for y in range(8):
                image[row * 8 + y][column * 8 : column * 8 + 8] = pixels[y]
    return image


def rings_image_to_piece(image: list[list[int]]) -> bytes:
    """Encode a 16x16 image as a 2x2 sprite piece (column-major tiles)."""
    out = bytearray()
    for column in range(2):
        for row in range(2):
            for y in range(8):
                line = image[row * 8 + y][column * 8 : column * 8 + 8]
                out.extend(line[x] << 4 | line[x + 1] for x in range(0, 8, 2))
    return bytes(out)


def rings_build_frames(sheet: bytes) -> bytes:
    tiles = [
        sheet[i * rings_TILE_SIZE : (i + 1) * rings_TILE_SIZE] for i in range(rings_SHEET_TILES)
    ]
    front = rings_piece_to_image(tiles[0:4], 2, 2)
    angle = rings_piece_to_image(tiles[4:8], 2, 2)
    edge_piece = rings_piece_to_image(tiles[8:10], 1, 2)
    edge = [[0] * 16 for _ in range(16)]
    for y in range(16):
        edge[y][4:12] = edge_piece[y]
    angle_flipped = [list(reversed(line)) for line in angle]
    frames = b"".join(rings_image_to_piece(image) for image in (front, angle, edge, angle_flipped))
    if len(frames) != 16 * rings_TILE_SIZE:
        raise AssertionError("ring frames must be 16 tiles")
    if frames[:128] != b"".join(tiles[0:4]) or frames[128:256] != b"".join(tiles[4:8]):
        raise AssertionError("front/angle frames must equal the source tiles")
    return frames


def rings_write_checked(
    path: Path, data: bytes, apply: bool, parser: argparse.ArgumentParser, compare=None
) -> None:
    if path.exists():
        existing = path.read_bytes()
        same = compare(existing) if compare else existing == data
        if not same:
            parser.error(f"{path} exists and differs; refusing to overwrite")
        print(f"{path.relative_to(rings_ROOT)} already matches")
    elif apply:
        path.write_bytes(data)
        print(f"Wrote {path.relative_to(rings_ROOT)} ({len(data)} bytes)")
    else:
        print(f"OK: {path.relative_to(rings_ROOT)} would be {len(data)} bytes; rerun with --apply")


def rings_main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--apply", action="store_true", help="write missing outputs")
    args = parser.parse_args()
    sheet = kosinski_decode_moduled(rings_KOSM.read_bytes())
    if len(sheet) != rings_SHEET_TILES * rings_TILE_SIZE:
        parser.error(
            f"{rings_KOSM.name}: {len(sheet) // rings_TILE_SIZE} tiles, expected {rings_SHEET_TILES}"
        )
    if rings_NEM.exists() and nemesis_decode(rings_NEM.read_bytes()) != sheet:
        parser.error(f"{rings_NEM.name} and {rings_KOSM.name} decode differently")
    frames = rings_build_frames(sheet)
    sparkles_raw = sheet[10 * rings_TILE_SIZE : 14 * rings_TILE_SIZE]
    rings_write_checked(rings_FRAMES, frames, args.apply, parser)
    rings_write_checked(
        rings_SPARKLES,
        kosinski_encode_moduled(sparkles_raw),
        args.apply,
        parser,
        compare=lambda blob: kosinski_decode_moduled(blob) == sparkles_raw,
    )
    return 0


shield_ROOT = get_root()
shield_TILE_SIZE = 32
shield_SHIELD_KOSM = shield_ROOT / "artkosm" / "Shield.kosm"
shield_SHIELD_NEM = shield_ROOT / "artnem" / "Shield.nem"
shield_SHIELD_UNC = shield_ROOT / "artunc" / "Shield.unc"
shield_SHIELD_TILES = 27
shield_STARS_KOSM = shield_ROOT / "artkosm" / "Invincibility Stars.kosm"
shield_STARS_NEM = shield_ROOT / "artnem" / "Invincibility Stars.nem"
shield_STARS_UNC = shield_ROOT / "artunc" / "Invincibility Stars Restore.unc"
shield_STARS_TILES = 36


def shield_decode_checked(
    parser: argparse.ArgumentParser, kosm: Path, nem: Path, tiles: int
) -> bytes:
    raw = kosinski_decode_moduled(kosm.read_bytes())
    if len(raw) != tiles * shield_TILE_SIZE:
        parser.error(f"{kosm.name}: {len(raw) // shield_TILE_SIZE} tiles, expected {tiles}")
    if nem.exists() and nemesis_decode(nem.read_bytes()) != raw:
        parser.error(f"{nem.name} and {kosm.name} decode differently")
    return raw


def shield_main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply", action="store_true", help=f"write {shield_SHIELD_UNC.relative_to(shield_ROOT)}"
    )
    args = parser.parse_args()
    stars = shield_decode_checked(parser, shield_STARS_KOSM, shield_STARS_NEM, shield_STARS_TILES)
    if shield_STARS_UNC.read_bytes() != stars:
        parser.error(f"{shield_STARS_UNC.name} differs from {shield_STARS_KOSM.name}")
    print(
        f"OK: {shield_STARS_UNC.name} matches {shield_STARS_KOSM.name} ({shield_STARS_TILES} tiles)"
    )
    shield = shield_decode_checked(
        parser, shield_SHIELD_KOSM, shield_SHIELD_NEM, shield_SHIELD_TILES
    )
    if shield_SHIELD_UNC.exists():
        if shield_SHIELD_UNC.read_bytes() != shield:
            parser.error(f"{shield_SHIELD_UNC} exists and differs; refusing to overwrite")
        print(f"{shield_SHIELD_UNC} already matches ({len(shield)} bytes)")
        return 0
    if args.apply:
        shield_SHIELD_UNC.write_bytes(shield)
        print(f"Wrote {shield_SHIELD_UNC} ({len(shield)} bytes, {shield_SHIELD_TILES} tiles)")
    else:
        print(f"OK: {len(shield)} bytes, {shield_SHIELD_TILES} tiles; rerun with --apply to write")
    return 0


walls_ROOT = get_root()
walls_KOSM = walls_ROOT / "artkosm" / "Special Walls.kosm"
walls_NEM = walls_ROOT / "artnem" / "Special Walls.nem"
walls_DESTINATION = walls_ROOT / "artunc" / "Special Walls.unc"
walls_TILE_SIZE = 32
walls_EXPECTED_TILES = 9 + 15 * 16


def walls_main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply", action="store_true", help=f"write {walls_DESTINATION.relative_to(walls_ROOT)}"
    )
    args = parser.parse_args()
    raw = kosinski_decode_moduled(walls_KOSM.read_bytes())
    if len(raw) != walls_EXPECTED_TILES * walls_TILE_SIZE:
        parser.error(
            f"{walls_KOSM.name}: {len(raw) // walls_TILE_SIZE} tiles, expected {walls_EXPECTED_TILES}"
        )
    if walls_NEM.exists() and nemesis_decode(walls_NEM.read_bytes()) != raw:
        parser.error(f"{walls_NEM.name} and {walls_KOSM.name} decode differently")
    if walls_DESTINATION.exists():
        if walls_DESTINATION.read_bytes() != raw:
            parser.error(f"{walls_DESTINATION} exists and differs; refusing to overwrite")
        print(f"{walls_DESTINATION} already matches ({len(raw)} bytes)")
        return 0
    if args.apply:
        walls_DESTINATION.write_bytes(raw)
        print(f"Wrote {walls_DESTINATION} ({len(raw)} bytes, {walls_EXPECTED_TILES} tiles)")
    else:
        print(f"OK: {len(raw)} bytes, {walls_EXPECTED_TILES} tiles; rerun with --apply to write")
    return 0


def codec_main() -> None:
    """Convert individual art files without altering the source."""
    from s1tools.codecs import kosinski, nemesis

    parser = argparse.ArgumentParser(description=codec_main.__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument(
        "--from-format", choices=["raw", "nemesis", "kosinski", "kosm"], required=True
    )
    parser.add_argument(
        "--to-format", choices=["raw", "nemesis", "kosinski", "kosm"], required=True
    )
    parser.add_argument("--output-file", type=Path, required=True)
    parser.add_argument("--compressor", help="Nemesis compressor executable")
    parser.add_argument(
        "--template",
        type=Path,
        help="Nemesis code table template instead of an external compressor",
    )
    args = parser.parse_args()
    if args.output_file.exists():
        parser.error("Output already exists")
    decoders = {
        "raw": lambda b: b,
        "nemesis": nemesis.decode,
        "kosinski": kosinski.decode,
        "kosm": kosinski.decode_moduled,
    }
    raw = decoders[args.from_format](args.source.read_bytes())
    if args.to_format == "raw":
        result = raw
    elif args.to_format == "kosinski":
        result = kosinski.encode(raw)
    elif args.to_format == "kosm":
        result = kosinski.encode_moduled(raw)
    elif args.template:
        result = nemesis.encode_with_table(args.template.read_bytes(), raw)
    else:
        result = nemesis.compress_bytes(raw, args.compressor)
    if decoders[args.to_format](result) != raw:
        raise ValueError("Conversion changed decoded pixels")
    args.output_file.parent.mkdir(parents=True, exist_ok=True)
    args.output_file.write_bytes(result)
    print(f"Wrote {args.output_file}: {len(raw)} decoded bytes")


def inputs_main() -> None:
    """Extract the checked resource inputs into a portable directory."""
    import shutil

    from s1tools.common import get_source

    parser = argparse.ArgumentParser(description=inputs_main.__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    if args.output_dir.exists() and any(args.output_dir.iterdir()):
        parser.error("Output directory must be empty")
    source = get_source("s1").parent
    shutil.copytree(source, args.output_dir, dirs_exist_ok=True)
    print(f"Extracted source inputs to {args.output_dir}")
