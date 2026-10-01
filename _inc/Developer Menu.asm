; ===========================================================================
; ---------------------------------------------------------------------------
; Developer menu (entered from the unlocked title menu)
;
; The validated settings are loaded from SRAM into v_dev_settings; they survive
; level, Special Stage and title reloads as well as the reset button.
; See docs/developer_menu.md for the option semantics.
; ---------------------------------------------------------------------------

devmenu_magic:		equ $5D					; v_dev_magic value once defaults are set

devmenu_row_emeralds: equ 0
devmenu_row_debug: equ 1
devmenu_row_rings: equ 2
devmenu_row_drain: equ 3
devmenu_row_god: equ 4
devmenu_rows: equ 5

devmenu_header_len:	equ 6					; "CHEATS"
devmenu_label_len:	equ 21					; characters per option name
devmenu_value_len:	equ 3					; characters per option value

devmenu_header_row:	equ 9					; top tile offset of the header
devmenu_start_row:	equ 11					; top tile offset of the first option
devmenu_start_col:	equ levsel_start_col			; same left edge as the level select
devmenu_vram_header:	equ vram_win+(devmenu_header_row<<7)+((devmenu_start_col+(devmenu_label_len+devmenu_value_len-devmenu_header_len)/2)<<1)
devmenu_vram_rows:	equ vram_win+(devmenu_start_row<<7)+(devmenu_start_col<<1)

; ---------------------------------------------------------------------------
; Set the default settings unless they are already valid. Called on every
; menu entry. Startup instead loads the validated SRAM record.
; ---------------------------------------------------------------------------

DevMenu_ChkDefaults:
		cmpi.b	#devmenu_magic,(v_dev_magic).w
		beq.w	Settings_Normalize
Settings_Defaults:
		clr.b (v_character_p1).w
		move.b #Character_Off,(v_character_p2).w
		clr.b (v_options_menuitem).w
		clr.b	(v_dev_debug).w
		clr.b	(v_dev_super).w		; obsolete RAM slots remain reserved
		clr.b	(v_dev_emeralds).w
		clr.b	(v_dev_all_emeralds).w
		clr.b	(v_title_unlocked).w
		move.b	#50,(v_dev_superrings).w
		move.b	#1,(v_dev_superdrain).w
		clr.b	(v_dev_god).w
		clr.b	(v_dev_menuitem).w
		move.b	#devmenu_magic,(v_dev_magic).w
		rts
; End of function DevMenu_ChkDefaults

; ===========================================================================
; ---------------------------------------------------------------------------
; Menu entry from the title screen (reached by Tit_CheckMenuButtons,
; so rts returns to MainGameLoop)
; ---------------------------------------------------------------------------

Tit_EnterDevMenu:
		clr.b	(v_jpadpress1).w			; consume the confirming A/C/Start
		bsr.w	LevSel_PrepareScreen			; level select palette and background
		move.w	#0,(v_levseldelay).w			; reuse the level select repeat delay
		bsr.w	DevMenu_Draw				; draw the menu before entering the main loop
		bsr.w	LevSel_ShowScreen			; show the completed menu in one step

DevMenu_Loop:
		move.b	#id_VBlank_Title,(v_vblank_routine).w	; set VBlank routine to $04
		bsr.w	WaitForVBlank				; wait for VBlank to finish
		bsr.w	DevMenu_Controls			; change row or setting
		bne.s	DevMenu_Exit				; branch if Start requested return
		bsr.w	RunPLC					; keep loading PLC_Main like the level select
		bra.s	DevMenu_Loop

DevMenu_Exit:
		bra.w	Tit_MenuReturn

; ---------------------------------------------------------------------------
; Menu controls
;
; output:
;	d0 = 1 and Z clear to leave the menu, otherwise d0 = 0 and Z set
; ---------------------------------------------------------------------------

DevMenu_Controls:
		move.b	(v_jpadpress1).w,d1			; get current button presses
		andi.b	#btnUp+btnDn,d1				; is up/down pressed this frame?
		bne.s	.updown					; if yes, branch
		subq.w	#1,(v_levseldelay).w			; if held, subtract 1 from delay until next move
		bpl.s	.change					; if time remains, branch

	.updown:
		move.w	#12-1,(v_levseldelay).w			; reset time delay
		move.b	(v_jpadhold1).w,d1			; get currently held buttons
		andi.b	#btnUp+btnDn,d1				; is up/down held?
		beq.s	.change					; if not, branch
		moveq	#0,d0
		move.b	(v_dev_menuitem).w,d0			; get currently selected row
		btst	#bitUp,d1				; is up held?
		beq.s	.down					; if not, branch
		subq.w	#1,d0					; move up 1 row
		bpl.s	.down					; if still valid, branch
		moveq	#devmenu_rows-1,d0			; wrap to the last row

	.down:
		btst	#bitDn,d1				; is down held?
		beq.s	.setrow					; if not, branch
		addq.w	#1,d0					; move down 1 row
		cmpi.w	#devmenu_rows,d0			; is it past the last row?
		blo.s	.setrow					; if not, branch
		moveq	#0,d0					; wrap to the first row

	.setrow:
		move.b	d0,(v_dev_menuitem).w			; set new row
		bra.w	.redraw
; ---------------------------------------------------------------------------

	.change:
		move.b	(v_jpadpress1).w,d1			; get current button presses
		andi.b	#btnABC+btnStart+btnL+btnR,d1		; was an action button pressed?
		beq.w	.none					; if not, branch
		andi.b	#btnStart,d1			; only Start returns; B toggles like A/C
		bne.w	.exit
		move.b	(v_jpadpress1).w,d1
		moveq	#0,d0
		move.b	(v_dev_menuitem).w,d0			; get currently selected row
		cmpi.b	#devmenu_row_rings,d0			; is SUPER RINGS selected?
		beq.s	.rings					; if yes, branch

		add.w	d0,d0					; the other rows are ON/OFF switches
		lea	DevMenu_Vars(pc),a1
		movea.w	(a1,d0.w),a1				; get the setting's RAM address
		eori.b	#1,(a1)					; toggle it
		cmpi.b	#devmenu_row_drain*2,d0
		bne.s	.save
		tst.b	(v_dev_superdrain).w
		beq.s	.save
		tst.b	(v_dev_superrings).w
		bne.s	.save
		move.b	#10,(v_dev_superrings).w	; enabling drain at zero promotes to 10
		bra.s	.save
; ---------------------------------------------------------------------------

	.rings:
		lea	DevMenu_RingSteps(pc),a1
		move.b	(v_dev_superrings).w,d0			; get current threshold
		moveq	#DevMenu_RingSteps_end-DevMenu_RingSteps-1,d2

	.findstep:
		cmp.b	(a1,d2.w),d0				; is this the current step?
		beq.s	.foundstep				; if yes, branch
		dbf	d2,.findstep				; check the next step
		moveq	#DevMenu_RingSteps_end-DevMenu_RingSteps-1,d2 ; unknown value: treat as the last step

	.foundstep:
		btst	#bitL,d1				; is left pressed?
		beq.s	.nextstep				; if not, advance
		subq.w	#1,d2					; previous step
		bpl.s	.setstep				; if still valid, branch
		moveq	#DevMenu_RingSteps_end-DevMenu_RingSteps-1,d2 ; wrap to the last step
		bra.s	.setstep

	.nextstep:
		addq.w	#1,d2					; next step
		cmpi.w	#DevMenu_RingSteps_end-DevMenu_RingSteps,d2 ; is it past the last step?
		blo.s	.setstep				; if not, branch
		moveq	#0,d2					; wrap to the first step

	.setstep:
		move.b	(a1,d2.w),(v_dev_superrings).w		; set new threshold

	.save:
		jsr	(Settings_Normalize).l
		jsr	(Settings_Save).l

	.redraw:
		bsr.w	DevMenu_Draw				; refresh the menu

	.none:
		moveq	#0,d0					; stay in the menu
		rts
; ---------------------------------------------------------------------------

	.exit:
		moveq	#1,d0					; leave the menu
		rts
; End of function DevMenu_Controls

; ---------------------------------------------------------------------------
; RAM address of each row's setting (SUPER RINGS is handled separately)
; ---------------------------------------------------------------------------

DevMenu_Vars:
		dc.w v_dev_all_emeralds&$FFFF
		dc.w v_dev_debug&$FFFF
		dc.w v_dev_superrings&$FFFF
		dc.w v_dev_superdrain&$FFFF
		dc.w v_dev_god&$FFFF

DevMenu_RingSteps:
		dc.b 0, 10, 50					; SUPER RINGS values in menu order
DevMenu_RingSteps_end:
		even

; ===========================================================================
; ---------------------------------------------------------------------------
; Draw the menu with the level select font (selected row in yellow)
; ---------------------------------------------------------------------------

DevMenu_Draw:
		lea	(vdp_data_port).l,a6			; prepare VDP data write
		locVRAM	devmenu_vram_header,4(a6)		; header position
		lea	(DevMenu_Header).l,a1
		move.w	#levsel_white,d3
		moveq	#devmenu_header_len-1,d2
		bsr.w	DevMenu_DrawText			; draw "CHEATS"

		lea	(DevMenu_Labels).l,a1			; first option name
		locVRAM	devmenu_vram_rows,d4			; first option position
		moveq	#0,d1					; row index

	.row:
		move.l	d4,4(a6)				; set VRAM address for this row
		move.w	#levsel_white,d3			; unselected rows are white
		cmp.b	(v_dev_menuitem).w,d1			; is this the selected row?
		bne.s	.colour					; if not, branch
		move.w	#levsel_yellow,d3			; selected row is yellow

	.colour:
		moveq	#devmenu_label_len-1,d2
		bsr.w	DevMenu_DrawText			; draw option name (a1 advances to the next one)
		move.l	a1,-(sp)
		bsr.s	DevMenu_GetValue			; a1 = value text for this row
		moveq	#devmenu_value_len-1,d2
		bsr.w	DevMenu_DrawText			; draw value right after the name
		movea.l	(sp)+,a1
		addi.l	#$00800000,d4				; next line
		addq.w	#1,d1
		cmpi.w	#devmenu_rows,d1			; have all rows been drawn?
		blo.s	.row					; if not, loop
		locVRAM vram_win+(17<<7)+(levsel_start_col<<1),4(a6)
		lea	DevMenu_Hint(pc),a1
		move.w	#levsel_white,d3
		moveq	#19-1,d2
		bra.w	DevMenu_DrawText
; End of function DevMenu_Draw

; ---------------------------------------------------------------------------
; Get the value text of a row
;
; input:
;	d1.w = row
; output:
;	a1 = 3-character value text
; ---------------------------------------------------------------------------

DevMenu_GetValue:
		cmpi.w	#devmenu_row_rings,d1
		beq.s	.rings
		move.w	d1,d0
		add.w	d0,d0
		lea	DevMenu_Vars(pc),a1
		movea.w	(a1,d0.w),a1				; get the setting's RAM address
		moveq	#1,d0
		and.b	(a1),d0					; 0 = "OFF", 1 = " ON"
		bra.s	.gottext

	.rings:
		move.b	(v_dev_superrings).w,d2
		moveq	#2,d0					; "  0"
		tst.b	d2
		beq.s	.gottext
		moveq	#3,d0					; " 10"
		cmpi.b	#10,d2
		beq.s	.gottext
		moveq	#4,d0					; " 50"

	.gottext:
		move.w	d0,d2
		add.w	d0,d0
		add.w	d2,d0					; 3 characters per value
		lea	(DevMenu_Values).l,a1
		adda.w	d0,a1
		rts
; End of function DevMenu_GetValue

; ---------------------------------------------------------------------------
; Draw characters with the level select font
;
; input:
;	a1 = text
;	d2 = number of characters - 1
;	d3 = VRAM setting (white or yellow)
;	a6 = VDP data port (address already set)
; ---------------------------------------------------------------------------

DevMenu_DrawText:
		moveq	#0,d0
		move.b	(a1)+,d0				; get current character
		bpl.s	.char					; is it a valid character? if yes, branch
		move.w	#0,(a6)					; draw a blank character
		dbf	d2,DevMenu_DrawText			; loop until all characters are drawn
		rts

	.char:
		add.w	d3,d0					; combine char with VRAM setting
		move.w	d0,(a6)					; send to VRAM
		dbf	d2,DevMenu_DrawText			; loop until all characters are drawn
		rts
; End of function DevMenu_DrawText

; ===========================================================================
; ---------------------------------------------------------------------------
; Developer menu text (same character set as LevelMenuText)
; ---------------------------------------------------------------------------

	charset ' ', $FF
	charset '0','9',$00
	charset 'Y','Z',$0F ; Y and Z come before A-X
	charset 'A','X',$11

DevMenu_Header:
		dc.b "CHEATS"
DevMenu_Header_end:

DevMenu_Labels:
		dc.b "ALL EMERALDS         "
		dc.b "DEBUG                "
		dc.b "SUPER RINGS          "
		dc.b "RING DRAIN           "
		dc.b "GOD MODE             "
DevMenu_Labels_end:

DevMenu_Hint:
		dc.b "PRESS START TO EXIT"

DevMenu_Values:
		dc.b "OFF"					; 0
		dc.b " ON"					; 1
		dc.b "  0"					; 2
		dc.b " 10"					; 3
		dc.b " 50"					; 4
		dc.b "   "					; 5
DevMenu_Values_end:
		even

	if MOMPASS=1
		if DevMenu_Header_end-DevMenu_Header<>devmenu_header_len
			warning "DevMenu_Header does not match devmenu_header_len."
		endif
		if DevMenu_Labels_end-DevMenu_Labels<>devmenu_rows*devmenu_label_len
			warning "DevMenu_Labels does not match expected row count/length."
		endif
		if DevMenu_Values_end-DevMenu_Values<>6*devmenu_value_len
			warning "DevMenu_Values does not match expected value count/length."
		endif
		if (DevMenu_RingSteps-DevMenu_Vars)/2<>devmenu_row_god+1
			warning "DevMenu_Vars does not match the ON/OFF rows."
		endif
	endif

	charset	; reset charset to default
	even
