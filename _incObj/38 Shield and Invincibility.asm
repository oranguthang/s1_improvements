; ===========================================================================
; ---------------------------------------------------------------------------
; Object 38 - shield and invincibility stars
; ---------------------------------------------------------------------------

ShieldItem:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Shi_Index(pc,d0.w),d1
		jmp	Shi_Index(pc,d1.w)
; ===========================================================================
Shi_Index:	dc.w Shi_Main-Shi_Index
		dc.w Shi_Shield-Shi_Index
		dc.w Shi_Stars-Shi_Index

stars_lag:	equ objoff_30		; lag index before stars update position again
; ===========================================================================

Shi_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)			; advance to Shi_Shield
		move.l	#Map_Shield,obMap(a0)			; set shield mappings
		move.b	#sprite_cam_field,obRender(a0)		; set playfield-positioning mode
		move.b	#1,obPriority(a0)			; set sprite priority (above Sonic)
		move.b	#32/2,obActWid(a0)			; set sprite display width

		tst.b	obAnim(a0)				; is object a shield?
		bne.s	.stars					; if not, branch
		move.w	#ArtTile_Shield,obGfx(a0)		; shield-specific art tile
		rts						; return

	.stars:
		addq.b	#2,obRoutine(a0)			; advance to Shi_Stars
		move.w	#ArtTile_Invincibility,obGfx(a0)	; stars-specific art tile
		rts						; return
; ===========================================================================

Shi_Shield:	; Routine 2
		tst.b	(v_invinc).w				; has Sonic gained invincibility after already having a shield?
		bne.s	.hide					; if yes, hide shield sprite
		tst.b	(v_supersonic).w			; hide shield while Super
		bne.s	.hide
		tst.b	(v_shield).w				; has Sonic lost the shield?
		beq.s	.delete					; if yes, delete it

		move.w	(v_player+obX).w,obX(a0)		; keep copying Sonic's X-position
		move.w	(v_player+obY).w,obY(a0)		; keep copying Sonic's Y-position
		move.b	(v_player+obStatus).w,obStatus(a0)	; keep Sonic's status flags for rendering
		lea	(Ani_Shield).l,a1			; load shield animation script
		jsr	(AnimateSprite).l			; keep animating shield
		move.l	#Art_Shield,d1				; shield art for the shared slot
		moveq	#0,d4					; shield key flag
		bsr.w	ShieldStars_LoadGfx
		bmi.s	.hide					; new tiles could not be queued yet
		jmp	(DisplaySprite).l			; display shield sprite

	.hide:
		rts						; hide shield sprite but don't delete it

	.delete:
		jmp	(DeleteObject).l			; delete shield object
; ===========================================================================

Shi_Stars:	; Routine 4
		tst.b	(v_invinc).w				; has invincibility run out?
		beq.w	Shi_Start_Delete			; if yes, delete stars object
		tst.b	(v_supersonic).w			; hide invincibility stars while Super
		bne.s	Shi_Start_Delete

		move.w	(v_trackpos).w,d0			; get index value for tracking data
		move.b	obAnim(a0),d1				; get stars animation ID (1-4)
		subq.b	#1,d1					; make it 0-based
		bra.s	.trail					; skip over dead code

; ===========================================================================
; unused older trailing code that makes a much shorter trail
	; .trail_unused:
		lsl.b	#4,d1					; multiply animation ID by 16
		addq.b	#4,d1
		sub.b	d1,d0
		move.b	stars_lag(a0),d1
		sub.b	d1,d0					; use earlier tracking data to create trail
		addq.b	#4,d1
		andi.b	#$F,d1
		move.b	d1,stars_lag(a0)
		bra.s	.updateStars
; ===========================================================================

	.trail:
		lsl.b	#3,d1					; multiply animation ID by 8
		move.b	d1,d2
		add.b	d1,d1
		add.b	d2,d1					; multiply by 3
		addq.b	#4,d1					; advance to next recorded position array index
		sub.b	d1,d0					; d0 = base index for animation ID

		; This makes stars effectively only update position every 6 frames to create a small jitter effect
		move.b	stars_lag(a0),d1			; get previous lag value
		sub.b	d1,d0					; subtract lag value use earlier tracking data to create trail
		addq.b	#4,d1					; increment lag value to previous recording array index
		cmpi.b	#6*4,d1					; has lag value exceeded limit? (=$18)
		blo.s	.updateLag				; if not, branch
		moveq	#0,d1					; reset lag value
	;.a:
	.updateLag:
		move.b	d1,stars_lag(a0)			; update lag value for next run

	; .b:
	.updateStars:
		lea	(v_tracksonic).w,a1			; load Sonic's recorded position data array (each entry is 4 bytes, a word per X/Y)
		lea	(a1,d0.w),a1				; go to desired recorded position
		move.w	(a1)+,obX(a0)				; set new X-position
		move.w	(a1)+,obY(a0)				; set new Y-position
		move.b	(v_player+obStatus).w,obStatus(a0)	; keep Sonic's status flags for rendering
		lea	(Ani_Shield).l,a1			; load stars animation script (bundled with shield animations)
		jsr	(AnimateSprite).l			; keep animating stars
		move.l	#Art_InvincibilityStars,d1		; stars art for the shared slot
		move.w	#$8000,d4				; stars key flag
		bsr.s	ShieldStars_LoadGfx			; all four stars objects stay in phase
		bmi.s	.nodisplay				; new tiles could not be queued yet
		jmp	(DisplaySprite).l			; keep displaying stars

	.nodisplay:
		rts
; ===========================================================================

Shi_Start_Delete:
		jmp	(DeleteObject).l			; delete invincibility stars object

; ---------------------------------------------------------------------------
; Queue the tiles of the current frame into the shared 18-tile slot at
; ArtTile_Shield. The shield, invincibility stars and Super Sonic stars are
; never shown together, so they share the slot. v_shieldartkey records what
; is in it (DPLC script offset, bit 15 set for stars; 0 = unknown), so the
; DMA is only queued when the tiles change. Anything else that writes the
; slot must clear v_shieldartkey.
;
; The whole entry is queued or none of it: if the DMA queue lacks room for
; every transfer, the key stays unchanged (retry next frame) and the caller
; hides this frame instead of showing it with stale tiles. The room check and
; the queue writes run with interrupts masked (UseVIntSafeDMA=0), so VBlank
; cannot flush the queue in between. The art must not cross a 128kB boundary
; (checked in sonic.asm), so each DPLC task takes exactly one queue entry.
;
; input:
;	d1.l = art source
;	d4.w = key flag (0 = shield, $8000 = stars)
;
; output:
;	d0.l = 0 (Z set) to display, -1 (N set) to hide this frame
;	all other registers preserved
; ---------------------------------------------------------------------------

ShieldStars_LoadGfx:
		movem.l	d1-d6/a1-a2,-(sp)
		moveq	#0,d0
		move.b	obFrame(a0),d0				; load frame number
		add.w	d0,d0
		lea	(ShieldDynPLC).l,a2			; load DPLC script
		move.w	(a2,d0.w),d0				; get offset of this frame's entry
		or.w	d0,d4					; key = script offset + art flag
		adda.w	d0,a2					; find current DPLC entry
		moveq	#0,d5
		move.b	(a2)+,d5				; get number of tasks in this entry
		beq.s	.display				; blank frame: leave the slot as it is
		cmp.w	(v_shieldartkey).w,d4			; are these tiles already loaded?
		beq.s	.display				; if yes, branch

		move.w	sr,-(sp)
		disableInts					; keep VBlank from flushing the queue meanwhile
		move.w	d5,d0
		mulu.w	#DMAEntry.len,d0			; queue space for the whole entry
		movea.w	(VDP_Command_Buffer_Slot).w,a1
		adda.w	d0,a1
		cmpa.w	#VDP_Command_Buffer_Slot,a1		; does every transfer fit?
		bhi.s	.full					; if not, queue nothing and retry next frame
		move.w	d4,(v_shieldartkey).w
		subq.w	#1,d5					; loop count
		move.l	d1,d6					; keep art source
		move.w	#ArtTile_Shield*tile_size,d4		; target VRAM address

	.loop:
		moveq	#0,d1
		move.b	(a2)+,d1				; get first byte of DPLC task
		lsl.w	#8,d1
		move.b	(a2)+,d1				; get second byte of DPLC task
		move.w	d1,d3
		lsr.w	#8,d3
		andi.w	#$F0,d3					; tile count-1 in the upper nybble
		addi.w	#$10,d3					; d3 = transfer length in words
		andi.w	#$FFF,d1				; first art tile
		lsl.l	#5,d1					; multiply by tile_size
		add.l	d6,d1					; add art source
		move.w	d4,d2					; set target VRAM address
		add.w	d3,d4
		add.w	d3,d4					; next VRAM address
		jsr	(QueueDMATransfer).l
		dbf	d5,.loop
		move.w	(sp)+,sr				; restore interrupts

	.display:
		moveq	#0,d0					; show this frame
		movem.l	(sp)+,d1-d6/a1-a2			; (movem keeps the flags)
		rts

	.full:
		move.w	(sp)+,sr				; restore interrupts
		moveq	#-1,d0					; old tiles are still in the slot: hide
		movem.l	(sp)+,d1-d6/a1-a2
		rts
