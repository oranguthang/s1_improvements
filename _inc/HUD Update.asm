; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to update the HUD numbers in VRAM (called from VBlank).
; ---------------------------------------------------------------------------

HUD_Update:
		tst.w	(f_debugmode).w				; is debug mode on?
		beq.s	.chkscore				; ordinary counters are shared by both HUD modes
		bsr.w	HudDebug				; update separate coordinates and sprite statistics
; ---------------------------------------------------------------------------

.chkscore:
		tst.b	(f_scorecount).w			; does the score need updating?
		beq.s	.chkrings				; if not, branch
		clr.b	(f_scorecount).w			; clear update flag

		locVRAM	(ArtTile_HUDScore)*tile_size,d0		; set VRAM address
		move.l	(v_score).w,d1				; load score
		bsr.w	Hud_Score				; write score digits to VRAM

.chkrings:
		tst.b	(f_ringcount).w				; does the ring counter need updating?
		beq.s	.chktime				; if not, branch
		bpl.s	.notzero				; should leading digits get reset (flag >= $80)? if not, branch
		bsr.w	Hud_ResetRings				; reset rings to 0 and clear leading digits (Sonic got hit)
	.notzero:
		clr.b	(f_ringcount).w				; clear update flag

		locVRAM	(ArtTile_HUDRings)*tile_size,d0		; set VRAM address
		moveq	#0,d1					; clear d1
		move.w	(v_rings).w,d1				; load number of rings
		bsr.w	Hud_Rings				; write rings digits

.chktime:
		tst.b	(f_timecount).w				; does the time need updating?
		beq.w	.chklives				; if not, branch
		tst.w	(f_pause).w				; is the game paused?
		bne.w	.chklives				; if yes, branch
		tst.w	(v_debuguse).w				; item placement pauses the act clock
		bne.w	.chklives

		; Each byte in v_time is treated individually in the format "00 0M SS FF", and it's updated right-to-left:
		;   FF (v_timecent) = frame counter for one second (increments seconds after crossing 60 and resets to 00, used internally only)
		;   SS (v_timesec)  = seconds (increments minutes after crossing 60 and resets to 00)
		;   0M (v_timemin)  = minutes (can't ever go above 9 due to time overs, so high nibble is unused)
		;   00              = unused (although it could be used for a hypothetical "hours" counter)

		lea	(v_time).w,a1				; load current time as pointer
		cmpi.l	#(9*$10000)+(59*$100)+59,(a1)+		; is the time 9:59:59? (and advance pointer by 4)
		bne.s	.advancetime				; if not, branch
		tst.w	(f_debugmode).w				; debug retains its exemption from time over
		bne.w	.chklives
		tst.b	(v_dev_god).w				; is God Mode on?
		bne.w	.chklives				; if yes, hold the clock at 9:59 without a time over
		bra.w	TimeOver				; kill Sonic from a time over

	.advancetime:
	if FeatureCentiseconds
		tst.b	(v_gamemode).w				; is the level still fading in?
		bmi.s	.chklives				; if yes, start the clock once it is playable
	endif
		addq.b	#1,-(a1)				; increment 1/60s counter (v_timecent)
		cmpi.b	#60,(a1)				; check if passed 60
	if FeatureCentiseconds
		blo.s	.updatecentis				; if not, only the hundredths change
	else
		blo.s	.chklives				; if not, branch (and skip updating time in VRAM entirely)
	endif
		move.b	#0,(a1)					; reset 1/60s counter to 0

		addq.b	#1,-(a1)				; increment seconds counter (v_timesec)
		cmpi.b	#60,(a1)				; check if passed 60
		blo.s	.updatetime				; if not, branch
		move.b	#0,(a1)					; reset seconds counter to 0

		addq.b	#1,-(a1)				; increment minutes counter (v_timemin)
		cmpi.b	#9,(a1)					; check if passed 9
		blo.s	.updatetime				; if not, branch
		move.b	#9,(a1)					; force minutes to never exceed 9

	.updatetime:
		locVRAM	(ArtTile_HUDTimeMins)*tile_size,d0	; set VRAM address
		moveq	#0,d1					; clear minutes
		move.b	(v_timemin).w,d1			; load minutes
		bsr.w	Hud_Mins				; write minutes digit to VRAM

		locVRAM	(ArtTile_HUDTimeSecs)*tile_size,d0	; set VRAM address
		moveq	#0,d1					; clear d1
		move.b	(v_timesec).w,d1			; load seconds
		bsr.w	Hud_Secs				; write seconds digits to VRAM
	if FeatureCentiseconds
	.updatecentis:
		locVRAM	(ArtTile_HUDCentis)*tile_size,d0	; set VRAM address
		moveq	#0,d1					; clear d1
		move.b	(v_timecent).w,d1			; load the 1/60s counter
		move.b	Hud_FramesToCentis(pc,d1.w),d1		; show it as hundredths of a second
		bsr.w	Hud_Secs				; write the two digits to VRAM
	endif

.chklives:
		tst.b	(f_lifecount).w				; does the lives counter need updating?
		beq.s	.chkbonus				; if not, branch
		clr.b	(f_lifecount).w				; clear update flag
		bsr.w	Hud_Lives				; write lives digits to VRAM

.chkbonus:
		tst.b	(f_endactbonus).w			; do time/ring bonus counters need updating?
		beq.s	.finish					; if not, branch
		clr.b	(f_endactbonus).w			; clear update flag

		locVRAM	ArtTile_Bonuses*tile_size		; set VRAM address
		moveq	#0,d1					; clear d1
		move.w	(v_timebonus).w,d1			; load time bonus
		bsr.w	Hud_TimeRingBonus			; write time bonus digits to VRAM

		moveq	#0,d1					; clear d1
		move.w	(v_ringbonus).w,d1			; load ring bonus
		bsr.w	Hud_TimeRingBonus			; write rings bonus digits to VRAM

.finish:
		rts						; return
; End of function HUD_Update

; ---------------------------------------------------------------------------
; Kill Sonic when a time over has occurred (9:59:59)
; ---------------------------------------------------------------------------

	if FeatureCentiseconds
; Selbi's Add Centiseconds HUD (https://info.sonicretro.org/SCHG_How-to:Add_Centiseconds_HUD):
; frame 0-59 of the current second as hundredths, 00-99.
Hud_FramesToCentis:
	rept 60
		dc.b (*-Hud_FramesToCentis)*99/59
	endr
	endif

TimeOver:
		clr.b	(f_timecount).w				; stop time counter

		lea	(v_player).w,a0				; load Sonic object
		movea.l	a0,a2					; avoid dangling pointer
		bsr.w	KillSonic				; force kill Sonic

		move.b	#1,(f_timeover).w			; set flag to load time over objects
		rts						; return
; End of function TimeOver

; ===========================================================================
; ---------------------------------------------------------------------------
; Alternate HUD updating subroutine while debug mode is enabled
; ---------------------------------------------------------------------------

HudDebug:
		bsr.w	HudDb_ChkHidden				; may the debug tiles be used now?
		bne.s	.return
		bsr.w	HudDb_XY				; camera/player coordinates (upper right)
		bra.w	HudDb_Sprites				; separate SPR row, without replacing TIME
.return:
		rts
; End of function HudDebug


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to reset the rings counter to __0 (clearing the leading digits)
; ---------------------------------------------------------------------------

; Hud_LoadZero:
Hud_ResetRings:
		locVRAM	(ArtTile_HUDRings)*tile_size		; set VRAM address
		lea	Hud_Base_Rings(pc),a2			; load rings digits initialization data
		move.w	#(Hud_Base_End-Hud_Base_Rings)-1,d2	; write 3 digits
		bra.s	Hud_Init_8x16Digits			; write digits to VRAM

; ---------------------------------------------------------------------------
; Subroutine to load uncompressed HUD patterns ("E", "0", colon)
; ---------------------------------------------------------------------------

Hud_Base:
		lea	(vdp_data_port).l,a6			; set VDP data port
		bsr.w	Hud_Lives				; write lives counter to VRAM

		locVRAM	(ArtTile_HUDScore_E)*tile_size		; set VRAM address to the "E" in score
		lea	Hud_Base_Score(pc),a2			; load HUD digits initialization data
		move.w	#(Hud_Base_End-Hud_Base_Score)-1,d2	; write all digits for score, time, rings
	if FeatureCentiseconds
		bsr.s	Hud_Init_8x16Digits
		locVRAM	(ArtTile_HUDCentiSep)*tile_size		; set VRAM address to the second colon
		lea	Hud_Base_Centis(pc),a2
		moveq	#1-1,d2					; write the colon
		bsr.s	Hud_Init_8x16Digits
		locVRAM	(ArtTile_HUDCentis)*tile_size		; set VRAM address to the hundredths
		moveq	#2-1,d2					; write "00"
	endif
		; fall-through to Hud_Init_8x16Digits...

; ---------------------------------------------------------------------------
; Subroutine to initialize 8x16 tiles digits to VRAM to their default values.
; 
; input:
;	VRAM = must be set to target address
;	a2 = initialization data array
;	d2 = number of tiles to write - 1
; ---------------------------------------------------------------------------

; loc_1C83E:
Hud_Init_8x16Digits:
		lea	Art_Hud(pc),a1				; load uncompressed 8x16 HUD number graphics

.loopdigits:
		move.w	#(8*2)-1,d1				; write two tiles (each digit is 8x16)
		move.b	(a2)+,d0				; get next value from initialization data
		bmi.s	.blankdigit				; is it negative ($FF)? if yes, write blank tiles
		ext.w	d0					; extend initialization byte value to word
		lsl.w	#5,d0					; multiply by $20 (tile_size)
		lea	(a1,d0.w),a3				; set start in Art_Hud to relevant digit
	.writedigit:
		move.l	(a3)+,(a6)				; write digit graphics to VRAM
		dbf	d1,.writedigit				; loop until two tiles have been transferred
	.nextdigit:
		dbf	d2,.loopdigits				; loop if more digits are to be initialized
		rts						; return if done
; ---------------------------------------------------------------------------
	.blankdigit:
		move.l	#0,(a6)					; write blank data
		dbf	d1,.blankdigit				; loop until two tiles have been transferred
		bra.s	.nextdigit				; continue to main digit loop
; End of function Hud_Base

; ===========================================================================
; Initialization tiles for the HUD. Each byte represents an instruction:
;    -1 = write blank tiles
;     0 = write a literal "0" digit
;   $16 = write letter "E" (for score text)
;   $14 = write colon ":" (for time counter)
; The last two are tile offsets in Art_Hud.

Hud_Base_Score:	dc.b $16,  -1,  -1,  -1,  -1,  -1,  -1,	  0	; score (E______0)
Hud_Base_Time:	dc.b   0, $14,   0,   0				; time  (0:00)
Hud_Base_Rings:	dc.b  -1,  -1,   0				; rings (__0)
Hud_Base_End:
	if FeatureCentiseconds
Hud_Base_Centis: dc.b $14, 0, 0				; second colon, then hundredths (:00)
	endif
		even
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load debug mode numbers patterns
; ---------------------------------------------------------------------------

HudDb_XY:
		locVRAM	(ArtTile_Debug_Coords)*tile_size	; set VRAM address (dedicated tiles, see Map_HUDDebug)
		move.w	(v_screenposx).w,d1			; load camera x-position
		swap	d1					; move it to upper word
		move.w	(v_player+obX).w,d1			; load Sonic's x-position to lower word
		bsr.s	HudDb_XY_Write				; write left block of debug digits

		move.w	(v_screenposy).w,d1			; load camera y-position
		swap	d1					; move it to upper word
		move.w	(v_player+obY).w,d1			; load Sonic's y-position
		; fall-through to HudDb_XY_Write...		; write right block of debug digits
; ---------------------------------------------------------------------------

HudDb_XY_Write:
		moveq	#8-1,d6					; write 8 digits in total
		lea	(Art_Text).l,a1				; load uncompressed 8x8 font graphics

.loopdigits:
		rol.w	#4,d1					; move uppest nybble in word to lowest nybble
		move.w	d1,d2					; make a copy (need to preserve d1 for the loop)
		andi.w	#$F,d2					; limit digit to one nybble
		cmpi.w	#$A,d2					; is digit $A-$F?
		blo.s	.writedigit				; if not, branch
		addq.w	#7,d2					; adjust tile offset for hex letters
	.writedigit:
		lsl.w	#5,d2					; multiply by $20 (tile_size)
		lea	(a1,d2.w),a3				; set start in Art_Text to relevant digit
	rept 8
		move.l	(a3)+,(a6)				; write digit graphics to VRAM (8 lines = 1 tile)
	endr
		swap	d1					; alternate between upper and lower word while writing
		dbf	d6,.loopdigits				; loop for all 8 digits in a block
		rts						; return
; End of function HudDb_XY

; Draw SPR and a two-digit decimal sprite count into its five separate tiles.
HudDb_Sprites:
		locVRAM	ArtTile_Debug_Stats*tile_size
		lea	(Art_Text).l,a1
		lea	HudDb_SpriteLabel(pc),a2
		moveq	#3-1,d6
.label:
		moveq	#0,d2
		move.b	(a2)+,d2
		bsr.s	HudDb_WriteGlyph
		dbf	d6,.label
		moveq	#0,d1
		move.b	(v_spritecount).w,d1
		divu.w	#10,d1					; quotient=tens, remainder=ones
		move.w	d1,d2
		bsr.s	HudDb_WriteGlyph
		swap	d1
		move.w	d1,d2
		; fall through for the ones digit

HudDb_WriteGlyph:
		lsl.w	#5,d2
		lea	(a1,d2.w),a3
	rept 8
		move.l	(a3)+,(a6)
	endr
		rts

HudDb_SpriteLabel:	dc.b 'S'-'0','P'-'0','R'-'0'
		even


; ---------------------------------------------------------------------------
; Check whether the debug coordinates may use ArtTile_Debug_Coords. Those
; tiles also hold the Game Over art, the bonus counters and ending animals.
; Used by HudDebug (tile writes) and BuildHUD (sprites), so both stop and
; resume on the same frame.
;
; output:
;	d0 = 0 and Z set if the coordinates are shown, otherwise d0 = 1
; ---------------------------------------------------------------------------

HudDb_ChkHidden:
		move.b	(v_gamemode).w,d0
		andi.b	#$7F,d0					; ignore the pre-level flag
		cmpi.b	#id_Level,d0				; only levels and demos keep these tiles free
		beq.s	.level
		cmpi.b	#id_Demo,d0
		bne.s	.hide					; Special Stage results, ending, credits

	.level:
		cmpi.b	#id_GameOverCard,(v_gameovertext1).w	; GAME OVER / TIME OVER card?
		beq.s	.hide
		tst.b	(v_endcard).w				; results card with bonus counters?
		bne.s	.hide
	if FeatureS2Stars
		tst.b	(v_invinc).w				; Sonic 2 stars use these tiles while invincible
		bne.s	.hide
	endif
		tst.w	(v_debuguse).w				; debug placement entered while dying?
		bne.s	.show					; (Game Over art is only queued after that)
		cmpi.b	#6,(v_player+obRoutine).w		; is Sonic dying? (Game Over art may load)
		bhs.s	.hide

	.show:
		moveq	#0,d0
		rts

	.hide:
		moveq	#1,d0
		rts
; End of function HudDb_ChkHidden


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load rings numbers patterns
; ---------------------------------------------------------------------------

Hud_Rings:
		lea	(Hud_100).l,a2				; affect three digits
		moveq	#3-1,d6					; write three digits
		bra.s	Hud_Write_8x16Digits_SkipLeading	; skip over

; ---------------------------------------------------------------------------
; Subroutine to load score numbers patterns
; ---------------------------------------------------------------------------

Hud_Score:
		lea	(Hud_100000).l,a2			; affect six digits
		moveq	#6-1,d6					; write six digits
		; fall-through to Hud_Write_8x16Digits_SkipLeading...

; ---------------------------------------------------------------------------
; Subroutine to write a decimal representation of an input value as
; 8x16 tiles digits to VRAM, skipping leading zeroes.
; 
; input:
;	d1 = input hexadecimal value
;	d2 = number of tiles to write - 1
;	a2 = starting "Hud_1..." value
;	VRAM = must be set to target address
; 
; These input values are identical for all other "Hud_Write_..." subroutines.
; ---------------------------------------------------------------------------

; Hud_LoadArt:
Hud_Write_8x16Digits_SkipLeading:
		moveq	#0,d4					; set flag to skip leading zeroes
		lea	Art_Hud(pc),a1				; load uncompressed 8x16 HUD number graphics

.loopdigits:
		moveq	#0,d2					; clear d2
		move.l	(a2)+,d3				; get digit to write to this loop

	.finddigit:
		sub.l	d3,d1					; decrement affected digit in input value
		bcs.s	.digitfound				; if carry was set, d2 now points to the correct digit, branch
		addq.w	#1,d2					; increment target digit
		bra.s	.finddigit				; loop until correct digit has been found
; ---------------------------------------------------------------------------

	.digitfound:
		add.l	d3,d1					; undo last decrement

		tst.w	d2					; was resulting target digit 0?
		beq.s	.skipleadingzeroes			; if yes, branch
		move.w	#1,d4					; start writing digits now
	.skipleadingzeroes:
		tst.w	d4					; has first non-zero digit been hit yet?
		beq.s	.nextdigit				; if not, don't write digits yet

		lsl.w	#6,d2					; multiply by $40 (tile_size*2)
		move.l	d0,4(a6)				; set VRAM address to next digit
		lea	(a1,d2.w),a3				; set start in Art_Hud to relevant digit
	rept 8*2
		move.l	(a3)+,(a6)				; write digit graphics to VRAM
	endr

	.nextdigit:
		addi.l	#$400000,d0				; advance VRAM pointer to next digit
		dbf	d6,.loopdigits				; repeat for all digits
		rts						; return
; End of function Hud_Write_8x16Digits_SkipLeading

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load countdown numbers on the continue screen.
; ---------------------------------------------------------------------------

ContScrCounter:
		locVRAM	ArtTile_Continue_Number*tile_size	; set VRAM start
		lea	(vdp_data_port).l,a6			; set VDP port
		lea	(Hud_10).l,a2				; affect two digits
		moveq	#2-1,d6					; write two digits
		; fall-through to Hud_Write_8x16Digits_WithLeading_Continuous...

; ---------------------------------------------------------------------------
; Edited copy-paste of Hud_Write_8x16Digits_WithLeading, but continuously
; writing to VRAM instead of changing the pointer VRAM between digits.
; ---------------------------------------------------------------------------

Hud_Write_8x16Digits_WithLeading_Continuous:
		moveq	#0,d4					; clear d4 (redundant, leading zeroes are not skipped here)
		lea	Art_Hud(pc),a1				; load uncompressed 8x16 HUD number graphics

.loopdigits:
		moveq	#0,d2					; clear d2
		move.l	(a2)+,d3				; get digit to write to this loop

	.finddigit:
		sub.l	d3,d1					; decrement affected digit in input value
		bcs.s	.digitfound				; if carry was set, d2 now points to the correct digit, branch
		addq.w	#1,d2					; increment target digit
		bra.s	.finddigit				; loop until correct digit has been found
; ---------------------------------------------------------------------------

	.digitfound:
		add.l	d3,d1					; undo last decrement
		lsl.w	#6,d2					; multiply by $40 (tile_size*2)
		lea	(a1,d2.w),a3				; set start in Art_Hud to relevant digit
	rept 8*2
		move.l	(a3)+,(a6)				; write digit graphics to VRAM
	endr
		dbf	d6,.loopdigits				; repeat for both digits
		rts						; return
; End of function ContScrCounter

; ===========================================================================
; ---------------------------------------------------------------------------
; Configuration values for converting hexadecimal numbers to decimal.
; The subroutines will subtract one of these values from the input value,
; looping until it has caused an underflow. Meanwhile, it will keep track
; of the number of iterations it took to cause that underflow, which will
; represent the relevant decimal digit. The code will then repeat the entire
; process with the "Hud_1..." value below it for the next decimal digit,
; until all digits have been converted to decimal and written to VRAM.
; ---------------------------------------------------------------------------
Hud_100000:	dc.l	100000
Hud_10000:	dc.l	 10000
Hud_1000:	dc.l	  1000
Hud_100:	dc.l	   100
Hud_10:		dc.l	    10
Hud_1:		dc.l	     1

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load time numbers patterns
; ---------------------------------------------------------------------------

Hud_Mins:
		lea	(Hud_1).l,a2				; affect one digit
		moveq	#1-1,d6					; write one digit
		bra.s	Hud_Write_8x16Digits_WithLeading	; skip over
; ===========================================================================

Hud_Secs:
		lea	(Hud_10).l,a2				; affect two digits
		moveq	#2-1,d6					; write two digits
		; fall-through to Hud_Write_8x16Digits_WithLeading...

; ---------------------------------------------------------------------------
; Subroutine to write a decimal representation of an input value as
; 8x16 tiles digits to VRAM, NOT skipping leading zeroes.
;
; This appears to be a dirty copy-paste of Hud_Write_8x16Digits_SkipLeading,
; as it has some unused leftovers of that subroutine.
; ---------------------------------------------------------------------------

; loc_1C9BA: Hud_DrawDigits:
Hud_Write_8x16Digits_WithLeading:
		moveq	#0,d4					; clear d4 (redundant, leading zeroes are not skipped here)
		lea	Art_Hud(pc),a1				; load uncompressed 8x16 HUD number graphics

.loopdigits:
		moveq	#0,d2					; clear d2
		move.l	(a2)+,d3				; get digit to write to this loop

	.finddigit:
		sub.l	d3,d1					; decrement affected digit in input value
		bcs.s	.digitfound				; if carry was set, d2 now points to the correct digit, branch
		addq.w	#1,d2					; increment target digit
		bra.s	.finddigit				; loop until correct digit has been found
; ---------------------------------------------------------------------------

	.digitfound:
		add.l	d3,d1					; undo last decrement

	if FixBugs=0
		; This appears to be a leftover from a dirty copy-paste job of Hud_Write_8x16Digits_SkipLeading,
		; as it still checks for leading zeroes, but doesn't do anything with that information.
		tst.w	d2					; was resulting target digit 0?
		beq.s	.skipleadingzeroes			; if yes, branch
		move.w	#1,d4					; set flag that first non-zero digit was found (unused)
	.skipleadingzeroes:
	endif

		lsl.w	#6,d2					; multiply by $40 (tile_size*2)
		move.l	d0,4(a6)				; set VRAM address to next digit
		lea	(a1,d2.w),a3				; set start in Art_Hud to relevant digit
	rept 8*2
		move.l	(a3)+,(a6)				; write digit graphics to VRAM
	endr

		addi.l	#$400000,d0				; advance VRAM pointer to next digit
		dbf	d6,.loopdigits				; repeat for all digits
		rts						; return
; End of function Hud_Write_8x16Digits_WithLeading

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load time/ring bonus numbers patterns for end-of-level cards.
; ---------------------------------------------------------------------------

Hud_TimeRingBonus:
		lea	(Hud_1000).l,a2				; affect four digits
		moveq	#4-1,d6					; write four digits
		; fall-through to Hud_Write_8x16Digits_ClearLeading...

; ---------------------------------------------------------------------------
; This is another edited copy-paste of Hud_Write_8x16Digits_SkipLeading,
; but actively clearing the leading zeroes instead of just ignoring them.
; ---------------------------------------------------------------------------

Hud_Write_8x16Digits_ClearLeading:
		moveq	#0,d4					; set flag to skip leading zeroes
		lea	Art_Hud(pc),a1				; load uncompressed 8x16 HUD number graphics

.loopdigits:
		moveq	#0,d2					; clear d2
		move.l	(a2)+,d3				; get digit to write to this loop

	.finddigit:
		sub.l	d3,d1					; decrement affected digit in input value
		bcs.s	.digitfound				; if carry was set, d2 now points to the correct digit, branch
		addq.w	#1,d2					; increment target digit
		bra.s	.finddigit				; loop until correct digit has been found
; ---------------------------------------------------------------------------

	.digitfound:
		add.l	d3,d1					; undo last decrement

		tst.w	d2					; was resulting target digit 0?
		beq.s	.skipleadingzeroes			; if yes, branch
		move.w	#1,d4					; start writing digits now
	.skipleadingzeroes:
		tst.w	d4					; has first non-zero digit been hit yet?
		beq.s	.cleardigit				; if not, clear this digit

		lsl.w	#6,d2					; multiply by $40 (tile_size*2)
		lea	(a1,d2.w),a3				; set start in Art_Hud to relevant digit
	rept 8*2
		move.l	(a3)+,(a6)				; write digit graphics to VRAM
	endr

	.nextdigit:
		dbf	d6,.loopdigits				; repeat for all digits
		rts						; return
; ---------------------------------------------------------------------------

.cleardigit:
		moveq	#(8*2)-1,d5				; write two tiles (each digit is 8x16)
	.clearloop:
		move.l	#0,(a6)					; write blank data
		dbf	d5,.clearloop				; loop until two tiles have been transferred
		bra.s	.nextdigit				; continue to main digit loop
; End of function Hud_TimeRingBonus

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load number of lives in HUD.
; ---------------------------------------------------------------------------

Hud_Lives:
		locVRAM	(ArtTile_Lives_Counter_Num)*tile_size,d0 ; set VRAM address
		moveq	#0,d1					; clear d1
		move.b	(v_lives).w,d1				; load number of lives
		lea	(Hud_10).l,a2				; affect two digits
		moveq	#2-1,d6					; write two digits
		; fall-through to Hud_Write_8x8Digits_WithLeading...

; ---------------------------------------------------------------------------
; Once again, more or less a copy-paste of the previous code, albeit with
; adjustments for 8x8 digits instead of 8x16 digits, and forcing to write
; even when the number of lives is 0, for game overs.
; ---------------------------------------------------------------------------

Hud_Write_8x8Digits_WithLeading:
		moveq	#0,d4					; set flag to skip leading zeroes
		lea	Art_LivesNums(pc),a1			; load uncompressed 8x8 lives counter number graphics

.loopdigits:
		move.l	d0,4(a6)				; set VRAM address to next digit

		moveq	#0,d2					; clear d2
		move.l	(a2)+,d3				; get digit to write to this loop

	.finddigit:
		sub.l	d3,d1					; decrement affected digit in input value
		bcs.s	.digitfound				; if carry was set, d2 now points to the correct digit, branch
		addq.w	#1,d2					; increment target digit
		bra.s	.finddigit				; loop until correct digit has been found
; ---------------------------------------------------------------------------

	.digitfound:
		add.l	d3,d1					; undo last decrement

		tst.w	d2					; was resulting target digit 0?
		beq.s	.skipleadingzeroes			; if yes, branch
		move.w	#1,d4					; start writing digits now
	.skipleadingzeroes:
		tst.w	d4					; has first non-zero digit been hit yet?
		beq.s	.cleardigit				; if not, clear this digit

	.writedigit:
		lsl.w	#5,d2					; multiply by $20 (tile_size)
		lea	(a1,d2.w),a3				; set start in Art_LivesNums to relevant digit
	rept 8
		move.l	(a3)+,(a6)				; write digit graphics to VRAM
	endr

	.nextdigit:
		addi.l	#$400000,d0				; advance VRAM pointer to next digit
		dbf	d6,.loopdigits				; repeat for all digits
		rts						; return
; ===========================================================================

.cleardigit:
		tst.w	d6					; is this the last digit?
		beq.s	.writedigit				; if yes, write digit it even if it's 0 (for game overs)

		moveq	#8-1,d5					; write one tile
	.clearloop:
		move.l	#0,(a6)					; write blank data
		dbf	d5,.clearloop				; loop until two tiles have been transferred
		bra.s	.nextdigit				; continue to main digit loop
; End of function Hud_Lives
