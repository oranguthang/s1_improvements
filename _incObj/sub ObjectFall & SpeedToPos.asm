; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to make an object fall downwards, increasingly fast
; ---------------------------------------------------------------------------
gravity:	equ	$38				; gravity constant used by many objects
; ---------------------------------------------------------------------------

ObjectFall:
		movem.w	obVelX(a0),d0/d3			; sign-extend both 8.8 velocities
		asl.l	#8,d0					; convert X velocity to 16.16 delta
		add.l	d0,obX(a0)				; update X, including subpixel position
		move.l	obX(a0),d2				; preserve the original d2 result
		asl.l	#8,d3					; convert Y velocity to 16.16 delta
		move.l	d3,d0					; preserve the original d0 result
		add.l	d3,obY(a0)				; move with the pre-gravity velocity
		addi.w	#gravity,obVelY(a0)		; apply gravity for the next frame
		move.l	obY(a0),d3				; preserve the original d3 and condition codes
		rts						; return
; End of function ObjectFall


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine translating object speed to update object position.
; Identical to ObjectFall, but without applying gravity.
; ---------------------------------------------------------------------------

SpeedToPos:
		movem.w	obVelX(a0),d0/d3			; sign-extend both 8.8 velocities
		asl.l	#8,d0					; convert X velocity to 16.16 delta
		add.l	d0,obX(a0)				; update X, including subpixel position
		move.l	obX(a0),d2				; preserve the original d2 result
		asl.l	#8,d3					; convert Y velocity to 16.16 delta
		move.l	d3,d0					; preserve the original d0 result
		add.l	d3,obY(a0)				; update Y, including subpixel position
		move.l	obY(a0),d3				; preserve the original d3 and condition codes
		rts						; return
; End of function SpeedToPos
