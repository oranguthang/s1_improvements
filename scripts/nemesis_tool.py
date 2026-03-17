#!/usr/bin/env python3
"""File and bytes helpers for Clownacy's clownnemesis-tool."""

from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import uuid


ROOT = Path(__file__).resolve().parents[1]
TOOL_ROOT = ROOT / "build_tools" / "clownnemesis"
TOOL_PATH = TOOL_ROOT / "build" / "Release" / "clownnemesis-tool.exe"
TEMP_ROOT = TOOL_ROOT / "pytemp"


def get_tool_path() -> Path:
    if not TOOL_PATH.is_file():
        raise FileNotFoundError(f"clownnemesis-tool.exe not found: {TOOL_PATH}")
    return TOOL_PATH


def run_tool(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(get_tool_path()), *args],
        check=True,
        capture_output=True,
        text=True,
    )


def decompress_file(input_path: Path | str, output_path: Path | str) -> None:
    run_tool("-d", str(input_path), str(output_path))


def compress_file(input_path: Path | str, output_path: Path | str, accurate: bool = True) -> None:
    run_tool("-ca" if accurate else "-c", str(input_path), str(output_path))


def _create_workspace() -> Path:
    TEMP_ROOT.mkdir(parents=True, exist_ok=True)
    workspace = TEMP_ROOT / f"job-{uuid.uuid4().hex}"
    workspace.mkdir(parents=True, exist_ok=False)
    return workspace


def _cleanup_workspace(workspace: Path) -> None:
    shutil.rmtree(workspace, ignore_errors=True)


def decompress_bytes(data: bytes) -> bytes:
    workspace = _create_workspace()
    try:
        input_path = workspace / "input.nem"
        output_path = workspace / "output.bin"
        input_path.write_bytes(data)
        decompress_file(input_path, output_path)
        return output_path.read_bytes()
    finally:
        _cleanup_workspace(workspace)


def compress_bytes(data: bytes, accurate: bool = True) -> bytes:
    workspace = _create_workspace()
    try:
        input_path = workspace / "input.bin"
        output_path = workspace / "output.nem"
        input_path.write_bytes(data)
        compress_file(input_path, output_path, accurate=accurate)
        return output_path.read_bytes()
    finally:
        _cleanup_workspace(workspace)
