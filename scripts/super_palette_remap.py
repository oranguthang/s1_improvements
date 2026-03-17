#!/usr/bin/env python3
"""Remap Super Sonic-conflicting palette indices in Nemesis art."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from nemesis_tool import compress_bytes, decompress_bytes
from super_palette_candidates import ROOT, build_report


def parse_mapping(text: str) -> dict[int, int]:
    mapping: dict[int, int] = {}
    for pair in text.split(','):
        left, right = pair.split(':', 1)
        src = int(left.strip(), 0)
        dst = int(right.strip(), 0)
        if not (0 <= src <= 15 and 0 <= dst <= 15):
            raise ValueError(f'invalid nibble mapping {src}:{dst}')
        mapping[src] = dst
    return mapping


def remap_raw_bytes(data: bytes, mapping: dict[int, int]) -> bytes:
    output = bytearray(len(data))
    for i, byte in enumerate(data):
        hi = (byte >> 4) & 0xF
        lo = byte & 0xF
        hi = mapping.get(hi, hi)
        lo = mapping.get(lo, lo)
        output[i] = (hi << 4) | lo
    return bytes(output)


def used_indices(data: bytes) -> list[int]:
    used = set()
    for byte in data:
        used.add((byte >> 4) & 0xF)
        used.add(byte & 0xF)
    return sorted(used)


def default_output_path(input_path: Path, strategy: str) -> Path:
    return input_path.with_suffix(f'.{strategy}.nem')


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('asset', help='Path to input .nem file, relative to repo root or absolute')
    parser.add_argument('--strategy', choices=('direct', 'merge_warm', 'custom'), default='direct')
    parser.add_argument('--map', dest='custom_map', help='Explicit nibble map, e.g. 2:12,3:13,4:14,5:15')
    parser.add_argument('--output', help='Output .nem path')
    parser.add_argument('--in-place', action='store_true', help='Overwrite the input asset')
    parser.add_argument('--dry-run', action='store_true', help='Do not write output, only print analysis')
    parser.add_argument('--json', action='store_true', help='Emit JSON summary')
    args = parser.parse_args(argv)

    input_path = Path(args.asset)
    if not input_path.is_absolute():
        input_path = ROOT / input_path
    input_path = input_path.resolve()

    report = build_report(str(input_path.relative_to(ROOT)).replace('\\', '/'), [input_path.stem])

    if args.strategy == 'custom':
        if not args.custom_map:
            raise SystemExit('--map is required with --strategy custom')
        mapping = parse_mapping(args.custom_map)
    elif args.strategy == 'direct':
        if not report.direct_map:
            raise SystemExit(f'No direct_map available for {input_path}')
        mapping = report.direct_map
    else:
        if not report.merge_warm_map:
            raise SystemExit(f'No merge_warm_map available for {input_path}')
        mapping = report.merge_warm_map

    source_bytes = input_path.read_bytes()
    raw_before = decompress_bytes(source_bytes)
    raw_after = remap_raw_bytes(raw_before, mapping)
    nem_after = compress_bytes(raw_after, accurate=True)

    summary = {
        'asset': str(input_path.relative_to(ROOT)).replace('\\', '/'),
        'strategy': args.strategy,
        'mapping': mapping,
        'before_used': used_indices(raw_before),
        'after_used': used_indices(raw_after),
        'raw_size': len(raw_before),
        'nem_size_before': len(source_bytes),
        'nem_size_after': len(nem_after),
    }

    if not args.dry_run:
        if args.in_place:
            output_path = input_path
        else:
            output_path = Path(args.output) if args.output else default_output_path(input_path, args.strategy)
            if not output_path.is_absolute():
                output_path = ROOT / output_path
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_bytes(nem_after)
        summary['output'] = str(output_path.relative_to(ROOT)).replace('\\', '/')

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(f"asset: {summary['asset']}")
        print(f"strategy: {summary['strategy']}")
        print(f"mapping: {summary['mapping']}")
        print(f"before_used: {summary['before_used']}")
        print(f"after_used:  {summary['after_used']}")
        print(f"sizes: raw={summary['raw_size']} nem_before={summary['nem_size_before']} nem_after={summary['nem_size_after']}")
        if 'output' in summary:
            print(f"output: {summary['output']}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
