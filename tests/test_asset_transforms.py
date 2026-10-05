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


def test_knuckles_frame_constants_match_the_importer() -> None:
    import re

    from s1tools import knuckles

    source = (ROOT / "_incObj/Knuckles Glide.asm").read_text(encoding="utf-8")
    values = {
        name: int(value, 16)
        for name, value in re.findall(r"^(knux_\w+): equ \$(\w+)", source, re.M)
    }
    assert values["knux_transform_frame"] == knuckles.TRANSFORM
    assert values["knux_walk_frame"] == knuckles.WALK8
    plan = knuckles.frame_plan()
    # Eight S3K walk frames per orientation, in S1 orientation order.
    assert [plan[knuckles.WALK8 + i][0] for i in range(32)] == list(range(1, 33))
    # The victory frames follow the walk block (knux_walk_frame+4*8).
    assert knuckles.VICTORY == knuckles.WALK8 + 32
    assert [plan[knuckles.VICTORY + i][0] for i in range(4)] == [0xB1, 0xB2, 0xB3, 0xB4]
    assert knuckles.FRAME_COUNT <= 0x100


def test_tails_tail_object_matches_the_importer() -> None:
    import re

    from s1tools import tails

    header = (ROOT / "_maps/Tails.asm").read_text(encoding="utf-8")
    assert re.search(r"^fr_TailsWalk equ \$(\w+)", header, re.M)[1] == f"{tails.WALK8:X}"
    assert re.search(r"^fr_TailsVictory equ \$(\w+)", header, re.M)[1] == f"{tails.VICTORY:X}"
    assert tails.FRAME_COUNT <= 0x100
    constants = (ROOT / "_Constants.asm").read_text(encoding="utf-8")
    slot = int(re.search(r"^Tails_Tail_Tiles:\s+equ (\d+)", constants, re.M)[1])
    assert slot == 32 - tails.BODY_TILES_WITH_TAIL
    source = (ROOT / "_incObj/8F Tails Tail.asm").read_text(encoding="utf-8")
    scripts = re.findall(r"^\.\w+:\s+dc\.b (.+)$", source, re.M)
    frames = [
        int(value.replace("$", ""), 16 if "$" in value else 10)
        for line in scripts
        for value in (part.strip() for part in line.split(",")[1:])
        if not value.startswith(("af", "tailani"))
    ]
    # Every scripted tail frame exists in the imported tail mappings.
    assert max(frames) < tails.TAIL_FRAMES


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


@pytest.mark.parametrize("suffix", ["", " - LZ Underwater", " - SBZ3 Underwater"])
@pytest.mark.parametrize(("name", "fixed", "last"), [("Tails", 2, 0x58), ("Knuckles", 3, 0x78)])
def test_super_partner_cycles_keep_shared_colours(
    suffix: str, name: str, fixed: int, last: int
) -> None:
    """Super cycles change fur only; Tails' index 2 and Knuckles' shoes stay put."""
    normal = (ROOT / f"palette/{name}{suffix}.bin").read_bytes()
    static = (ROOT / f"palette/Super {name}{suffix}.bin").read_bytes()
    cycle = (ROOT / f"palette/Cycle - Super {name}{suffix.replace(' - ', ' ')}.bin").read_bytes()
    assert static[:4] == normal[:4] and static[12:] == normal[12:]
    # CharacterAsset_CycleLast in _inc/Character Assets.asm reads the last entry.
    assert len(cycle) >= last + 8
    # S3K's Super Tails cycle starts on his normal colours, then pulses yellow.
    assert any(cycle[entry : entry + 8] != normal[4:12] for entry in range(0x30, last + 8, 8))
    assert cycle[:8] == normal[4:12]  # the fade starts from the normal form
    assert cycle[0x30:0x38] == static[4:12]  # and ends on the static Super palette
    slot = (fixed - 2) * 2
    for entry in range(0, len(cycle), 8):
        assert cycle[entry + slot : entry + slot + 2] == normal[fixed * 2 : fixed * 2 + 2]


def test_super_flickies_fit_their_vram_slot() -> None:
    art = (ROOT / "artunc/Super Tails Flickies.unc").read_bytes()
    assert len(art) == 14 * 32  # ArtTile_SuperTailsFlickies, below the points
    assert any(art)


def test_special_stage_results_keep_original_colours() -> None:
    """The results screen has its own palette for the recoloured shared art."""
    line = [
        (ROOT / "palette/Special Stage Results.bin").read_bytes()[i : i + 32]
        for i in range(0, 128, 32)
    ]
    # HUD text moved from colour 15 to 12: both must be the original green.
    assert line[0][24:26] == line[0][30:32] == bytes.fromhex("04c0")


def test_extended_title_cards_append_gray_ovals() -> None:
    from s1tools.character_ui import EXTENDED_OVAL, EXTENDED_SMALL_OVAL, GRAY

    art = (ROOT / "artunc/Title Cards Extended.unc").read_bytes()
    tiles = [art[i : i + 32] for i in range(0, len(art), 32)]
    assert len(tiles) == EXTENDED_SMALL_OVAL + 2 + 16 + 2
    original = tiles[EXTENDED_OVAL : EXTENDED_OVAL + 16] + tiles[EXTENDED_SMALL_OVAL:][:2]
    gray = tiles[EXTENDED_SMALL_OVAL + 2 :]
    for source, copy in zip(original, gray, strict=True):
        for a, b in zip(source, copy, strict=True):
            for shift in (4, 0):
                nibble = a >> shift & 15
                assert b >> shift & 15 == GRAY.get(nibble, nibble)
    # The player's fur colours 2-5 never reach the level card ovals.
    assert not any(n in (2, 3, 4, 5) for tile in gray for b in tile for n in (b >> 4, b & 15))


def test_every_feature_option_is_documented() -> None:
    import re

    source = (ROOT / "sonic.asm").read_text(encoding="utf-8")
    options = re.findall(r"^(Feature\w+) = [01]\s*$", source, re.MULTILINE)
    assert len(options) >= 15
    # The range check rejects anything other than 0 or 1.
    check = re.search(r"if \((Feature\w+(?:\|Feature\w+)*)\)&~1", source)
    assert check and sorted(check.group(1).split("|")) == sorted(options)
    docs = (ROOT / "docs/modding.md").read_text(encoding="utf-8")
    table = docs.split("## Feature options", 1)[1].split("\n## ", 1)[0]
    for option in options:
        assert f"`{option}`" in table, option


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
        ("player", "super-forms"),
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

    sources = {group: get_source(group) for group in ("shared", "s1", "s2")}
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


def test_enigma_encoder_round_trips_every_layout() -> None:
    from s1tools.codecs import enigma

    for path in sorted((ROOT / "sslayout").glob("*.eni")):
        words = enigma.decode(path.read_bytes())
        assert enigma.decode(enigma.encode(words)) == words, path.name


def test_seventh_emerald_resources() -> None:
    from s1tools.codecs import enigma

    # Stage 7 is stage 6 with the grey emerald ($40) turned into block $28.
    six = bytearray(enigma.decode_bytes((ROOT / "sslayout/6 (REV01).eni").read_bytes()))
    six[six.index(0x40)] = 0x28
    assert enigma.decode_bytes((ROOT / "sslayout/7.eni").read_bytes()) == bytes(six)
    starts = ROOT / "startpos/Special Stages"
    assert (starts / "ss7.bin").read_bytes() == (starts / "ss6.bin").read_bytes()
    # Each palette variant only adds the cyan ramp in otherwise free slots.
    cyan = (0x0EE6, 0x0CC2, 0x0880)
    for name, line, slots in (
        ("Special Stage", 1, (7, 8, 9)),
        ("Special Stage Results", 3, (7, 8, 9)),
        ("Ending", 1, (10, 11, 15)),
    ):
        expected = bytearray((ROOT / f"palette/{name}.bin").read_bytes())
        for slot, colour in zip(slots, cyan, strict=True):
            offset = line * 32 + slot * 2
            expected[offset : offset + 2] = colour.to_bytes(2, "big")
        assert (ROOT / f"palette/{name} - Seventh Emerald.bin").read_bytes() == bytes(expected)
