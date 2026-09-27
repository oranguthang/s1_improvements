; ---------------------------------------------------------------------------
; Sprite mappings - "PRESS START BUTTON" and "TM" from title screen
;
; Each frame uses different art (see PSB_Main), so an editor shows only some
; frames correctly per art file (Flex2 entries in sonic1.flex.json):
;	.psb		- artnem/Title Screen PSB.nem ("Press Start")
;	.spritemask	- artnem/Title Screen Foreground.nem ("Press Start & Masking")
;	.tm		- artnem/Title Screen TM.nem ("TM Symbol")
; ---------------------------------------------------------------------------
Map_PSB_internal:	mappingsTable
	mappingsTableEntry.w	.blank	; "PRESS START BUTTON" flash-off frame
	mappingsTableEntry.w	.psb
	mappingsTableEntry.w	.spritemask
	mappingsTableEntry.w	.tm

.blank:	spriteHeader
.blank_End

; Tiles are relative to ArtTile_Title_PressStart; centred on the object (PSB_Main adds $40 to X)
.psb:	spriteHeader
	spritePiece	-$40, 0, 4, 1, 0, 0, 0, 0, 0	; "PRESS START BUTTON"
	spritePiece	-$20, 0, 4, 1, 4, 0, 0, 0, 0
	spritePiece	0, 0, 4, 1, 8, 0, 0, 0, 0
	spritePiece	$20, 0, 4, 1, $C, 0, 0, 0, 0
	spritePiece	$40, 0, 2, 1, $10, 0, 0, 0, 0
.psb_End

.spritemask:	spriteHeader
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0	; sprite line limiter
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$48, 4, 4, 0, 0, 0, 0, 0

	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -$28, 4, 4, 0, 0, 0, 0, 0

	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
	spritePiece	-$80, -8, 4, 4, 0, 0, 0, 0, 0
.spritemask_End

.tm:	spriteHeader
	spritePiece	-8, -4, 2, 1, 0, 0, 0, 0, 0	; "TM"
.tm_End

	even
