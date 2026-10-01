"""Check editor-format boundaries and avoid accidental data loss."""

from __future__ import annotations

from pathlib import Path

import pytest
from s1tools import common, levels, sonlvl

ROOT = Path(__file__).resolve().parents[1]


def test_ring_group_conversion_uses_positions_and_preserves_objects() -> None:
    # Three rings in a horizontal group, followed by a monitor and terminator.
    group = bytes.fromhex("010002002502")
    monitor = bytes.fromhex("030002002600")
    terminal = bytes.fromhex("ffff00000000")
    result, rings, groups, count = levels.rings_split(group + monitor + terminal, "example.bin")
    assert result == monitor + terminal
    assert groups == 1 and count == 3
    assert rings == bytes.fromhex("010002000110020001200200ffffffff")


def test_object_terminator_is_required() -> None:
    with pytest.raises((ValueError, AssertionError)):
        levels.objects_decode_objpos(bytes.fromhex("010002002600"))


def test_block_and_chunk_references() -> None:
    assert levels.blocks_main([]) == 0
    assert levels.chunks_main([]) == 0


def test_sonlvl_references_match_without_rewriting() -> None:
    paths = list((ROOT / "Utility Project Files/SonLVL INI Files").glob("SonLVL.rev*.ini"))
    before = {p: p.read_bytes() for p in paths}
    count, differences = sonlvl.sync_sync(ROOT)
    assert count == 38 and differences == []
    assert {p: p.read_bytes() for p in paths} == before


def test_source_bundle_has_checked_inputs() -> None:
    source = common.get_source("cd")
    assert (source / "CD-Art.bin").is_file()
    assert (source / "Fall.png").is_file()


def test_output_cannot_escape_project(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(common, "_ROOT", tmp_path / "project")
    with pytest.raises(ValueError, match="escapes"):
        common.write_outputs({tmp_path / "unrelated.bin": b"bad"}, apply=True)
    assert not (tmp_path / "unrelated.bin").exists()
