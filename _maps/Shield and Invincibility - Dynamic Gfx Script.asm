; ---------------------------------------------------------------------------
; Uncompressed graphics loading array for the shield and invincibility stars
; (shared by both art sheets; frames 1-3 read Art_Shield, 4-7 read
; Art_InvincibilityStars). Frames that use the same tiles share a script, so
; ShieldStars_LoadGfx skips the transfer while the tiles are already loaded.
; ---------------------------------------------------------------------------
ShieldDynPLC_internal:	mappingsTable
	mappingsTableEntry.w	ShiPLC_Null
	mappingsTableEntry.w	ShiPLC_First
	mappingsTableEntry.w	ShiPLC_Shield2
	mappingsTableEntry.w	ShiPLC_First
	mappingsTableEntry.w	ShiPLC_First
	mappingsTableEntry.w	ShiPLC_First
	mappingsTableEntry.w	ShiPLC_Stars34
	mappingsTableEntry.w	ShiPLC_Stars34

ShiPLC_Null:	dplcHeader
ShiPLC_Null_End

ShiPLC_First:	dplcHeader
	dplcEntry	9, 0
	dplcEntry	9, 9
ShiPLC_First_End

ShiPLC_Shield2:	dplcHeader
	dplcEntry	9, $12
ShiPLC_Shield2_End

ShiPLC_Stars34:	dplcHeader
	dplcEntry	9, $12
	dplcEntry	9, $1B
ShiPLC_Stars34_End

	even
