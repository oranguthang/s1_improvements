# ruff: noqa: F405, E402
"""Built-ROM companion regression checks; run through check_sidekick.py."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
import sys

from check_sidekick_effects import raster

sys.path.insert(0, str(ROOT / "tests"))
sys.path.insert(0, str(ROOT / "tools"))
from check_dust_and_music import c1
from s1tools.codecs.kosinski import decode_moduled
from s1tools.sidekick import SHARED, recolour
from s1tools.sidekick_dust import POOLS
from unicorn.m68k_const import *  # noqa: F403


def tiles(data):
    return {i: data[i * 32 : i * 32 + 32] for i in range(len(data) // 32)}


def run():
    for zone, pool in POOLS.items():
        c = c1()
        dmas = []
        body = c.s["v_sidekick_dust"]
        c.w(body, c.s["id_SidekickDust"])
        c.reg(UC_M68K_REG_A0, body)
        c.w("v_zone", c.s["id_SBZ"] if zone == "FZ" else c.s["id_" + zone])
        c.w("v_act", 2 if zone == "FZ" else 0)
        c.skip(
            "QueueDMATransfer",
            lambda cpu, dmas=dmas: dmas.append(
                tuple(cpu.uc.reg_read(r) for r in (UC_M68K_REG_D1, UC_M68K_REG_D2, UC_M68K_REG_D3))
            ),
        )
        for frame in range(7):
            dmas.clear()
            c.w(body + c.s["obFrame"], frame)
            c.call("Sidekick_LoadDustDynPLC")
            actual = {}
            for source, dest, n in dmas:
                data = bytes(c.uc.mem_read(source, n * 2))
                for j in range(n // 16):
                    actual[dest // 32 + j] = data[j * 32 : j * 32 + 32]
            base = c.s["DustDynPLC"]
            off = c.r(base + frame * 2, 2)
            script = base + off
            count = c.r(script)
            flat = b""
            for i in range(count):
                v = c.r(script + 1 + i * 2, 2)
                n = (v >> 12) + 1
                start = v & 0xFFF
                flat += bytes(c.uc.mem_read(c.s["Art_SpinDust"] + start * 32, n * 32))
            before = raster(c, "Map_SpinDust", frame, 0, tiles(flat))
            after = raster(c, "Map_SidekickSpinDust_" + zone, frame, 0, actual)
            assert before == after, ("spin pixels", zone, frame)
            assert set(actual) <= set(pool)
        dmas.clear()
        c.reg(UC_M68K_REG_D1, c.s["Art_SkidDust"])
        c.reg(UC_M68K_REG_D2, 0)
        c.reg(UC_M68K_REG_D3, 16)
        c.call("Sidekick_DustTransfer")
        actual = {}
        for source, dest, n in dmas:
            data = bytes(c.uc.mem_read(source, n * 2))
            for j in range(n // 16):
                actual[dest // 32 + j] = data[j * 32 : j * 32 + 32]
        original = tiles(bytes(c.uc.mem_read(c.s["Art_SkidDust"], 16 * 32)))
        for frame in range(4):
            assert raster(c, "Map_SkidDust", frame, 0, original) == raster(
                c, "Map_SidekickSkidDust_" + zone, frame, 0, actual
            ), ("skid pixels", zone, frame)
        assert set(actual) == set(pool)
        # Check real PLC payload sizes, not just their start addresses.
        names = ["PLC_Main", "PLC_Main2", "PLC_Explode", "PLC_Points"]
        if zone == "FZ":
            names += ["PLC_FZBoss"]
            layout = (ROOT / "objpos/fz.bin").read_bytes()
            assert {
                layout[i + 4] & 127
                for i in range(0, len(layout), 6)
                if layout[i : i + 2] != b"\xff\xff"
            } == {0x71}
            mainart = c.r(c.s["KosM_SBZ"], 2) // 32
            assert not set(pool) & set(range(mainart))
        else:
            names += ["PLC_" + zone, "PLC_" + zone + "2", "PLC_" + zone + "Animals", "PLC_Signpost"]
            if zone != "SBZ":
                names += ["PLC_Boss"]
            else:
                names += ["PLC_EggmanSBZ2"]
        for name in names:
            assert name in c.s, name
            plc = c.s[name]
            for i in range(c.r(plc, 2) + 1):
                ptr = c.r(plc + 2 + i * 6, 4)
                dest = c.r(plc + 6 + i * 6, 2) // 32
                n = c.r(ptr, 2) // 32
                if ptr == c.s["KosM_SpinPform"]:
                    n = c.r("KosM_SidekickSpinPlatform", 2) // 32
                assert not set(pool) & set(range(dest, dest + n)), (
                    "PLC conflict",
                    zone,
                    name,
                    hex(dest),
                    n,
                )
    c = c1()
    raw = decode_moduled((ROOT / "artkosm/SBZ Spinning Platform.kosm").read_bytes())
    compact = decode_moduled(
        (ROOT / "artkosm/sidekick/SBZ Spinning Platform Compact.kosm").read_bytes()
    )
    before = tiles(recolour(raw, SHARED))
    after = tiles(compact)
    for frame in range(5):
        assert raster(c, "Map_Spin", frame, 0, before) == raster(
            c, "Map_SidekickSpinPlatform", frame, 0, after
        ), ("SBZ platform pixels", frame)
    print(
        "7 zones × (7 spin + 4 skid) frames: pixel-identical maps/DMAs; audited PLC gaps remain disjoint"
    )


if __name__ == "__main__":
    run()
