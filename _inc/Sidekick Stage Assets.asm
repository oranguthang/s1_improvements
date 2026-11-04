; Palette-specific copies. Original scenery tiles keep their colours.
KosM_SidekickSYZ: binclude "artkosm/sidekick/8x8 - SYZ Paired.kosm"
        even
Blk16_SidekickSYZ: binclude "map16/sidekick/SYZ.bin"
        even
KosM_SidekickBossChain: binclude "artkosm/sidekick/GHZ Boss Chain.kosm"
        even
PLC_SidekickBossChain: plcheader
        plcm KosM_SidekickBossChain,$3E8
PLC_SidekickBossChain_end:
