# ruff: noqa: F405, E402
"""Built-ROM companion regression checks; run through check_sidekick.py."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
from check_sidekick_collision import place, read, setup
from unicorn.m68k_const import *  # noqa: F403


def run():
    c, b, o = setup()
    p = c.s["v_player"]
    c.w("v_zone", 1)
    c.w("v_act", 0)
    place(c, b, 0xB20, 0x340, status=0x42)
    c.reg(UC_M68K_REG_A0, b)
    c.call("Sidekick_SwapContext")
    c.call("Sidekick_LZGimmicks")
    assert c.r("f_wtunnelmode") and read(c, b, "obX") == 0xB24
    c.call("Sidekick_SwapContext")
    assert not c.r("f_wtunnelmode") and c.r("sk_ctx_tunnel")
    assert c.r(p + c.s["obX"], 2) == 0
    # Exact slide chunk, own speed/animation and leader state preserved.
    c, b, o = setup()
    place(c, b, 0x200, 0x200, status=0)
    c.w("v_zone", 1)
    c.w(c.s["v_lvllayout_fg"] + 0x102, 2)
    c.reg(UC_M68K_REG_A0, b)
    c.call("Sidekick_SwapContext")
    c.call("LZWaterSlides")
    assert c.r("f_slidemode") and c.r(b + c.s["obAnim"]) == c.s["id_Slide"]
    c.call("Sidekick_SwapContext")
    assert not c.r("f_slidemode") and c.r("sk_ctx_slide")
    # Conveyor moves buddy only; native pass owns leader.
    c, b, o = setup()
    place(c, b, 300, 190, status=0)
    c.w(o + c.s["conv_width"], 56)
    c.w(o + c.s["conv_speed"], 0xFFFE, 2)
    c.reg(UC_M68K_REG_A0, o)
    c.call("Sidekick_Conveyor")
    assert read(c, b, "obX") == 298 and c.r(p + c.s["obX"], 2) == 0
    # P2 bumper never queues a hit for P1.
    c, b, o = setup()
    place(c, b, 280, 200, status=2)
    c.w("v_character_p1", 1)
    c.skip("FindFreeObj", lambda cpu: cpu.reg(UC_M68K_REG_SR, 0x2700))
    c.skip("AddPoints")
    c.reg(UC_M68K_REG_A0, b)
    c.reg(UC_M68K_REG_A1, o)
    leader = bytes(c.uc.mem_read(p, 64))
    c.call("Sidekick_Bumper")
    assert read(c, b, "obVelX") & 0x8000 and bytes(c.uc.mem_read(p, 64)) == leader
    assert c.r(o + c.s["obColProp"]) == 0 and c.r(o + c.s["obAnim"]) == 1
    # Own pole grip, input/release, finite break and P1's grabbed pole safe.
    for shared in (False, True):
        c, b, o = setup()
        place(c, b, 325, 200, status=2)
        c.w(o, c.s["id_Pole"])
        c.w(o + c.s["obRoutine"], 2)
        c.w(o + c.s["obSubtype"], 1)
        c.reg(UC_M68K_REG_A0, b)
        c.reg(UC_M68K_REG_A1, o)
        c.call("Sidekick_GrabPole")
        assert c.r("v_sidekick_pole", 2) == o & 65535
        c.w("v_jpadhold2", c.s["btnUp"])
        c.call("Sidekick_PoleMove")
        assert read(c, b, "obX") == 320 and read(c, b, "obY") == 199
        c.w("v_sidekick_poletimer", 1, 2)
        c.w(o + c.s["pole_grabbed"], int(shared))
        c.call("Sidekick_PoleMove")
        assert not c.r("v_sidekick_pole", 2)
        if shared:
            assert c.r(o + c.s["pole_breaktime"], 2) == 1 and c.r(o + c.s["obRoutine"]) == 2
        else:
            assert c.r(o + c.s["obRoutine"]) == 4 and not c.r(o + c.s["obColType"])
        assert not c.r("f_playerctrl")
    # Normal bubble wrapper sees buddy's air, restores P1 and keeps d7.
    c, b, o = setup()
    c.w("v_air", 30, 2)
    c.w("sk_ctx_air", 7, 2)
    c.w(o + c.s["obRoutine"], 12)
    c.w(o + c.s["drown_numtime"], 15, 2)
    c.w(o + c.s["obRender"], 0x80)
    c.skip("AnimateSprite")
    c.skip("DisplaySprite")
    c.reg(UC_M68K_REG_A0, o)
    c.reg(UC_M68K_REG_D7, 0x12345678)
    c.call("SidekickAirBubble")
    assert c.r("v_air", 2) == 30 and c.r(o + c.s["drown_numtime"], 2) == 14
    assert c.uc.reg_read(UC_M68K_REG_D7) == 0x12345678
    print("independent currents/slides/conveyors/bumpers/poles and air-number context passed")


if __name__ == "__main__":
    run()
