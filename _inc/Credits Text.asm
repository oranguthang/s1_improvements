; ===========================================================================
; ---------------------------------------------------------------------------
; Credits pages written as plain text (FeatureTextCredits). Adapted from
; "Use Plane Mappings for Credits in Sonic 1", system 2
; (https://info.sonicretro.org/SCHG_How-to:Enigma_Credits_in_Sonic_1): original
; guide by Fukuller, updated and expanded by Selbi. The 16x16 font has a
; blank glyph and A-Z; this project adds the "2" of "YU 2" from the original
; credits font.
;
; Rules: exactly 9 pages of 14 lines, each line exactly 20 characters, using
; uppercase letters, "2" and spaces. The build rejects anything else.
; ---------------------------------------------------------------------------

Credits_LineLength:	equ 320/8
Credits_RowCount:	equ 224/8
Credits_PageLines:	equ 14
Credits_PageColumns:	equ 20
Credits_TwoGlyph:	equ 27				; after the blank glyph and A-Z

; Write the current page to plane A through a RAM buffer.
Credits_LoadPageMappings:
		move.w	(v_creditsnum).w,d0
		add.w	d0,d0
		lea	Credits_TilemapText(pc),a0
		adda.w	(a0,d0.w),a0				; text of this page
		lea	(v_ram_start).l,a1			; tilemap buffer
		moveq	#Credits_PageLines-1,d0
	.row:
		moveq	#Credits_PageColumns-1,d1
	.column:
		moveq	#0,d2
		move.b	(a0)+,d2
		cmpi.b	#' ',d2
		bne.s	.notSpace
		moveq	#0,d2					; blank glyph
		bra.s	.glyph
	.notSpace:
		cmpi.b	#'2',d2
		bne.s	.letter
		moveq	#Credits_TwoGlyph,d2
		bra.s	.glyph
	.letter:
		subi.b	#'A'-1,d2				; A is glyph 1
	.glyph:
		lsl.w	#2,d2					; four tiles per glyph
		addi.w	#ArtTile_Credits_Text_Font,d2
		move.w	d2,(a1)					; top left
		addq.w	#1,d2
		move.w	d2,Credits_LineLength*2(a1)		; bottom left
		addq.w	#1,d2
		move.w	d2,2(a1)				; top right
		addq.w	#1,d2
		move.w	d2,Credits_LineLength*2+2(a1)		; bottom right
		addq.w	#2*2,a1					; next 16-pixel cell
		dbf	d1,.column
		adda.w	#Credits_LineLength*2,a1		; skip the row of bottom halves
		dbf	d0,.row
		move.w	sr,-(sp)
		disable_ints					; VBlank also talks to the VDP
		lea	(v_ram_start).l,a1
		locVRAM	vram_fg,d0
		moveq	#Credits_LineLength-1,d1
		moveq	#Credits_RowCount-1,d2
		jsr	(TilemapToVRAM).l			; copyTilemap, out of bsr range here
		move.w	(sp)+,sr
		rts

; Check a page line while assembling.
creditsline:	macro text
		if strlen(text)<>Credits_PageColumns
			fatal "Each credits line must have exactly 20 characters: \{text}"
		endif
		set i, 0
		while (i<strlen(text))
			set char, substr(text,i,1)
			if (char<>' ')&(char<>'2')&((char<'A')|(char>'Z'))
				fatal "Credits lines may only use A-Z, 2 and spaces: \{text}"
			endif
			set i, i+1
		endm
		dc.b text
		endm

Credits_TilemapText:
		dc.w Credits_Page_staff-Credits_TilemapText
		dc.w Credits_Page_gameplan-Credits_TilemapText
		dc.w Credits_Page_program-Credits_TilemapText
		dc.w Credits_Page_character-Credits_TilemapText
		dc.w Credits_Page_design-Credits_TilemapText
		dc.w Credits_Page_soundproduce-Credits_TilemapText
		dc.w Credits_Page_soundprogram-Credits_TilemapText
		dc.w Credits_Page_thanks-Credits_TilemapText
		dc.w Credits_Page_presentedby-Credits_TilemapText

Credits_Page_staff:
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "  SONIC TEAM STAFF  "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
Credits_Page_gameplan:
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "  GAME PLAN         "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "      CAROL YAS     "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
Credits_Page_program:
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "  PROGRAM           "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "        YU2         "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
Credits_Page_character:
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "  CHARACTER DESIGN  "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "      BIGISLAND     "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
Credits_Page_design:
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "    DESIGN          "
		creditsline "                    "
		creditsline "                    "
		creditsline "        JINYA       "
		creditsline "                    "
		creditsline "       PHENIX RIE   "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
Credits_Page_soundproduce:
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "   SOUND PRODUCE    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "  MASATO NAKAMURA   "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
Credits_Page_soundprogram:
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "   SOUND PROGRAM    "
		creditsline "                    "
		creditsline "                    "
		creditsline "       JIMITA       "
		creditsline "                    "
		creditsline "       MACKY        "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
Credits_Page_thanks:
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "  SPECIAL THANKS    "
		creditsline "                    "
		creditsline "                    "
		creditsline "    FUJIO MINEGISHI "
		creditsline "                    "
		creditsline "         PAPA       "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
Credits_Page_presentedby:
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline " PRESENTED BY SEGA  "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
		creditsline "                    "
Credits_TilemapText_End:
	if Credits_TilemapText_End-Credits_TilemapText<>9*2+9*Credits_PageLines*Credits_PageColumns
		fatal "The credits need exactly nine pages of fourteen lines"
	endif
		even
KosM_CreditsTextFont:	binclude	"artkosm/Credits - Text Font.kosm"	; generated by s1tools player ui
		even
