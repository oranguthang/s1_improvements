# Credits and sources

Sonic the Hedgehog and its game assets belong to Sega and their respective creators. The assembly foundation is the [Sonic Retro Sonic 1 disassembly](https://github.com/sonicretro/s1disasm). Technical guides are available in the [Sonic Retro How-To collection](https://info.sonicretro.org/SCHG_How-to:Guide).

Modifications are maintained by oranguthang. Included third-party tools retain their own license files and attribution. Asset source checksums identify the exact input files used by the resource tools.

## Player and palette resources

Super Sonic player art, mappings, dynamic graphics, transformation effects and dry palette originate from the [Sonic 2 disassembly](https://github.com/sonicretro/s2disasm). Game-specific underwater cycles and shared-resource palette remaps adapt these assets for Sonic 1.

Character resource selection adapts Selbi's [Adding Extra Characters](https://info.sonicretro.org/SCHG_How-to:Add_Extra_Characters) guide, based on Sonic 65's original work. ROM descriptors extend the approach to separate player selections and normal/Super resource sets.

Solo Tails body/tail art and Knuckles art, mappings, DPLC and lives icons originate from the [Sonic 3 & Knuckles disassembly](https://github.com/sonicretro/skdisasm), using the resource versions in [sk_improvements](https://github.com/oranguthang/sk_improvements). The importer repacks the frames and adapts palette indices and origins for Sonic 1. Flight uses the ascent-pulse and endurance approach from Sonic 3 & Knuckles. Knuckles gliding, climbing and ledge transitions adapt its movement rules to Sonic 1 terrain collision.

## Title resources

The independent title resources follow [Make an Alternative Title Screen](https://info.sonicretro.org/SCHG_How-to:Make_an_Alternative_Title_Screen). The source archive is retained with the resource inputs for repeatable extraction.

## MD Debugger

MD Debugger and ConvSym are by [Vladikcomper](https://github.com/vladikcomper/md-modules). The included MIT license is in `_debug/md-debugger/LICENSE`.

## Movement artwork

Figure-eight and spring poses use resources from the [Sonic CD disassembly](https://github.com/sonicretro/scddisasm). Indexed pixels and mapping origins are preserved by the import tools.

Falling frames are supplied by the [Sonic Retro falling-sprite tutorial](https://info.sonicretro.org/SCHG_How-to:Add_a_Falling_Animation). The original source images accompany the import inputs.
