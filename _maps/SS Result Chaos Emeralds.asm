; ---------------------------------------------------------------------------
; Sprite mappings - chaos emeralds from the special stage results screen
; ---------------------------------------------------------------------------
Map_SSRC_internal:	mappingsTable
	mappingsTableEntry.w	.chaos_blue
	mappingsTableEntry.w	.chaos_yellow
	mappingsTableEntry.w	.chaos_pink
	mappingsTableEntry.w	.chaos_green
	mappingsTableEntry.w	.chaos_red
	mappingsTableEntry.w	.chaos_gray
	if Feature7thEmerald
	mappingsTableEntry.w	.chaos_cyan
	endif
	mappingsTableEntry.w	.blank

.chaos_blue:	spriteHeader
	spritePiece	-8, -8, 2, 2, 4, 0, 0, 1, 0
.chaos_blue_End

.chaos_yellow:	spriteHeader
	spritePiece	-8, -8, 2, 2, 0, 0, 0, 0, 0
.chaos_yellow_End

.chaos_pink:	spriteHeader
	spritePiece	-8, -8, 2, 2, 4, 0, 0, 2, 0
.chaos_pink_End

.chaos_green:	spriteHeader
	spritePiece	-8, -8, 2, 2, 4, 0, 0, 3, 0
.chaos_green_End

.chaos_red:	spriteHeader
	spritePiece	-8, -8, 2, 2, 8, 0, 0, 1, 0
.chaos_red_End

.chaos_gray:	spriteHeader
	spritePiece	-8, -8, 2, 2, $C, 0, 0, 1, 0
.chaos_gray_End

	if Feature7thEmerald
.chaos_cyan:	spriteHeader	; the grey tiles in line 3, whose slots 7-9 hold cyan
	spritePiece	-8, -8, 2, 2, $C, 0, 0, 3, 0
.chaos_cyan_End
	endif

.blank:	spriteHeader	; Blank frame
.blank_End

	even
