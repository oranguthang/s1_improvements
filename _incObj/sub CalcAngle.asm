; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine calculate an arctangent of two input coordinates (i.e. the angle)
; 
; input:
;	d1 = x-axis distance
;	d2 = y-axis distance
; 
; output:
;	d0 = angle (d0.l = $0000xxxx)
;	d1-d4 and all address registers are preserved
; ---------------------------------------------------------------------------

CalcAngle:
		move.l	d3,-(sp)				; store register data (d0 doubles as the Y work register, so d4 is no longer used)
		moveq	#0,d3					; clear upper word for the 32-bit shift below
		move.w	d1,d3					; copy X distance
		bpl.s	.posX					; if it's already positive, branch
		neg.w	d3					; convert to positive
.posX:
		moveq	#0,d0					; clear upper word for the 32-bit shift below
		move.w	d2,d0					; copy Y distance
		bpl.s	.posY					; if it's already positive, branch
		neg.w	d0					; convert to positive
.posY:
		cmp.w	d3,d0					; find out which one has a larger distance
		bhs.s	.yIsBigger				; if Y has a larger (or equal) distance, branch

.xIsBigger:	; degrees 0 to 45 (X is nonzero here)
		lsl.l	#8,d0					; multiply Y by 100 (creating fraction space)
		divu.w	d3,d0					; divide by X distance (quotient < $100)
		move.w	d0,d3					; use quotient as table index
		moveq	#0,d0					; prepare 0 degree angle
		move.b	Angle_Data(pc,d3.w),d0			; load correct angle (advance up to correct angle 00 - 45 degrees)
		bra.s	.checkXFlip				; continue to 360 accommodation
; ===========================================================================

.yIsBigger:	; degrees 45 to 90
		tst.w	d0					; is Y 0 (and therefore X as well)?
		beq.s	CA_NullAngle				; if yes, branch to finish with angle $40 right away
		lsl.l	#8,d3					; multiply X by 100 (creating fraction space)
		divu.w	d0,d3					; divide by Y distance (quotient <= $100)
		moveq	#$40,d0					; prepare 90 degree angle
		sub.b	Angle_Data(pc,d3.w),d0			; load correct angle (subtract down to correct angle 90 - 45 degrees)

.checkXFlip:
		tst.w	d1					; check X distance
		bpl.s	.chkYFlip				; if distance were positive, branch to skip mirror
		neg.w	d0					; mirror angle
		addi.w	#$40*2,d0				; ''

.chkYFlip:
		tst.w	d2					; check Y distance
		bpl.s	.return					; if distance were positive, branch to skip flip
		neg.w	d0					; flip angle
		addi.w	#$40*4,d0				; ''

.return:
		movem.l	(sp)+,d3				; restore register data (movem keeps the CCR from the flip checks)
		rts						; return
; ===========================================================================

CA_NullAngle:
		moveq	#$40,d0					; force angle to $40 (90 degrees)
		movem.l	(sp)+,d3				; restore register data (movem keeps the CCR)
		rts						; return
; End of function CalcAngle

; ===========================================================================
; This data consists of 256 bytes to account for one 45 degree section of a circle.
; The other quadrants are retrieved by adding multiples of $40.
; The extra 257th byte at the end is for ratio X=Y when inputs are unequal 0.

Angle_Data:
		dc.b    0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  2,  2,  2,  2,  2,  2
		dc.b    3,  3,  3,  3,  3,  3,  3,  4,  4,  4,  4,  4,  4,  5,  5,  5
		dc.b    5,  5,  5,  6,  6,  6,  6,  6,  6,  6,  7,  7,  7,  7,  7,  7
		dc.b    8,  8,  8,  8,  8,  8,  8,  9,  9,  9,  9,  9,  9, $A, $A, $A
		dc.b   $A, $A, $A, $A, $B, $B, $B, $B, $B, $B, $B, $C, $C, $C, $C, $C
		dc.b   $C, $C, $D, $D, $D, $D, $D, $D, $D, $E, $E, $E, $E, $E, $E, $E
		dc.b   $F, $F, $F, $F, $F, $F, $F,$10,$10,$10,$10,$10,$10,$10,$11,$11
		dc.b  $11,$11,$11,$11,$11,$11,$12,$12,$12,$12,$12,$12,$12,$13,$13,$13
		dc.b  $13,$13,$13,$13,$13,$14,$14,$14,$14,$14,$14,$14,$14,$15,$15,$15
		dc.b  $15,$15,$15,$15,$15,$15,$16,$16,$16,$16,$16,$16,$16,$16,$17,$17
		dc.b  $17,$17,$17,$17,$17,$17,$17,$18,$18,$18,$18,$18,$18,$18,$18,$18
		dc.b  $19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$1A,$1A,$1A,$1A,$1A,$1A
		dc.b  $1A,$1A,$1A,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1C,$1C,$1C
		dc.b  $1C,$1C,$1C,$1C,$1C,$1C,$1C,$1C,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D
		dc.b  $1D,$1D,$1D,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F
		dc.b  $1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$20,$20,$20,$20,$20,$20
		dc.b  $20
		even
; ===========================================================================
