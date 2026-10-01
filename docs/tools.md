# Resource tools

## Install and invocation

Use Python 3.11 or newer. From the project directory:

```sh
python -m pip install -e ".[dev]"
python -m s1tools --help
ruff check tools tests
ruff format --check tools tests
python -m pytest
```

Pillow is used by image imports and previews. ROM assembly itself does not need Python. Nemesis encoding with a supplied code-table template is built in. To compress arbitrary new Nemesis art, install [Clownacy's clownnemesis](https://github.com/Clownacy/clownnemesis) and set `NEMESIS_TOOL` to the executable, or pass `--compressor` to `art codec`.

Global flags go before the command group. `--root PATH` selects the target disassembly. `--output PATH` first copies it into an empty directory, then operates there. `--source PATH` selects an input bundle containing `s1/`, `s2/`, `sk/`, `cd/` and `title.zip`. Operation-specific options follow the group and command. Commands that alter game resources require `--apply`, `--write` or an explicit output filename/directory. Previews and audit reports go under `tmp/`.

## Inputs and reproducibility

`tools/data/source_inputs.zip` contains the exact resource inputs for the supplied recipes. The JSON manifests next to it list input SHA-256 checksums, palette rules and player-frame parameters. Sources and attribution are described in [CREDITS](../CREDITS.md). The tools validate packaged inputs before using them and extract them under `tmp/asset-inputs`. No Git history or sibling checkout is needed.

To inspect or reuse the source bundle:

```sh
python -m s1tools art inputs --output-dir tmp/source-inputs
```

For custom imports, explicitly provide source data. The player/remap commands reject incompatible input hashes instead of silently importing another revision of the artwork. To support new source artwork, update the source manifest and the corresponding frame/mapping parameters deliberately. The bundled recipes reproduce generated data, not manual level edits made in SonLVL.

## Player graphics

```sh
python -m s1tools player super --verify
python -m s1tools player figure8 --verify
python -m s1tools player air --verify
python -m s1tools player tails
```

Use `--apply` instead of `--verify` to regenerate. Order matters: Super base assets, then figure-eight, then air poses. Player importers retain the appended mapping/DPLC hooks. They preserve palette indices, frame IDs and sprite geometry; they do not use image quantization. The ordinary Sonic base art remains an input when computing appended tile offsets.

`player tails` verifies the solo Tails resources; `player tails --apply` regenerates them independently of Sonic's appended artwork. It reads the bundled Sonic 3 & Knuckles body/tail art and mapping/DPLC tables, repacks them to the Sonic 1 frame conventions, and generates dry/underwater palettes and the lives icon. It preserves indexed pixels, applies an explicit colour-index remap and rejects frames larger than the existing 32-tile player VRAM slot.

For a separate output project:

```sh
python -m s1tools --output tmp/generated-project player super --apply
python -m s1tools --root tmp/generated-project player figure8 --apply
python -m s1tools --root tmp/generated-project player air --apply
```

## Palette remaps

`palettes badniks --verify` and `palettes objects --verify` compare current art with deterministic remaps of the original inputs. `--apply` reproduces them. Protected tiles remain unchanged, including Buzz Bomber's missile. Newtron can share tiles across its two palette lines.

The named stage profiles are `bubbles`, `platform`, `seesaw`, `button`, `searchlight` and `column`. Use `--check` to check selected tiles or `--apply` to recolour them. Column/searchlight share the SYZ resource and apply non-overlapping selections. To repeat a profile from original pixels, copy its source `.nem` from the extracted `s1/artnem/` into a scratch project before applying it; retain current mappings for tile selection.

```sh
python -m s1tools palettes water --check
python -m s1tools palettes water --apply
python -m s1tools palettes audit --json
python -m s1tools palettes remap "artnem/Enemy Motobug.nem" --strategy direct --dry-run
```

`palettes remap` changes an arbitrary Nemesis resource; specify `--apply` and either `--output` or `--in-place` to write it. It reports its nibble map and decoded sizes. Prefer a separate output while choosing custom mappings.

Use `palettes preview --palette FILE --cycle FILE --output-file tmp/palette.html` for a portable cycle viewer. It accepts a 16-colour palette line and rows of four Mega Drive colour words. Both controls and palette labels are in English.

## Art conversion and extraction

```sh
python -m s1tools art rings
python -m s1tools art shield
python -m s1tools art walls
python -m s1tools art codec input.nem --from-format nemesis --to-format kosm --output-file tmp/output.kosm
python -m s1tools art convert --output-dir tmp/converted-art
```

The first three commands verify ring animation/sparkles, shield/invincibility and Special Stage wall output; `--apply` writes missing generated resources after consistency checks. `art convert` converts the current `artnem/` collection to an empty output directory. Generated compressed bytes are round-trip checked. A later mod may intentionally change resident art, so do not blindly replace an existing output collection.

## Title resources

`title compare` compares decoded pixels and priority bits with the source archive. `title audit` checks active VRAM ranges and editor references. `title import` validates the independent title resource set; `--write` imports it. To select an alternate archive, provide a bundle with `title.zip` through the global `--source` flag.

`title prompt` extracts the fourteen prompt tiles from the original foreground resource. It is a legacy extraction operation; the independent title archive uses its own eighteen-tile prompt. Use `--output-file` to save the extracted legacy version without overwriting the game's current prompt.

## Level data and SonLVL

```sh
python -m s1tools levels blocks
python -m s1tools levels chunks
python -m s1tools levels objects --write
python -m s1tools levels giant-rings
python -m s1tools sonlvl sync
```

Block/chunk checks follow act headers and validate references in both editor revisions. Convert original formats with `levels blocks --convert SOURCE_MAP16 --output-dir EMPTY_DIR` or `levels chunks --convert SOURCE_MAP256 --output-dir EMPTY_DIR`. Object snapshots are written to `tmp/object_snapshot/objects.json`; `--compare FILE` compares with a saved snapshot.

`levels split-rings --input-dir ORIGINAL_OBJPOS --output-dir EMPTY_DIR` separates grouped ring objects into object and four-byte ring lists. For the bundled original layouts, use the extracted `s1/objpos` directory. `--apply` installs the separated lists only when a ring directory does not already exist. Use output mode for inspecting a conversion before applying it to a mod.

After changing act header resource paths, run `sonlvl sync --write`. Only resource fields are changed; layouts, objects, rings and start positions remain intact. Non-contiguous custom VRAM layouts require explicit editor configuration.

`sonlvl roundtrip --api PATH_TO_SonLVLAPI.dll` checks editor load/save in a separate project copy. This command requires Windows and Windows PowerShell 5.1. Other commands do not require SonLVL or Windows.

## Inspection and generated tables

`sprites render Monitor --frame 0` renders a Flex object definition to BMP. `levels gallery GHZ` creates a block/palette viewer under `tmp/`. No preview files are stored as game assets.

`tables ring-loss` verifies the air/underwater velocity table against the engine sine data. Use `--apply` after intentionally changing the sine table.

## Verification boundaries

Resource checks validate file formats, indices, checksums and decoded output. They do not prove emulator timing or all gameplay behaviours. Retain normal playtesting when changing code, resource ownership or level geometry.
