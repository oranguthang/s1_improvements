# ruff: noqa: F405, E402
"""Built-ROM companion regression checks; run through check_sidekick.py."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
from check_sidekick_collision import place, read, setup
from unicorn.m68k_const import *  # noqa: F403


def carry():
    for character in (0, 2):
        c, b, o = setup()
        p = c.s["v_player"]
        c.skip("Sonic_Floor")
        c.skip("Sonic_LevelBound")
        c.skip("Sonic_FindCeiling", lambda cpu: cpu.reg(UC_M68K_REG_D1, 16))
        c.w("v_character_p1", character)
        c.w("v_gamemode", 12)
        place(c, b, 300, 160, status=2)
        c.w("sk_ctx_flight", 1)
        c.w(c.s["sk_ctx_flight"] + 2, 480, 2)
        c.w(p + c.s["obRoutine"], 2)
        c.w(p + c.s["obX"], 300, 2)
        c.w(p + c.s["obY"], 188, 2)
        c.w(p + c.s["obStatus"], 6)
        c.w(p + c.s["obHeight"], 14)
        c.reg(UC_M68K_REG_A0, b)
        c.call("Sidekick_UpdateCarry")
        assert c.r("v_sidekick_carry")
        assert c.r(p + c.s["obAnim"]) == c.s["id_Carry"]
        assert c.r(p + c.s["obHeight"]) == 19
        c.reg(UC_M68K_REG_A0, p)
        c.w(b + c.s["obX"], 320, 2)
        c.w(b + c.s["obY"], 150, 2)
        c.call("Sidekick_CarriedMovement")
        assert (read(c, p, "obX"), read(c, p, "obY")) == (320, 179)
        c.w(b + c.s["obStatus"], 3)
        c.call("Sidekick_CarriedMovement")
        assert c.r(p + c.s["obStatus"]) & 1 and c.r(p + c.s["obRender"]) & 1
        c.w("v_sidekick_carrydelay", 0, 2)
        c.w("v_jpadpress2", c.s["btnC"])
        c.call("Sidekick_CarriedMovement")
        assert not c.r("v_sidekick_carry") and read(c, p, "obVelY") == 0xFA00
        assert c.r(p + c.s["obAnim"]) == c.s["id_Roll"]
        # Script locks must release a rider, including Knuckles.
        c.w("v_sidekick_carry", 255)
        c.w("f_playerctrl", 0x80)
        c.call("Sidekick_CarriedMovement")
        assert not c.r("v_sidekick_carry")
    # A level object pushing the rider must win over the next carry update.
    # Test head contact too: it must drop the rider instead of moving through.
    for head_contact in (False, True):
        c, b, _ = setup()
        p = c.s["v_player"]
        c.skip("Sonic_Floor")
        c.skip("Sonic_LevelBound")
        clearance = [16]
        c.skip(
            "Sonic_FindCeiling",
            lambda cpu, clearance=clearance: cpu.reg(UC_M68K_REG_D1, clearance[0] & 65535),
        )
        place(c, b, 300, 160, status=2)
        c.w("sk_ctx_flight", 1)
        c.w(c.s["sk_ctx_flight"] + 2, 480, 2)
        c.w(p + c.s["obRoutine"], 2)
        c.w(p + c.s["obX"], 300, 2)
        c.w(p + c.s["obY"], 188, 2)
        c.w(p + c.s["obStatus"], 2)
        c.reg(UC_M68K_REG_A0, b)
        c.call("Sidekick_UpdateCarry")
        assert c.r("v_sidekick_carry")
        c.reg(UC_M68K_REG_A0, p)
        if head_contact:
            clearance[0] = -3
        else:
            c.w(p + c.s["obX"], 308, 2)
        c.call("Sidekick_CarriedMovement")
        assert not c.r("v_sidekick_carry")
        if not head_contact:
            assert read(c, p, "obX") == 308
    print("Sonic/Knuckles catch, hanging, movement, jump release, script cancellation passed")


def water():
    c, b, o = setup()
    c.reg(UC_M68K_REG_A0, b)
    c.w("v_zone", c.s["id_LZ"])
    c.w("v_waterpos1", 150, 2)
    place(c, b, 300, 200, 0x400, status=2)
    c.w(b + c.s["obVelX"], 0x400, 2)
    c.call("Sidekick_SwapContext")
    c.call("Sidekick_Water")
    assert read(c, b, "obVelX") == 0x200 and read(c, b, "obVelY") == 0x100
    c.w("v_sidekick_manual", 600, 2)
    c.call("Sidekick_SpeedSettings")
    assert c.r("v_sonspeedmax", 2) == 0x300
    c.w("v_air", 1, 2)
    c.w("v_sidekick_airframes", 59, 2)
    c.call("Sidekick_Water")
    assert c.r("v_air", 2) == 0
    c.w("v_sidekick_airframes", 59, 2)
    c.call("Sidekick_Water")
    assert c.r("v_sidekick_state") == 4 and c.r(b + c.s["obAnim"]) == c.s["id_Drown"]
    c.call("Sidekick_SwapContext")
    assert c.r("v_air", 2) == 0 and c.r("sk_ctx_air", 2) == 0xFFFF
    # Bubble refills Tails only and preserves the leader's air and velocities.
    c.w("v_sidekick_state", 0)
    c.w(b + c.s["obStatus"], 0x42)
    c.w(b + c.s["obY"], 200, 2)
    c.w(o + c.s["obY"], 190, 2)
    c.w(o + c.s["bub_inhalable"], 1)
    c.w("sk_ctx_air", 2, 2)
    c.w("v_air", 5, 2)
    c.reg(UC_M68K_REG_A0, o)
    assert c.call("Sidekick_TryBubble")
    assert c.r("sk_ctx_air", 2) == 30 and c.r("v_air", 2) == 5
    assert c.r(b + c.s["obAnim"]) == c.s["id_GetAir"]
    # Dry manual speed returns after CPU catch-up.
    c.reg(UC_M68K_REG_A0, b)
    c.w(b + c.s["obStatus"], 2)
    c.w(b + c.s["obY"], 100, 2)
    c.call("Sidekick_SwapContext")
    c.call("Sidekick_Water")
    c.call("Sidekick_SpeedSettings")
    assert c.r("v_sonspeedmax", 2) == 0x600 and c.r("v_air", 2) == 30
    c.call("Sidekick_SwapContext")
    print("isolated water entry, speeds, air, drowning, bubble, dry manual restoration passed")


if __name__ == "__main__":
    carry()
    water()
