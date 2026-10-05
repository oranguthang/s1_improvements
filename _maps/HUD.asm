; ---------------------------------------------------------------------------
; Sprite mappings - SCORE, TIME, RINGS
; ---------------------------------------------------------------------------
Map_HUD_internal:	mappingsTable
	mappingsTableEntry.w	.allyellow
	mappingsTableEntry.w	.ringred
	mappingsTableEntry.w	.timered
	mappingsTableEntry.w	.allred

.allyellow:	spriteHeader
	spritePiece	0, -$80, 4, 2, 0, 0, 0, 1, 1		; "SCOR"
	spritePiece	$20, -$80, 4, 2, $18, 0, 0, 1, 1	; "E" and first three score digits
	spritePiece	$40, -$80, 4, 2, $20, 0, 0, 1, 1	; last four score digits

	spritePiece	0, -$70, 4, 2, $10, 0, 0, 1, 1		; "TIME"
	spritePiece	$28, -$70, 4, 2, $28, 0, 0, 1, 1	; time counter
	if FeatureCentiseconds
	spritePiece	$48, -$70, 1, 2, (ArtTile_HUDCentiSep-ArtTile_HUD), 0, 0, 1, 1	; second colon
	spritePiece	$50, -$70, 2, 2, (ArtTile_HUDCentis-ArtTile_HUD), 0, 0, 1, 1	; hundredths
	endif

	spritePiece	0, -$60, 4, 2, 8, 0, 0, 1, 1		; "RING"
	spritePiece	$20, -$60, 1, 2, 0, 0, 0, 1, 1		; "S"
	spritePiece	$30, -$60, 3, 2, $30, 0, 0, 1, 1	; rings counter

	if FeatureInfiniteLives=0
	spritePiece	0, $40, 2, 2, $10A, 0, 0, 0, 1		; lives counter (Sonic icon)
	spritePiece	$10, $40, 4, 2, $10E, 0, 0, 1, 1	; lives counter ("SONIC x N" text)
	endif
.allyellow_End
	even

.ringred:	spriteHeader
	spritePiece	0, -$80, 4, 2, 0, 0, 0, 1, 1		; "SCOR"
	spritePiece	$20, -$80, 4, 2, $18, 0, 0, 1, 1	; "E" and first three score digits
	spritePiece	$40, -$80, 4, 2, $20, 0, 0, 1, 1	; last four score digits

	spritePiece	0, -$70, 4, 2, $10, 0, 0, 1, 1		; "TIME"
	spritePiece	$28, -$70, 4, 2, $28, 0, 0, 1, 1	; time counter
	if FeatureCentiseconds
	spritePiece	$48, -$70, 1, 2, (ArtTile_HUDCentiSep-ArtTile_HUD), 0, 0, 1, 1	; second colon
	spritePiece	$50, -$70, 2, 2, (ArtTile_HUDCentis-ArtTile_HUD), 0, 0, 1, 1	; hundredths
	endif

	spritePiece	0, -$60, 4, 2, 8, 0, 0, 0, 1		; (red) "RING"
	spritePiece	$20, -$60, 1, 2, 0, 0, 0, 0, 1		; (red) "S"
	spritePiece	$30, -$60, 3, 2, $30, 0, 0, 1, 1	; rings counter

	if FeatureInfiniteLives=0
	spritePiece	0, $40, 2, 2, $10A, 0, 0, 0, 1		; lives counter (Sonic icon)
	spritePiece	$10, $40, 4, 2, $10E, 0, 0, 1, 1	; lives counter ("SONIC x N" text)
	endif
.ringred_End
	even

.timered:	spriteHeader
	spritePiece	0, -$80, 4, 2, 0, 0, 0, 1, 1		; "SCOR"
	spritePiece	$20, -$80, 4, 2, $18, 0, 0, 1, 1	; "E" and first three score digits
	spritePiece	$40, -$80, 4, 2, $20, 0, 0, 1, 1	; last four score digits

	spritePiece	0, -$70, 4, 2, $10, 0, 0, 0, 1		; (red) "TIME"
	spritePiece	$28, -$70, 4, 2, $28, 0, 0, 1, 1	; time counter
	if FeatureCentiseconds
	spritePiece	$48, -$70, 1, 2, (ArtTile_HUDCentiSep-ArtTile_HUD), 0, 0, 1, 1	; second colon
	spritePiece	$50, -$70, 2, 2, (ArtTile_HUDCentis-ArtTile_HUD), 0, 0, 1, 1	; hundredths
	endif

	spritePiece	0, -$60, 4, 2, 8, 0, 0, 1, 1		; "RING"
	spritePiece	$20, -$60, 1, 2, 0, 0, 0, 1, 1		; "S"
	spritePiece	$30, -$60, 3, 2, $30, 0, 0, 1, 1	; rings counter

	if FeatureInfiniteLives=0
	spritePiece	0, $40, 2, 2, $10A, 0, 0, 0, 1		; lives counter (Sonic icon)
	spritePiece	$10, $40, 4, 2, $10E, 0, 0, 1, 1	; lives counter ("SONIC x N" text)
	endif
.timered_End
	even

.allred:	spriteHeader
	spritePiece	0, -$80, 4, 2, 0, 0, 0, 1, 1		; "SCOR"
	spritePiece	$20, -$80, 4, 2, $18, 0, 0, 1, 1	; "E" and first three score digits
	spritePiece	$40, -$80, 4, 2, $20, 0, 0, 1, 1	; last four score digits

	spritePiece	0, -$70, 4, 2, $10, 0, 0, 0, 1		; (red) "TIME"
	spritePiece	$28, -$70, 4, 2, $28, 0, 0, 1, 1	; time counter
	if FeatureCentiseconds
	spritePiece	$48, -$70, 1, 2, (ArtTile_HUDCentiSep-ArtTile_HUD), 0, 0, 1, 1	; second colon
	spritePiece	$50, -$70, 2, 2, (ArtTile_HUDCentis-ArtTile_HUD), 0, 0, 1, 1	; hundredths
	endif

	spritePiece	0, -$60, 4, 2, 8, 0, 0, 0, 1		; (red) "RING"
	spritePiece	$20, -$60, 1, 2, 0, 0, 0, 0, 1		; (red) "S"
	spritePiece	$30, -$60, 3, 2, $30, 0, 0, 1, 1	; rings counter

	if FeatureInfiniteLives=0
	spritePiece	0, $40, 2, 2, $10A, 0, 0, 0, 1		; lives counter (Sonic icon)
	spritePiece	$10, $40, 4, 2, $10E, 0, 0, 1, 1	; lives counter ("SONIC x N" text)
	endif
.allred_End
	even
