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
| `FeatureS2Stars` | Invincibility shows Sonic 1's four trailing stars instead of Sonic 2's (both use the shared white and gray). |
| `FeatureVictoryPoses` | After the signpost the player runs off to the right, and after a capsule walks right, as in the original game. |
| `FeatureS3KDrums` | With the Sonic 3 & Knuckles driver, Sonic 1 songs play Sonic 1's own kick, snare and timpani samples. |

The attract and credits demos were recorded for the original controls, so while `f_demo` is set the button moves (Spin Dash, Peel-Out, Air Roll, Jump Dash and Homing Attack, Light Dash) stay off. A new move started from a button press needs the same `f_demo` check.

`FeatureSoundDriver` chooses the sound driver: 2 (the default) is Flamewing's Flamedriver, the Sonic 3 & Knuckles Z80 driver; 1 is Sonic 1's 68000 driver with Mega PCM 2; 0 is Sonic 1's 68000 driver with its original Z80 DAC driver. See Sound driver below.

Five optional alternatives are off by default; 1 enables them:

| Option | When 1 |
|---|---|
| `FeatureCDDrowning` | As in Sonic CD's Tidal Tempest, the music keeps playing below 12 seconds of air and an unused Sonic 1 sound ($AB) beeps every second; the countdown numbers still appear. Music changes are no longer held back while air is low. |
| `FeatureTextCredits` | The credits pages are plain text in `_inc/Credits Text.asm`, drawn on plane A with a 16x16 font (see Credits text below). |
| `Feature7thEmerald` | A seventh, cyan Chaos Emerald and Special Stage 7 (see Seventh Chaos Emerald below). Super forms and the good ending then need all seven. |
| `FeatureCentiseconds` | The HUD clock also shows hundredths of a second, `0:00:00`, as in Sonic CD (see HUD centiseconds below). |
| `FeatureInfiniteLives` | The lives counter is hidden and dying never ends the game. Rings, score and Special Stage items no longer award lives or continues, and 1-up monitors give 10 rings. Time Over still restarts the act. |

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

## Title cards

Level, end-of-act and Special Stage results cards come from `_inc/Title Cards Extended.asm`, after [Extend Title Cards in Sonic 1](https://info.sonicretro.org/SCHG_How-to:Extend_Title_Cards_in_Sonic_1). Each act has its own name, typed as text at the top of the file: uppercase and lowercase letters (now including J, Q, V, W and X) and spaces, at most 20 characters. The `maketitlecard` macro builds the sprite mappings, the letter list and the card's movement data at assembly time, and only the letters a card uses are written to VRAM. Level cards also cover act 4 slots. "ZONE", "PASSED", the results headers and the solo names ("SONIC HAS", "TAILS HAS", "KNUCKLES HAS") are set there too; a solo name may use at most 11 letters.

`artunc/Title Cards Extended.unc` is generated by `player ui`: the downloaded font followed by gray copies of the big and small ovals. Level and end-of-act cards use the gray copies, so they never pick up the player's fur colours; the Special Stage results keep the original yellow ovals with that screen's own palette. The cards occupy the 128-tile title card slot at `ArtTile_Title_Card`, which the animals and explosions reuse once the cards have left. The include sits after the aligned player art at the end of the ROM so that it cannot shift those DMA banks.

## Credits text

With `FeatureTextCredits`, `_inc/Credits Text.asm` holds the nine credits pages as text, after system 2 of [Use Plane Mappings for Credits in Sonic 1](https://info.sonicretro.org/SCHG_How-to:Enigma_Credits_in_Sonic_1). Each page has exactly 14 lines of 20 characters; uppercase letters, the digit 2 and spaces are allowed, and the `creditsline` macro rejects anything else. `Credits_LoadPageMappings` writes the page to plane A through the RAM buffer at `v_ram_start`, replacing the sprite-based credits object. The 16x16 font (`artkosm/Credits - Text Font.kosm`, 112 tiles at `ArtTile_Credits_Text_Font` up to the plane A table) is generated by `player ui` from the downloaded font plus the "2" of the original credits font. "SONIC TEAM PRESENTS" and "TRY AGAIN" keep the original sprites.

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

The Special Stage gives each character a block colour, the same for every player: Sonic's blue (palette line 0 slots 2–5), Tails' orange (line 1, formerly the yellow blocks) and Knuckles' red (line 2, formerly the pink blocks). Line 0 slots 2–5 hold the player's fur in levels, so the stage does not load the character's fur colours. Instead, `SSPlayer_Assets` gives Tails and Knuckles their own rolling frames ($2E–$32), generated by `s1tools.special_stage`: each frame is drawn in two layers, the details (outline, white, greys, skin, shoes) on line 0, whose shared colours match the levels, and the fur on the character's block line. `Sonic_Animate` and `Sonic_LoadGfx` use these mappings, DPLC and art in the Special Stage. Tails' rolling tails come along: object $8F points them against the velocity turned by `v_ssangle` and loads two-layer tail frames into the slot's last `TailsTailSS_Tiles` tiles. The ramps are in `palette/Special Stage.bin` and match `TAILS_RAMP` and `KNUCKLES_RAMP` in `s1tools.special_stage`. A new character needs an `SSPlayer_Assets` entry (zeros keep its own frames).

## Seventh Chaos Emerald

`Feature7thEmerald` follows Speems' [Add 7th Chaos Emerald and Special Stage](https://info.sonicretro.org/SCHG_How-to:Add_7th_Chaos_Emerald_and_Special_Stage_in_Sonic_1). `ss_emeralds_num` becomes 7, so the stage rotation, the collected list, Super forms, the results screen, "GOT THEM ALL", the ending and the Try Again screen all count seven. `v_emldlist` always has room for seven entries (the RAM layout no longer depends on the option). Special Stage 7 (`sslayout/7.eni`, start position `ss7.bin`) is stage 6 with its grey emerald replaced by block $28, the otherwise unused 1-Up block, which this option turns into the cyan emerald (`id_SS_Emerald7_Cyan`). The layout was made with `s1tools.codecs.enigma.encode`; S1SSEdit lists it as stage 7 but still draws block $28 as a 1-Up. The cyan comes from the grey emerald's tiles in free palette slots, each screen with its own palette file: the Special Stage uses line 1 slots 7–9, the results screen line 3 slots 7–9, and the ending and Try Again screen line 1 slots A, B and F. The ending art has no grey slots there, so `player endings` writes `artkosm/Ending - Seventh Emerald.kosm`, four recoloured tiles loaded at `$524`, where Revision 0's unused Eggman art would go.

## HUD centiseconds

With `FeatureCentiseconds` the clock reads `0:00:00`, after Selbi's [Add Centiseconds HUD](https://info.sonicretro.org/SCHG_How-to:Add_Centiseconds_HUD). `Hud_FramesToCentis` turns the frame counter of the current second into hundredths. The second colon uses the two free tiles `$7BE–$7BF` after the ring sparkles; the digits use `$7FC–$7FF`, after the 224-line horizontal scroll table (`hscroll_table_size`). The clock starts once the level has faded in. Time Over still happens at 9:59.

## Victory poses

With `FeatureVictoryPoses` the signpost and the capsule wait until the player has landed, then `Sonic_StartVictory` locks the controls and stops the player. The results card sets `victorypose` (player SST byte `$39`) in `Got_Main`, once its letters have loaded, so the pose starts together with the card. `Sonic_Move` then selects `id_Victory` ($23) instead of the standing animation. The idea follows AleDrawer2008's [Add Victory Poses In Sonic 1](https://info.sonicretro.org/SCHG_How-to:Add_Victory_Poses_In_Sonic_1): Sonic shows the two-finger pose from that guide (`player air` imports it as `fr_Victory1`/`fr_Victory2`), Tails gives a thumbs-up and kneels (S3K's `AniTails13`, frames $A5 and $A6, at `fr_TailsVictory`) and Knuckles plays S3K's punch and raised fist (`knux_victory_frame`). Every character's animation table needs an entry for $23; Super Sonic's points at his standing animation, because the act results revert Super forms first. The Scrap Brain Act 2 cutscene clears the flag so the player can walk on.

## Sound driver

With `FeatureSoundDriver = 2`, [Flamedriver](https://github.com/flamewing/flamedriver), Flamewing's improved Sonic 3 & Knuckles Z80 driver, plays all music and sound effects. Its files are in `sound/flamedriver/` (`UPSTREAM_COMMIT.txt` names the version; the changes there are the include paths, the sample sets and ID prefixes in `Config.asm`, the quiet `DebugSoundbanks`, a disabled `shared` line, and `Tables.asm`, which replaces the Sonic 3 & Knuckles tables at the end of `Macros.asm`). The Sonic 1 songs and effects stay the SMPS2ASM sources in `sound/music` and `sound/sfx`: SMPS2ASM converts them for the driver while assembling. `sound/S3K Music Bank.asm` and `sound/S3K SFX Bank.asm` place them in the 32 KiB banks the Z80 reads through its ROM window, the DAC samples come from `sound/flamedriver/DACBanks.asm`, and the build compresses the Z80 program into the space reserved by `Size_of_Snd_driver_guess`.

The game keeps its Sonic 1 interface. `QueueSound1`–`QueueSound3`, `f_pausemusic` and `f_speedup` in `v_snddriver_ram` are read by `UpdateMusic` in `sound/S3K Driver.asm` every VBlank, which sends the song, effect, pause or tempo to the driver. Songs and commands go one per frame; a second one waits in its queue slot for the next frame. Speed shoes use the Sonic 3 & Knuckles tempo step of 8. The driver resumes the song under a 1-up by itself, so `v_current_music` keeps the song below it. It saves that song over its sound effect tracks, so nothing may start an effect until the 1-up ends: the driver ignores effects while the 1-up plays, `UpdateMusic` drops the ones queued in the 1-up's frame, and `smpsNop` (`$E2`, the driver's fade-to-previous command, which would end that lock) assembles to nothing in Sonic 1 songs (`sound/flamedriver/_smps2asm_inc.asm`). The pushable block asks for its sound every frame; `UpdateMusic` lets it play out for its 31 frames, as Sonic 1's driver did with `smpsClearPush`. Repeated Spin Dash revs rise in pitch as in Sonic 3 & Knuckles. The SEGA chant is Sonic 1's own sample, resampled by `s1tools sound sega` to the driver's playback rate of about 14.4 kHz (`sound/flamedriver/Sega PCM.bin`); Start on the SEGA screen ends it through `StopSegaPCM`. With this driver the `stopZ80`/`waitZ80`/`startZ80` macros stop the Z80 again around DMA and controller reads; the SEGA screen reads the controller without them so the chant does not stall.

`FeatureS3KDrums` maps the six DAC notes Sonic 1 songs use (`dKick`, `dSnare` and the four timpani pitches) to the Sonic 3 & Knuckles kick, snare and timpani in `Gen_Sample_Table`. The timpani pitches keep Sonic 1's intervals: rates $0B, $0E, $15 and $16 for high, middle, low and very low, and $14 for the plain timpani. Set it to 0 to hear Sonic 1's own samples through the same driver. Every other Sonic 3 & Knuckles and Sonic 2 sample is available to new songs by its SMPS2ASM name.

With `FeatureSoundDriver = 1`, Vladikcomper's [Mega PCM 2](https://github.com/vladikcomper/MegaPCM) replaces Sonic 1's Z80 DAC driver, integrated as in [Add Mega PCM 2 to Sonic 1](https://info.sonicretro.org/SCHG_How-to:Add_Mega_PCM_2_to_Sonic_1). `MegaPCM/` holds the driver blob, its macros and `SampleTable.asm`, whose samples are in `sound/dac/megapcm`. SMPS plays DAC notes $81–$8B through `MPCM_play`; the timpani pitches are separate sample entries. Mega PCM protects itself during DMA, so the `stopZ80`/`waitZ80`/`startZ80` macros assemble to nothing and only `WriteFMI`/`WriteFMII` pause the Z80 around YM2612 writes. The extended integration is included: pausing pauses the sample, the DAC panning follows the track, the DAC fades in and out with the music, and sound effects keep playing during fades. To add a sample, give it a free ID in `SampleTable` (and an `incdac` line) and use that note in a song's DAC track. With 0, `build.lua` compresses the original Z80 driver again. Drivers 0 and 1 build the same ROM as before the Sonic 3 & Knuckles driver was added.

## Sub-sprites

Set render bit 6 and a nonzero `obSubSprites` to opt in. Up to seven children use three bytes each at `$29–$3D`: signed X offset, signed Y offset and frame. The parent keeps its normal mapping and graphics. Do not reuse this RAM as object scratch while children are enabled. GHZ bridges provide a grouped-object example.

## Shield, stars and points VRAM

With `FeatureS2Stars` the invincibility stars are object $02 (`_incObj/02 Invincibility Stars S2.asm`), a port of Sonic 2's obj35 after KoiSAKANA's [guide](https://info.sonicretro.org/SCHG_How-to:Port_Sonic_2_invincibility_stars_to_Sonic_1). Four groups of two sub-sprites circle and trail the player. Their 34 tiles are DMA-transferred once to `$55E–$57F`, the Game Over area, which they can share because death, the act results and the giant ring all end invincibility; the debug coordinates stay hidden while the player is invincible. Otherwise shield, invincibility, Super stars and Super Tails' Flickies share the protected `$541–$552` slot and use mutually exclusive loading. `v_shieldartkey` names the resident owner: a shield/stars DPLC key, `$4000` for Super stars or `$4001` for the 14 Flicky tiles. Points occupy `$553–$55B`. Keep their tile ranges independent from Game Over and debug text. Loading a new owner must also change the active mappings/DPLC state.

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

To add a song, append its pointer to `MusicIndex` and a `bgm_*` constant before `bgm__Last`; an added sound effect goes into `ExtSoundIndex`.

The Sonic 3 & Knuckles driver keeps the same ranges for the game, but the order of `Gen_Music_Table` and `Gen_Sound_Table` in `sound/flamedriver/Tables.asm` decides the IDs: music from $01 and sound effects from $A0, the waterfall and the added effects included, up to $D4; `_Constants.asm` derives every `sfx_*` from the driver's `zsfx_*` ID. The commands keep $FB–$FF. To add a song, declare it in `Gen_Music_Table` and include it as `Mus_<name>` in `sound/S3K Music Bank.asm` (a full bank fails the build; a new bank starts with `startBank`, `Music_Master_Table` and the `UniBank.asm` include); to add an effect, declare it in `Gen_Sound_Table` and include it as `Sound_<name>` in `sound/S3K SFX Bank.asm`. Keep `RingLeft` right after `Ring`. Sonic 1's `smpsClearPush` and `smpsStopSpecial` do not exist in this driver; wrap Sonic 1-only flags in `if SonicDriverVer==1`. The Level Select sound test plays IDs $00–$FF directly: Left/Right step by one, A skips ahead by $10, B+A goes back by $10, and C or Start plays the selection. With the hidden Japanese credits cheat, $9E and $9F still start the credits and the ending.

## Character resources

`_inc/Character Assets.asm` adapts Selbi's [Adding Extra Characters](https://info.sonicretro.org/SCHG_How-to:Add_Extra_Characters) guide. Each registered character has two ROM descriptors, normal and Super. They select uncompressed player art, mappings, DPLC, animation scripts, dry/LZ/SBZ3 palettes, Super palette cycles, speed-dependent animation scripts and the lives-icon PLC. Sonic, solo Tails and solo Knuckles are registered. The Super records of Tails and Knuckles reuse their normal art, mappings, DPLC and animations and differ only in palettes and cycles. The last bytes of each record are `CharacterAsset_CycleStep`, `CycleHold` and `CycleLast`: game frames per steady palette entry, frames shown on the last entry before looping, and the byte offset of that last entry. The loop restarts at offset `$30`, after the six transformation entries.

`v_character_selected` stores the persistent solo choice in reserved settings RAM. `v_character_p1` holds the active scene character. `UpdateSceneCharacter` applies the saved choice at the game-mode dispatcher only for interactive levels and Special Stages; presentation scenes, attract demos and credit demos always use Sonic. Special Stage results also switch to Sonic, and the next playable level restores the saved choice. Existing RAM fields retain their addresses. Title OPTIONS selects the character; multiplayer and Competition modes are not supported. SRAM version 2 persists the selection and accepts version 1 settings records. The unused `v_character_p2` byte stays `$FF` solely for compatibility with the existing SRAM layout; it is not a menu option.

`GetCharacterAssets` takes the slot in `d0.w` (0 or 1) and form in `d1.b` (zero for normal, nonzero for Super), and returns a descriptor in `a3`. It preserves other registers and condition flags. Invalid slots select P1; invalid character IDs use Sonic's resources. `GetPlayer1Assets_Normal`, `GetPlayer1Assets_Super` and `GetPlayer1Assets_Current` supply the active player's selection. The `character_asset` macro reads a pointer field and preserves `a3`; its destination must not be `a3`.

To register another character, add an ID in `_Constants.asm`, increase `Character_Count`, and append a normal/Super pointer pair to `CharacterAssets`. Create both records using the `CharacterAsset_*` offsets. Add an eight-character name in `Options_Names`, palette entries and a dedicated lives-icon PLC as needed. Existing PLC IDs must retain their order. Descriptor sizes and table counts are checked during assembly.

The animation driver still expects Sonic's animation IDs, frame conventions and orientation groups. `CharacterAsset_WalkFrames` (the descriptor's last byte) selects six or eight walking frames per floor orientation, after [Support 8 Walk/Run Frames](https://info.sonicretro.org/SCHG_How-to:Support_8_Walk/Run_Frames_in_Sonic_1): Sonic uses six; Tails and Knuckles use all eight S3K walk frames from separate blocks at `fr_TailsWalk` and `knux_walk_frame`. Scripts that share the frame index with an eight-frame walk, such as the run, must pad to eight entries. Super Sonic keeps his own eight-frame walk, and the fast normal run uses the descriptor's figure-eight script. Tails and Knuckles supply normal running cycles for that slot. New artwork must follow these conventions or receive a dedicated animation driver. Movement abilities, collision dimensions and character-specific cinematic artwork require separate implementation.

`_incObj/Tails Flight.asm` implements solo flight and swimming. A/B/C starts flight or adds an ascent pulse; A takes Light Dash first when a ring chain is in reach. The eight-second endurance and flight flags reset on landing, damage, death and debug placement. Tails uses the existing player collision dimensions. The importer adapts Sonic 3 & Knuckles mapping origins. Walking, running, hurt and other poses whose tails are part of the S3K body art keep them in the body frame.

`_incObj/8F Tails Tail.asm` ports S3K's `Obj_Tails_Tail`. While Tails is selected, `SonicPlayer` spawns it in `v_tailsobj` (object slot 14). Every frame it copies the player's position, facing, priority and plane priority, then picks a tail animation from Tails' animation ID (`TTail_AniSelection`): swish while waiting or ducking, a flick on looking up, directional tails while rolling or jumping, spin dash, skid, push, balance and the flight rotor (slow when the flight time has run out). Pushing reuses the walk animation in S1, so a walk animation with status bit 5 set selects the push tails. Rolling tails point against the velocity in eight headings, with a four-step swish. Tail art is DMA-transferred to `ArtTile_Tails_Tail`, the second half of the 32-tile player slot. Body frames shown with a separate tail therefore fit in 16 tiles, which `player tails` checks. When a larger body frame covers that half, the tail hides for that frame and reloads afterwards. The tail blinks with the player after damage, hides in debug placement and deletes itself once the player object is replaced, for example by an ending or results object. To give another character separate tails or similar pieces, reuse this object with its own art, mappings, DPLC and selection table.

`_incObj/Knuckles Glide.asm` implements solo gliding, terrain-wall climbing, wall jumps and ledge transitions. Its compact glide hitbox returns to the standing size after release, landing, damage or death. Gliding attacks enemies, monitors and compatible smashable walls. Ordinary solid objects remain non-climbable. The S3K importer preserves indexed pixels, packs each frame into the same 32-tile player slot and maps the normal/Super resource pair to the normal artwork. Knuckles uses a lower jump than Sonic and keeps normal running poses at high speed.

`_incObj/8E Super Tails Flickies.asm` ports S3K's `Obj_SuperTailsBirds`. `Tails_SpawnFlickies` spawns the four birds in the stars' object slots `v_starsobj1`–`v_starsobj4` when Super Tails breaks an 'S' monitor (`Pow_ChkS`), as in the S3K prototypes; `Sonic_ActivateSuper` gives Super Tails no stars; reversion and death clear the Super stars only when that slot really holds them, so the Flickies can fly away. A bird targets objects whose collision type is a badnik or boss (`obColType` nonzero, top bits clear), reading the collision queue and falling back to a scan of level object RAM. Hits reuse `React_DestroyBadnik` (points combo, animal and explosion) and `React_DamageBoss` (boss hit counter and defeat flag) from `Sonic ReactToItem.asm`, so player collisions and Flickies score identically. The include stays at the end of the object code: placing it near object $8D pushes existing short branches in Scrap Brain objects out of range.

The shared-art range is inclusive at `SharedFirst` and exclusive at `SharedEnd`; equal values disable it. Super Sonic uses this range for the original spring/air-pose art. DPLC offsets within that range refer to `SharedArt`. Super palette cycles retain the existing eight-byte frame format and transformation/reversion sequence; the steady-frame count and timing come from the descriptor. Palette refresh changes only indices 2–5, so replacement characters must account for the other shared colours.

Normal Sonic retains the player-water palette ID from the act header; other registered characters use their descriptor's LZ or SBZ3 ID. The lives icon is queued when the title, level or Special Stage results load. If a selection changes during gameplay, update mappings and palettes and invalidate `v_sonframenum` before drawing: the frame cache alone cannot detect a different art source.
