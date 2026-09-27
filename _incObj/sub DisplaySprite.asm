; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to display a sprite/object, when a0 is the object RAM
; ---------------------------------------------------------------------------

	; The fast queue-full check below relies on the entry counter byte overflowing
	; into bit 7 exactly when the layer is full, i.e. a $80 byte layer.
	if spritelayer_size<>$80
		fatal "DisplaySprite requires spritelayer_size = $80, but it is $\{spritelayer_size}."
	endif
	if spritelayer_num<>8
		fatal "DisplaySprite requires spritelayer_num = 8, but it is $\{spritelayer_num}."
	endif

DisplaySprite:
		moveq	#spritelayer_num-1,d0			; possible sprite priorities
		and.b	obPriority(a0),d0			; mask by object's sprite priority (upper byte of the old word read)
		add.w	d0,d0					; double it for word-based indexing
		movea.w	DSpr_Layers(pc,d0.w),a1			; get target sprite queue layer
		move.w	(a1),d0					; get layer's entry counter (always $00-$7E)
		addq.b	#2,d0					; increase count by another entry (word)
		bmi.s	.return					; if counter went to $80, layer is full, drop queuing this sprite
		move.w	d0,(a1)					; set new entry counter
		move.w	a0,(a1,d0.w)				; insert RAM address for object

	.return:
		rts						; return
; End of function DisplaySprite

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to display a 2nd sprite/object, when a1 is the object RAM
; ---------------------------------------------------------------------------

; DisplaySprite1: <-- old misnomer
DisplaySprite2:
		moveq	#spritelayer_num-1,d0			; possible sprite priorities
		and.b	obPriority(a1),d0			; mask by object's sprite priority (upper byte of the old word read)
		add.w	d0,d0					; double it for word-based indexing
		movea.w	DSpr_Layers(pc,d0.w),a2			; get target sprite queue layer
		move.w	(a2),d0					; get layer's entry counter (always $00-$7E)
		addq.b	#2,d0					; increase count by another entry (word)
		bmi.s	.return					; if counter went to $80, layer is full, drop queuing this sprite
		move.w	d0,(a2)					; set new entry counter
		move.w	a1,(a2,d0.w)				; insert RAM address for object

	.return:
		rts						; return
; End of function DisplaySprite2

; ---------------------------------------------------------------------------
; Precalculated sprite queue layer addresses (short RAM addresses)
; ---------------------------------------------------------------------------
DSpr_Layers:
		dc.w v_spritequeue+(spritelayer_size*0)
		dc.w v_spritequeue+(spritelayer_size*1)
		dc.w v_spritequeue+(spritelayer_size*2)
		dc.w v_spritequeue+(spritelayer_size*3)
		dc.w v_spritequeue+(spritelayer_size*4)
		dc.w v_spritequeue+(spritelayer_size*5)
		dc.w v_spritequeue+(spritelayer_size*6)
		dc.w v_spritequeue+(spritelayer_size*7)
