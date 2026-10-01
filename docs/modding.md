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

## Object placements and state

Ordinary object records are six bytes: X word, Y/flip word, object ID/remember byte, subtype. Sort by X and terminate with `$FFFF` X. Each placed object has respawn state. Use the `respawn_entry` macro; `$14–$15` is the state pointer. `$23` is reserved for sub-sprite count. Preserve `d7`, the object executor counter, in helpers called while an object runs.

## Ordinary ring lists

Placed rings use four-byte S3K records in `objpos/Rings/`: X word and Y word, sorted by X, terminated by `$FFFFFFFF`. Each act can hold up to 512 rings. SonLVL uses `ringfmt=S3K`. Giant rings remain ordinary objects; lost/debug rings retain their object routines.

## Graphics and DMA

Level resources use moduled Kosinski in `artkosm/`. Add a `plcm` entry and a VRAM tile constant when adding graphics. The bounded PLC/DMA queues must retain their capacity and residency checks. Do not display mappings until their graphics are resident. Keep both SonLVL INIs and object definitions consistent with compression changes.

The VDP DMA source counter wraps within a 128 KiB ROM bank. Giant-ring, flash and Tails player art are aligned and checked during assembly so their transfers cannot cross that boundary. Retain those checks when moving or expanding uncompressed artwork.

## Collision queue

Collidable objects are queued during object execution. Keep the existing count bounds and reset the queue each frame. Sonic reactions consume this queue instead of scanning all object slots.

## Special Stage wall art

Rotated wall graphics are streamed from `artunc/Special Walls.unc`. The source sheet and the DMA slot must match the wall mapping frame dimensions.

## Sub-sprites

Set render bit 6 and a nonzero `obSubSprites` to opt in. Up to seven children use three bytes each at `$29–$3D`: signed X offset, signed Y offset and frame. The parent keeps its normal mapping and graphics. Do not reuse this RAM as object scratch while children are enabled. GHZ bridges provide a grouped-object example.

## Shield, stars and points VRAM

Shield, invincibility and Super stars share the protected `$541–$552` slot and use mutually exclusive loading. Points occupy `$553–$55B`. Keep their tile ranges independent from Game Over and debug text. Loading a new owner must also change the active mappings/DPLC state.

## Ring animation

Ordinary and lost rings stream their animation from `artunc/Ring Frames.unc`; sparkle art remains separately resident. Keep normal pickup bookkeeping and sparkle capacity shared by Light Dash and ordinary contact.

## Debug HUD slots

Coordinate digits use `$570–$57F`; the SPR label/count uses `$55C–$560`. Hide this overlay when another screen owns those tiles, and upload all digits before displaying it again.

## Smashable rocks

The GHZ purple rock has an optional Smashable subtype in both SonLVL definitions. Ordinary placements retain their solid behaviour. Destruction checks rolling and speed, emits debris/points, and retains respawn bookkeeping.

## Resources per act

`_inc/LevelHeaders.asm` holds four header pointers per zone. Each 24-byte header selects primary/secondary PLC addresses, raw blocks/chunks, collision index, normal palette, underwater level/player palettes and music. SBZ3 is internally LZ act 4; Final Zone is SBZ act 3. Change an act header to select independent resources. Keep custom VRAM layouts explicit and synchronize both SonLVL revisions.

## Music per act

The final act-header field selects the level song. Restoration considers drowning, boss state, Super and invincibility. Boss completion clears the boss override; speed shoes adjust tempo without restarting an ordinary track.

## Character resources

`_inc/Character Assets.asm` adapts Selbi's [Adding Extra Characters](https://info.sonicretro.org/SCHG_How-to:Add_Extra_Characters) guide. Each registered character has two ROM descriptors, normal and Super. They select uncompressed player art, mappings, DPLC, animation scripts, dry/LZ/SBZ3 palettes, Super palette cycles, speed-dependent animation scripts and the lives-icon PLC. Sonic and solo Tails are registered. Tails uses the same descriptor for both forms and is excluded from Super activation.

`v_character_p1` and `v_character_p2` store character IDs without moving existing RAM fields. They default to Sonic and OFF (`$FF`) and survive act transitions. Title OPTIONS selects P1; P2 reserves a selection for future multiplayer and cannot be enabled. A second player object, separate physics and Super state are not implemented. SRAM version 2 persists the selections and accepts version 1 settings records.

`GetCharacterAssets` takes the slot in `d0.w` (0 or 1) and form in `d1.b` (zero for normal, nonzero for Super), and returns a descriptor in `a3`. It preserves other registers and condition flags. Invalid slots select P1; invalid character IDs use Sonic's resources. `GetPlayer1Assets_Normal`, `GetPlayer1Assets_Super` and `GetPlayer1Assets_Current` supply the active player's selection. The `character_asset` macro reads a pointer field and preserves `a3`; its destination must not be `a3`.

To register another character, add an ID in `_Constants.asm`, increase `Character_Count`, and append a normal/Super pointer pair to `CharacterAssets`. Create both records using the `CharacterAsset_*` offsets. Add an eight-character name in `Options_Names`, palette entries and a dedicated lives-icon PLC as needed. Existing PLC IDs must retain their order. Descriptor sizes and table counts are checked during assembly.

The animation driver still expects Sonic's animation IDs, frame conventions and orientation groups: normal walking uses six frames per orientation, Super walking uses eight, and the fast normal run uses the descriptor's figure-eight script. Tails supplies a normal running cycle for that slot. New artwork must follow these conventions or receive a dedicated animation driver. Movement abilities, collision dimensions and character-specific cinematic artwork require separate implementation.

`_incObj/Tails Flight.asm` implements solo flight and swimming. B/C starts flight or adds an ascent pulse; A retains Light Dash. The eight-second endurance and flight flags reset on landing, damage, death and debug placement. Tails uses the existing player collision dimensions. The importer adapts Sonic 3 & Knuckles mapping origins and samples six walk frames per orientation. Separate tail frames are packed with the body, keeping every DMA frame within the existing 32-tile player slot. Large ending illustrations remain Sonic's artwork and restore its normal palette when the cinematic starts.

The shared-art range is inclusive at `SharedFirst` and exclusive at `SharedEnd`; equal values disable it. Super Sonic uses this range for the original spring/air-pose art. DPLC offsets within that range refer to `SharedArt`. Super palette cycles retain the existing eight-byte frame format, transformation/reversion sequence and ten steady frames. Palette refresh changes only indices 2–5, so replacement characters must account for the other shared colours.

Normal Sonic retains the player-water palette ID from the act header; other registered characters use their descriptor's LZ or SBZ3 ID. The lives icon is queued when the title, level or Special Stage results load. If a selection changes during gameplay, update mappings and palettes and invalidate `v_sonframenum` before drawing: the frame cache alone cannot detect a different art source.
