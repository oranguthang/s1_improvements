; ---------------------------------------------------------------------------
; Sprite mappings - purple rock (GHZ)
; ---------------------------------------------------------------------------
Map_PRock_internal:	mappingsTable
	mappingsTableEntry.w	.rock
	mappingsTableEntry.w	.fragmented

.rock:	spriteHeader
	spritePiece	-$18, -$10, 3, 4, 0, 0, 0, 0, 0
	spritePiece	0, -$10, 3, 4, $C, 0, 0, 0, 0
.rock_End

.fragmented: spriteHeader
    spritePiece -24, -16, 2, 4, 0, 0, 0, 0, 0
    spritePiece -8, -16, 1, 4, 8, 0, 0, 0, 0
    spritePiece 0, -16, 1, 4, 12, 0, 0, 0, 0
    spritePiece 8, -16, 2, 4, 16, 0, 0, 0, 0
.fragmented_End

    even
