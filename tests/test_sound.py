"""Consistency of the Flamedriver tables and banks."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def table(name: str) -> list[str]:
    text = (ROOT / "sound/flamedriver/Tables.asm").read_text(encoding="utf-8")
    body = text.split(f"{name} macro", 1)[1].split("\tendm", 1)[0]
    return re.findall(r"^\tdecl\w+ (\w+)$", body, re.M)


def bank(path: str, prefix: str) -> list[str]:
    text = (ROOT / path).read_text(encoding="utf-8")
    return re.findall(rf"^{prefix}(\w+):\tinclude ", text, re.M)


def test_music_bank_follows_music_table() -> None:
    assert bank("sound/S3K Music Bank.asm", "Mus_") == table("Gen_Music_Table")


def test_sfx_bank_follows_sound_table() -> None:
    sounds = table("Gen_Sound_Table")
    assert bank("sound/S3K SFX Bank.asm", "Sound_") == sounds
    assert sounds.index("RingLeft") == sounds.index("Ring") + 1
    assert 0xA0 + len(sounds) - 1 < 0xFB, "sound effects must stay below the commands"
