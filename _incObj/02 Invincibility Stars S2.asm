; ===========================================================================
; ---------------------------------------------------------------------------
; Object 02 - Sonic 2 invincibility stars (FeatureS2Stars)
;
; Port of Sonic 2's obj35, after KoiSAKANA's "Port Sonic 2 invincibility
; stars to Sonic 1" (https://info.sonicretro.org/SCHG_How-to:Port_Sonic_2_invincibility_stars_to_Sonic_1).
; The first object circles the player; it spawns three more that follow the
; recorded positions further back. Each draws two stars as sub-sprites
; (obSubSprites). The art is 34 uncompressed tiles, DMA-transferred to
; ArtTile_InvStarsS2 when invincibility starts. That area holds the Game Over
; art, the act results counters and the debug coordinates, none of which can
; be shown while the stars are: death, the act results and the giant ring all
; clear v_invinc, and HudDb_ChkHidden hides the debug coordinates meanwhile.
; ---------------------------------------------------------------------------

InvStarsS2:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	IStar_Index(pc,d0.w),d1
		jmp	IStar_Index(pc,d1.w)
; ===========================================================================
IStar_Index:	dc.w IStar_Init-IStar_Index
		dc.w IStar_Main-IStar_Index
		dc.w IStar_Trail-IStar_Index

istar_frames:	equ objoff_30		; frame script of a trailing group (4 bytes)
istar_angle:	equ objoff_34		; angle of the first star around the group's centre
istar_phase:	equ objoff_35		; script offset of the second star
istar_trail:	equ objoff_36		; position along the trail (0 = around the player)
istar_ready:	equ objoff_37		; set in the first object once the art is queued
istar_count:	equ objoff_38		; current script position (2 bytes)

; Frame script, starting angle and phase of each group; the first group
; uses IStar_MainFrames instead.
IStar_Groups:
		dc.l 0
		dc.b 4, 0
		dc.l IStar_Frames1
		dc.b 0, $B
		dc.l IStar_Frames2
		dc.b $16, $D
		dc.l IStar_Frames3
		dc.b $2C, $D
; ===========================================================================

IStar_Init:	; Routine 0
		moveq	#0,d2
		lea	IStar_Groups(pc),a2
		lea	(a0),a1
		moveq	#4-1,d1

	.spawn:
		move.b	obID(a0),obID(a1)			; load the star groups into v_starsobj1-4
		move.b	#4,obRoutine(a1)
		move.l	#Map_InvStarsS2,obMap(a1)
		move.w	#ArtTile_InvStarsS2,obGfx(a1)
		move.b	#sprite_cam_field|sprite_subsprites,obRender(a1)
		move.b	#1,obPriority(a1)
		move.b	#64/2,obActWid(a1)			; stars reach 31 pixels out
		clr.b	obFrame(a1)				; the parent frame is blank
		move.b	#2,obSubSprites(a1)			; two stars per group
		move.b	d2,istar_trail(a1)
		addq.w	#1,d2
		move.l	(a2)+,istar_frames(a1)
		move.b	(a2)+,istar_angle(a1)
		move.b	(a2)+,istar_phase(a1)
		clr.b	istar_ready(a1)
		clr.w	istar_count(a1)
		lea	object_size(a1),a1
		dbf	d1,.spawn

		move.b	#2,obRoutine(a0)
; ===========================================================================

IStar_Main:	; Routine 2
		tst.b	(v_invinc).w				; has invincibility run out?
		beq.w	IStar_Delete
		tst.b	(v_supersonic).w			; Super forms have their own stars
		bne.w	IStar_Delete
		tst.b	istar_ready(a0)				; are the tiles queued?
		bne.s	.ready
		bsr.w	IStar_LoadGfx
	.ready:
		lea	(v_player).w,a1
		move.w	obX(a1),obX(a0)				; circle around the player
		move.w	obY(a1),obY(a0)
		lea	subspr_data(a0),a2
		lea	IStar_MainFrames(pc),a3
		moveq	#0,d5

	.getFrame:
		move.w	istar_count(a0),d2
		move.b	(a3,d2.w),d5
		bpl.s	.gotFrame
		clr.w	istar_count(a0)				; restart the script
		bra.s	.getFrame

	.gotFrame:
		addq.w	#1,istar_count(a0)
		move.b	istar_angle(a0),d6
		bsr.w	IStar_SetChild				; first star
		addi.w	#$20,d6
		bsr.w	IStar_SetChild				; second star, opposite the first
		moveq	#$12,d0					; spin with the player's facing
		btst	#0,obStatus(a1)
		beq.s	.spin
		neg.w	d0
	.spin:
		add.b	d0,istar_angle(a0)
		bra.s	IStar_Display
; ===========================================================================

IStar_Trail:	; Routine 4
		tst.b	(v_invinc).w				; has invincibility run out?
		beq.w	IStar_Delete
		tst.b	(v_supersonic).w
		bne.w	IStar_Delete
		lea	(v_player).w,a1
		moveq	#0,d1
		move.b	istar_trail(a0),d1
		lsl.b	#2,d1
		move.w	d1,d2
		add.w	d1,d1
		add.w	d2,d1					; three recorded positions per group
		move.w	(v_trackpos).w,d0
		sub.b	d1,d0					; earlier recorded position
		lea	(v_tracksonic).w,a2
		lea	(a2,d0.w),a2
		move.w	(a2)+,obX(a0)
		move.w	(a2)+,obY(a0)
		lea	subspr_data(a0),a2
		movea.l	istar_frames(a0),a3

	.getFrame:
		move.w	istar_count(a0),d2
		move.b	(a3,d2.w),d5
		bpl.s	.gotFrame
		clr.w	istar_count(a0)				; restart the script
		bra.s	.getFrame

	.gotFrame:
		swap	d5					; keep the first star's frame
		add.b	istar_phase(a0),d2
		move.b	(a3,d2.w),d5				; the second star runs ahead in the script
		addq.w	#1,istar_count(a0)
		move.b	istar_angle(a0),d6
		bsr.s	IStar_SetChild
		addi.w	#$20,d6
		swap	d5
		bsr.s	IStar_SetChild
		moveq	#2,d0
		btst	#0,obStatus(a1)
		beq.s	.spin
		neg.w	d0
	.spin:
		add.b	d0,istar_angle(a0)

IStar_Display:
		tst.b	(v_starsobj1+istar_ready).w		; are the tiles queued?
		beq.s	.hide
		cmpi.w	#2*60,(v_player+invtime).w		; flash for the last two seconds
		bhi.s	.show
		btst	#2,(v_framecount+1).w			; all groups blink together
		bne.s	.hide
	.show:
		jmp	(DisplaySprite).l

	.hide:
		rts
; ===========================================================================

IStar_Delete:
		jmp	(DeleteObject).l

; ---------------------------------------------------------------------------
; Write one star: position at angle d6 around the group, frame d5.
; ---------------------------------------------------------------------------

IStar_SetChild:
		andi.w	#$3E,d6
		move.b	IStar_Offsets(pc,d6.w),subspr_x(a2)
		move.b	IStar_Offsets+1(pc,d6.w),subspr_y(a2)
		move.b	d5,subspr_frame(a2)
		addq.w	#subspr_size,a2
		rts

; Circle of 32 X/Y offsets (Sonic 2's byte_1DB42).
IStar_Offsets:
		dc.w   $F00,  $F03,  $E06,  $D08,  $B0B,  $80D,  $60E,  $30F
		dc.w    $10, -$3F1, -$6F2, -$8F3, -$BF5, -$DF8, -$EFA, -$FFD
		dc.w  $F000, -$F04, -$E07, -$D09, -$B0C, -$80E, -$60F, -$310
		dc.w   -$10,  $3F0,  $6F1,  $8F2,  $BF4,  $DF7,  $EF9,  $FFC

; ---------------------------------------------------------------------------
; Queue the 34 star tiles once, when the DMA queue has room for them.
; ---------------------------------------------------------------------------

IStar_LoadGfx:
		move.w	sr,-(sp)
		disableInts					; keep VBlank from flushing the queue meanwhile
		movea.w	(VDP_Command_Buffer_Slot).w,a1
		adda.w	#DMAEntry.len,a1
		cmpa.w	#VDP_Command_Buffer_Slot,a1		; is there room for the transfer?
		bhi.s	.full					; if not, retry next frame
		move.l	#Art_InvStarsS2,d1
		move.w	#ArtTile_InvStarsS2*tile_size,d2
		move.w	#(Art_InvStarsS2_End-Art_InvStarsS2)/2,d3
		jsr	(QueueDMATransfer).l
		st.b	istar_ready(a0)
	.full:
		move.w	(sp)+,sr
		rts

; Frame scripts (Sonic 2's byte_1DB82 to byte_1DBBD); a negative byte loops.
IStar_MainFrames:
		dc.b	8, 5, 7, 6, 6, 7, 5, 8, 6, 7, 7, 6, -1
IStar_Frames1:
		dc.b	8, 7, 6, 5, 4, 3, 4, 5, 6, 7, -1
		dc.b	3, 4, 5, 6, 7, 8, 7, 6, 5, 4
IStar_Frames2:
		dc.b	8, 7, 6, 5, 4, 3, 2, 3, 4, 5, 6, 7, -1
		dc.b	2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3
IStar_Frames3:
		dc.b	7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, -1
		dc.b	1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2
		even
