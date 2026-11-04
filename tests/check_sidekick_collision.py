# ruff: noqa: F405, E402
"""Built-ROM companion regression checks; run through check_sidekick.py."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
import sys

sys.path.insert(0, str(ROOT / "tests"))
from check_dust_and_music import c1
from unicorn.m68k_const import *  # noqa: F403


def setup():
    c = c1()
    c.skip("QueueSound2")
    b = c.s["v_sidekick_player"]
    o = c.s["v_lvlobjspace"]
    c.w("v_sidekick_active", 255)
    c.w(b + c.s["obRoutine"], 2)
    c.w(b + c.s["obHeight"], 19)
    c.w(b + c.s["obWidth"], 9)
    c.w(o + c.s["obID"], 0x18)
    c.w(o + c.s["obX"], 300, 2)
    c.w(o + c.s["obY"], 200, 2)
    c.w(o + c.s["obActWid"], 32)
    c.w(o + c.s["obRender"], 0x84)
    c.reg(UC_M68K_REG_A0, o)
    c.reg(UC_M68K_REG_D1, 32)
    c.reg(UC_M68K_REG_D2, 16)
    c.reg(UC_M68K_REG_D3, 16)
    c.reg(UC_M68K_REG_D4, 300)
    return c, b, o


def place(c, b, x, y, vy=0, prior=None, status=2):
    for name, value in [("obX", x), ("obY", y), ("obVelY", vy)]:
        c.w(b + c.s[name], value, 2)
    c.w(b + c.s["obStatus"], status)
    c.w("v_sidekick_prev_y", y if prior is None else prior, 2)


def read(c, b, name):
    return c.r(b + c.s[name], 2)


def run():
    # Landing, undersides and side walls. Whole native API survives the pass.
    c, b, o = setup()
    place(c, b, 300, 167, 0x300, prior=158)
    regs = [UC_M68K_REG_D0 + i for i in range(8)]
    # Register constants are contiguous, but use explicit address regs.
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
    before = [c.uc.reg_read(r) for r in regs]
    leader = c.uc.mem_read(c.s["v_player"], 64)
    c.w(o + c.s["obStatus"], 0x12)
    c.w(o + c.s["obSolid"], 0x35)
    c.call("Sidekick_Solid")
    assert read(c, b, "obY") == 164, read(c, b, "obY")
    assert read(c, b, "obVelY") == 0
    assert c.r("v_sidekick_platform", 2) == o & 0xFFFF
    assert c.r(b + c.s["obStatus"]) & 8
    assert c.r(o + c.s["obStatus"]) == 0x12 and c.r(o + c.s["obSolid"]) == 0x35
    assert c.uc.mem_read(c.s["v_player"], 64) == leader
    assert [c.uc.reg_read(r) for r in regs] == before
    c, b, o = setup()
    place(c, b, 300, 230, -0x300, prior=242)
    c.call("Sidekick_Solid")
    assert read(c, b, "obY") == 235
    assert read(c, b, "obVelY") == 0
    c, b, o = setup()
    place(c, b, 275, 200)
    c.w(b + c.s["obVelX"], 0x200, 2)
    c.call("Sidekick_Solid")
    assert read(c, b, "obX") == 268
    assert read(c, b, "obVelX") == 0
    # One-way platforms never catch a rising character from below.
    c, b, o = setup()
    place(c, b, 300, 190, -0x300, prior=210)
    c.call("Sidekick_Platform")
    assert c.r("v_sidekick_platform", 2) == 0
    c, b, o = setup()
    place(c, b, 300, 174, 0x300, prior=164)
    c.call("Sidekick_Platform")
    assert read(c, b, "obY") == 172
    # Movement recorded after the body ran must be carried once next frame.
    c.w(o + c.s["obX"], 308, 2)
    c.w(o + c.s["obY"], 204, 2)
    c.reg(UC_M68K_REG_A0, b)
    c.call("Sidekick_PlatformBegin")
    assert (read(c, b, "obX"), read(c, b, "obY")) == (308, 176)
    # Recycled slots and missed contacts detach, leaving P1 flags intact.
    c.w(o + c.s["obID"], 0x99)
    c.call("Sidekick_PlatformBegin")
    assert not c.r(b + c.s["obStatus"]) & 8 and c.r("v_sidekick_platform", 2) == 0
    # Three spring orientations use isolated launch state.
    for subtype, x, y, prior, vy, expected_x, expected_y in [
        (0, 300, 176, 158, 0x300, 0, -0x1000),
        (0x10, 310, 200, 200, 0, 0x1000, 0),
        (0x20, 300, 230, 242, -0x300, 0, 0x1000),
    ]:
        c, b, o = setup()
        c.w(o + c.s["obID"], c.s["id_Springs"])
        c.w(o + c.s["obSubtype"], subtype)
        c.w(o + c.s["spring_pow"], -0x1000, 2)
        if subtype == 0x10:
            c.reg(UC_M68K_REG_D1, 17)
        place(c, b, x, y, vy, prior=prior)
        c.call("Sidekick_Solid")
        assert read(c, b, "obVelX") == expected_x & 0xFFFF, (subtype, read(c, b, "obVelX"))
        assert read(c, b, "obVelY") == expected_y & 0xFFFF, (subtype, read(c, b, "obVelY"))
        assert c.r("v_sidekick_spring_delay") == 10
        c.w(o + c.s["obRoutine"], {0: 2, 0x10: 8, 0x20: 14}[subtype])
        c.call("Sidekick_SpringAnimation")
        assert c.r(o + c.s["obRoutine"]) == {0: 4, 0x10: 10, 0x20: 16}[subtype]
        c.call("Sidekick_SpringAnimation")
        assert c.r(o + c.s["obRoutine"]) == {0: 4, 0x10: 10, 0x20: 16}[subtype]
    print("isolated platform/top/side/underside, ABI, slot recycling, 3 spring directions passed")


if __name__ == "__main__":
    run()
