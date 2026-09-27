; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4B - Giant Ring for entry to Special Stage
; ---------------------------------------------------------------------------

GiantRing:
		tst.b	(v_endcard).w				; results cards now own the shared tiles
		beq.s	.active
		cmpi.b	#8,obRoutine(a0)			; retain a hidden parent until its flash is done
		beq.w	GRing_WaitFlash
		bra.w	DeleteObject				; also reject rings loaded after the handoff
	.active:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	GRing_Index(pc,d0.w),d1
		jmp	GRing_Index(pc,d1.w)
; ===========================================================================
GRing_Index:	dc.w GRing_Main-GRing_Index
		dc.w GRing_Animate-GRing_Index
		dc.w GRing_Collect-GRing_Index
		dc.w GRing_Delete-GRing_Index
		dc.w GRing_WaitFlash-GRing_Index

gring_kind:	equ objoff_38	; zero for end ring, one/two for free rings, $FF for bonus flash
gring_parent:	equ objoff_3C	; parent giant ring object address used by flash object
; ===========================================================================

GRing_Main:	; Routine 0
		move.l	#Map_GRing,obMap(a0)			; set mappings
		move.w	#ArtTile_Giant_Ring|Tile_Pal2,obGfx(a0)	; set art tile and palette line
		ori.b	#sprite_cam_field,obRender(a0)		; set to playfield positioned mode
		move.b	#128/2,obActWid(a0)			; set sprite display width

		moveq	#0,d0
		move.b	obSubtype(a0),d0
		beq.s	.checkVisible
		subq.b	#1,d0
		btst	d0,(v_midring_flags).w		; remove a free ring used before this reload
		bne.w	GRing_Delete
	.checkVisible:
		out_of_range.w	GRing_Delete			; discard rings beyond the object window
		tst.b	(v_gfxringslotstate).w	; flash temporarily owns the shared art slot
		bne.s	.waitForApproach
		move.w	obX(a0),d0
		sub.w	(v_screenposx).w,d0		; ring center relative to camera
		cmpi.w	#-96,d0				; start loading near the left edge
		blt.s	.waitForApproach
		cmpi.w	#416,d0				; or 32 pixels before the right edge
		bgt.s	.waitForApproach
		move.w	obY(a0),d0
		sub.w	(v_screenposy).w,d0		; also require the ring near the vertical view
		cmpi.w	#-64,d0				; 32 pixels before the top edge
		blt.s	.waitForApproach
		cmpi.w	#288,d0				; 32 pixels beyond the bottom edge
		ble.s	.checkEmeralds
	.waitForApproach:
		rts
	.checkEmeralds:
		cmpi.b	#ss_emeralds_num,(v_emeralds).w		; do you have all 6 emeralds?
		bne.s	.checkSubtype
		tst.b	obSubtype(a0)			; act-end rings disappear after all emeralds
		beq.w	GRing_Delete
		bra.s	GRing_Okay				; free rings become 50-ring bonuses
	.checkSubtype:
		tst.b	obSubtype(a0)			; free rings have no ring-count requirement
		bne.s	GRing_Okay

	.checkRings:
		cmpi.w	#ss_giantring_rings,(v_rings).w		; end ring requires 50 rings
		bhs.s	GRing_Okay
		rts
; ===========================================================================

GRing_Okay:
		addq.b	#2,obRoutine(a0)			; set to GRing_Animate
		move.b	#2,obPriority(a0)			; set sprite priority
		move.b	#col_none,obColType(a0)		; wait until all ring tiles are loaded
		bset	#1,(v_gfxringslotstate).w	; ring owns the shared VRAM slot
		clr.b	(v_gfxexplosionrestore).w	; cancel a prior ring's restore
		move.w	#Art_BigRing_size,(v_gfxbigring).w	; trigger AniArt_GiantRing to load 96 tiles ($C00)
; ---------------------------------------------------------------------------

GRing_Animate:	; Routine 2
		btst	#0,(v_gfxringslotstate).w	; do not display ring mappings with flash art
		bne.s	.waitForArt
		move.w	obX(a0),d0
		sub.w	(v_screenposx).w,d0		; ring center relative to camera
		cmpi.w	#-128,d0				; 64 pixels past the left edge
		blt.w	GRing_Dormant
		cmpi.w	#448,d0				; 64 pixels past the right edge
		bgt.w	GRing_Dormant
		move.w	obY(a0),d0
		sub.w	(v_screenposy).w,d0
		cmpi.w	#-96,d0				; 64 pixels past the top edge
		blt.w	GRing_Dormant
		cmpi.w	#320,d0				; 64 pixels past the bottom edge
		bgt.w	GRing_Dormant
		tst.w	(v_gfxbigring).w			; hide incomplete ring graphics
		bne.s	.waitForArt
		move.b	#col_16x32|col_item,obColType(a0)
		move.b	(v_ani1_frame).w,obFrame(a0)		; set frame (updated in SynchroAnimate => Sync2)
		bra.w	DisplaySprite
	.waitForArt:
		rts
; ===========================================================================

GRing_Dormant:
		clr.b	obRoutine(a0)			; keep object for a possible camera reversal
		move.b	#col_none,obColType(a0)
		bsr.s	GRing_RestoreExplosion
		rts
; ===========================================================================

GRing_Offscreen:
		bsr.s	GRing_RestoreExplosion
		bra.w	DeleteObject
; ===========================================================================

GRing_RestoreExplosion:
		clr.w	(v_gfxbigring).w			; stop remaining ring tile transfers
		bclr	#1,(v_gfxringslotstate).w	; release ring ownership
		btst	#0,(v_gfxringslotstate).w	; never overwrite an active flash
		bne.s	.done
		move.b	#1,(v_gfxexplosionrestore).w	; restore explosions in the next VBlank
	.done:
		rts
; ===========================================================================

GRing_Collect:	; Routine 4
		cmpi.b	#ss_emeralds_num,(v_emeralds).w	; all emeralds turn free rings into bonuses
		bne.s	.stageEntry
		tst.b	obSubtype(a0)
		beq.w	GRing_Offscreen			; hide any act-end ring already on screen
		bra.w	GRing_Bonus
	.stageEntry:
		subq.b	#2,obRoutine(a0)			; go back to GRing_Animate
		move.b	#col_none,obColType(a0)			; disable further collision with ring

		bsr.w	FindFreeObj				; find a free object RAM slot
		bne.w	GRing_NoFlashSlot			; retry next time if RAM is full
		_move.b	#id_RingFlash,obID(a1)			; load giant ring flash object
		move.w	obX(a0),obX(a1)				; copy X-position
		move.w	obY(a0),obY(a1)				; copy Y-position
		move.l	a0,gring_parent(a1)			; make flash object remember parent ring object
		move.b	obSubtype(a0),gring_kind(a1)	; remember whether this ring ends the act
		move.w	(v_player+obX).w,d0			; get Sonic's X-position
		cmp.w	obX(a0),d0				; has Sonic entered the giant ring from the right?
		blo.s	.noFlip					; if not, branch
		bset	#sprite_xflip_bit,obRender(a1)		; set X-flip flag for flash object

	.noFlip:
		move.b	#$81,(f_playerctrl).w	; freeze Sonic and ignore objects during the flash
		clr.w	(v_player+obVelX).w
		clr.w	(v_player+obVelY).w
		clr.w	(v_player+obInertia).w
		move.b	#id_Null,(v_player+obAnim).w	; hide Sonic at the point of contact
		move.b	#5,(v_gfxringslotstate).w	; flash owns slot; queue a single VBlank DMA
		clr.b	(v_gfxexplosionrestore).w	; cancel an older ring's pending restore
		move.b	#8,obRoutine(a0)			; hide ring while its art is replaced
		clr.w	(v_gfxbigring).w			; stop any unfinished ring tile transfers
		bra.w	GRing_PlaySnd

GRing_NoFlashSlot:
		move.b	#col_16x32|col_item,obColType(a0)	; keep the ring usable if flash could not spawn
		rts

; Free giant rings give 50 rings once all Chaos Emeralds are collected.
GRing_Bonus:
		subq.b	#2,obRoutine(a0)			; keep the ring active if no flash slot is free
		move.b	#col_none,obColType(a0)
		bsr.w	FindFreeObj
		bne.w	GRing_NoFlashSlot
		_move.b	#id_RingFlash,obID(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.l	a0,gring_parent(a1)
		move.b	#$FF,gring_kind(a1)		; flash without Special Stage transition
		move.w	(v_player+obX).w,d0
		cmp.w	obX(a0),d0
		blo.s	.noFlip
		bset	#sprite_xflip_bit,obRender(a1)
	.noFlip:
		move.b	#5,(v_gfxringslotstate).w	; flash owns the art slot
		clr.b	(v_gfxexplosionrestore).w
		move.b	#8,obRoutine(a0)			; hide ring until the flash finishes
		clr.w	(v_gfxbigring).w
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		subq.b	#1,d0
		bset	d0,(v_midring_flags).w		; do not respawn this bonus on act reload
		moveq	#50,d0
		jsr	(AddRings).l			; add 50 rings (capped at 999) and award any 100-ring lives
		bne.s	.playSound			; if a life was awarded, play extra life music
		move.w	#sfx_GiantRing,d0
	.playSound:
		move.l	a0,-(sp)
		jsr	(QueueSound2).l
		movea.l	(sp)+,a0
		rts						; flash removes ring and restores explosion art

GRing_PlaySnd:
		move.w	#sfx_GiantRing,d0			; set giant ring sound
		jsr	(QueueSound2).l				; play it
		rts						; flash keeps the hidden parent ring alive
; ===========================================================================

GRing_Delete:	; Routine 6
		bra.w	DeleteObject				; delete giant ring

GRing_WaitFlash:	; Routine 8
		rts						; parent is hidden until flash releases it

; Results cards overlap the giant-ring/explosion slot. An uncollected end
; ring can remain in the locked camera forever, so waiting for it to leave
; the screen deadlocks RunPLC. Remove it before building the next sprites.
; Keep flash ownership: an active flash must finish before the card DMA.
GRing_EndAct:
		movem.l	d0-d2/a1,-(sp)
		clr.w	(v_gfxbigring).w			; cancel unfinished ring uploads
		bclr	#1,(v_gfxringslotstate).w	; retain flash and pending-flash DMA bits
		clr.b	(v_gfxexplosionrestore).w	; results art will replace this slot
		lea	(v_lvlobjspace).w,a1
		moveq	#(v_lvlobjend-v_lvlobjspace)/object_size-1,d2
	.loop:
		cmpi.b	#id_GiantRing,obID(a1)
		bne.s	.next
		cmpi.b	#8,obRoutine(a1)			; flash still needs its parent at frame 3
		beq.s	.next
		jsr	(DeleteChild).l				; advances a1 past the cleared slot
		bra.s	.advance
	.next:
		lea	object_size(a1),a1
	.advance:
		dbf	d2,.loop
		movem.l	(sp)+,d0-d2/a1
		rts


; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7C - Flash effect when you collect the Giant Ring
; ---------------------------------------------------------------------------

RingFlash:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Flash_Index(pc,d0.w),d1
		jmp	Flash_Index(pc,d1.w)
; ===========================================================================
Flash_Index:	dc.w Flash_Main-Flash_Index
		dc.w Flash_ChkDel-Flash_Index
		dc.w Flash_Delete-Flash_Index
; ===========================================================================

Flash_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)			; set to Flash_ChkDel
		move.l	#Map_Flash,obMap(a0)			; set mappings
		move.w	#ArtTile_Giant_Ring_Flash|Tile_Pal2,obGfx(a0) ; set art tile and palette line
		ori.b	#sprite_cam_field,obRender(a0)		; set to playfield positioned mode
		move.b	#0,obPriority(a0)			; set to maximum sprite priority
		move.b	#64/2,obActWid(a0)			; set sprite display width
		move.b	#-1,obFrame(a0)				; set to frame -1 so first run of Flash_Collect will set it to 0
; ---------------------------------------------------------------------------

Flash_ChkDel:	; Routine 2
		btst	#2,(v_gfxringslotstate).w	; do not show the flash before its DMA finishes
		bne.s	.waitForArt
		bsr.s	Flash_Collect				; advance ring animation, delete Sonic, and set flag
		bra.w	DisplaySprite				; keep updating even if the camera passes the flash
	.waitForArt:
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to handle the Giant Ring flash advance ring animation,
; delete Sonic, and set flag (this did not need to be a subroutine...)
; ---------------------------------------------------------------------------

Flash_Collect:
		subq.b	#1,obTimeFrame(a0)			; decrement delay until next frame
		bpl.w	.return					; if time remains, branch
		move.b	#1,obTimeFrame(a0)			; reset delay to 2 frames
		addq.b	#1,obFrame(a0)				; advance to next frame
		cmpi.b	#8,obFrame(a0)				; has animation finished? (8 frames)
		bhs.w	.deleteSonic				; if yes, branch
		cmpi.b	#3,obFrame(a0)				; is 3rd frame displayed?
		bne.w	.return					; if not, branch

		movea.l	gring_parent(a0),a1			; get parent giant ring object address
		move.b	#6,obRoutine(a1)			; delete parent object
		cmpi.b	#$FF,gring_kind(a0)		; bonus already awarded at contact
		beq.s	.return
		moveq	#0,d0
		move.b	gring_kind(a0),d0			; is this a free ring in the middle?
		beq.s	.endRing
		subq.b	#1,d0
		bset	d0,(v_midring_flags).w		; do not offer it again after returning
		move.b	(v_lastlamp).w,d1			; preserve the latest real checkpoint ID
		andi.b	#$7F,d1
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	(Lamp_StoreInfo).l			; save current act state for return
		movea.l	(sp)+,a0
		cmpi.w	#id_LZ_act3,(v_zone_act).w
		bne.s	.keepWater
		cmpi.b	#2,gring_kind(a0)		; second LZ3 ring is before the corks
		bne.s	.keepWater
		move.w	#$508,(v_lamp_wtrpos).w	; restart the local water rise
		move.b	#2,(v_lamp_wtrrout).w
		clr.b	(v_lamp_wtrstat).w
	.keepWater:
		ori.b	#$80,d1
		move.b	d1,(v_lastlamp).w		; restore as a temporary checkpoint
		move.b	d1,(v_lastlamp+1).w
		move.w	obX(a0),(v_lamp_xpos).w	; return at the center of the ring
		move.w	obY(a0),(v_lamp_ypos).w	; search from the ring, not Sonic's fall position
		bsr.w	GRing_ProjectReturnY		; settle the return point on the floor below
		bra.s	.afterRing

	.endRing:
		move.b	#1,(f_bigring).w			; original ring ends the act
	.afterRing:
		clr.b	(v_invinc).w				; remove invincibility
		clr.b	(v_shield).w				; remove shield

	.return:
		rts						; return
; ---------------------------------------------------------------------------

	.deleteSonic:
		addq.b	#2,obRoutine(a0)			; set to Flash_Delete
		cmpi.b	#$FF,gring_kind(a0)
		beq.s	.bonusDone			; keep Sonic in the level
		tst.b	gring_kind(a0)
		beq.s	.endAct
		jsr	(Sonic_RevertFromEvent).l
		move.b	#id_Special,(v_gamemode).w	; return to the same act afterwards
	.endAct:
		move.w	#0,(v_player).w				; delete Sonic object
		addq.l	#4,sp					; skip returning to Flash_ChkDel
		rts						; return
	.bonusDone:
		addq.l	#4,sp					; skip drawing the expired frame
		rts
; End of function Flash_Collect
; ===========================================================================
; Find the first solid floor below the center of the giant ring.
; Query in 16px steps so the normal floor collision routine can resolve slopes.
; Leave the ring-center Y if no floor is found within 512px.
; ---------------------------------------------------------------------------
GRing_ProjectReturnY:
		movem.l	d0-d7/a0-a4,-(sp)
		subq.l	#2,sp					; scratch byte for collision angle
		lea	(v_player).w,a0			; use Sonic's loop collision state
		move.w	(v_lamp_xpos).w,d3
		move.w	(v_lamp_ypos).w,d2
		addi.w	#sonic_height,d2			; bottom of standing Sonic
		moveq	#32-1,d7				; search at most 512 pixels down
	.scan:
		cmpi.w	#$800,d2				; do not wrap past the layout's bottom
		bhs.s	.done
		lea	(sp),a4
		clr.b	(a4)
		movea.w	#$10,a3
		moveq	#0,d6
		moveq	#$D,d5					; top-solid floor tiles
		jsr	(FindFloor).l
		cmpi.w	#16,d1				; blank tiles return 16 pixels or more
		bhs.s	.next					; also reject floors above Sonic
		add.w	d1,d2					; exact floor surface, including slopes
		subi.w	#sonic_height,d2
		move.w	d2,(v_lamp_ypos).w
		bra.s	.done
	.next:
		addi.w	#16,d2
		dbf	d7,.scan
	.done:
		addq.l	#2,sp
		movem.l	(sp)+,d0-d7/a0-a4
		rts
; ===========================================================================

Flash_Delete:	; Routine 4
		clr.b	(v_gfxringslotstate).w
		cmpi.b	#$FF,gring_kind(a0)
		bne.s	.done
		tst.b	(v_endcard).w			; results cards may already own this art
		bne.s	.done
		move.b	#1,(v_gfxexplosionrestore).w
	.done:
		bra.w	DeleteObject				; delete flash object
