; ---------------------------------------------------------------------------
; Palette index
; ---------------------------------------------------------------------------

makePalEntry:	macro paletteLabel,paletteRAMaddress,{INTLABEL}
__LABEL__:	label	(*-Pal_Index)/8
		dc.l paletteLabel
		dc.w paletteRAMaddress,(paletteLabel_end-paletteLabel)/4-1
		endm
; ---------------------------------------------------------------------------

Pal_Index:

; Id			Palette label,		RAM location
; NOTE: Palette size is calculated dynamically using an end marker made by bincludeEndMarker
palid_SegaBG:		makePalEntry	Pal_SegaBG, 		v_palette_line_1
palid_Title:		makePalEntry	Pal_Title,		v_palette_line_1
palid_LevelSel:		makePalEntry	Pal_LevelSel,		v_palette_line_1
palid_Sonic:		makePalEntry	Pal_Sonic,		v_palette_line_1

	Pal_Levels:
palid_GHZ:		makePalEntry	Pal_GHZ, 		v_palette_line_2
palid_LZ:		makePalEntry	Pal_LZ, 		v_palette_line_2
palid_MZ:		makePalEntry	Pal_MZ, 		v_palette_line_2
palid_SLZ:		makePalEntry	Pal_SLZ,		v_palette_line_2
palid_SYZ:		makePalEntry	Pal_SYZ,		v_palette_line_2
palid_SBZ1:		makePalEntry	Pal_SBZ1, 		v_palette_line_2
	zonewarning Pal_Levels,8

palid_Special:		makePalEntry	Pal_Special, 		v_palette_line_1
palid_LZWater:		makePalEntry	Pal_LZWater, 		v_palette_line_1
palid_SBZ3:		makePalEntry	Pal_SBZ3, 		v_palette_line_2
palid_SBZ3Water:	makePalEntry	Pal_SBZ3Water, 		v_palette_line_1
palid_SBZ2:		makePalEntry	Pal_SBZ2, 		v_palette_line_2
palid_LZSonWater:	makePalEntry	Pal_LZSonWater,		v_palette_line_1
palid_SBZ3SonWat:	makePalEntry	Pal_SBZ3SonWat,		v_palette_line_1
palid_SSResult:		makePalEntry	Pal_SSResult, 		v_palette_line_1
palid_Continue:		makePalEntry	Pal_Continue, 		v_palette_line_1
palid_Ending:		makePalEntry	Pal_Ending, 		v_palette_line_1
palid_SuperSonic:	makePalEntry	Pal_SuperSonic,		v_palette_line_1
palid_SuperSonicWater:	makePalEntry	Pal_SuperSonicWater,	v_palette_line_1
palid_SuperSonicSBZ3Water:	makePalEntry	Pal_SuperSonicSBZ3Water,	v_palette_line_1
	even


; ===========================================================================
; ---------------------------------------------------------------------------
; Palette data bincludes
; ---------------------------------------------------------------------------

Pal_SegaBG:		bincludeEndMarker	"palette/Sega Background.bin"
Pal_Title:		bincludeEndMarker	"palette/Title Screen.bin"
Pal_LevelSel:		bincludeEndMarker	"palette/Level Select.bin"
Pal_Sonic:		bincludeEndMarker	"palette/Sonic.bin"
Pal_GHZ:		bincludeEndMarker	"palette/Green Hill Zone.bin"
Pal_LZ:			bincludeEndMarker	"palette/Labyrinth Zone.bin"
Pal_LZWater:		bincludeEndMarker	"palette/Labyrinth Zone Underwater.bin"
Pal_MZ:			bincludeEndMarker	"palette/Marble Zone.bin"
Pal_SLZ:		bincludeEndMarker	"palette/Star Light Zone.bin"
Pal_SYZ:		bincludeEndMarker	"palette/Spring Yard Zone.bin"
Pal_SBZ1:		bincludeEndMarker	"palette/SBZ Act 1.bin"
Pal_SBZ2:		bincludeEndMarker	"palette/SBZ Act 2.bin"
Pal_Special:		bincludeEndMarker	"palette/Special Stage.bin"
Pal_SBZ3:		bincludeEndMarker	"palette/SBZ Act 3.bin"
Pal_SBZ3Water:		bincludeEndMarker	"palette/SBZ Act 3 Underwater.bin"
Pal_LZSonWater:		bincludeEndMarker	"palette/Sonic - LZ Underwater.bin"
Pal_SBZ3SonWat:		bincludeEndMarker	"palette/Sonic - SBZ3 Underwater.bin"
Pal_SSResult:		bincludeEndMarker	"palette/Special Stage Results.bin"
Pal_Continue:		bincludeEndMarker	"palette/Special Stage Continue Bonus.bin"
Pal_Ending:		bincludeEndMarker	"palette/Ending.bin"

Pal_SuperSonic:
		dc.w $0000, $0000, $04AA, $0ACA, $0ECC, $0EEE, $0EEE, $0CC0
		dc.w $0888, $0444, $08AE, $046A, $000E, $0008, $0004, $00EE
Pal_SuperSonic_end:

Pal_SuperSonicWater:
		dc.w $0000, $0000, $0842, $0A64, $0C86, $0EA8, $0EEE, $0AAA
		dc.w $0888, $0444, $06AA, $0266, $0048, $0024, $0002, $00EE
Pal_SuperSonicWater_end:
Pal_SuperSonicSBZ3Water:
		dc.w $0000, $0000, $0A46, $0C68, $0E8A, $0EAC, $0ECE, $0CAC
		dc.w $0868, $0646, $0CAE, $086C, $060C, $0426, $0004, $00EE
Pal_SuperSonicSBZ3Water_end:
