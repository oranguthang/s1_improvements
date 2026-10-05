# Credits and sources

Sonic the Hedgehog and its game assets belong to Sega and their respective creators. The assembly foundation is the [Sonic Retro Sonic 1 disassembly](https://github.com/sonicretro/s1disasm). Technical guides are available in the [Sonic Retro How-To collection](https://info.sonicretro.org/SCHG_How-to:Guide).

Modifications are maintained by oranguthang. Included third-party tools retain their own license files and attribution. Asset source checksums identify the exact input files used by the resource tools.

## Player and palette resources

Super Sonic player art, mappings, dynamic graphics, transformation effects and dry palette originate from the [Sonic 2 disassembly](https://github.com/sonicretro/s2disasm). Game-specific underwater cycles and shared-resource palette remaps adapt these assets for Sonic 1.

Character resource selection adapts Selbi's [Adding Extra Characters](https://info.sonicretro.org/SCHG_How-to:Add_Extra_Characters) guide, based on Sonic 65's original work. ROM descriptors extend the approach to separate player selections and normal/Super resource sets.

Solo Tails body/tail art and Knuckles art, mappings, DPLC and lives icons originate from the [Sonic 3 & Knuckles disassembly](https://github.com/sonicretro/skdisasm), using the resource versions in [sk_improvements](https://github.com/oranguthang/sk_improvements). The importer repacks the frames and adapts palette indices and origins for Sonic 1. Flight uses the ascent-pulse and endurance approach from Sonic 3 & Knuckles; tail attacks use its Touch_Enemy/Check_TailsAttack angle check. Knuckles gliding, climbing and ledge transitions adapt its movement rules to Sonic 1 terrain collision.

Super Tails and Super Knuckles adapt Sonic 3 & Knuckles' `Tails_Transform`/`Knux_Transform`, the `PalCycle_SuperTails` and `PalCycle_SuperHyperKnuckles` colour cycles and the transformation poses. Super Flickies port `Obj_SuperTailsBirds` with its bird art and mappings; underwater cycles are derived from them for Sonic 1's water palettes.

Tails and Knuckles signpost portraits also use the original S3K end-sign art and DPLC. The 1UP monitor portraits reuse the S3K lives icons. Act-clear character names reuse the Sonic 1 title-card alphabet.

Their character-specific endings use the official Sonic the Hedgehog mobile remaster artwork, extracted by Parky33 and available in the [Ending sprite sheet](https://www.spriters-resource.com/mobile/sonicthehedgehogmobile/asset/65174/). The importer preserves pixel shapes and pose dimensions, adapts colours to the shared player palette and repacks mapping origins for the existing ending graphics slot. The blue emerald uses the independent sky palette.

## Title cards

The extended title card system and font come from [Extend Title Cards in Sonic 1](https://info.sonicretro.org/SCHG_How-to:Extend_Title_Cards_in_Sonic_1): main system by Selbi, AS port and result screens by RobiWanKenobi, lowercase letters from Yuu Yuu Hakusho: Makyou Toitsusen, missing uppercase JQVWX by SameyTheHedgie, title-case "Act" and lowercase "a" by MDTravis, and the act 4 number by Cinossu. The downloaded archive is kept with the resource inputs; this project adds gray oval copies and the solo character names.

## Credits text

The optional text credits follow [Use Plane Mappings for Credits in Sonic 1](https://info.sonicretro.org/SCHG_How-to:Enigma_Credits_in_Sonic_1) by Fukuller, updated and expanded by Selbi, including its sample 16x16 font. The "2" comes from the original Sonic 1 credits font.

## Title resources

The independent title resources follow [Make an Alternative Title Screen](https://info.sonicretro.org/SCHG_How-to:Make_an_Alternative_Title_Screen). The source archive is retained with the resource inputs for repeatable extraction.

## Water rendering

The surface-free water options follow ProjectFM's [Removing the Water Surface Object in Sonic 1](https://sonicresearch.org/community/index.php?threads/removing-the-water-surface-object-in-sonic-1.5975/), including MarkeyJester's correction for latching the displayed water scanline during VBlank. The gradual option transfers three colours per scanline as Sonic 3 & Knuckles does; the line option instead blanks one line and copies the full underwater palette by DMA, as Sonic 3 & Knuckles' Competition-mode H-int blanks the display for its mid-frame DMA.

## MD Debugger

MD Debugger and ConvSym are by [Vladikcomper](https://github.com/vladikcomper/md-modules). The included MIT license is in `_debug/md-debugger/LICENSE`.

## Movement artwork

Figure-eight and spring poses use resources from the [Sonic CD disassembly](https://github.com/sonicretro/scddisasm). Indexed pixels and mapping origins are preserved by the import tools.

Falling frames are supplied by the [Sonic Retro falling-sprite tutorial](https://info.sonicretro.org/SCHG_How-to:Add_a_Falling_Animation). The original source images accompany the import inputs.
