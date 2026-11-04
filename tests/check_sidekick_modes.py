# ruff: noqa: F405, E402
"""Built-ROM companion regression checks; run through check_sidekick.py."""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
from check_dust_and_music import c1

c = c1()
c.skip("Settings_Save")
for selected, leader, p2 in [
    (0, 0, 255),
    (1, 1, 255),
    (2, 2, 255),
    (3, 0, 1),
    (4, 2, 1),
    (5, 0, 255),
    (255, 0, 255),
]:
    for mode in (12, 16, 20, 24):
        c.w("v_character_selected", selected)
        c.w("v_gamemode", mode)
        c.w("f_demo", 0, 2)
        c.call("UpdateSceneCharacter")
        assert c.r("v_character_p1") == leader, (selected, mode)
        assert c.r("v_character_p2") == p2, (selected, mode)
    c.call("Settings_Normalize")
    assert c.r("v_character_selected") == (selected if selected < 5 else 0)
for demo in (1, 0x8001):
    for selected in range(5):
        c.w("v_character_selected", selected)
        c.w("v_gamemode", 8)
        c.w("f_demo", demo, 2)
        c.call("UpdateSceneCharacter")
        assert c.r("v_character_p1") == 0 and c.r("v_character_p2") == 1
c.w("f_demo", 0, 2)
c.w("v_character_selected", 0)
for direction, expected in [(c.s["btnR"], [1, 2, 3, 4, 0]), (c.s["btnL"], [4, 3, 2, 1, 0])]:
    for selected in expected:
        c.w("v_jpadpress1", direction)
        c.call("Options_ReadInput")
        assert c.r("v_character_selected") == selected
print("5 mode selection, solo-compatible IDs, invalid SRAM values and both demo flags passed")
