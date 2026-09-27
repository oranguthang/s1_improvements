; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4F - Splats enemy (MZ, restored from the prototype)
; ---------------------------------------------------------------------------

Splats:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Splats_Index(pc,d0.w),d1
		jmp	Splats_Index(pc,d1.w)
; ===========================================================================
Splats_Index:	dc.w Splats_Main-Splats_Index		; 0
		dc.w Splats_Wait-Splats_Index		; 2
		dc.w Splats_Bounce-Splats_Index		; 4
		dc.w Splats_FallLava-Splats_Index	; 6
; ===========================================================================

Splats_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)			; advance to Splats_Wait
		move.l	#Map_Splats,obMap(a0)			; set mappings
		move.w	#ArtTile_Splats|Tile_Pal2,obGfx(a0)	; set art tile and palette line
		move.b	#sprite_cam_field,obRender(a0)		; set to playfield-positioned mode
		move.b	#4,obPriority(a0)			; set sprite priority
		move.b	#24/2,obActWid(a0)			; set sprite display width
		move.b	#40/2,obHeight(a0)			; set height
		move.b	#col_24x40|col_badnik,obColType(a0)	; set hitbox size to 24x40 (destroyable badnik)

		tst.b	obSubtype(a0)				; is subtype 0?
		beq.s	Splats_Wait				; if yes, use the small trigger zone
		move.w	#$300,d2				; use a large trigger zone
		bra.s	Splats_TriggerSet
; ===========================================================================

Splats_Wait:	; Routine 2
		move.w	#$E0,d2					; use the default trigger zone

Splats_TriggerSet:
		move.w	#$100,d1				; prepare X speed (right)
		bset	#sprite_xflip_bit,obRender(a0)		; face right
		move.w	(v_player+obX).w,d0			; get Sonic's X-position
		sub.w	obX(a0),d0				; subtract Splats' X-position
		bcc.s	.chkTrigger				; if Sonic is to the right, branch
		neg.w	d0					; make distance positive
		neg.w	d1					; prepare X speed (left)
		bclr	#sprite_xflip_bit,obRender(a0)		; face left

	.chkTrigger:
		cmp.w	d2,d0					; is Sonic within the trigger zone?
		bcc.s	Splats_Bounce				; if not, bounce in place
		move.w	d1,obVelX(a0)				; start moving towards Sonic
		addq.b	#2,obRoutine(a0)			; advance to Splats_Bounce
; ---------------------------------------------------------------------------

Splats_Bounce:	; Routine 4
		bsr.w	ObjectFall				; apply gravity and update position
		move.b	#1,obFrame(a0)				; use "ears flapping" frame
		tst.w	obVelY(a0)				; is Splats moving upwards?
		bmi.s	.chkWall				; if yes, branch
		move.b	#0,obFrame(a0)				; use "standing" frame

		bsr.w	ObjFloorDist				; get distance to floor
		tst.w	d1					; has Splats hit the floor?
		bpl.s	.chkWall				; if not, branch
		move.w	(a1),d0					; get 16x16 block Splats landed on
		andi.w	#$3FF,d0				; keep only the block ID
		cmpi.w	#$16A,d0				; is it an MZ lava block?
		blo.s	.bounce					; if not, branch
		addq.b	#2,obRoutine(a0)			; advance to Splats_FallLava
		bra.s	.chkWall

	.bounce:
		add.w	d1,obY(a0)				; align with floor
		move.w	#-$400,obVelY(a0)			; bounce up

	.chkWall:
		bsr.w	ChkHitLeftRightWall			; has Splats hit a wall?
		beq.s	.display				; if not, branch
		neg.w	obVelX(a0)				; reverse direction
		bchg	#sprite_xflip_bit,obRender(a0)		; flip sprite
		bchg	#0,obStatus(a0)				; flip status

	.display:
		bra.w	RememberState				; display, or delete if out of range
; ===========================================================================

Splats_FallLava: ; Routine 6
		bsr.w	ObjectFall				; sink through the lava
		tst.b	obRender(a0)				; is Splats on screen?
		bpl.w	DeleteObject				; if not, delete
		bra.w	DisplaySprite				; display sprite
