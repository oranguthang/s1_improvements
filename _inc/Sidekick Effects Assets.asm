; Lossless paired effects: generated from the original star/points sheets.
; 24 nonempty star tiles. The shield slot is free during invincibility.
Map_InvStarsS2_Paired: mappingsTable
        mappingsTableEntry.w .frame0
        mappingsTableEntry.w .frame1
        mappingsTableEntry.w .frame2
        mappingsTableEntry.w .frame3
        mappingsTableEntry.w .frame4
        mappingsTableEntry.w .frame5
        mappingsTableEntry.w .frame6
        mappingsTableEntry.w .frame7
        mappingsTableEntry.w .frame8
.frame0: spriteHeader
.frame0_End
.frame1: spriteHeader
        spritePiece -4,-8,1,1,$541,0,0,0,0
.frame1_End
.frame2: spriteHeader
        spritePiece -4,-8,1,1,$542,0,0,0,0
.frame2_End
.frame3: spriteHeader
        spritePiece -4,-8,1,2,$543,0,0,0,0
.frame3_End
.frame4: spriteHeader
        spritePiece -4,-8,1,2,$545,0,0,0,0
.frame4_End
.frame5: spriteHeader
        spritePiece -4,-8,1,2,$547,0,0,0,0
.frame5_End
.frame6: spriteHeader
        spritePiece -8,-8,2,2,$549,0,0,0,0
.frame6_End
.frame7: spriteHeader
        spritePiece -8,-8,2,2,$54D,0,0,0,0
.frame7_End
.frame8: spriteHeader
        spritePiece -16,-8,1,1,$57E,0,0,0,0
        spritePiece -8,-8,1,2,$551,0,0,0,0
        spritePiece 0,-16,1,4,$55A,0,0,0,0
        spritePiece 8,-8,1,1,$57F,0,0,0,0
.frame8_End
        even
Sidekick_StarsDMAs:
        dc.w 0,$A820,288
        dc.w 576,$AB40,64
        dc.w 704,$AFC0,32
Sidekick_StarsDMAs_End:
        even
KosM_SidekickPointsCompact: binclude "artkosm/sidekick/Points Compact.kosm"
        even
Map_Points_Paired: mappingsTable
        mappingsTableEntry.w .points0
        mappingsTableEntry.w .points1
        mappingsTableEntry.w .points2
        mappingsTableEntry.w .points3
        mappingsTableEntry.w .points4
        mappingsTableEntry.w .points5
        mappingsTableEntry.w .points6
.points0: spriteHeader
        spritePiece -8,-4,2,1,0,0,0,0,0
.points0_End
.points1: spriteHeader
        spritePiece -8,-4,1,1,2,0,0,0,0
        spritePiece 0,-4,1,1,1,0,0,0,0
.points1_End
.points2: spriteHeader
        spritePiece -8,-4,1,1,3,0,0,0,0
        spritePiece 0,-4,1,1,1,0,0,0,0
.points2_End
.points3: spriteHeader
        spritePiece -8,-4,3,1,4,0,0,0,0
.points3_End
.points4: spriteHeader
        spritePiece -4,-4,1,1,4,0,0,0,0
.points4_End
.points5: spriteHeader
        spritePiece -12,-4,3,1,4,0,0,0,0
        spritePiece 1,-4,2,1,5,0,0,0,0
.points5_End
.points6: spriteHeader
        spritePiece -12,-4,3,1,4,0,0,0,0
        spritePiece 6,-4,2,1,5,0,0,0,0
.points6_End
        even
