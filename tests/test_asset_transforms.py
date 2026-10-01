"""Regression checks for byte-preserving resource transformations."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest
from s1tools.codecs import kosinski, nemesis

ROOT = Path(__file__).resolve().parents[1]


def test_knuckles_gameplay_pose_sources() -> None:
    """S1 gameplay IDs must select the corresponding S3K poses."""
    from s1tools.knuckles import frame_plan

    plan = frame_plan()
    # S3K's animation table uses CE..D1 for pushing, B1/B2 for hanging,
    # 9D/9E for stopping and 9F..AA for balancing. The shared S3K event
    # IDs select 8E for spring, 8D for hurt and AB for death (not surf 91).
    assert [plan[i][0] for i in range(0x45, 0x49)] == list(range(0xCE, 0xD2))
    assert [plan[i][0] for i in (0x41, 0x42)] == [0xB1, 0xB2]
    assert [plan[i][0] for i in (0x37, 0x38)] == [0x9D, 0x9E]
    assert [plan[i][0] for i in range(0x87, 0x93)] == list(range(0x9F, 0xAB))
    assert plan[0x40][0] == 0x8E
    assert plan[0x55][0] == 0x8D
    assert plan[0x4D][0] == 0xAB
    assert plan[0x4C][0] == 0xAD
    assert [plan[i][0] for i in range(0x58, 0x5E)] == list(range(0x86, 0x8C))


@pytest.mark.parametrize("suffix", ["", " - LZ Underwater", " - SBZ3 Underwater"])
def test_solo_character_palettes_protect_object_colours(suffix: str) -> None:
    reference = (ROOT / f"palette/Sonic{suffix}.bin").read_bytes()
    for name in ("Tails", "Knuckles"):
        palette = (ROOT / f"palette/{name}{suffix}.bin").read_bytes()
        assert palette[:4] == reference[:4]
        assert palette[12:] == reference[12:]
        assert len({palette[i : i + 2] for i in range(4, 12, 2)}) == 4
        assert palette[4:12] != reference[4:12]


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
        ("player", "knuckles"),
        ("player", "palette"),
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


def test_shared_palette_preserves_unselected_tiles() -> None:
    from s1tools.common import get_source, load_data

    source = get_source("shared")
    for name, asset in load_data("shared_player_palette.json")["assets"].items():
        suffix = Path(name).suffix
        decode = (
            nemesis.decode
            if suffix == ".nem"
            else kosinski.decode_moduled
            if suffix == ".kosm"
            else bytes
        )
        before = decode((source / asset["source"]).read_bytes())
        after = decode((ROOT / name).read_bytes())
        selected = {tile for start, end in asset["ranges"] for tile in range(start, end)}
        assert len(before) == len(after), name
        for tile in range(len(before) // 32):
            if tile not in selected:
                assert before[tile * 32 : (tile + 1) * 32] == after[tile * 32 : (tile + 1) * 32], (
                    name,
                    tile,
                )


def test_score_label_uses_the_same_yellow_for_dynamic_e() -> None:
    hud = kosinski.decode_moduled((ROOT / "artkosm/HUD.kosm").read_bytes())
    numbers = (ROOT / "artunc/HUD Numbers.unc").read_bytes()
    # SCOR is resident art; E is uploaded separately by Hud_Base.
    for glyph in (hud[: 8 * 32], numbers[22 * 32 : 24 * 32]):
        colours = {n for b in glyph for n in (b >> 4, b & 15)}
        assert 12 in colours and colours <= {0, 1, 12}
