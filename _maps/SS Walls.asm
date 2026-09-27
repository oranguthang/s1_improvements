; ---------------------------------------------------------------------------
; Sprite mappings - walls of the special stage
; ---------------------------------------------------------------------------
; Only the current rotation is kept in VRAM (see SS_AnimateBlocks), so both
; frames start at tile 0. The full 16-rotation sheet is artunc/Special Walls.unc:
; rotation 0 is 9 tiles (3x3), rotations 1-$F are 16 tiles (4x4) each.
Map_SSWalls_internal:	mappingsTable
	mappingsTableEntry.w	.straight ; 00/90 degrees
	mappingsTableEntry.w	.angled   ; any other rotation

.straight:	spriteHeader
	spritePiece	-$C, -$C, 3, 3, 0, 0, 0, 0, 0
.straight_End

.angled:	spriteHeader
	spritePiece	-$10, -$10, 4, 4, 0, 0, 0, 0, 0
.angled_End

	even
