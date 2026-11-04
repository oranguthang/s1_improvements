; Empty source tiles omitted; all visible platform pixels retained.
KosM_SidekickSpinPlatform: binclude "artkosm/sidekick/SBZ Spinning Platform Compact.kosm"
        even
Map_SidekickSpinPlatform: mappingsTable
        mappingsTableEntry.w .flat
        mappingsTableEntry.w .spin1
        mappingsTableEntry.w .spin2
        mappingsTableEntry.w .spin3
        mappingsTableEntry.w .spin4
.flat: spriteHeader
        spritePiece -16,-8,2,2,0,0,0,0,0
        spritePiece 0,-8,2,2,0,1,0,0,0
.flat_End
.spin1: spriteHeader
        spritePiece -16,-16,2,2,18,0,0,0,0
        spritePiece 0,-8,1,1,22,0,0,0,0
        spritePiece 8,-8,1,1,23,0,0,0,0
        spritePiece -16,0,1,1,24,0,0,0,0
        spritePiece -8,0,1,1,25,0,0,0,0
        spritePiece 0,0,2,2,26,0,0,0,0
.spin1_End
.spin2: spriteHeader
        spritePiece -16,-16,2,2,4,0,0,0,0
        spritePiece 0,-8,1,1,8,0,0,0,0
        spritePiece -8,0,1,1,9,0,0,0,0
        spritePiece 0,0,2,2,10,0,0,0,0
.spin2_End
.spin3: spriteHeader
        spritePiece -16,-16,3,2,30,0,0,0,0
        spritePiece -8,0,3,2,36,0,0,0,0
.spin3_End
.spin4: spriteHeader
        spritePiece -8,-16,2,2,14,0,0,0,0
        spritePiece -8,0,2,2,14,0,1,0,0
.spin4_End
        even
