# MD Debugger error screen

`make build` produces `s1built.bin` with the blue MD Debugger 2.6 exception screen and a ConvSym DEB2 symbol table. `make build-debug` produces the same configuration under the separate name `s1built.debug.bin`. `build.bat` and SonLVL builds also use the blue screen. The ROM is padded with `$FF` after appending symbols, to a power-of-two cartridge size starting at exactly 1 MiB (1,048,576 bytes). The checksum and ROM-end header are fixed after padding. No intentional crash is present in gameplay code.

The exception screen shows the error, PC and its symbol, D0-D7, A0-A6, SP, SR, USP and the stack. A opens address-register symbols, B opens the backtrace, and Start returns to the exception screen. Unexpected traps and interrupts use the same error handler. This diagnostic screen is independent of the in-game Debug Mode setting. Upstream documentation: https://github.com/vladikcomper/md-modules/tree/master/modules/errorhandler

## Building without the symbol table

Symbols are enabled by default, including release builds. To omit them explicitly:

```sh
make build SYMBOLS=0
# Alternate output name:
make build-debug SYMBOLS=0
```

Both commands keep the blue error screen and its numeric PC/register/stack display. Function names and symbolic backtrace labels are unavailable. ConvSym is not used. Without Make, run `lua build.lua --no-symbols` (optionally add `debug`); on Windows use `build_tools/lua/lua.exe build.lua --no-symbols`.

The no-symbols ROM is also padded with `$FF` to at least 1 MiB. No DEB2 table is appended: the debugger detects the missing signature and falls back to numeric addresses. Padding must always follow any symbol table, never separate it from the debugger blob.

## Tools and platforms

Builds with symbols need ConvSym 2.12.1 in addition to the existing assembler and p2bin. Official Windows x86_64 and Linux x86_64 executables are bundled; other platforms can build ConvSym from https://github.com/vladikcomper/md-modules/tree/master/utils/convsym and either place it in the appropriate `build_tools/<platform>/` directory or set the `CONVSYM` environment variable to its path. Linux users may need `chmod +x build_tools/Linux-x86_64/convsym` after extracting a ZIP.

Official release: https://github.com/vladikcomper/md-modules/releases/tag/v.2.6-mddebugger

Assembly bundles and ConvSym binaries are redistributed under the included MIT license, copyright Vladikcomper. The ErrorHandler blob is unchanged from the `as` release bundle. Configuration is in `_debug/md-debugger/Debugger.asm`; SR/USP display is enabled for this project.
