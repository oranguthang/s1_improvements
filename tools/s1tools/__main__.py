"""Command-line entry point for resource import, conversion and validation."""

from __future__ import annotations

import argparse
import importlib
import inspect
import sys
from pathlib import Path

from s1tools.common import configure

COMMANDS = {
    "art": {
        "inputs": ("art", "inputs_main"),
        "codec": ("art", "codec_main"),
        "convert": ("art", "convert_main"),
        "rings": ("art", "rings_main"),
        "shield": ("art", "shield_main"),
        "walls": ("art", "walls_main"),
    },
    "palettes": {
        "preview": ("palettes", "preview_main"),
        "water": ("palettes", "water_main"),
        "badniks": ("palettes", "badnik_main"),
        "objects": ("palettes", "object_main"),
        "bubbles": ("palettes", "bubbles_main"),
        "platform": ("palettes", "platform_main"),
        "seesaw": ("palettes", "seesaw_main"),
        "button": ("palettes", "button_main"),
        "searchlight": ("palettes", "searchlight_main"),
        "column": ("palettes", "column_main"),
        "audit": ("palettes", "audit_main"),
        "remap": ("palettes", "remap_main"),
    },
    "player": {
        "palette": ("shared_palette", "main"),
        "knuckles": ("knuckles", "main"),
        "tails": ("tails", "main"),
        "super": ("player", "super_main"),
        "figure8": ("player", "figure8_main"),
        "air": ("player", "air_main"),
    },
    "title": {
        "import": ("title", "import_main"),
        "compare": ("title", "compare_main"),
        "audit": ("title", "audit_main"),
        "prompt": ("title", "prompt_main"),
    },
    "levels": {
        "blocks": ("levels", "blocks_main"),
        "chunks": ("levels", "chunks_main"),
        "objects": ("levels", "objects_main"),
        "split-rings": ("levels", "rings_main"),
        "giant-rings": ("levels", "giant_main"),
        "gallery": ("levels", "gallery_main"),
    },
    "sonlvl": {"sync": ("sonlvl", "sync_main"), "roundtrip": ("sonlvl", "roundtrip_main")},
    "sprites": {"render": ("sprites", "main")},
    "tables": {"ring-loss": ("tables", "main")},
}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog="Commands: " + "; ".join(k + ": " + ", ".join(v) for k, v in COMMANDS.items()),
    )
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="Sonic 1 project directory")
    parser.add_argument(
        "--source", type=Path, help="input bundle directory containing s1/, s2/, cd/ and title.zip"
    )
    parser.add_argument(
        "--output", type=Path, help="copy the project to an empty directory before operating"
    )
    parser.add_argument("group", choices=COMMANDS)
    parser.add_argument("command")
    parser.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args(argv)
    if args.command not in COMMANDS[args.group]:
        parser.error("Unknown command. Choose: " + ", ".join(COMMANDS[args.group]))
    configure(args.root, args.source, args.output)
    module, name = COMMANDS[args.group][args.command]
    function = getattr(importlib.import_module("s1tools." + module), name)
    previous = sys.argv
    try:
        sys.argv = ["s1tools " + args.group + " " + args.command, *args.arguments]
        result = function(args.arguments) if inspect.signature(function).parameters else function()
        return result or 0
    finally:
        sys.argv = previous


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError) as error:
        print(f"Error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
