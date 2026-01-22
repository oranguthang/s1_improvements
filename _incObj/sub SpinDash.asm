; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to check for starting to charge a Spin Dash
; ---------------------------------------------------------------------------

Sonic_SpinDash:
		btst	#0,spindash_flag(a0)		; is Spin Dash flag already set?
		bne.s	Sonic_UpdateSpindash		; if yes, branch to alternate routine
		cmpi.b	#id_Duck,obAnim(a0)		; is Sonic in his ducking animation?
		bne.s	.end				; if not, branch
		moveq	#btnABC,d0			; is A, B, or C...
		and.b	(v_jpadpress2).w,d0		; ...currently pressed? (not held)
		beq.w	.end				; if not, branch

		move.b	#id_SpinDash,obAnim(a0)		; change Sonic's animation to Spin Dashing
		move.w	#sfx_SpinDash,d0		; set Spin Dash sound
		jsr	(QueueSound2).l			; play it
		addq.l	#4,sp				; skip previous stack entry (i.e. don't do anything else in Sonic_MdNormal)
		bset	#0,spindash_flag(a0)		; set the Spin Dash flag
		clr.w	spindash_count(a0)		; set the Spin Dash counter to start at 0

		bsr.w	Sonic_LevelBound		; because we skipped the stack pointer...
		bsr.w	Sonic_AnglePos			; ...we need to manually run some Sonic stuff
.end:
		rts
; ===========================================================================

Sonic_UpdateSpindash:
		btst	#bitDn,(v_jpadhold2).w		; is down (still) held?
		bne.w	Sonic_ChargingSpindash		; if yes, keep charging Spin Dash

		move.b	#$E,obHeight(a0)		; reset Sonic's height to the appropriate value
		move.b	#7,obWidth(a0)			; reset Sonic's width to the appropriate value
		move.b	#id_Roll,obAnim(a0)		; set Sonic's animation to rolling
		addq.w	#5,obY(a0)			; add the difference between Sonic's rolling and standing heights
		bclr	#0,spindash_flag(a0)		; unset Spin Dash flag
		bset	#2,obStatus(a0)			; set Sonic's rolling flag
		move.w	#sfx_Teleport,d0		; set Spin Dash zoom sound
		jsr	(QueueSound2).l 		; play it

		moveq	#0,d0				; clear d0
		move.b	spindash_count(a0),d0		; get number of Spin Dash revs that were performed
		lsl.w	#7,d0				; multiply by $80 for each rev
		move.w	d0,d1				; copy for camera-delay calculation
		addi.w	#$800,d0			; add base speed of $800

		btst	#0,obStatus(a0)			; is Sonic looking to the left?
		beq.s	.not_left			; if not, branch
		neg.w	d0				; negate charge direction
.not_left:	move.w	d0,obInertia(a0)		; apply final speed

		; Camera delay
		add.w	d1,d1				; double 0-based speed
		andi.w	#$1F00,d1			; limit result (not necessary, none of the removed bits are ever set in the first place)
		neg.w	d1				; make result negative
		addi.w	#$2000,d1			; add a static base delay against it
		move.w	d1,(v_cam_x_delay).w		; set the final value as camera delay

		bra.s	Sonic_Spindash_ResetScr		; skip
; ===========================================================================

Sonic_ChargingSpindash:
		move.b	#id_SpinDash,obAnim(a0)		; make sure Spin Dash animation stays

		tst.w	spindash_count(a0)		; were any revs done?
		beq.s	.no_rev				; if not, branch
		move.w	spindash_count(a0),d0		; get current number of revs
		lsr.w	#5,d0				; divide that number by 32
		sub.w	d0,spindash_count(a0)		; subtract that number from the stored revs (basically a decay)
		bhs.s	.no_rev				; if result is still positive, branch
		clr.w	spindash_count(a0)		; if we underflowed, reset rev counter to 0
.no_rev:
		moveq	#btnABC,d0			; is A, B, or C...
		and.b	(v_jpadpress2).w,d0		; ...currently pressed? (not held)
		beq.w	Sonic_Spindash_ResetScr		; if not, branch
		move.w	#(id_SpinDash<<8),obAnim(a0)	; restart Spin Dash animation
		move.w	#sfx_SpinDash,d0		; set Spin Dash charge sound
		jsr	(QueueSound2).l			; play it
		addi.w	#$200,spindash_count(a0)	; increase rev counter by 2
		cmpi.w	#$800,spindash_count(a0)	; did we exceed the maximum?
		blo.s	Sonic_Spindash_ResetScr		; if not, branch
		move.w	#$800,spindash_count(a0)	; cap charge counter at maximum

Sonic_Spindash_ResetScr:
		addq.l	#4,sp				; skip previous stack entry (i.e. don't do anything else in Sonic_MdNormal)
		cmpi.w	#(224/2)-16,(v_lookshift).w	; is vertical camera offset at base level?
		beq.s	.resetscr_end			; if yes, branch
		bhs.s	.pull_cam_up			; if not and the camera is offset downwards, branch
		addq.w	#2,(v_lookshift).w		; move camera down
		bra.s	.resetscr_end			; skip over
.pull_cam_up:	subq.w	#2,(v_lookshift).w		; move camera up

.resetscr_end:
		bsr.w	Sonic_LevelBound		; because we skipped the stack pointer...
		bsr.w	Sonic_AnglePos			; ...we need to manually run some Sonic stuff
		rts
; End of function Sonic_SpinDash
