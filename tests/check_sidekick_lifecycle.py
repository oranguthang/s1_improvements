"""Context, object-loop ownership, debug art and SRAM lifetime regressions."""

from check_dust_and_music import c1
from unicorn.m68k_const import UC_M68K_REG_D7


def run():
    c = c1()
    c.skip("Sidekick_Run", lambda cpu: cpu.reg(UC_M68K_REG_D7, 0xDEADBEEF))
    c.reg(UC_M68K_REG_D7, 23)
    c.call("SidekickTails")
    assert c.uc.reg_read(UC_M68K_REG_D7) == 23
    assert c.s["v_sidekick_ram"] >= 0xFFFF8400
    assert c.s["v_sidekick_ram_end"] <= 0xFFFF9400
    for label in (
        "Art_SidekickTails",
        "Art_SidekickTailsTail",
        "Art_SidekickStars",
        "Art_SidekickDebugFont",
    ):
        assert c.s[label] // 0x20000 == (c.s[label + "_End"] - 1) // 0x20000, label

    for selected in (3, 4):
        c = c1()
        c.call("Settings_Defaults")
        c.w("v_character_selected", selected)
        c.call("Settings_Save")
        c.w("v_character_selected", 0)
        c.call("Settings_Load")
        assert c.r("v_character_selected") == selected
    c = c1()
    c.w("v_gamemode", 12)
    c.w("v_character_p2", 1)
    c.w("v_sidekick_active", 255)
    c.w("v_sidekick_debug_ready", 255)
    c.w("v_screenposx", 0x1234, 2)
    c.w("v_screenposy", 0x5678, 2)
    c.w(c.s["v_player"] + c.s["obX"], 0x9ABC, 2)
    c.w(c.s["v_player"] + c.s["obY"], 0xDEF0, 2)
    c.call("Sidekick_DebugMap")
    base = c.s["v_sidekick_debugmap"]
    glyphs = [c.r(base + 5 + i * 5, 2) & 2047 for i in range(16)]
    assert glyphs == [0x541 + n for n in [1, 2, 3, 4, 9, 10, 11, 12, 5, 6, 7, 8, 13, 14, 15, 0]]
    assert c.r(base, 2) == 2 and c.r(base + 2) == 21
    c.w("v_sidekick_carry", 255)
    c.w("v_sidekick_assist", 180)
    b = c.s["v_sidekick_player"]
    c.w(b + c.s["flashtime"], 1, 2)
    from unicorn.m68k_const import UC_M68K_REG_A0

    c.reg(UC_M68K_REG_A0, b)
    c.call("Sidekick_Hurt")
    assert c.r("v_sidekick_carry") and c.r("v_sidekick_assist") == 180
    # P2 gets normal damage/drowning feedback without touching P1 rings/lives.
    from unicorn.m68k_const import UC_M68K_REG_A2, UC_M68K_REG_D0

    for target, sound in [(None, "sfx_Death"), ("id_Spikes", "sfx_HitSpikes")]:
        c = c1()
        b = c.s["v_sidekick_player"]
        o = c.s["v_lvlobjspace"]
        sounds = []
        c.skip(
            "QueueSound2", lambda cpu, sounds=sounds: sounds.append(cpu.uc.reg_read(UC_M68K_REG_D0))
        )
        c.reg(UC_M68K_REG_A0, b)
        c.reg(UC_M68K_REG_A2, o)
        c.w(o, c.s[target] if target else 0x40)
        c.w("v_rings", 42, 2)
        c.w("v_lives", 3)
        c.call("Sidekick_Hurt")
        assert sounds == [c.s[sound]]
        c.call("Sidekick_Hurt")
        assert sounds == [c.s[sound]]
        assert c.r("v_rings", 2) == 42 and c.r("v_lives") == 3
    c = c1()
    b = c.s["v_sidekick_player"]
    sounds = []
    c.skip("QueueSound2", lambda cpu: sounds.append(cpu.uc.reg_read(UC_M68K_REG_D0)))
    c.reg(UC_M68K_REG_A0, b)
    c.w(b + c.s["obY"], 200, 2)
    c.w(b + c.s["obStatus"], 0x42)
    c.w("v_zone", c.s["id_LZ"])
    c.w("v_waterpos1", 150, 2)
    c.w("v_air", 0, 2)
    c.w("v_sidekick_airframes", 59, 2)
    c.call("Sidekick_Water")
    assert sounds == [c.s["sfx_Drown"]]
    print(
        "object loop counter, RAM bounds, paired SRAM, debug glyphs and invulnerability lifetime passed"
    )
