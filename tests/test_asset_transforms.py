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
    from s1tools.common import get_source
    from s1tools.knuckles import COLOURS

    reference = (ROOT / f"palette/Sonic{suffix}.bin").read_bytes()
    original = (get_source("shared") / f"palette/Sonic{suffix}.bin").read_bytes()
    # All shared shades, including Crabmeat's dark red and yellow, stay original.
    assert reference[:4] == original[:4]
    assert reference[12:] == original[12:]
    green = {"": 0x0080, " - LZ Underwater": 0x0442, " - SBZ3 Underwater": 0x0646}
    knuckles = (ROOT / f"palette/Knuckles{suffix}.bin").read_bytes()
    assert COLOURS[5] == 3
    assert knuckles[6:8] == green[suffix].to_bytes(2, "big")
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
        ("player", "ui"),
        ("player", "endings"),
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

    sources = {group: get_source(group) for group in ("shared", "s1")}
    for name, asset in load_data("shared_player_palette.json")["assets"].items():
        suffix = Path(name).suffix
        decode = (
            nemesis.decode
            if suffix == ".nem"
            else kosinski.decode_moduled
            if suffix == ".kosm"
            else bytes
        )
        input_suffix = Path(asset["source"]).suffix
        input_decode = (
            nemesis.decode
            if input_suffix == ".nem"
            else kosinski.decode_moduled
            if input_suffix == ".kosm"
            else bytes
        )
        asset_source = sources[asset.get("source_group", "shared")]
        before = input_decode((asset_source / asset["source"]).read_bytes())
        after = decode((ROOT / name).read_bytes())
        for before_byte, after_byte in zip(before, after, strict=True):
            if before_byte >> 4 == 8:
                assert after_byte >> 4 == 8, name
            if before_byte & 15 == 8:
                assert after_byte & 15 == 8, name
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


def test_title_card_ovals_do_not_use_character_colours() -> None:
    from s1tools.common import get_source

    before = nemesis.decode((get_source("s1") / "artnem/Title Cards.nem").read_bytes())
    after = kosinski.decode_moduled((ROOT / "artkosm/Title Cards.kosm").read_bytes())
    assert len(after) == len(before) == 128 * 32
    assert after[: 0x6E * 32] == before[: 0x6E * 32]
    colours = {n for b in after[0x6E * 32 :] for n in (b >> 4, b & 15)}
    assert colours <= {0, 1, 6, 7, 8, 9}


def test_ending_blue_remap_preserves_other_emeralds_and_transparency() -> None:
    original = kosinski.decode_moduled((ROOT / "artkosm/Ending - Emeralds.kosm").read_bytes())
    shared = kosinski.decode_moduled((ROOT / "artkosm/Ending - Shared Emeralds.kosm").read_bytes())
    # Only the blue gem's four tiles change; other gems and the flash stay intact.
    assert shared[: 4 * 32] == original[: 4 * 32]
    assert shared[8 * 32 :] == original[8 * 32 :]
    for before, after in zip(original, shared, strict=True):
        assert (before >> 4 == 0) == (after >> 4 == 0)
        assert (before & 15 == 0) == (after & 15 == 0)
    for name in ("Emeralds", "Logo"):
        before = kosinski.decode_moduled(
            (ROOT / f"artkosm/Ending - {'StH Logo' if name == 'Logo' else name}.kosm").read_bytes()
        )
        after = kosinski.decode_moduled(
            (ROOT / f"artkosm/Ending - Shared {name}.kosm").read_bytes()
        )
        for a, b in zip(before, after, strict=True):
            assert (a >> 4 == 6) == (b >> 4 == 6)
            assert (a & 15 == 6) == (b & 15 == 6)


@pytest.mark.parametrize("name", ["Tails", "Knuckles"])
def test_ending_glow_keeps_the_head_and_feet_stationary(name: str) -> None:
    from PIL import Image
    from s1tools.character_endings import mobile_frames
    from s1tools.common import get_source

    sheet = Image.open(get_source("mobile") / "ending.png").convert("RGB")
    hold, glow = mobile_frames(sheet, name)[:2]
    # Sparkles cover the hands/tail. The head and shoes retain their placement.
    for bounds in ((116, 114, 138, 122), (108, 144, 150, 150)):
        unchanged = hold.crop(bounds)
        assert unchanged.getbbox()
        assert unchanged.tobytes() == glow.crop(bounds).tobytes()


@pytest.mark.parametrize("name", ["Tails", "Knuckles"])
def test_mobile_ending_mapping_preserves_every_pixel(name: str) -> None:
    from PIL import Image
    from s1tools.character_endings import ENDING_TILES, mobile_frames
    from s1tools.common import get_source
    from s1tools.sprites import decode_tiles, parse_mappings

    source = Image.open(get_source("mobile") / "ending.png").convert("RGB")
    art = kosinski.decode_moduled((ROOT / f"artkosm/Ending - {name}.kosm").read_bytes())
    tiles = decode_tiles(art)
    assert len(tiles) <= ENDING_TILES
    table, frames = parse_mappings(ROOT / f"_maps/Ending Sequence {name}.asm")
    for label, expected in zip(table, mobile_frames(source, name), strict=True):
        actual = Image.new("P", expected.size)
        assert len(frames[label]) <= 24  # Original Sonic's largest ending pose.
        for piece in frames[label]:
            assert -128 <= piece.y <= 127
            assert piece.tile + piece.width_tiles * piece.height_tiles <= len(tiles)
            for tx in range(piece.width_tiles):
                for ty in range(piece.height_tiles):
                    tile = tiles[piece.tile + tx * piece.height_tiles + ty]
                    for y, row in enumerate(tile):
                        for x, colour in enumerate(row):
                            if colour:
                                actual.putpixel(
                                    (128 + piece.x + tx * 8 + x, 128 + piece.y + ty * 8 + y),
                                    colour,
                                )
        assert actual.tobytes() == expected.tobytes(), label


def test_invincibility_stars_use_shared_colours() -> None:
    from s1tools.common import get_source

    original = (get_source("shared") / "artunc/Invincibility Stars Restore.unc").read_bytes()
    art = (ROOT / "artunc/Invincibility Stars Restore.unc").read_bytes()
    assert art == nemesis.decode((ROOT / "artnem/Invincibility Stars.nem").read_bytes())
    assert art == kosinski.decode_moduled((ROOT / "artkosm/Invincibility Stars.kosm").read_bytes())
    colours = {n for b in art for n in (b >> 4, b & 15)}
    assert colours == {0, 6, 7, 8, 9}
    for before, after in zip(original, art, strict=True):
        assert (before >> 4 == 0) == (after >> 4 == 0)
        assert (before & 15 == 0) == (after & 15 == 0)
    for suffix in ("", " - LZ Underwater", " - SBZ3 Underwater"):
        palettes = [
            (ROOT / f"palette/{name}{suffix}.bin").read_bytes()
            for name in ("Sonic", "Tails", "Knuckles")
        ]
        for colour in colours:
            assert len({p[colour * 2 : colour * 2 + 2] for p in palettes}) == 1


def test_water_transition_covers_changed_colours() -> None:
    """WaterSurfaceGradual: a colour left out of the table stays dry underwater."""
    import re

    source = (ROOT / "_inc/LZWaterFeatures.asm").read_text()
    block = source.split("WaterTransition_LZ:", 1)[1].split("WaterTransition_LZ_End:", 1)[0]
    words = [int(value, 16) for value in re.findall(r"\$([0-9A-F]+)", block)]
    covered = set()
    for offset in words:
        assert offset % 2 == 0 and offset // 32 == (offset + 4) // 32, hex(offset)
        covered |= {offset // 2, offset // 2 + 1, offset // 2 + 2}

    def words_of(name: str) -> list[bytes]:
        data = (ROOT / "palette" / name).read_bytes()
        return [data[i : i + 2] for i in range(0, len(data), 2)]

    changed = {16 * 3 + 0xB, 16 * 3 + 0xC, 16 * 3 + 0xD}  # conveyor cycle
    for zone, dry, wet in (
        ("LZ", "Labyrinth Zone.bin", "Labyrinth Zone Underwater.bin"),
        ("SBZ3", "SBZ Act 3.bin", "SBZ Act 3 Underwater.bin"),
    ):
        for player in ("Sonic", "Tails", "Knuckles"):
            above = words_of(f"{player}.bin") + words_of(dry)
            below = words_of(f"{player} - {zone} Underwater.bin") + words_of(wet)[16:]
            changed |= {i for i in range(64) if i % 16 and above[i] != below[i]}
    assert changed <= covered, sorted(hex(i * 2) for i in changed - covered)
