"""Regression checks for byte-preserving resource transformations."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest
from s1tools.codecs import kosinski, nemesis

ROOT = Path(__file__).resolve().parents[1]


def run(*command: str) -> str:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(ROOT / "tools")
    result = subprocess.run(
        [sys.executable, "-m", "s1tools", "--root", str(ROOT), *command],
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    return result.stdout


@pytest.mark.parametrize("size", [32, 64, 4064, 4096, 4128, 8224])
def test_kosinski_module_boundaries(size: int) -> None:
    data = bytes((i * i + 7 * i) % 256 for i in range(size))
    encoded = kosinski.encode_moduled(data)
    assert kosinski.decode_moduled(encoded) == data


@pytest.mark.parametrize(
    "name", ["Enemy Buzz Bomber.nem", "Title Screen Foreground.nem", "LZ Bubbles & Countdown.nem"]
)
def test_nemesis_pixels_preserve_template(name: str) -> None:
    template = (ROOT / "artnem" / name).read_bytes()
    pixels = nemesis.decode(template)
    assert nemesis.decode(nemesis.encode_with_table(template, pixels)) == pixels


@pytest.mark.parametrize(
    "command",
    [
        ("player", "super", "--verify"),
        ("player", "figure8", "--verify"),
        ("player", "air", "--verify"),
        ("player", "tails"),
        ("palettes", "badniks", "--verify"),
        ("palettes", "objects", "--verify"),
        ("palettes", "water", "--check"),
        ("art", "rings"),
        ("art", "shield"),
        ("art", "walls"),
        ("tables", "ring-loss"),
        ("title", "import"),
    ],
)
def test_reproduction_matches_game_data(command: tuple[str, ...]) -> None:
    run(*command)


def test_conversion_preserves_input_and_rejects_overwrite(tmp_path: Path) -> None:
    original = ROOT / "artnem/Enemy Motobug.nem"
    before = original.read_bytes()
    output = tmp_path / "art.kosm"
    run(
        "art",
        "codec",
        str(original),
        "--from-format",
        "nemesis",
        "--to-format",
        "kosm",
        "--output-file",
        str(output),
    )
    assert kosinski.decode_moduled(output.read_bytes()) == nemesis.decode(before)
    assert original.read_bytes() == before
    with pytest.raises(AssertionError, match="Output already exists"):
        run(
            "art",
            "codec",
            str(original),
            "--from-format",
            "nemesis",
            "--to-format",
            "kosm",
            "--output-file",
            str(output),
        )


def test_palette_preview_is_portable(tmp_path: Path) -> None:
    output = tmp_path / "palette.html"
    run(
        "palettes",
        "preview",
        "--palette",
        str(ROOT / "palette/Sonic.bin"),
        "--cycle",
        str(ROOT / "palette/Cycle - Super Sonic LZ Underwater.bin"),
        "--output-file",
        str(output),
    )
    text = output.read_text()
    assert "const frames=" in text
    assert "Frame ${n+1}" in text
