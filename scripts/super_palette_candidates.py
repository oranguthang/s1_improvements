#!/usr/bin/env python3
"""Analyze line-0 sprite art that collides with Super Sonic's palette."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from nemesis_tool import decompress_bytes


ROOT = Path(__file__).resolve().parents[1]
SOURCE_INDICES = (2, 3, 4, 5)
SAFE_TARGET_ORDER = (12, 13, 14, 15, 10, 11, 8, 9, 7, 6)
MERGE_WARM_MAP = {2: 6, 3: 7, 4: 8, 5: 9}


ASSET_USERS = {
    "artnem/Signpost.nem": ["Signpost"],
    "artnem/Prison Capsule.nem": ["Prison Capsule"],
    "artnem/Lamppost.nem": ["Lamppost"],
    "artnem/Animal Rabbit.nem": ["Animal Rabbit"],
    "artnem/Animal Chicken.nem": ["Animal Chicken"],
    "artnem/Animal Penguin.nem": ["Animal Penguin"],
    "artnem/Animal Seal.nem": ["Animal Seal"],
    "artnem/Animal Pig.nem": ["Animal Pig"],
    "artnem/Animal Flicky.nem": ["Animal Flicky"],
    "artnem/Animal Squirrel.nem": ["Animal Squirrel"],
    "artnem/Enemy Crabmeat.nem": ["Crabmeat"],
    "artnem/Enemy Buzz Bomber.nem": ["Buzz Bomber"],
    "artnem/Enemy Chopper.nem": ["Chopper"],
    "artnem/Enemy Burrobot.nem": ["Burrobot"],
    "artnem/Enemy Motobug.nem": ["Moto Bug"],
    "artnem/Enemy Newtron.nem": ["Newtron (palette 0 variant)"],
    "artnem/Enemy Basaran.nem": ["Basaran"],
    "artnem/Enemy Roller.nem": ["Roller"],
    "artnem/Enemy Bomb.nem": ["Bomb"],
    "artnem/Enemy Orbinaut.nem": ["Orbinaut (LZ/SBZ variants)"],
    "artnem/LZ Gargoyle & Fireball.nem": ["LZ Gargoyle fire variant"],
    "artnem/SBZ Electrocuter.nem": ["Electrocuter"],
    "artnem/Spikes.nem": ["Spikes"],
    "artnem/Spring Horizontal.nem": ["Spring Horizontal"],
    "artnem/Spring Vertical.nem": ["Spring Vertical"],
    "artnem/SBZ Spinning Platform.nem": ["SBZ Spinning Platform"],
    "artnem/Boss - Main.nem": ["Eggman body"],
    "artnem/Boss - Weapons.nem": ["Eggman weapons / seat"],
    "artnem/Boss - Eggman in SBZ2 & FZ.nem": ["Eggman SBZ2/FZ body"],
    "artnem/Boss - Final Zone.nem": ["Final Zone boss"],
    "artnem/Boss - Eggman after FZ Fight.nem": ["Eggman after FZ fight"],
}


@dataclass
class Report:
    asset: str
    users: list[str]
    used_indices: list[int]
    source_indices: list[int]
    is_candidate: bool
    free_stable_indices: list[int]
    direct_map: dict[int, int]
    merge_warm_map: dict[int, int]
    merge_warm_collisions: list[int]


def decode_nemesis(path: Path) -> set[int]:
    data = decompress_bytes(path.read_bytes())
    used: set[int] = set()
    for byte in data:
        used.add((byte >> 4) & 0xF)
        used.add(byte & 0xF)
    return used


def build_report(asset: str, users: list[str]) -> Report:
    used = decode_nemesis(ROOT / asset)
    source_used = sorted(set(used) & set(SOURCE_INDICES))
    free_stable = [index for index in SAFE_TARGET_ORDER if index not in used]
    direct_map: dict[int, int] = {}
    if len(free_stable) >= len(source_used):
        direct_map = {
            src: dst for src, dst in zip(source_used, free_stable[: len(source_used)])
        }
    merge_warm_map = {src: MERGE_WARM_MAP[src] for src in source_used}
    merge_warm_collisions = sorted(set(merge_warm_map.values()) & used)
    return Report(
        asset=asset,
        users=users,
        used_indices=sorted(used),
        source_indices=source_used,
        is_candidate=bool(source_used),
        free_stable_indices=free_stable,
        direct_map=direct_map,
        merge_warm_map=merge_warm_map,
        merge_warm_collisions=merge_warm_collisions,
    )


def build_reports() -> list[Report]:
    return [build_report(asset, users) for asset, users in ASSET_USERS.items()]


def report_as_json(reports: list[Report]) -> str:
    return json.dumps([report.__dict__ for report in reports], indent=2)


def report_as_text(reports: list[Report]) -> str:
    lines = []
    for report in reports:
        lines.append(f"{report.asset}")
        lines.append(f"  users: {', '.join(report.users)}")
        lines.append(f"  used: {report.used_indices}")
        lines.append(f"  uses_2_5: {report.source_indices}")
        lines.append(f"  candidate: {'yes' if report.is_candidate else 'no'}")
        if report.direct_map:
            lines.append(f"  direct_map: {report.direct_map}")
        else:
            lines.append("  direct_map: none")
        lines.append(f"  merge_warm_map: {report.merge_warm_map}")
        if report.merge_warm_collisions:
            lines.append(f"  merge_warm_collisions: {report.merge_warm_collisions}")
        else:
            lines.append("  merge_warm_collisions: none")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="emit JSON instead of text")
    args = parser.parse_args(argv)

    reports = build_reports()
    if args.json:
        sys.stdout.write(report_as_json(reports))
        sys.stdout.write("\n")
    else:
        sys.stdout.write(report_as_text(reports))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))


