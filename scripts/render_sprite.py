#!/usr/bin/env python3
"""Render Sonic 1 sprite art + mappings + palette to BMP without running the ROM."""

from __future__ import annotations

import argparse
import json
import math
import re
import struct
import sys
from dataclasses import dataclass
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from nemesis_tool import decompress_bytes

ROOT = Path(__file__).resolve().parents[1]
FLEX_PATH = ROOT / 'sonic1.flex.json'


@dataclass
class Piece:
    x: int
    y: int
    width_tiles: int
    height_tiles: int
    tile: int
    palette_line: int
    xflip: bool
    yflip: bool


@dataclass
class ObjectDef:
    name: str
    art_path: Path
    compression: str
    art_offset: int
    mapping_path: Path
    palette_paths: list[tuple[Path, int]]
    dplc_enabled: bool


def parse_number(text: str) -> int:
    text = text.strip()
    text = text.replace('$', '0x')
    if text.startswith('-0x'):
        return -int(text[1:], 16)
    if text.startswith('0x'):
        return int(text, 16)
    return int(text, 10)


def flatten_objects(nodes):
    for node in nodes:
        if 'children' in node:
            yield from flatten_objects(node['children'])
        else:
            yield node


def load_object_definition(name: str) -> ObjectDef:
    data = json.loads(FLEX_PATH.read_text(encoding='utf-8'))
    for node in flatten_objects(data['objects']):
        if node.get('name', '').lower() != name.lower():
            continue
        art = node['art']
        palettes = []
        for palette in node.get('palettes', []):
            palettes.append((ROOT / Path(palette['path']), int(palette.get('length', 1))))
        return ObjectDef(
            name=node['name'],
            art_path=ROOT / Path(art['path']),
            compression=art['compression'],
            art_offset=int(art.get('offset', 0)),
            mapping_path=ROOT / Path(node['mappings']['path']),
            palette_paths=palettes,
            dplc_enabled=bool(node.get('dplcs', {}).get('enabled', False)),
        )
    raise SystemExit(f'Object not found in sonic1.flex.json: {name}')


def load_art(obj: ObjectDef) -> bytes:
    data = obj.art_path.read_bytes()
    if obj.compression.lower() == 'nemesis':
        data = decompress_bytes(data)
    elif obj.compression.lower() != 'uncompressed':
        raise SystemExit(f'Unsupported compression: {obj.compression}')
    if obj.art_offset:
        data = data[obj.art_offset :]
    return data


def decode_tiles(data: bytes) -> list[list[list[int]]]:
    if len(data) % 32 != 0:
        raise SystemExit(f'Art size is not a multiple of 32 bytes: {len(data)}')
    tiles = []
    for tile_index in range(0, len(data), 32):
        tile_bytes = data[tile_index : tile_index + 32]
        rows = []
        for row in range(8):
            row_bytes = tile_bytes[row * 4 : row * 4 + 4]
            pixels = []
            for b in row_bytes:
                pixels.append((b >> 4) & 0xF)
                pixels.append(b & 0xF)
            rows.append(pixels)
        tiles.append(rows)
    return tiles


def load_palette_lines(obj: ObjectDef) -> list[list[tuple[int, int, int]]]:
    lines: list[list[tuple[int, int, int]]] = []
    for palette_path, declared_lines in obj.palette_paths:
        blob = palette_path.read_bytes()
        available_lines = len(blob) // 32
        line_count = min(max(declared_lines, 1), max(available_lines, 1))
        for i in range(line_count):
            chunk = blob[i * 32 : (i + 1) * 32]
            line = []
            for j in range(0, len(chunk), 2):
                word = (chunk[j] << 8) | chunk[j + 1]
                blue = (word >> 8) & 0xF
                green = (word >> 4) & 0xF
                red = word & 0xF
                def expand(component: int) -> int:
                    component = component & 0xE
                    return round(component / 0xE * 255)
                line.append((expand(red), expand(green), expand(blue)))
            lines.append(line)
    return lines or [[(0, 0, 0)] * 16]


def parse_mappings(path: Path) -> tuple[list[str], dict[str, list[Piece]]]:
    table: list[str] = []
    frames: dict[str, list[Piece]] = {}
    current_label: str | None = None

    for raw_line in path.read_text(encoding='utf-8').splitlines():
        line = raw_line.split(';', 1)[0].strip()
        if not line:
            continue
        if 'mappingsTableEntry.w' in line:
            label = line.split('mappingsTableEntry.w', 1)[1].strip()
            table.append(label)
            continue
        if line.endswith(':\tspriteHeader') or line.endswith(': spriteHeader'):
            label = line.split(':', 1)[0].strip()
            current_label = label
            frames[current_label] = []
            continue
        if line.startswith('spritePiece'):
            if current_label is None:
                continue
            args = [part.strip() for part in line.split('spritePiece', 1)[1].split(',')]
            if len(args) < 9:
                raise SystemExit(f'Unexpected spritePiece format in {path}: {raw_line}')
            piece = Piece(
                x=parse_number(args[0]),
                y=parse_number(args[1]),
                width_tiles=parse_number(args[2]),
                height_tiles=parse_number(args[3]),
                tile=parse_number(args[4]),
                palette_line=parse_number(args[5]),
                xflip=bool(parse_number(args[6])),
                yflip=bool(parse_number(args[7])),
            )
            frames[current_label].append(piece)
            continue
    return table, frames


def checkerboard(width: int, height: int) -> list[list[tuple[int, int, int]]]:
    image = []
    for y in range(height):
        row = []
        for x in range(width):
            light = ((x // 8) + (y // 8)) % 2 == 0
            row.append((210, 210, 210) if light else (170, 170, 170))
        image.append(row)
    return image


def render_frame(tiles, palette_lines, pieces: list[Piece]) -> tuple[list[list[tuple[int, int, int]]], tuple[int, int, int, int]]:
    if not pieces:
        return checkerboard(8, 8), (0, 0, 7, 7)
    min_x = min(piece.x for piece in pieces)
    min_y = min(piece.y for piece in pieces)
    max_x = max(piece.x + piece.width_tiles * 8 for piece in pieces)
    max_y = max(piece.y + piece.height_tiles * 8 for piece in pieces)
    width = max_x - min_x
    height = max_y - min_y
    image = checkerboard(width, height)

    for piece in pieces:
        palette_line = palette_lines[min(piece.palette_line, len(palette_lines) - 1)]
        for ty in range(piece.height_tiles):
            for tx in range(piece.width_tiles):
                tile_index = piece.tile + ty * piece.width_tiles + tx
                if tile_index >= len(tiles):
                    continue
                tile = tiles[tile_index]
                px = piece.x - min_x + tx * 8
                py = piece.y - min_y + ty * 8
                for row in range(8):
                    sy = 7 - row if piece.yflip else row
                    for col in range(8):
                        sx = 7 - col if piece.xflip else col
                        value = tile[sy][sx]
                        if value == 0:
                            continue
                        image[py + row][px + col] = palette_line[value]
    return image, (min_x, min_y, max_x - 1, max_y - 1)


def write_bmp(path: Path, image: list[list[tuple[int, int, int]]]) -> None:
    height = len(image)
    width = len(image[0]) if height else 0
    row_size = (width * 3 + 3) & ~3
    pixel_array_size = row_size * height
    file_size = 14 + 40 + pixel_array_size
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('wb') as f:
        f.write(b'BM')
        f.write(struct.pack('<IHHI', file_size, 0, 0, 54))
        f.write(struct.pack('<IIIHHIIIIII', 40, width, height, 1, 24, 0, pixel_array_size, 2835, 2835, 0, 0))
        for row in reversed(image):
            row_bytes = bytearray()
            for r, g, b in row:
                row_bytes.extend((b, g, r))
            row_bytes.extend(b'\x00' * (row_size - len(row_bytes)))
            f.write(row_bytes)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('object_name', help='Object name from sonic1.flex.json, e.g. "Monitor"')
    parser.add_argument('--frame', type=int, help='Render only one frame index')
    parser.add_argument('--output-dir', default='tmp/rendered-sprites', help='Output directory relative to repo root')
    args = parser.parse_args(argv)

    obj = load_object_definition(args.object_name)
    if obj.dplc_enabled:
        raise SystemExit(f'DPLC-enabled object not yet supported: {obj.name}')

    art = load_art(obj)
    tiles = decode_tiles(art)
    palette_lines = load_palette_lines(obj)
    table, frames = parse_mappings(obj.mapping_path)

    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = ROOT / output_dir
    slug = re.sub(r'[^A-Za-z0-9._-]+', '_', obj.name)

    indices = [args.frame] if args.frame is not None else list(range(len(table)))
    for index in indices:
        if index < 0 or index >= len(table):
            raise SystemExit(f'Frame index out of range: {index}')
        label = table[index]
        pieces = frames.get(label, [])
        image, bounds = render_frame(tiles, palette_lines, pieces)
        out_path = output_dir / f'{slug}.{index:02d}.bmp'
        write_bmp(out_path, image)
        print(f'{out_path.relative_to(ROOT)}  label={label}  bounds={bounds}  pieces={len(pieces)}')

    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
