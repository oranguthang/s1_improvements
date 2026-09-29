; ---------------------------------------------------------------------------
; Explicit Special Stage 1..6 selection. Earned progress is not used as a
; selector and is never reset here. v_ss_override is consumed by SS_Load.
; ---------------------------------------------------------------------------
LevSel_SSControls:
		move.b	(v_jpadpress1).w,d1
		andi.b	#btnL+btnR,d1
		beq.s	.return
		moveq	#0,d0
		move.b	(v_ss_selected).w,d0
		btst	#bitL,d1
		beq.s	.right
		subq.w	#1,d0
		bpl.s	.right
		moveq	#ss_emeralds_num-1,d0
	.right:
		btst	#bitR,d1
		beq.s	.store
		addq.w	#1,d0
		cmpi.w	#ss_emeralds_num,d0
		blo.s	.store
		moveq	#0,d0
	.store:
		move.b	d0,(v_ss_selected).w
		jmp	(LevSelTextLoad).l
	.return:
		rts

LevSel_DrawSSNumber:
		cmpi.b	#ss_emeralds_num,(v_ss_selected).w
		blo.s	.valid
		clr.b	(v_ss_selected).w
	.valid:
		move.w	#levsel_white,d3
		cmpi.w	#levsel_ss_row,(v_levselitem).w
		bne.s	.colorReady
		move.w	#levsel_yellow,d3
	.colorReady:
		locVRAM levsel_vram_main+(levsel_ss_row<<7)+(levsel_ss_col<<1),4(a6)
		moveq	#0,d0
		move.b	(v_ss_selected).w,d0
		addq.w	#1,d0
		add.w	d3,d0
		move.w	d0,(a6)
		rts

LevSel_StartSpecial:
		cmpi.b	#ss_emeralds_num,(v_ss_selected).w
		blo.s	.valid
		clr.b	(v_ss_selected).w
	.valid:
		move.b	(v_ss_selected).w,d0
		addq.b	#1,d0
		move.b	d0,(v_ss_override).w
		move.b	#1,(v_ss_manual).w
		clr.b	(v_jpadpress1).w
		clr.w	(f_demo).w
		clr.w	(f_restart).w
		clr.w	(v_lastlamp).w			; no old ring/lamppost respawn
		clr.b	(v_midring_flags).w
		clr.b	(v_endring_bonus).w
		move.w	#-1,(v_midring_act).w
		clr.b	(f_playerctrl).w
		clr.b	(f_lockctrl).w
		clr.b	(f_timeover).w
		clr.b	(v_supersonic).w
		clr.b	(v_superpal_state).w
		clr.w	(v_superpal_frame).w
		clr.b	(v_superpal_timer).w
		clr.b	(v_invinc).w
		clr.b	(v_shoes).w
		clr.b	(v_shield).w
		move.b	#id_Special,(v_gamemode).w
		clr.w	(v_zone_act).w
		move.b	#3,(v_lives).w
		clr.w	(v_rings).w
		clr.l	(v_time).w
		clr.l	(v_score).w
	if Revision<>0
		move.l	#5000,(v_scorelife).w
	endif
		rts

SS_ManualReturn:
		tst.b	(v_ss_manual).w
		beq.s	.return				; actual ring entries retain their saved act
		clr.b	(v_ss_manual).w
		jmp	(Tit_MenuReturn).l			; after results, return straight to the menu
	.return:
		rts
