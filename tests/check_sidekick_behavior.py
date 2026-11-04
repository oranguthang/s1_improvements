"""Companion timing, carry poses, swept SS collision and stage ownership."""

from check_sidekick_collision import setup
from unicorn.m68k_const import (
    UC_M68K_REG_A0,
    UC_M68K_REG_D1,
    UC_M68K_REG_D2,
    UC_M68K_REG_D3,
    UC_M68K_REG_D4,
    UC_M68K_REG_D6,
)


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


def special_projection():
    c, body, scratch = setup()
    c.w("v_gamemode", c.s["id_Special"])
    c.w("v_screenposx", 800, 2)
    c.w("v_screenposy", 700, 2)
    c.w(body + c.s["obID"], c.s["id_SidekickTails"])
    c.w(body + c.s["obRender"], c.s["sprite_cam_ss"] | c.s["sprite_rawmappings"])
    c.w(body + c.s["obMap"], scratch, 4)
    c.uc.mem_write(scratch, bytes(5))  # one opaque sprite piece at the object's origin
    c.w(body + c.s["obX"], 990, 2)
    c.w(body + c.s["obY"], 802, 2)
    sat = c.s["v_spritetablebuffer"]
    for angle, x, y in [(0, 318, 230), (0x4000, 298, 270), (0x8000, 258, 250), (0xC000, 278, 210)]:
        c.w("v_ssangle", angle, 2)
        c.reg(UC_M68K_REG_A0, body)
        c.call("DisplaySprite")
        c.call("BuildSprites")
        assert (c.r(sat + 6, 2), c.r(sat, 2)) == (x, y)
        assert (c.r(body + c.s["obX"], 2), c.r(body + c.s["obY"], 2)) == (990, 802)
    print(
        "SS sprite projection follows all four maze quadrants without changing physics coordinates"
    )


def edge_pose():
    c, _, _ = setup()
    p = c.s["v_player"]
    c.reg(UC_M68K_REG_A0, p)
    c.skip("ObjFloorDist", lambda cpu: cpu.reg(UC_M68K_REG_D1, 16))
    c.w(p + c.s["angleright"], 3)
    c.w(p + c.s["victorypose"], 1)
    c.call("Sonic_Move")
    assert not c.r(p + c.s["victorypose"]) and c.r(p + c.s["obAnim"]) == c.s["id_Balance"]
    c.call("Sonic_Animate")
    assert c.r(p + c.s["obFrame"]) == c.s["fr_Balance1"]
    c.w(p + c.s["victorypose"], 1)
    c.w(c.s["v_endcard"] + c.s["obID"], c.s["id_GotThroughCard"])
    c.call("Sonic_Move")
    assert c.r(p + c.s["obAnim"]) == c.s["id_Victory"]
    print(
        "The ledge uses balance frames even with a stale victory flag. Results retain the victory pose."
    )


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


def ring_destination():
    for current, expected in (
        ("id_GHZ_act1", "id_GHZ_act2"),
        ("id_GHZ_act2", "id_GHZ_act3"),
        ("id_MZ_act2", "id_MZ_act3"),
    ):
        c, _, _ = setup()
        c.skip("DisplaySprite")
        card = c.s["v_endcardring"]
        c.reg(UC_M68K_REG_A0, card)
        c.w(card + c.s["obRoutine"], 0xA)
        c.w("v_zone_act", c.s[current], 2)
        c.w("v_gamemode", c.s["id_Level"])
        c.w("f_bigring", 1)
        c.call("GotThroughCard")
        assert c.r("v_gamemode") == c.s["id_Special"]
        assert c.r("v_zone_act", 2) == c.s[expected]
        # Sidekick_RingFadeFrame temporarily runs objects in level mode.
        c.w("v_gamemode", c.s["id_Level"])
        c.call("GotThroughCard")
        assert c.r("v_zone_act", 2) == c.s[expected]
        assert c.r("v_gamemode") == c.s["id_Level"]
        assert c.r("f_restart", 2) == 0
    print("End ring chooses the next act once, even while the results card runs in the white fade")


def results_pose():
    c, b, _ = setup()
    c.w("v_gamemode", c.s["id_Level"])
    c.w("sk_ctx_character", c.s["Character_Tails"])
    c.w("v_player", c.s["id_SonicPlayer"])
    c.w(b + c.s["obGfx"], c.s["ArtTile_Sidekick"], 2)
    c.w(b + c.s["obStatus"], 2)
    c.w("v_sidekick_state", 3)  # still flying back when the leader finishes
    c.w("v_sidekick_returning", 255)
    c.w("v_sidekick_lastframe", 255)
    transfers = []
    c.skip(
        "QueueDMATransfer",
        lambda cpu: transfers.append(
            (cpu.uc.reg_read(UC_M68K_REG_D2), cpu.uc.reg_read(UC_M68K_REG_D3))
        ),
    )
    c.skip("DisplaySprite")
    c.call("Sidekick_FinishScene")
    assert c.r("v_sidekick_active") and c.r(b + c.s["victorypose"])
    assert not c.r("v_sidekick_state") and not c.r("v_sidekick_returning")
    assert c.r(b + c.s["obAnim"]) == c.s["id_Spring"]
    assert transfers
    c.w(b + c.s["obStatus"], 0)
    c.reg(UC_M68K_REG_A0, b)
    for _ in range(24):
        c.call("Sidekick_Victory")
    assert c.r(b + c.s["obFrame"]) == c.s["fr_TailsVictory"] + 1
    start = c.s["ArtTile_Sidekick"] * 32
    end = c.s["ArtTile_LevelBonuses"] * 32
    assert max(dest + words * 2 for dest, words in transfers) == end
    assert all(start <= dest and dest + words * 2 <= end for dest, words in transfers)
    print("Tails lands and poses in the 18 tiles below the act bonus digits")


def special_return():
    c, body, _ = setup()
    c.uc.mem_map(0xFF0000, 0x10000)
    c.skip("DisplaySprite")
    c.skip("QueueDMATransfer")
    c.w("v_gamemode", c.s["id_Special"])
    p = c.s["v_player"]
    c.w(p + c.s["obRoutine"], 2)
    c.w(p + c.s["obX"], 960, 2)
    c.w(p + c.s["obY"], 900, 2)
    c.w("v_screenposx", 800, 2)
    c.w("v_screenposy", 788, 2)
    c.w("v_ssangle", 0x4000, 2)
    base = c.s["v_sslayout_base"]
    # A solid area includes all adjacent candidates and the leader fallback.
    for row in range(39, 44):
        for col in range(38, 45):
            c.w(base + row * 128 + col, 1)
    c.reg(UC_M68K_REG_A0, body)
    c.call("Sidekick_SSStartReturn")
    for _ in range(50):
        c.call("Sidekick_SSReturn")
        assert c.r("v_sidekick_state") == c.s["sidekick_ss_return"]
    assert c.r(body + c.s["obFrame"]) == c.s["fr_TailsSSReturn"]
    for row in range(39, 44):
        for col in range(38, 45):
            c.w(base + row * 128 + col, 0)
    for _ in range(10):
        c.call("Sidekick_SSReturn")
        if not c.r("v_sidekick_state"):
            break
    assert c.r("v_sidekick_state") == 0
    assert c.r(body + c.s["obX"], 2) == 936 and c.r(body + c.s["obY"], 2) == 900
    assert c.r(body + c.s["obFrame"]) == c.s["fr_Roll1"]
    assert c.r(body + c.s["obRender"]) == c.s["sprite_cam_ss"]
    # A closing gate under the visible companion starts the flight in place.
    for row in range(39, 43):
        for col in range(39, 43):
            c.w(base + row * 128 + col, c.s["id_SS_RedWhite"])
    c.call("Sidekick_SSBegin")
    assert c.r("v_sidekick_state") == c.s["sidekick_ss_return"]
    assert c.r(body + c.s["obX"], 2) == 288
    assert c.r(body + c.s["obScreenY"], 2) == 216
    print("Special Stage returns visibly from a blocked spot and curls only on clear ground")


def run():
    following()
    poses()
    special()
    special_projection()
    special_return()
    edge_pose()
    fade()
    ring_destination()
    results_pose()


if __name__ == "__main__":
    run()
