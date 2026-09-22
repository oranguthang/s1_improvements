# Sonic 1 Improvements

A Sonic the Hedgehog disassembly with gameplay extensions, engine improvements and editable resources for building further mods.

## Build

Run `make build` to create `s1built.bin`. GNU Make is required. Windows uses the bundled Lua and assembler tools. Linux and macOS require Lua 5.3 or newer on PATH; use `make build LUA=lua5.4` to select a different executable. Platform-specific tools are in `build_tools`.

The assembly switches `Revision` and `FixBugs` are in `sonic.asm`. Keep both revisions and both switch values buildable when modifying shared routines. Open the projects under `Utility Project Files` to edit game resources.

See [credits and sources](CREDITS.md) for attribution. Resource tools are optional; normal ROM builds use the checked-in game assets and do not require Python.

## Disclaimer

Any and all content presented in this repository is presented for informational and educational purposes only. Commercial usage is expressly prohibited. Sonic Retro claims no ownership of any code in these repositories. You assume responsibility for using this content responsibly. Sonic Retro claims no responsibility or warranty.
