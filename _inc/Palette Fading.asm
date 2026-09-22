; ===========================================================================
; ---- Palette fading subroutines input format, shared by all variations ----
;
; v_pfade_start = Start position in palette. One word per color. Examples:
;                 $00: palette line 1, first color
;                 $20: palette line 2, first color
;                 $42: palette line 3, second color
; 
; v_pfade_size  = Number of colors to affect, minus 1. Examples:
;                 $0F: 16 colors (one palette line)
;                 $1F: 32 colors (two palette lines)
;                 $3F: is the entire palette (four palette lines)
; 
; v_pfade_start and v_pfade_size are back to back in RAM, so they usually
; get set together as a single word write to v_pfade_start. The most common
; setting is $003F for "the entire palette", which is why it has a shorthand.
; 
; One more note about RGB: the Mega Drive stores the color values backwards,
; meaning that one color word has the format BGR (blue-green-red).
; ===========================================================================


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to fade in from black
; ---------------------------------------------------------------------------

PaletteFadeIn:
		move.w	#$003F,(v_pfade_start).w		; set start position = 0; affect all $40 palette colors
; ---------------------------------------------------------------------------

PalFadeIn_Alt:	; start position and size are already set
		moveq	#0,d0					; clear d0
		lea	(v_palette).w,a0			; load palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance palette buffer to start position
		moveq	#cBlack,d1				; fill palette with black ($000)
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fillBlack:
		move.w	d1,(a0)+				; make color black
		dbf	d0,.fillBlack 				; loop until colors have been filled with black

		moveq	#14,d4					; highest Genesis color component
		moveq	#0,d6					; update every other frame
	.fadeMainLoop:
		bsr.w	RunPLC
		move.b	#id_VBlank_PaletteFade,(v_vblank_routine).w ; set VBlank routine to fade-in ($12)
		bsr.w	WaitForVBlank				; wait for VBlank to transfer CRAM and sync screen
		bchg	#0,d6
		beq.s	.fadeMainLoop
		bsr.s	FadeIn_FromBlack			; fade-in all affected colors from black a bit more
		subq.b	#2,d4
		bne.s	.fadeMainLoop
		move.b	#id_VBlank_PaletteFade,(v_vblank_routine).w
		bsr.w	WaitForVBlank				; transfer the final colors

		rts						; return
; End of function PaletteFadeIn
; ===========================================================================

FadeIn_FromBlack:
		moveq	#0,d0					; clear d0
		lea	(v_palette).w,a0			; load active palette buffer
		lea	(v_palette_fading).w,a1			; load fade-in palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance active palette buffer to start position
		adda.w	d0,a1					; advance fade-in palette buffer to start position
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fadeColors:
		bsr.s	FadeIn_AddColor				; fade-in current color a bit more
		dbf	d0,.fadeColors				; loop until all colors have been faded in more
; ---------------------------------------------------------------------------

		cmpi.b	#id_LZ,(v_zone).w			; are we in Labyrinth Zone?
		bne.s	.return					; if not, don't affect underwater palette buffer

		moveq	#0,d0					; clear d0
		lea	(v_palette_water).w,a0			; load active underwater palette buffer
		lea	(v_palette_water_fading).w,a1		; load fade-in underwater palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance active underwater palette buffer to start position
		adda.w	d0,a1					; advance fade-in underwater palette buffer to start position
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fadeColorsWater:
		bsr.s	FadeIn_AddColor				; fade-in current color from black a bit more
		dbf	d0,.fadeColorsWater			; loop until all water colors have been faded in more

	.return:
		rts						; return
; End of function FadeIn_FromBlack
; ===========================================================================

; Fade all three color components together on alternating frames.

FadeIn_AddColor:
		move.b	(a1),d5					; target blue component
		move.w	(a1)+,d1				; target green and red components
		move.b	d1,d2
		lsr.b	#4,d1					; isolate green
		andi.b	#$0E,d2					; isolate red
		move.w	(a0),d3
		cmp.b	d5,d4					; add blue when its target step is reached
		bhi.s	.noBlue
		addi.w	#$200,d3
.noBlue:
		cmp.b	d1,d4
		bhi.s	.noGreen
		addi.b	#$20,d3
.noGreen:
		cmp.b	d2,d4
		bhi.s	.noRed
		addq.b	#2,d3
.noRed:
		move.w	d3,(a0)+
		rts
; End of function FadeIn_AddColor


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to fade out to black
; ---------------------------------------------------------------------------

PaletteFadeOut:
		move.w	#$003F,(v_pfade_start).w		; set start position = 0; affect all $40 palette colors

		moveq	#8-1,d4				; eight simultaneous color steps
		moveq	#0,d6					; update every other frame
	.fadeMainLoop:
		bsr.w	RunPLC
		move.b	#id_VBlank_PaletteFade,(v_vblank_routine).w ; set VBlank routine to fade-in ($12)
		bsr.w	WaitForVBlank				; wait for VBlank to transfer CRAM and sync screen
		bchg	#0,d6
		beq.s	.fadeMainLoop
		bsr.s	FadeOut_ToBlack				; fade-out all affected colors to black a bit more
		dbf	d4,.fadeMainLoop

		rts						; return
; End of function PaletteFadeOut
; ===========================================================================

FadeOut_ToBlack:
		moveq	#0,d0					; clear d0
		lea	(v_palette).w,a0			; load active palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance active palette buffer to start position
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fadeColors:
		bsr.s	FadeOut_DecColor			; fade-out current color a bit more
		dbf	d0,.fadeColors				; repeat for size of palette

		; Underwater palette is faded out to black even in non-LZ levels
		moveq	#0,d0					; clear d0
		lea	(v_palette_water).w,a0			; load active underwater palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance active palette buffer to start position
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fadeColorsWater:
		bsr.s	FadeOut_DecColor			; fade-out current color to black a bit more
		dbf	d0,.fadeColorsWater			; loop until all water colors have been faded out more

		rts						; return
; End of function FadeOut_ToBlack
; ===========================================================================

FadeOut_DecColor:
		move.w	(a0),d5
		move.w	d5,d1
		move.b	d1,d2
		move.b	d1,d3
		andi.w	#$0E00,d1
		beq.s	.noBlue
		subi.w	#$200,d5
.noBlue:
		andi.w	#$00E0,d2
		beq.s	.noGreen
		subi.b	#$20,d5
.noGreen:
		andi.b	#$0E,d3
		beq.s	.noRed
		subq.b	#2,d5
.noRed:
		move.w	d5,(a0)+
		rts
; End of function FadeOut_DecColor


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to fade in from white (Special Stage)
; ---------------------------------------------------------------------------

PaletteWhiteIn:
		move.w	#$003F,(v_pfade_start).w		; set start position = 0; affect all $40 palette colors
; ---------------------------------------------------------------------------

PalWhiteIn_Alt:	; start position and size are already set
		moveq	#0,d0					; clear d0
		lea	(v_palette).w,a0			; load palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance palette buffer to start position
		move.w	#cWhite,d1				; fill palette with white ($EEE)
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fillWhite:
		move.w	d1,(a0)+				; make color white
		dbf	d0,.fillWhite				; fill palette with white

		moveq	#14,d4					; highest Genesis color component
		moveq	#0,d6					; update every other frame
	.fadeMainLoop:
		bsr.w	RunPLC
		move.b	#id_VBlank_PaletteFade,(v_vblank_routine).w ; set VBlank routine to fade-in ($12)
		bsr.w	WaitForVBlank				; wait for VBlank to transfer CRAM and sync screen
		bchg	#0,d6
		beq.s	.fadeMainLoop
		bsr.s	WhiteIn_FromWhite			; fade-in all affected colors from white a bit more
		subq.b	#2,d4
		bne.s	.fadeMainLoop
		move.b	#id_VBlank_PaletteFade,(v_vblank_routine).w
		bsr.w	WaitForVBlank				; transfer the final colors

		rts						; return
; End of function PaletteWhiteIn
; ===========================================================================

WhiteIn_FromWhite:
		moveq	#0,d0					; clear d0
		lea	(v_palette).w,a0			; load active palette buffer
		lea	(v_palette_fading).w,a1			; load fade-in palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance active palette buffer to start position
		adda.w	d0,a1					; advance fade-in palette buffer to start position
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fadeColors:
		bsr.s	WhiteIn_DecColor			; fade-in current color from white a bit more
		dbf	d0,.fadeColors				; repeat for size of palette
; ---------------------------------------------------------------------------

		cmpi.b	#id_LZ,(v_zone).w			; are we in Labyrinth Zone?
		bne.s	.return					; if not, don't affect underwater palette buffer

		moveq	#0,d0					; clear d0
		lea	(v_palette_water).w,a0			; load active underwater palette buffer
		lea	(v_palette_water_fading).w,a1		; load fade-in underwater palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance active underwater palette buffer to start position
		adda.w	d0,a1					; advance fade-in underwater palette buffer to start position
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fadeColorsWater:
		bsr.s	WhiteIn_DecColor			; fade-in current color from white a bit more
		dbf	d0,.fadeColorsWater			; loop until all water colors have been faded in more

	.return:
		rts						; return
; End of function WhiteIn_FromWhite
; ===========================================================================

WhiteIn_DecColor:
		move.b	(a1),d5
		move.w	(a1)+,d1
		move.b	d1,d2
		lsr.b	#4,d1
		andi.b	#$0E,d2
		move.w	(a0),d3
		cmp.b	d5,d4					; lower blue while current step is above target
		bls.s	.noBlue
		subi.w	#$200,d3
.noBlue:
		cmp.b	d1,d4
		bls.s	.noGreen
		subi.b	#$20,d3
.noGreen:
		cmp.b	d2,d4
		bls.s	.noRed
		subq.b	#2,d3
.noRed:
		move.w	d3,(a0)+
		rts
; End of function WhiteIn_DecColor


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to fade out to white (Special Stage)
; ---------------------------------------------------------------------------

PaletteWhiteOut:
		move.w	#$003F,(v_pfade_start).w		; set start position = 0; affect all $40 palette colors

		moveq	#8-1,d4				; eight simultaneous color steps
		moveq	#0,d6					; update every other frame
	.fadeMainLoop:
		bsr.w	RunPLC
		move.b	#id_VBlank_PaletteFade,(v_vblank_routine).w ; set VBlank routine to fade-in ($12)
		bsr.w	WaitForVBlank				; wait for VBlank to transfer CRAM and sync screen
		bchg	#0,d6
		beq.s	.fadeMainLoop
		bsr.s	WhiteOut_ToWhite			; fade-out all affected colors to white bit more
		dbf	d4,.fadeMainLoop

		rts						; return
; End of function PaletteWhiteOut
; ===========================================================================

WhiteOut_ToWhite:
		moveq	#0,d0					; clear d0
		lea	(v_palette).w,a0			; load active palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance active palette buffer to start position
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fadeColors:
		bsr.s	WhiteOut_AddColor			; fade-out current color to white a bit more
		dbf	d0,.fadeColors				; loop until all colors have been faded out more

		; Underwater palette is faded out to white even in non-LZ levels
		moveq	#0,d0					; clear d0
		lea	(v_palette_water).w,a0			; load active underwater palette buffer
		move.b	(v_pfade_start).w,d0			; get specified start position offset
		adda.w	d0,a0					; advance active underwater palette buffer to start position
		move.b	(v_pfade_size).w,d0			; get number of colors to affect (minus 1 for dbf)
	.fadeColorsWater:
		bsr.s	WhiteOut_AddColor			; fade-out current color to white a bit more
		dbf	d0,.fadeColorsWater			; loop until all colors have been faded out more

		rts						; return
; End of function WhiteOut_ToWhite
; ===========================================================================

WhiteOut_AddColor:
		move.w	(a0),d5
		move.w	d5,d1
		move.b	d1,d2
		move.b	d1,d3
		andi.w	#$0E00,d1
		cmpi.w	#$0E00,d1
		beq.s	.noBlue
		addi.w	#$200,d5
.noBlue:
		andi.w	#$00E0,d2
		cmpi.w	#$00E0,d2
		beq.s	.noGreen
		addi.b	#$20,d5
.noGreen:
		andi.b	#$0E,d3
		cmpi.b	#$0E,d3
		beq.s	.noRed
		addq.b	#2,d5
.noRed:
		move.w	d5,(a0)+
		rts
; End of function WhiteOut_AddColor
