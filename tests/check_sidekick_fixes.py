"""Regressions for appended art, carry eligibility, fast following and SS spawns."""

from check_dust_and_music import c1
from check_sidekick_collision import place, setup
from s1tools.sidekick import SHARED, recolour
from unicorn.m68k_const import UC_M68K_REG_A0, UC_M68K_REG_D1, UC_M68K_REG_D2, UC_M68K_REG_D3


def player_art():
    c = c1()
    p = c.s["v_player"]
    c.reg(UC_M68K_REG_A0, p)
    c.w("v_gamemode", 12)
    c.w("v_character_p2", 1)
    transfers = []
    c.skip(
        "QueueDMATransfer",
        lambda cpu: transfers.append(
            (
                cpu.uc.reg_read(UC_M68K_REG_D1),
                cpu.uc.reg_read(UC_M68K_REG_D2),
                cpu.uc.reg_read(UC_M68K_REG_D3),
            )
        ),
    )
    total = 0
    for super_, table, source, frames in [
        (0, "SonicDynPLC", "Art_Sonic", range(c.s["fr_SonicCarry2"] + 1)),
        (1, "SuperSonicDynPLC", "Art_SuperSonic", range(c.s["fr_SuperAirPosesEnd"])),
    ]:
        c.w("v_supersonic", super_)
        for frame in frames:
            c.w("v_sonframenum", 255)
            c.w(p + c.s["obFrame"], frame)
            transfers.clear()
            c.call("Sonic_LoadGfx")
            offset = c.r(c.s[table] + frame * 2, 2)
            if offset & 0x8000:
                offset -= 0x10000
            cue = c.s[table] + offset
            count = c.r(cue)
            expected = []
            base = c.s[source]
            if super_ and c.s["fr_SuperSpringTwirl1"] <= frame < c.s["fr_SuperAirPosesEnd"]:
                base = c.s["Art_Sonic"]
            for i in range(count):
                entry = c.r(cue + 1 + i * 2, 2)
                n = (entry >> 12) + 1
                offset = entry & 4095
                expected.append(recolour(bytes(c.uc.mem_read(base + offset * 32, n * 32)), SHARED))
            assert len(transfers) == len(expected), (super_, frame)
            dest = c.s["ArtTile_Sonic"] * 32
            for (address, target, words), data in zip(transfers, expected, strict=True):
                assert target == dest and words * 2 == len(data), (
                    super_,
                    hex(frame),
                    hex(target),
                    hex(dest),
                    words,
                    len(data),
                )
                assert bytes(c.uc.mem_read(address, len(data))) == data, (
                    super_,
                    hex(frame),
                    hex(address),
                )
                assert address // 0x20000 == (address + len(data) - 1) // 0x20000
                dest += len(data)
            assert dest <= c.s["ArtTile_Sonic"] * 32 + 32 * 32
            total += 1
    print(
        f"{total} normal/Super DPLC frames match the original art, including spring/carry/Light Dash/figure-eight"
    )


def controls_and_carry():
    c, b, _ = setup()
    p = c.s["v_player"]
    c.w("v_gamemode", 12)
    c.w(p + c.s["obX"], 100, 2)
    place(c, b, 76, 200, status=0)
    c.w("v_jpadhold1", c.s["btnR"])
    c.w(c.s["v_tracksonic"] + 188, 76, 2)
    c.w(c.s["v_sidekick_history"] + 188, c.s["btnR"])
    c.reg(UC_M68K_REG_A0, b)
    c.call("Sidekick_ReadControls")
    assert c.r("sk_ctx_controls") & c.s["btnR"]
    c, b, _ = setup()
    p = c.s["v_player"]
    c.w("v_gamemode", 12)
    c.skip("Sonic_Floor")
    c.skip("Sonic_LevelBound")
    c.skip("Sonic_FindCeiling", lambda cpu: cpu.reg(UC_M68K_REG_D1, 16))
    place(c, b, 300, 160, status=2)
    c.w("sk_ctx_flight", 1)
    c.w(c.s["sk_ctx_flight"] + 2, 480, 2)
    c.w(p + c.s["obRoutine"], 2)
    c.w(p + c.s["obX"], 300, 2)
    c.w(p + c.s["obY"], 188, 2)
    c.w(p + c.s["obStatus"], 2)
    c.reg(UC_M68K_REG_A0, b)
    c.w("v_sidekick_returning", 255)
    c.call("Sidekick_UpdateCarry")
    assert not c.r("v_sidekick_carry")
    c.w("v_sidekick_returning", 0)
    c.call("Sidekick_UpdateCarry")
    assert c.r("v_sidekick_carry") and c.r(p + c.s["obAnim"]) == c.s["id_Carry"]
    print("delayed follow input; no respawn carry; dedicated carried animation passed")


def ss_spawn():
    for blocked in ("left", "both"):
        c = c1()
        c.uc.mem_map(0xFF0000, 0x10000)
        p = c.s["v_player"]
        b = c.s["v_sidekick_player"]
        c.w(p + c.s["obX"], 960, 2)
        c.w(p + c.s["obY"], 800, 2)

        def block(x, c=c):
            at = c.s["v_sslayout_base"] + ((800 + 68) // 24) * 128 + (x + 20) // 24
            # The neighbour's outside column is beyond the leader's sensors.
            c.w(at if x < 960 else at + 1, 1)

        block(936)
        if blocked == "both":
            block(984)
        c.reg(UC_M68K_REG_A0, b)
        c.call("Sidekick_SSPlace")
        assert c.r(b + c.s["obX"], 2) == (984 if blocked == "left" else 960)
        assert c.r(b + c.s["obY"], 2) == 800 and not c.r(b + c.s["sonss_touchedblock_id"])
    print("Special Stage adjacent/fallback spawn uses clear wall sensors")


def run():
    player_art()
    controls_and_carry()
    ss_spawn()
