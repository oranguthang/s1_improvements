; ---------------------------------------------------------------------------
; Sprite mappings - rings (both revisions)
;
; Ring art is dynamic (#42): tiles 0-3 hold the current ordinary ring frame and
; tiles 4-7 the current lost ring frame, both copied by RingArt_Update. Frames
; 0-3 keep their old IDs but draw the same slot; the rotation is in VRAM.
; Sparkles are resident at tile 8 (ArtTile_Ring_Sparkle).
; ---------------------------------------------------------------------------
Map_Ring_internal:	mappingsTable
	mappingsTableEntry.w	.ring	; 0-3 - ordinary ring (Sync2 phase)
	mappingsTableEntry.w	.ring
	mappingsTableEntry.w	.ring
	mappingsTableEntry.w	.ring
	mappingsTableEntry.w	.sparkle1
	mappingsTableEntry.w	.sparkle2
	mappingsTableEntry.w	.sparkle3
	mappingsTableEntry.w	.sparkle4
	mappingsTableEntry.w	.blank	; 8 - blank (REV01 frame, now in both revisions)
	mappingsTableEntry.w	.lost	; 9 - lost ring (Sync4 phase)

.ring:	spriteHeader
	spritePiece	-8, -8, 2, 2, 0, 0, 0, 0, 0	; ordinary ring slot
.ring_End

.sparkle1:	spriteHeader
	spritePiece	-8, -8, 2, 2, 8, 0, 0, 0, 0	; sparkle
.sparkle1_End

.sparkle2:	spriteHeader
	spritePiece	-8, -8, 2, 2, 8, 1, 1, 0, 0	; sparkle
.sparkle2_End

.sparkle3:	spriteHeader
	spritePiece	-8, -8, 2, 2, 8, 1, 0, 0, 0	; sparkle
.sparkle3_End

.sparkle4:	spriteHeader
	spritePiece	-8, -8, 2, 2, 8, 0, 1, 0, 0	; sparkle
.sparkle4_End

.blank:	spriteHeader
.blank_End

.lost:	spriteHeader
	spritePiece	-8, -8, 2, 2, 4, 0, 0, 0, 0	; lost ring slot
.lost_End

	even
