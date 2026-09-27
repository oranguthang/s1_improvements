; ---------------------------------------------------------------------------
; Sprite mappings - Splats enemy (MZ, restored from the prototype)
; ---------------------------------------------------------------------------
Map_Splats_internal:	mappingsTable
	mappingsTableEntry.w	.bounce0
	mappingsTableEntry.w	.bounce1

.bounce0:	spriteHeader
	spritePiece	-$C, -$14, 3, 4, 0, 0, 0, 0, 0
	spritePiece	-$C, $C, 3, 1, $C, 0, 0, 0, 0
.bounce0_End

.bounce1:	spriteHeader
	spritePiece	-$C, -$14, 3, 4, $F, 0, 0, 0, 0
	spritePiece	-5, $C, 2, 1, $1B, 0, 0, 0, 0
.bounce1_End

	even
