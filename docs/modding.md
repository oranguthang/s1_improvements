# Modding reference

## Feature options

The `Feature*` switches in `sonic.asm` turn this project's gameplay additions on (1, the default) or off (0). Off restores the original Sonic 1 behaviour for that feature only. The code stays assembled but is never entered, so a feature can be switched off without moving data or touching other features. The default build is unchanged by these switches.

| Option | When 0 |
|---|---|
| `FeatureSpinDash` | Down+A/B/C while ducking jumps as in the original game. |
| `FeaturePeelOut` | Up+A/B/C jumps. |
| `FeatureAirRoll` | Pressing A/B/C again in the air does nothing. |
| `FeatureHomingAttack` | No Jump Dash or Homing Attack. |
| `FeatureLightDash` | No Light Dash. |
| `FeatureSpringPoses` | Normal Sonic uses the original single spring pose, and no character switches to a falling pose. |
| `FeatureExtendedCamera` | The camera keeps the original fixed focus. |
| `FeatureMomentum` | Input caps ground and air speed at the running limit, as in the original game. |
| `FeatureRollJumpSteering` | A jump from a roll locks midair steering again. |
| `FeatureInstantTally` | Act and Special Stage bonuses always count down. |
| `FeatureExtraLives` | Rings award lives only at 100 and 200. |
| `FeatureLamppostRings` | Restarting from a lamppost starts with no rings. Returning from a giant ring still keeps them. |
| `FeatureSuper` | No character can transform, and the good ending keeps the normal form. The CHEATS ring settings stay but have no effect. |
| `FeatureTails`, `FeatureKnuckles` | OPTIONS skips that character, and a saved selection of it falls back to Sonic. Its art, ending and code stay in the ROM. |

## Shared palettes

The selected solo character owns the protected colours at indices 2–5 of palette line 0: blue for Sonic or orange for Tails. Knuckles uses 2/4/5 for red/pink fur and 3 for green shoe panels. Each has dry, Labyrinth and Scrap Brain Act 3 palettes. Gameplay objects and badniks keep stable colours outside these slots, allowing future Super forms to cycle fur independently of them. Each Super cycle writes indices 2–5 as well. Super Tails' first entry repeats his normal index 2, and Super Knuckles' second entry repeats his normal index 3, so his green shoe panels never cycle. Simultaneous players with independent fur ramps would require a separate palette allocation and further resource changes.

The remaining colours are black at 1, white at 6, gray at 7/8/9, skin at A/B, red shades at C/D/E and yellow at F. All character palettes agree outside the protected slots, preserving the original Sonic 1 object colours and three gray shades. Knuckles' cuffs use shared yellow and tan instead of replacing the dark red or yellow entries with orange.

Shared level objects and badnik art use stable indices for affected details. Their gray, red and yellow indices stay intact. Mixed sheets retain tiles belonging only to other palette lines. HUD labels and counters use the level's first palette line for yellow and white; player portraits keep line 0. Graphic resources are shared rather than duplicated just to recolour them. Flicky feathers use the shared red shoe shades C/D/E, so released birds and ending birds keep their colours during player palette changes. The shield and its monitor icon use stable gray shades; the shield icon and static screen frames in the monitor sheet are remapped. Hidden end-of-act bonus objects remap only character indices 2–5 to gray; their shared red, yellow, tan and white details keep their original colours. Invincibility stars retain the active character colours. `player palette` reproduces the palettes and HUD index changes from the checked source bundle.

## Underwater colour transition

Choose the Labyrinth and Scrap Brain Act 3 water surface in `sonic.asm`. Set exactly one of `WaterSurfaceSprites`, `WaterSurfaceLine` and `WaterSurfaceGradual` to 1; any other combination stops the build with an error.

- `WaterSurfaceSprites` keeps the original surface sprites. H-int is raised at the surface and `HBlank` copies the whole underwater palette behind them. Ripples start at `v_waterpos1`.
- `WaterSurfaceLine` has no surface sprites. H-int is raised on the line above the surface. `HBlank` waits on the VDP V counter, disables the display for one line, copies the whole underwater palette by DMA, and enables the display at the end of that line. Every layer, object and player changes on the same line, `WaterSurface_FirstLine` lines below `v_waterpos1`, directly under splashes. The blanked line shows the backdrop colour `WaterSurface_Backdrop`: colour 0 of the second palette line, which tiles and sprites never draw. `PalCycle_LZ` cycles it through `palette/Cycle - LZ Water Edge.bin` or `palette/Cycle - SBZ3 Water Edge.bin`, writing the same shade to both buffers so the line cannot change colour while the palette is copied. The level palettes hold the first shade; the underwater ones keep it through the `colours` override in `tools/data/shared_player_palette.json`. Sprites may be skipped on the line after the edge. Main-loop code must not program VDP DMA or addresses while H-int is enabled.
- `WaterSurfaceGradual` (default) has no surface at all. As in Sonic 3 & Knuckles, `WaterTransition_LZ` in `_inc/LZWaterFeatures.asm` lists three-colour transfers, one per scanline. Each word is a byte offset into the live underwater palette; each transfer covers that colour and the next two. Groups are ranked by the screen area they recolour, so the background, foreground and player change at the splash line and less common colours follow up to 18 lines lower. Only colours that differ underwater are listed: when adding a character, palette or cycle, include any colour whose dry and underwater values differ (`test_water_transition_covers_changed_colours` checks this). Keep offsets even, within one palette line, and preserve the timing loops in `HBlank`. `VBlank_WaterPalette` preloads groups clipped above the screen.

Without surface sprites both planes ripple from the first underwater line. `LZWater_UpdateBoundary` runs after camera scrolling so the palette boundary and row scroll use the same viewport, and `VBlank_WaterPalette` latches the H-int line together with the palette loaded at the top of the frame. Keep interrupts masked throughout `HBlank`, including its deferred screen and sound updates: the sound driver and VDP transfers cannot safely be re-entered by VBlank. `enable_display` and `disable_display` keep `v_vdp_buffer1` current because the line option restores the display from it.

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

Shield, invincibility, Super stars and Super Tails' Flickies share the protected `$541–$552` slot and use mutually exclusive loading. `v_shieldartkey` names the resident owner: a shield/stars DPLC key, `$4000` for Super stars or `$4001` for the 14 Flicky tiles. Points occupy `$553–$55B`. Keep their tile ranges independent from Game Over and debug text. Loading a new owner must also change the active mappings/DPLC state.

## Ring animation

Ordinary and lost rings stream their animation from `artunc/Ring Frames.unc`; sparkle art remains separately resident. Keep normal pickup bookkeeping and sparkle capacity shared by Light Dash and ordinary contact.

## Debug HUD slots

Coordinate digits use `$570–$57F`; the SPR label/count uses `$55C–$560`. Hide this overlay when another screen owns those tiles, and upload all digits before displaying it again.

## Debug placement lists

`_incObj/DebugMode.asm` keeps one item list per zone. The `dbugcommon` macro at the top of each list places the objects whose art every zone loads: a ring, the rings, shield, speed shoes, invincibility, extra-life and Eggman monitors, and a lamppost. Add a zone-specific object to that zone's list only when its art is loaded there.

## Animation frame limits

`AnimateSprite` accepts frames $00–$F9 for every object; $FA–$FF remain the script commands. `BuildSprites` reads mapping frames up to $FF. Six original objects still put `aniXFlip`/`aniYFlip` in their scripts and therefore keep frames $00–$1F: Crabmeat, the MZ/SLZ fireballs, the MZ boss fire, the MZ burning grass and both SBZ spinning platforms. `Anim_SetFrameAndFlipFlags` lists their IDs. New objects should mirror sprites with separate mappings instead of these flags.

## Smashable rocks

The GHZ purple rock has an optional Smashable subtype in both SonLVL definitions. Ordinary placements retain their solid behaviour. Destruction checks rolling and speed, emits debris/points, and retains respawn bookkeeping.

## Resources per act

`_inc/LevelHeaders.asm` holds four header pointers per zone. Each 24-byte header selects primary/secondary PLC addresses, raw blocks/chunks, collision index, normal palette, underwater level/player palettes and music. SBZ3 is internally LZ act 4; Final Zone is SBZ act 3. Change an act header to select independent resources. Keep custom VRAM layouts explicit and synchronize both SonLVL revisions.

## Music per act

The final act-header field selects the level song. Restoration considers drowning, boss state, Super and invincibility. Boss completion clears the boss override; speed shoes adjust tempo without restarting an ordinary track.

## Sound IDs

Sound IDs use the whole byte, following [Expand the Sonic 1 sound index](https://info.sonicretro.org/SCHG_How-to:Expand_the_Sonic_1_sound_index): music $01–$7F, sound effects $A0–$CF, the waterfall special sound $D0, added sound effects $D1–$FA (`ExtSoundIndex`) and the commands fade, SEGA, speed up, slow down and stop at $FB–$FF. $00 stops all sound, and $80 stays reserved as the driver's empty slot, which caps music below it. `SoundPriorities` covers every ID, and the build checks the ranges. Always use the `bgm_*`/`sfx_*` constants: the `ptr_mus81`-style labels keep their original Sonic 1 names although music now starts at $01.

To add a song, append its pointer to `MusicIndex` and a `bgm_*` constant before `bgm__Last`; an added sound effect goes into `ExtSoundIndex`. The Level Select sound test plays IDs $00–$FF directly: Left/Right step by one, A skips ahead by $10, B+A goes back by $10, and C or Start plays the selection. With the hidden Japanese credits cheat, $9E and $9F still start the credits and the ending.

## Character resources

`_inc/Character Assets.asm` adapts Selbi's [Adding Extra Characters](https://info.sonicretro.org/SCHG_How-to:Add_Extra_Characters) guide. Each registered character has two ROM descriptors, normal and Super. They select uncompressed player art, mappings, DPLC, animation scripts, dry/LZ/SBZ3 palettes, Super palette cycles, speed-dependent animation scripts and the lives-icon PLC. Sonic, solo Tails and solo Knuckles are registered. The Super records of Tails and Knuckles reuse their normal art, mappings, DPLC and animations and differ only in palettes and cycles. The last bytes of each record are `CharacterAsset_CycleStep`, `CycleHold` and `CycleLast`: game frames per steady palette entry, frames shown on the last entry before looping, and the byte offset of that last entry. The loop restarts at offset `$30`, after the six transformation entries.

`v_character_selected` stores the persistent solo choice in reserved settings RAM. `v_character_p1` holds the active scene character. `UpdateSceneCharacter` applies the saved choice at the game-mode dispatcher only for interactive levels and Special Stages; presentation scenes, attract demos and credit demos always use Sonic. Special Stage results also switch to Sonic, and the next playable level restores the saved choice. Existing RAM fields retain their addresses. Title OPTIONS selects the character; multiplayer and Competition modes are not supported. SRAM version 2 persists the selection and accepts version 1 settings records. The unused `v_character_p2` byte stays `$FF` solely for compatibility with the existing SRAM layout; it is not a menu option.

`GetCharacterAssets` takes the slot in `d0.w` (0 or 1) and form in `d1.b` (zero for normal, nonzero for Super), and returns a descriptor in `a3`. It preserves other registers and condition flags. Invalid slots select P1; invalid character IDs use Sonic's resources. `GetPlayer1Assets_Normal`, `GetPlayer1Assets_Super` and `GetPlayer1Assets_Current` supply the active player's selection. The `character_asset` macro reads a pointer field and preserves `a3`; its destination must not be `a3`.

To register another character, add an ID in `_Constants.asm`, increase `Character_Count`, and append a normal/Super pointer pair to `CharacterAssets`. Create both records using the `CharacterAsset_*` offsets. Add an eight-character name in `Options_Names`, palette entries and a dedicated lives-icon PLC as needed. Existing PLC IDs must retain their order. Descriptor sizes and table counts are checked during assembly.

The animation driver still expects Sonic's animation IDs, frame conventions and orientation groups: normal walking uses six frames per orientation, Super walking uses eight, and the fast normal run uses the descriptor's figure-eight script. Tails and Knuckles supply normal running cycles for that slot. New artwork must follow these conventions or receive a dedicated animation driver. Movement abilities, collision dimensions and character-specific cinematic artwork require separate implementation.

`_incObj/Tails Flight.asm` implements solo flight and swimming. A/B/C starts flight or adds an ascent pulse; A takes Light Dash first when a ring chain is in reach. The eight-second endurance and flight flags reset on landing, damage, death and debug placement. Tails uses the existing player collision dimensions. The importer adapts Sonic 3 & Knuckles mapping origins and samples six walk frames per orientation. Separate tail frames are packed with the body, keeping every DMA frame within the existing 32-tile player slot.

`_incObj/Knuckles Glide.asm` implements solo gliding, terrain-wall climbing, wall jumps and ledge transitions. Its compact glide hitbox returns to the standing size after release, landing, damage or death. Gliding attacks enemies, monitors and compatible smashable walls. Ordinary solid objects remain non-climbable. The S3K importer preserves indexed pixels, packs each frame into the same 32-tile player slot and maps the normal/Super resource pair to the normal artwork. Knuckles uses a lower jump than Sonic and keeps normal running poses at high speed.

`_incObj/8E Super Tails Flickies.asm` ports S3K's `Obj_SuperTailsBirds`. `Sonic_ActivateSuper` spawns the four birds in the stars' object slots `v_starsobj1`–`v_starsobj4`; reversion and death clear the Super stars only when that slot really holds them, so the Flickies can fly away. A bird targets objects whose collision type is a badnik or boss (`obColType` nonzero, top bits clear), reading the collision queue and falling back to a scan of level object RAM. Hits reuse `React_DestroyBadnik` (points combo, animal and explosion) and `React_DamageBoss` (boss hit counter and defeat flag) from `Sonic ReactToItem.asm`, so player collisions and Flickies score identically. The include stays at the end of the object code: placing it near object $8D pushes existing short branches in Scrap Brain objects out of range.

The shared-art range is inclusive at `SharedFirst` and exclusive at `SharedEnd`; equal values disable it. Super Sonic uses this range for the original spring/air-pose art. DPLC offsets within that range refer to `SharedArt`. Super palette cycles retain the existing eight-byte frame format and transformation/reversion sequence; the steady-frame count and timing come from the descriptor. Palette refresh changes only indices 2–5, so replacement characters must account for the other shared colours.

Normal Sonic retains the player-water palette ID from the act header; other registered characters use their descriptor's LZ or SBZ3 ID. The lives icon is queued when the title, level or Special Stage results load. If a selection changes during gameplay, update mappings and palettes and invalidate `v_sonframenum` before drawing: the frame cache alone cannot detect a different art source.
