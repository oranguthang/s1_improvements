# ruff: noqa: F405, E402
"""Built-ROM companion regression checks; run through check_sidekick.py."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
import sys

sys.path.insert(0, str(ROOT / "tests"))
sys.path.insert(0, str(ROOT / "tools"))
from check_dust_and_music import c1
from s1tools.codecs.kosinski import decode_moduled
from s1tools.sidekick import SHARED, recolour, source_labels
from unicorn.m68k_const import *  # noqa: F403


def context():
    c = c1()
    a = c.s["Sidekick_ContextFields"]
    fields = []
    while c.r(a, 2):
        src = c.r(a, 2) | 0xFFFF0000
        dst = c.r(a + 2, 2) | 0xFFFF0000
        n = c.r(a + 4, 2) + 1
        a += 6
        if n > 1:
            assert not (src | dst) & 1
        first = bytes((i * 11 + len(fields) + 30) & 255 for i in range(n))
        second = bytes((i * 7 + len(fields) + 170) & 255 for i in range(n))
        c.uc.mem_write(src, first)
        c.uc.mem_write(dst, second)
        fields.append((src, dst, first, second))
    regs = [
        UC_M68K_REG_D0,
        UC_M68K_REG_D1,
        UC_M68K_REG_D2,
        UC_M68K_REG_D3,
        UC_M68K_REG_D4,
        UC_M68K_REG_D5,
        UC_M68K_REG_D6,
        UC_M68K_REG_D7,
        UC_M68K_REG_A0,
        UC_M68K_REG_A1,
        UC_M68K_REG_A2,
        UC_M68K_REG_A3,
        UC_M68K_REG_A4,
        UC_M68K_REG_A5,
        UC_M68K_REG_A6,
    ]
    for i, r in enumerate(regs):
        c.reg(r, 0x12340000 + i)
    before = [c.uc.reg_read(r) for r in regs]
    c.call("Sidekick_SwapContext")
    for src, dst, first, second in fields:
        assert bytes(c.uc.mem_read(src, len(first))) == second
        assert bytes(c.uc.mem_read(dst, len(first))) == first
    assert [c.uc.reg_read(r) for r in regs] == before
    c.call("Sidekick_SwapContext")
    for src, dst, first, second in fields:
        assert bytes(c.uc.mem_read(src, len(first))) == first
        assert bytes(c.uc.mem_read(dst, len(first))) == second
    assert not c.r("v_sidekick_incontext")
    c.call("Sidekick_SwapEffectContext")
    c.call("Sidekick_SwapEffectContext")
    for src, dst, first, second in fields:
        assert bytes(c.uc.mem_read(src, len(first))) == first
        assert bytes(c.uc.mem_read(dst, len(first))) == second
    print(
        "aligned context round trips, all register preservation and lightweight effects context passed"
    )


def palettes():
    c = c1()
    c.w("v_gamemode", 12)
    c.w("v_character_p2", 1)
    labels = source_labels(ROOT)
    by_addr = {
        c.s[label]: path for path, names in labels.items() for label in names if label in c.s
    }
    for label, path, ranges in [
        ("KosM_Eggman", "artkosm/Boss - Main.kosm", [(0, 16), (45, 108)]),
        ("KosM_Weapons", "artkosm/Boss - Weapons.kosm", [(0, 6)]),
    ]:
        original = decode_moduled((ROOT / path).read_bytes())
        c.reg(UC_M68K_REG_A0, c.s[label])
        c.call("Sidekick_RemapPLC")
        target = c.uc.reg_read(UC_M68K_REG_A0)
        actual = decode_moduled((ROOT / by_addr[target]).read_bytes())
        expected = bytearray(original)
        for lo, hi in ranges:
            expected[lo * 32 : hi * 32] = recolour(original[lo * 32 : hi * 32], SHARED)
        assert actual == expected, (label, by_addr[target])
    for p2 in (1, 255):
        c.w("v_character_p2", p2)
        for label, path, ranges in (
            ("KosM_Lamp", "artkosm/Lamppost.kosm", ((0, 2), (6, 10))),
            ("KosM_LzWheel", "artkosm/LZ Wheel.kosm", ((0, 64),)),
        ):
            c.reg(UC_M68K_REG_A0, c.s[label])
            c.call("Sidekick_RemapPLC")
            assert c.uc.reg_read(UC_M68K_REG_A0) == c.s[label]
            art = decode_moduled((ROOT / path).read_bytes())
            for lo, hi in ranges:
                tiles = art[lo * 32 : hi * 32]
                assert recolour(tiles, SHARED) == tiles
    c.w("v_character_p2", 1)
    for label in ["KosM_Swing", "KosM_MzSwitch"]:
        c.reg(UC_M68K_REG_A0, c.s[label])
        c.call("Sidekick_RemapPLC")
        assert c.uc.reg_read(UC_M68K_REG_A0) == c.s[label]
    orig = decode_moduled((ROOT / "artkosm/8x8 - SYZ.kosm").read_bytes())
    new = decode_moduled((ROOT / "artkosm/sidekick/8x8 - SYZ Paired.kosm").read_bytes())
    before = (ROOT / "map16/SYZ.bin").read_bytes()
    after = (ROOT / "map16/sidekick/SYZ.bin").read_bytes()
    assert new[: len(orig)] == orig
    for tile in (0x34, 0x43):
        light = orig[tile * 32 : (tile + 1) * 32]
        assert recolour(light, SHARED) == light
    for i in range(0, len(before), 2):
        a = int.from_bytes(before[i : i + 2], "big")
        b = int.from_bytes(after[i : i + 2], "big")
        assert a & 0xF800 == b & 0xF800
        t = a & 2047
        u = b & 2047
        if t >= len(orig) // 32:
            assert a == b
            continue
        source = orig[t * 32 : (t + 1) * 32]
        expected = recolour(source, SHARED) if (a >> 13 & 3) == 0 else source
        assert new[u * 32 : (u + 1) * 32] == expected, ("SYZ tile", i, t, u, a >> 13 & 3)
    c.w("v_zone", 4)
    c.w("v_rom_blocks", c.s["Blk16_SYZ"], 4)
    c.call("Sidekick_LevelData")
    assert c.r("v_rom_blocks", 4) == c.s["Blk16_SidekickSYZ"]
    c.reg(UC_M68K_REG_A1, c.s["Unc_TitleCard"] + 64)
    c.reg(UC_M68K_REG_D1, 123)
    c.call("Sidekick_RemapRawA1")
    assert c.uc.reg_read(UC_M68K_REG_D1) == 123
    target = c.uc.reg_read(UC_M68K_REG_A1)
    assert bytes(c.uc.mem_read(target, 32)) == recolour(
        bytes(c.uc.mem_read(c.s["Unc_TitleCard"] + 64, 32)), SHARED
    )
    for name in ["Sonic", "Super Sonic", "Knuckles", "Super Knuckles"]:
        pal = (ROOT / f"palette/Sidekick - {name}.bin").read_bytes()
        tails = (ROOT / "palette/Tails.bin").read_bytes()
        assert pal[16:18] == tails[8:10] and pal[28:30] == tails[10:12]
        assert pal[14:16] == (ROOT / "palette/Sonic.bin").read_bytes()[14:16]
    print(
        "mixed-palette boss/weapon/wheel masks, SYZ dual-palette tiles, separate chains, raw title cards, stable companion palette passed"
    )


if __name__ == "__main__":
    context()
    palettes()
