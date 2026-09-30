"""Shared paths, checked inputs and transactional resource output."""

from __future__ import annotations

import hashlib
import json
import shutil
import sysconfig
import zipfile
from pathlib import Path

_ROOT = Path.cwd()
_SOURCE = None
_DATA = Path(__file__).resolve().parents[1] / "data"
if not _DATA.is_dir():
    _DATA = Path(sysconfig.get_path("data")) / "share/s1tools"
_IGNORED = {".git", "tmp", "__pycache__", ".venv", ".ruff_cache", ".pytest_cache", "build", "dist"}


def configure(root: Path, source: Path | None = None, output: Path | None = None) -> None:
    global _ROOT, _SOURCE
    root = root.resolve(strict=True)
    if not (root / "sonic.asm").is_file():
        raise ValueError(f"Not a Sonic 1 project: {root}")
    if output is not None:
        output = output.resolve()
        if output == root or root.is_relative_to(output):
            raise ValueError("Output must be a separate directory, not the project or its parent")
        if output.exists() and any(output.iterdir()):
            raise ValueError("Output directory must be empty")
        paths = project_files(root)
        for relative in paths:
            destination = output / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(root / relative, destination)
        root = output
    _ROOT = root
    _SOURCE = source.resolve(strict=True) if source else None


def get_root() -> Path:
    return _ROOT


def load_data(name: str) -> dict:
    return json.loads((_DATA / name).read_text(encoding="utf-8"))


def get_source(group: str) -> Path:
    if _SOURCE is not None:
        return _SOURCE / group
    target = get_root() / "tmp" / "asset-inputs"
    expected = {}
    for name in ("palette_remaps.json", "player_imports.json", "title_import.json"):
        for path, digest in load_data(name)["input_files"].items():
            expected[("s1/" + path) if name == "palette_remaps.json" else path] = digest
    with zipfile.ZipFile(_DATA / "source_inputs.zip") as archive:
        for path, digest in expected.items():
            destination = (target / path).resolve()
            if not destination.is_relative_to(target.resolve()):
                raise ValueError(f"Unsafe input path: {path}")
            if (
                destination.is_file()
                and hashlib.sha256(destination.read_bytes()).hexdigest() == digest
            ):
                continue
            data = archive.read(path)
            if hashlib.sha256(data).hexdigest() != digest:
                raise ValueError(f"Input checksum mismatch: {path}")
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(data)
    return target / group


def project_files(root: Path) -> list[Path]:
    return sorted(
        p.relative_to(root)
        for p in root.rglob("*")
        if p.is_file()
        and not any(
            part in _IGNORED or part.endswith(".egg-info") for part in p.relative_to(root).parts
        )
        and not p.name.startswith("s1built")
        and p.suffix not in {".srm", ".pyc", ".log", ".lst", ".p"}
    )


def normalized(path: Path, data: bytes) -> bytes:
    if path.suffix in {".asm", ".json", ".md", ".py"}:
        return data.replace(b"\r\n", b"\n")
    return data


def write_outputs(outputs: dict[Path, bytes], *, apply: bool) -> None:
    root = get_root().resolve()
    for path, data in outputs.items():
        if not path.resolve().is_relative_to(root):
            raise ValueError(f"Output escapes project: {path}")
        if not apply and (
            not path.is_file() or normalized(path, path.read_bytes()) != normalized(path, data)
        ):
            raise ValueError(f"Output mismatch: {path.relative_to(root)}")
    if apply:
        for path, data in outputs.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            temporary = path.with_name(path.name + ".new")
            temporary.write_bytes(data)
            temporary.replace(path)
    print(f"{'Wrote' if apply else 'Verified'} {len(outputs)} resources")
