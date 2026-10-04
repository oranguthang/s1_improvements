; ===========================================================================
; Object 8E - Super Tails' four Super Flickies, ported from Sonic 3 & Knuckles
; (Obj_SuperTailsBirds, https://github.com/sonicretro/skdisasm).
; Each bird circles Tails, picks a visible badnik or boss from the collision
; queue and flies into it. Several birds never chase the same object. When
; Tails stops being Super they fly off to the top left and disappear.
; ===========================================================================

flicky_angle:	equ objoff_30				; orbit angle (byte)
flicky_found:	equ objoff_31				; nonzero while chasing flicky_target
flicky_delay:	equ objoff_32				; frames before the next search
flicky_target:	equ objoff_34				; RAM address of the chased object (word)
flicky_search_delay:	equ 2*60			; S3K: search again two seconds after a hit

SuperTailsFlickies:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Flicky_Index(pc,d0.w),d1
		jmp	Flicky_Index(pc,d1.w)

Flicky_Index:
		dc.w Flicky_Init-Flicky_Index
		dc.w Flicky_Main-Flicky_Index
		dc.w Flicky_FlyAway-Flicky_Index

Flicky_Init:
		bsr.w	Flicky_LoadGfx
		bmi.w	Flicky_Return				; wait for the DMA queue
		addq.b	#2,obRoutine(a0)
		move.l	#Map_SuperTailsFlickies,obMap(a0)
		move.b	#sprite_cam_field,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#16/2,obActWid(a0)
		move.w	#ArtTile_SuperTailsFlickies|Tile_Prio,obGfx(a0)
		move.w	(v_player+obX).w,obX(a0)		; start off screen, top left of Tails
		subi.w	#$C0,obX(a0)
		move.w	(v_player+obY).w,obY(a0)
		subi.w	#$C0,obY(a0)
		clr.w	obVelX(a0)
		clr.w	obVelY(a0)

Flicky_Main:
		tst.b	(v_supersonic).w
		bne.s	.stillSuper
		clr.b	flicky_found(a0)			; Tails has reverted: fly away
		addq.b	#2,obRoutine(a0)
		bra.w	Flicky_FlyAway

	.stillSuper:
		bsr.w	Flicky_GetDestination
		bra.s	Flicky_MoveAndDraw

Flicky_FlyAway:
		move.w	(v_shieldartkey).w,d0		; reverting frees the slot; reload unless the shield took it
		beq.s	.slotFree
		cmpi.w	#$4001,d0
		bne.w	Flicky_Delete
	.slotFree:
		move.w	(v_player+obX).w,d2
		subi.w	#$C0,d2
		move.w	(v_player+obY).w,d3
		subi.w	#$C0,d3
		tst.b	obRender(a0)
		bpl.w	Flicky_Delete				; gone once off screen

Flicky_MoveAndDraw:
		bsr.w	Flicky_Move
		addq.b	#2,flicky_angle(a0)
		tst.w	obVelX(a0)
		beq.s	.flipped
		bclr	#0,obRender(a0)
		tst.w	obVelX(a0)
		bpl.s	.flipped
		bset	#0,obRender(a0)
	.flipped:
		subq.b	#1,obTimeFrame(a0)			; two-frame wing beat
		bpl.s	.display
		move.b	#1,obTimeFrame(a0)
		bchg	#0,obFrame(a0)
	.display:
		bsr.w	Flicky_LoadGfx
		bmi.s	Flicky_Return				; hide rather than show stale tiles
		jmp	(DisplaySprite).l

Flicky_Delete:
		jmp	(DeleteObject).l

Flicky_Return:
		rts

; Output d2/d3 = destination X/Y.
Flicky_GetDestination:
		tst.b	flicky_found(a0)
		bne.s	.chase
		tst.b	flicky_delay(a0)
		beq.s	.search
		subq.b	#1,flicky_delay(a0)
		bra.s	.orbit

	.search:
		bsr.w	Flicky_FindTarget
		bne.s	.chase

	.orbit:
		move.b	flicky_angle(a0),d0
		jsr	(CalcSine).l
		asr.w	#3,d0					; 32 pixels either side
		asr.w	#4,d1					; 16 pixels above and below
		move.w	(v_player+obX).w,d2
		move.w	(v_player+obY).w,d3
		subi.w	#$20,d3
		add.w	d0,d2
		add.w	d1,d3
		rts

	.chase:
		movea.w	flicky_target(a0),a1
		move.w	obX(a1),d2
		move.w	obY(a1),d3
		tst.b	obRender(a1)
		bpl.s	.release				; the target left the screen
		bsr.w	Flicky_IsEnemy
		beq.s	.release				; destroyed, flashing or replaced
		move.w	obX(a0),d0
		sub.w	d2,d0
		addi.w	#$C,d0
		cmpi.w	#$18,d0
		bhs.s	.return					; not within 12 pixels yet
		move.w	obY(a0),d0
		sub.w	d3,d0
		addi.w	#$C,d0
		cmpi.w	#$18,d0
		bhs.s	.return
		movem.l	d2-d3,-(sp)			; keep this frame's destination
		tst.b	obBossHits(a1)
		beq.s	.badnik
		jsr	(React_DamageBoss).l
		bra.s	.hit

	.badnik:
		jsr	(React_DestroyBadnik).l

	.hit:
		movem.l	(sp)+,d2-d3

	.release:
		clr.b	flicky_found(a0)
		move.b	#flicky_search_delay,flicky_delay(a0)

	.return:
		rts

; Return Z clear if a1 is a visible badnik or boss with collision enabled.
Flicky_IsEnemy:
		move.b	obColType(a1),d0
		beq.s	.no
		andi.b	#$C0,d0					; col_badnik/col_boss, not items or hazards
		bne.s	.no
		moveq	#1,d0
		rts
	.no:
		moveq	#0,d0
		rts

; Search the collision queue for an unclaimed enemy. Return Z clear if found.
Flicky_FindTarget:
		movem.l	d1/d6/a1-a3,-(sp)
		lea	(v_colqueue).w,a2
		move.w	(v_colqueue_ptr).w,d6
		sub.w	a2,d6					; queue size in bytes
		cmpi.w	#colqueue_entries*2,d6
		bhi.s	.fullScan				; ReactToItem rebuilds an invalid queue; scan RAM instead
		lsr.w	#1,d6
		subq.w	#1,d6
		bcs.s	.none

	.nextQueued:
		movea.w	(a2)+,a1
		bsr.s	.consider
		bne.s	.found
		dbf	d6,.nextQueued
		bra.s	.none

	.fullScan:
		lea	(v_lvlobjspace).w,a1
		moveq	#(v_lvlobjend-v_lvlobjspace)/object_size-1,d6
	.nextObject:
		bsr.s	.consider
		bne.s	.found
		lea	object_size(a1),a1
		dbf	d6,.nextObject

	.none:
		moveq	#0,d0
		movem.l	(sp)+,d1/d6/a1-a3
		rts

	.found:
		move.w	a1,flicky_target(a0)
		move.b	#1,flicky_found(a0)
		moveq	#1,d0
		movem.l	(sp)+,d1/d6/a1-a3
		rts

; Z clear if a1 is a visible enemy no other Flicky is chasing.
	.consider:
		tst.b	obRender(a1)
		bpl.s	.reject
		bsr.s	Flicky_IsEnemy
		beq.s	.reject
		lea	(v_starsobj1).w,a3
		moveq	#4-1,d1
	.otherBird:
		cmpa.l	a0,a3
		beq.s	.nextBird
		cmpi.b	#id_SuperTailsFlickies,obID(a3)
		bne.s	.nextBird
		tst.b	flicky_found(a3)
		beq.s	.nextBird
		cmpa.w	flicky_target(a3),a1
		beq.s	.reject
	.nextBird:
		lea	object_size(a3),a3
		dbf	d1,.otherBird
		moveq	#1,d0
		rts
	.reject:
		moveq	#0,d0
		rts

; Steer toward d2/d3 with S3K's acceleration, doubled twice when turning back.
Flicky_Move:
		move.w	#$20,d1
		cmp.w	obX(a0),d2
		bge.s	.right
		neg.w	d1
		tst.w	obVelX(a0)
		bmi.s	.xReady
		add.w	d1,d1
		add.w	d1,d1
		bra.s	.xReady
	.right:
		tst.w	obVelX(a0)
		bpl.s	.xReady
		add.w	d1,d1
		add.w	d1,d1
	.xReady:
		add.w	d1,obVelX(a0)

		move.w	#$20,d1
		sub.w	obY(a0),d3
		bcc.s	.below
		cmpi.w	#-$500,d3
		ble.s	.down
	.up:
		cmpi.w	#-$1000,obVelY(a0)
		ble.s	.yLimit
	.upAccel:
		neg.w	d1
		tst.w	obVelY(a0)
		bmi.s	.yReady
		add.w	d1,d1
		add.w	d1,d1
		bra.s	.yReady
	.below:
		cmpi.w	#$500,d3
		bge.s	.up
	.down:
		cmpi.w	#$1000,obVelY(a0)
		bge.s	.upAccel
	.yLimit:
		tst.w	obVelY(a0)
		bpl.s	.yReady
		add.w	d1,d1
		add.w	d1,d1
	.yReady:
		add.w	d1,obVelY(a0)
		jmp	(SpeedToPos).l

; Queue the 14 Flicky tiles into the shared shield slot once (key $4001).
; Output d0.l = 0 when the tiles are resident, -1 to wait for queue room.
Flicky_LoadGfx:
		movem.l	d1-d3/a1,-(sp)
		cmpi.w	#$4001,(v_shieldartkey).w
		beq.s	.loaded
		move.w	sr,-(sp)
		disableInts
		movea.w	(VDP_Command_Buffer_Slot).w,a1
		cmpa.w	#VDP_Command_Buffer_Slot,a1
		bhs.s	.full
		move.l	#Art_SuperTailsFlickies,d1
		move.w	#ArtTile_SuperTailsFlickies*tile_size,d2
		move.w	#14*tile_size/2,d3
		jsr	(QueueDMATransfer).l
		move.w	#$4001,(v_shieldartkey).w
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
