; ---------------------------------------------------------------------------
; Selbi's 6-button protocol, adapted to detect on every frame and preserve
; all existing input/RAM addresses. No extra-button action bindings yet.
; VBlank owns the Z80 bus across this call; standalone callers own it too.
; Reference: https://www.plutiedev.com/controllers#6-button
; ---------------------------------------------------------------------------
Joypad_PollTH macro hiPoll
	if hiPoll
		move.b	#$40,(a1)
	else
		move.b	#0,(a1)
	endif
		nop
		nop
	endm

JoypadInit:
		stopZ80
		waitZ80
		moveq	#$40,d0
		move.b	d0,(port_1_control).l
		move.b	d0,(port_2_control).l
		move.b	d0,(expansion_control).l
		move.b	d0,(port_1_data).l
		move.b	d0,(port_2_data).l
		clr.l	(v_jpadhold1).w
		clr.l	(v_jpadhold_p2).w
		startZ80
		rts

ReadJoypads:
		movem.l	d2,-(sp)				; retain the old routine's clobber set
		lea	(port_1_data).l,a1
		lea	(v_jpadhold1).w,a0
		bsr.s	.readPort
		lea	(port_2_data).l,a1
		lea	(v_jpadhold_p2).w,a0
		bsr.s	.readPort
		movem.l	(sp)+,d2
		rts

	.readPort:
		Joypad_PollTH 1
		moveq	#$3F,d0
		and.b	(a1),d0				; D-pad/B/C, active low
		Joypad_PollTH 0
		moveq	#$30,d1
		and.b	(a1),d1				; A/Start only, independent of D-pad
		lsl.b	#2,d1
		or.b	d1,d0
		not.b	d0
		move.b	(a0),d1
		move.b	d0,(a0)+
		eor.b	d0,d1
		and.b	d0,d1
		move.b	d1,(a0)+			; unchanged SACBRLDU edge behavior

		Joypad_PollTH 1
		Joypad_PollTH 0
		Joypad_PollTH 1
		Joypad_PollTH 0
		moveq	#$0F,d2
		and.b	(a1),d2				; sixth poll's ID, not A/Start states
		Joypad_PollTH 1				; always finish with TH high
		moveq	#$0F,d0
		and.b	(a1),d0
		tst.b	d2
		bne.s	.threeButton
		not.b	d0
		andi.b	#$0F,d0
		ori.b	#Joypad6_Connected,d0
		bra.s	.storeExtra
	.threeButton:
		moveq	#0,d0				; unplugged/3-button pads clear old extras
	.storeExtra:
		move.b	(a0),d1
		move.b	d0,(a0)+
		eor.b	d0,d1
		and.b	d0,d1
		andi.b	#$0F,d1				; type detection is never a button press
		move.b	d1,(a0)+
		rts
