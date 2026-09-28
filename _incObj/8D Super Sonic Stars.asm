; ===========================================================================
; Object 8D - Super Sonic speed stars, ported from Sonic 2 object 7E
; ===========================================================================

SuperSonicStars:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	SuperStars_Index(pc,d0.w),d1
		jmp	SuperStars_Index(pc,d1.w)

SuperStars_Index:
		dc.w SuperStars_Init-SuperStars_Index
		dc.w SuperStars_Main-SuperStars_Index

SuperStars_Init:
		addq.b	#2,obRoutine(a0)
		move.l	#Map_SuperSonicStars,obMap(a0)
		move.b	#sprite_cam_field,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#24/2,obActWid(a0)
		move.w	#ArtTile_SuperSonicStars,obGfx(a0)

SuperStars_Main:
		tst.b	(v_supersonic).w
		beq.w	SuperStars_Delete
		bsr.w	SuperStars_LoadGfx
		bmi.w	.waitForArt
		tst.b	objoff_30(a0)
		beq.s	.checkSpeed
		subq.b	#1,obTimeFrame(a0)
		bpl.s	.displayCheck
		move.b	#1,obTimeFrame(a0)
		addq.b	#1,obFrame(a0)
		cmpi.b	#6,obFrame(a0)
		blo.s	.displayCheck
		clr.b	obFrame(a0)
		clr.b	objoff_30(a0)
		move.b	#1,objoff_31(a0)
		rts

	.displayCheck:
		tst.b	objoff_31(a0)
		bne.s	.display

	.follow:
		move.w	(v_player+obX).w,obX(a0)
		move.w	(v_player+obY).w,obY(a0)

	.display:
		jmp	(DisplaySprite).l

	.checkSpeed:
		move.w	(v_player+obInertia).w,d0
		bpl.s	.speedPositive
		neg.w	d0
	.speedPositive:
		cmpi.w	#$800,d0
		blo.s	.hide
		clr.b	obFrame(a0)
		move.b	#1,objoff_30(a0)
		bra.s	.follow

	.hide:
		clr.b	objoff_30(a0)
		clr.b	objoff_31(a0)
		rts

	.waitForArt:
		rts

; A saturated DMA queue must not leave Super stars using shield tiles.
; Key $4000 is distinct from every shield/invincibility DPLC offset.
SuperStars_LoadGfx:
		movem.l	d1-d3/a1,-(sp)
		cmpi.w	#$4000,(v_shieldartkey).w
		beq.s	.loaded
		move.w	sr,-(sp)
		disableInts
		movea.w	(VDP_Command_Buffer_Slot).w,a1
		cmpa.w	#VDP_Command_Buffer_Slot,a1
		bhs.s	.full
		move.l	#Art_SuperSonicStars,d1
		move.w	#ArtTile_SuperSonicStars*tile_size,d2
		move.w	#14*tile_size/2,d3
		jsr	(QueueDMATransfer).l
		move.w	#$4000,(v_shieldartkey).w
		move.w	(sp)+,sr
.loaded:
		moveq	#0,d0
		movem.l	(sp)+,d1-d3/a1
		rts
.full:
		move.w	(sp)+,sr
		moveq	#-1,d0
		movem.l	(sp)+,d1-d3/a1
		rts

SuperStars_Delete:
		jmp	(DeleteObject).l
