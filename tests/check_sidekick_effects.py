# ruff: noqa: F405, E402
"""Built-ROM companion regression checks; run through check_sidekick.py."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
import sys

sys.path.insert(0, str(ROOT / "tests"))
sys.path.insert(0, str(ROOT / "tools"))
from check_dust_and_music import c1
from s1tools.codecs.kosinski import decode_moduled
from s1tools.sidekick import SHARED, recolour


def raster(c, label, frame, base, art):
    table = c.s[label]
    off = c.r(table + frame * 2, 2)
    if off & 0x8000:
        off -= 65536
    ptr = table + off
    pixels = {}
    for i in range(c.r(ptr)):
        at = ptr + 1 + 5 * i
        y = c.r(at)
        y = y - 256 if y & 128 else y
        x = c.r(at + 4)
        x = x - 256 if x & 128 else x
        shape = c.r(at + 1)
        w = (shape >> 2 & 3) + 1
        h = (shape & 3) + 1
        attr = (c.r(at + 2, 2) + base) & 65535
        for yy in range(h * 8):
            for xx in range(w * 8):
                sx = w * 8 - 1 - xx if attr & 0x800 else xx
                sy = h * 8 - 1 - yy if attr & 0x1000 else yy
                tile = (attr & 0x7FF) + (sx // 8) * h + sy // 8
                b = art[tile][(sy % 8) * 4 + (sx % 8) // 2]
                p = b & 15 if sx & 1 else b >> 4
                if p:
                    pixels[x + xx, y + yy] = (attr >> 13 & 3, p)
    return pixels


def run():
    c = c1()
    starraw = (ROOT / "artunc/Invincibility Stars S2.unc").read_bytes()
    original = {0x55E + i: recolour(starraw[i * 32 : i * 32 + 32], SHARED) for i in range(34)}
    packed = {}
    a = c.s["Sidekick_StarsDMAs"]
    occupied = set()
    for _ in range(3):
        offset = c.r(a, 2)
        dest = c.r(a + 2, 2) // 32
        n = c.r(a + 4, 2) // 16
        a += 6
        for j in range(n):
            packed[dest + j] = bytes(c.uc.mem_read(c.s["Art_SidekickStars"] + offset + j * 32, 32))
            occupied.add(dest + j)
    assert len(occupied) == 24
    for lo, hi in [(0x553, 0x55A), (0x55E, 0x57E), (0x580, 0x600), (0x680, 0x700)]:
        assert not occupied.intersection(range(lo, hi))
    for frame in range(9):
        before = raster(c, "Map_InvStarsS2", frame, 0x55E, original)
        after = raster(c, "Map_InvStarsS2_Paired", frame, 0, packed)
        assert before == after, ("star pixels", frame, len(before), len(after))
    raw = decode_moduled((ROOT / "artkosm/Points.kosm").read_bytes())
    compact = decode_moduled((ROOT / "artkosm/sidekick/Points Compact.kosm").read_bytes())
    assert len(compact) == 7 * 32
    before = {0x553 + i: raw[i * 32 : i * 32 + 32] for i in range(9)}
    after = {0x553 + i: compact[i * 32 : i * 32 + 32] for i in range(7)}
    for frame in range(7):
        assert raster(c, "Map_Points", frame, 0x2553, before) == raster(
            c, "Map_Points_Paired", frame, 0x2553, after
        ), ("points", frame)
    print(
        "9 star frames and 7 point captions: identical visible pixels; disjoint body/points/explosions/HUD VRAM"
    )


if __name__ == "__main__":
    run()
