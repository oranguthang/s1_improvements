; ---------------------------------------------------------------------------
; Sprite mappings - debug coordinates (upper right corner, see BuildHUD)
; HudDb_XY writes 16 8x8 digits column by column: the top row is the camera
; X/Y position and the bottom row is Sonic's X/Y position.
; A third row uses the separate five-tile SPR statistics slot.
; ---------------------------------------------------------------------------
Map_HUDDebug_internal:	mappingsTable
	mappingsTableEntry.w	.coords

.coords:	spriteHeader
	spritePiece	0, 0, 4, 2, ArtTile_Debug_Coords, 0, 0, 0, 1		; camera X over Sonic X
	spritePiece	$20, 0, 4, 2, (ArtTile_Debug_Coords+8), 0, 0, 0, 1		; camera Y over Sonic Y
	spritePiece	0, $10, 3, 1, ArtTile_Debug_Stats, 0, 0, 0, 1 ; SPR
	spritePiece	$30, $10, 2, 1, (ArtTile_Debug_Stats+3), 0, 0, 0, 1 ; decimal count
.coords_End
	even
