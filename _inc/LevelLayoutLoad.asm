; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load basic level data
; ---------------------------------------------------------------------------

LevelDataLoad:
        jsr (GetLevelHeader).l
        move.l a2,-(sp)
        move.l LevelHeader_Blocks(a2),(v_rom_blocks).w
        move.l LevelHeader_Chunks(a2),(v_rom_chunks).w
        bsr.w LevelLayoutLoad
        moveq #0,d0
        move.b LevelHeader_Palette(a2),d0
        bsr.w PalLoad_Fade
        movea.l (sp)+,a2
        movea.l LevelHeader_SecondPLC(a2),a1
        move.l a1,d0
        beq.s .skipPLC
        jsr (AddPLCFromAddress).l
.skipPLC:
        rts
; End of function LevelDataLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Level layout loading subroutine
; ---------------------------------------------------------------------------

LevelLayoutLoad:
		lea	(v_lvllayout).w,a3
	if FixBugs
		move.w	#(v_lvllayout_end-v_lvllayout)/4-1,d1
	else
		; ; v_lvllayout is only $400 bytes, but this clears $800...
		; In Sonic 2, this function was corrected to only clear the layout buffer.
		move.w	#(v_lvllayout_end-v_lvllayout)/2-1,d1
	endif
		moveq	#0,d0
	.clear:	move.l	d0,(a3)+
		dbf	d1,.clear				; loop until buffer is cleared ($A400-A7FF)

		lea	(v_lvllayout_fg).w,a3			; target RAM address for level foreground layout
		moveq	#0,d1					; offset in Level_Index (0 = FG layout)
		bsr.w	LevelLayoutLoad2			; load FG level layout into RAM

		lea	(v_lvllayout_bg).w,a3			; target RAM address for background layout
		moveq	#2,d1					; offset in Level_Index (2 = BG layout)
		; fall-through for second run...
; ---------------------------------------------------------------------------

; "LevelLayoutLoad2" is run twice for (once for the FG and BG layouts each)
LevelLayoutLoad2:
		move.w	(v_zone_act).w,d0			; get current zone and act
		cmpi.b	#id_Title,(v_gamemode).w		; is this the title screen? (v_zone_act stays GHZ1 there)
		bne.s	.notTitle				; if not, branch
		move.w	#id_Title_Layout,d0			; use the title row (separate title FG and BG layouts)
	.notTitle:
		lsl.b	#6,d0
		lsr.w	#5,d0
		move.w	d0,d2
		add.w	d0,d0
		add.w	d2,d0					; d0 = Level_Index row for current zone and act
		add.w	d1,d0					; add pre-specified offset to get either FG or BG layout
		lea	(Level_Index).l,a1			; get layout index
		move.w	(a1,d0.w),d0				; advance to desired layout pointer in index
		lea	(a1,d0.w),a1				; load layout pointer from index

		moveq	#0,d1
		move.w	d1,d2
		move.b	(a1)+,d1				; load level width (in chunks)
		move.b	(a1)+,d2				; load level height (in chunks)
	.loopAllRows:
		move.w	d1,d0					; reset row length (width)
		movea.l	a3,a0					; set next target layout row in RAM
	.loopRow:
		move.b	(a1)+,(a0)+				; copy next chunk ID byte
		dbf	d0,.loopRow				; loop for one whole row
		lea	layout_row(a3),a3			; advance to next (skip over other plane)
		dbf	d2,.loopAllRows				; repeat for number of rows

		rts
; End of function LevelLayoutLoad
