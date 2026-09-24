# Modding reference

## Shared palettes

Sonic cycles palette indices 2–5. Shared level objects and badnik art use stable indices for affected details. Choose palette lines deliberately when adding sprites; graphic resources are shared rather than duplicated just to recolour them.

## Placing giant rings

In either SonLVL project use object `$4B`. Subtype `$00` is an act-end ring with the ring threshold; `$01` and `$02` are independently tracked free rings. Place them with suitable solid ground below. VRAM is shared with transient effects, so retain the existing X/Y visibility guard and wait for graphics residency before drawing the flash.
