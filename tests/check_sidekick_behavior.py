"""Companion timing, carry poses, swept SS collision and stage ownership."""

from check_sidekick_collision import setup
from unicorn.m68k_const import UC_M68K_REG_A0, UC_M68K_REG_D4, UC_M68K_REG_D6


def following():
    c, b, _ = setup()
    c.reg(UC_M68K_REG_A0, b)
    c.w("v_gamemode", c.s["id_Level"])
    c.w(b + c.s["obX"], 100, 2)
    for i in range(64):
        c.w(c.s["v_tracksonic"] + i * 4, 100, 2)
    for frame in range(20):
        c.w("v_jpadhold2", c.s["btnR"] | c.s["btnUp"])
        c.call("Sidekick_RecordInput")
        c.w("v_trackpos", ((frame + 1) * 4) & 255, 2)
        c.call("Sidekick_ReadControls")
        assert c.r("sk_ctx_controls") == (0 if frame < 16 else c.s["btnR"] | c.s["btnUp"])
    c.w("v_gamemode", c.s["id_Special"])
    c.call("Sidekick_ReadControls")
    assert c.r("sk_ctx_controls") == c.s["btnR"]
    c.w("v_jpadhold_p2", c.s["btnL"] | c.s["btnDn"])
    c.w("v_jpadpress_p2", c.s["btnL"] | c.s["btnDn"])
    c.call("Sidekick_ReadControls")
    assert c.r("sk_ctx_controls") == c.r(c.s["sk_ctx_controls"] + 1) == c.s["btnL"]
    print("S2 16-frame input delay; Special Stage ignores Up/Down on both pads")


def poses():
    c, b, _ = setup()
    c.reg(UC_M68K_REG_A0, b)
    c.w("v_character_p1", c.s["Character_Tails"])
    c.w("v_tails_flying", 1)
    c.w("v_tails_flytime", 480, 2)
    c.w(b + c.s["obStatus"], 2)
    for carry in (0, 255):
        for rising in (False, True):
            c.w("v_sidekick_carry", carry)
            c.w("v_tails_flap", 30 if rising else 0)
            c.w(b + c.s["obVelY"], -256 if rising else 256, 2)
            c.call("Tails_FlightPose")
            expected = c.s["fr_TailsCarryUp" if rising else "fr_TailsCarry"] if carry else 0x75
            assert c.r(b + c.s["obFrame"]) == expected
    c.reg(UC_M68K_REG_A0, c.s["v_player"])
    c.w(c.s["v_player"] + c.s["obRoutine"], 2)
    c.w(c.s["v_player"] + c.s["obStatus"], 2)
    c.call("Tails_FlightPose")
    assert c.r(c.s["v_player"] + c.s["obFrame"]) == 0x75
    c.reg(UC_M68K_REG_A0, b)
    c.w("v_character_p1", 0)
    c.w("sk_ctx_character", c.s["Character_Tails"])
    c.w("v_lightdash", 1)
    c.w("sk_ctx_flight", 1)
    c.w(c.s["sk_ctx_flight"] + 2, 480, 2)
    c.call("Sidekick_SwapEffectContext")
    c.call("Tails_FlightPose")
    c.call("Sidekick_SwapEffectContext")
    assert c.r("v_lightdash") == 1 and c.r("sk_ctx_flight") == 1
    print("free/ascent/carry poses are distinct; leader Light Dash preserves companion flight")


def special():
    c, b, _ = setup()
    c.uc.mem_map(0xFF0000, 0x10000)
    c.reg(UC_M68K_REG_A0, b)
    c.w(b + c.s["obX"], 960, 2)
    c.w(b + c.s["obY"], 800, 2)
    base = c.s["v_sslayout_base"]
    cell = base + ((800 + 80) // 24) * 128 + (960 + 32) // 24
    # Actual native action dispatch, not a mock of the shared item routine.
    for block in ("GOAL", "UP", "DOWN", "R"):
        c.w(b + c.s["sonss_touchedblock_id"], c.s["id_SS_" + block])
        c.w("v_ssrotate", 64, 2)
        c.call("Sidekick_SSItems")
        assert c.r(b + c.s["obRoutine"]) == 2
        assert c.r("v_ssrotate", 2) == 64 and c.r("v_sidekick_state") == 0
    c.w(cell, c.s["id_SS_Ring"])
    c.w(b + c.s["sonss_touchedblock_id"], 0)
    c.call("Sidekick_SSItems")
    assert c.r("v_rings", 2) == 1
    c.w(cell, c.s["id_SS_Emerald1_Blue"])
    c.call("Sidekick_SSItems")
    assert c.r("v_emeralds") == 1
    c.w(cell, c.s["id_SS_Ghost"])
    c.call("Sidekick_SSItems")
    assert c.r(b + c.s["sonss_ghoststate"]) == 0
    c.w(cell, c.s["id_SS_InvGhostTrigger"])
    c.w(b + c.s["sonss_ghoststate"], 1)
    c.call("Sidekick_SSItems")
    assert c.r(b + c.s["sonss_ghoststate"]) == 0
    c.w(cell, c.s["id_SS_Ghost"])
    c.w(b + c.s["sonss_ghoststate"], 2)
    c.call("SonicSS_MakeGhostSolid")
    assert c.r(cell) == c.s["id_SS_Ghost"]
    # A single tile wall lies BETWEEN a clear old position and clear endpoint.
    c.w(cell, 0)
    for row in range(30, 45):
        c.w(base + row * 128 + 43, 1)
    c.w("v_sidekick_ss_oldx", 980 << 16, 4)
    c.w("v_sidekick_ss_oldy", 800 << 16, 4)
    c.w(b + c.s["obX"], 1060 << 16, 4)
    c.w(b + c.s["obY"], 800 << 16, 4)
    c.call("Sidekick_SSCommit")
    assert 980 <= c.r(b + c.s["obX"], 2) < 1012
    c.w("v_sidekick_ss_impulse", 255)
    c.w("v_sidekick_ss_oldx", 1008 << 16, 4)
    c.w(b + c.s["obX"], 1015 << 16, 4)
    c.call("Sidekick_SSCommit")
    assert c.r(b + c.s["obX"], 2) == 1008
    print("SS ownership, collectibles, ghost gates, fast wall sweeps and small bumper kicks passed")


def fade():
    c, _, _ = setup()
    observed = []
    c.skip("ExecuteObjects", lambda cpu: observed.append(cpu.r("v_gamemode")))
    c.skip("BuildSprites")
    c.w("v_sidekick_ring_entry", 255)
    c.w("v_gamemode", c.s["id_Special"])
    c.reg(UC_M68K_REG_D4, 7)
    c.reg(UC_M68K_REG_D6, 1)
    c.call("Sidekick_RingFadeFrame")
    assert observed == [c.s["id_Level"]] and c.r("v_gamemode") == c.s["id_Special"]
    assert c.uc.reg_read(UC_M68K_REG_D4) == 7 and c.uc.reg_read(UC_M68K_REG_D6) == 1
    assert c.r("v_framecount", 2) == 1
    print("giant-ring fade advances actors and preserves the fade counters/mode")


def run():
    following()
    poses()
    special()
    fade()


if __name__ == "__main__":
    run()
