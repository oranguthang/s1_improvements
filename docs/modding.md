# Modding reference

## Shared palettes

Sonic cycles palette indices 2–5. Shared level objects and badnik art use stable indices for affected details. Choose palette lines deliberately when adding sprites; graphic resources are shared rather than duplicated just to recolour them.

## Placing giant rings

In either SonLVL project use object `$4B`. Subtype `$00` is an act-end ring with the ring threshold; `$01` and `$02` are independently tracked free rings. Place them with suitable solid ground below. VRAM is shared with transient effects, so retain the existing X/Y visibility guard and wait for graphics residency before drawing the flash.

## Level editing

Editable layouts are in `levels/`, object placements in `objpos/`, and collision data in `collide/`. Some acts have separate REV00/REV01 placements. Update the intended revision rather than assuming both projects share every file.

## Swinging wrecking ball

The unused swinging-ball object variant is restored and has an editor definition alongside swinging platforms.

## Splats

Splats occupies object `$4F`, with code in `_incObj/4F Badnik - Splats.asm` and mappings in `_maps/Splats.asm`. Its palette line avoids Sonic cycle colours. Include graphics, PLC registration, object pointer and editor definition when adding another badnik.

## Independent title resources

The title screen uses its own art, block maps, chunk maps, layouts, camera bounds and prompt tiles. Edit its resources through the title entry in SonLVL. Green Hill resource changes do not alter the title emblem. Preserve the VRAM allocation used by the title animation and menus when replacing these assets.

## Blocks and chunks in ROM

`map16/*.bin` contains raw 8-byte 16×16 block records. `map256/*.bin` contains raw 512-byte 256×256 chunks. The engine reads them through `v_rom_blocks` and `v_rom_chunks`. SonLVL uses Uncompressed for both. Chunk IDs are limited to `$7F`, block IDs to `$3FF`. Former RAM buffers are assigned to named engine users; do not assume they are unused scratch memory.
