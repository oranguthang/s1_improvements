; ===========================================================================
; ---------------------------------------------------------------------------
; Object 8F - Tails' tails, ported from Sonic 3 & Knuckles (Obj_Tails_Tail,
; https://github.com/sonicretro/skdisasm). The tails follow the solo player,
; pick their animation from Tails' animation, and turn with the rolling
; velocity. Their art goes into the second half of the player VRAM slot;
; body frames that show the tails fit the first half (see s1tools player
; tails), while larger body frames draw their tails in the body art.
; ---------------------------------------------------------------------------

tail_parentani:	equ objoff_30			; Tails' animation seen last frame
tail_vramframe:	equ objoff_31			; tail frame resident in VRAM ($FF = none)

TailsTail:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	TTail_Index(pc,d0.w),d1
		jmp	TTail_Index(pc,d1.w)

TTail_Index:
		dc.w TTail_Init-TTail_Index
		dc.w TTail_Main-TTail_Index

TTail_Init:
		addq.b	#2,obRoutine(a0)
		move.l	#Map_TailsTail,obMap(a0)
		move.w	#ArtTile_Tails_Tail,obGfx(a0)
		move.b	#sprite_cam_field,obRender(a0)
		move.b	#2,obPriority(a0)
		move.b	#48/2,obActWid(a0)
		move.b	#-1,tail_parentani(a0)
		move.b	#-1,tail_vramframe(a0)

TTail_Main:
		lea	(v_player).w,a2
		cmpi.b	#id_SonicSpecial,obID(a2)		; rolling through a Special Stage?
		beq.w	TTail_Special
		cmpi.b	#id_SonicPlayer,obID(a2)		; replaced by an ending or results object?
		bne.w	TTail_Delete
		cmpi.b	#Character_Tails,(v_character_p1).w
		bne.w	TTail_Delete
		tst.w	(v_debuguse).w				; placement mode shows an item instead
		bne.w	TTail_Return
		move.w	obX(a2),obX(a0)
		move.w	obY(a2),obY(a0)
		move.b	obStatus(a2),d0
		andi.b	#1,d0					; facing only: the player's bit 1 means airborne,
		move.b	d0,obStatus(a0)				; which AnimateSprite would read as a Y flip
		move.b	obPriority(a2),obPriority(a0)
		move.w	obGfx(a2),d0
		andi.w	#Tile_Prio,d0				; follow the player's plane priority
		ori.w	#ArtTile_Tails_Tail,d0
		move.w	d0,obGfx(a0)

		bsr.w	TTail_SelectAnim
		cmpi.b	#tailani_Directional,d0
		bne.s	.scripted
		move.b	d0,obAnim(a0)
		move.b	d0,obPrevAni(a0)
		bsr.w	TTail_Directional
		bra.s	.animated
	.scripted:
		move.b	d0,obAnim(a0)
		lea	(Ani_TailsTail).l,a1
		jsr	(AnimateSprite).l

	.animated:
		tst.b	obFrame(a0)				; frame 0 is blank: the body draws its tails
		beq.w	TTail_Return
		bsr.w	TTail_BodyFitsHalf
		bne.w	TTail_Hidden				; the body art covers the tails slot this frame
		move.w	flashtime(a2),d0			; blink with the player after being hit
		beq.s	.visible
		addq.w	#1,d0					; Sonic_Display tested it before decrementing
		lsr.w	#3,d0
		bcc.w	TTail_Return
	.visible:
		bsr.w	TTail_LoadGfx
		jmp	(DisplaySprite).l

; In the Special Stage the player always rolls: point the tails against his
; velocity, turned with the stage, and draw them from the two-layer frames
; (s1tools.special_stage) in the slot's last TailsTailSS_Tiles tiles.
TTail_Special:
		cmpi.b	#Character_Tails,(v_character_p1).w
		bne.w	TTail_Delete
		tst.w	(v_debuguse).w				; placement mode shows an item instead
		bne.w	TTail_Return
		move.l	#Map_TailsTailSS,obMap(a0)
		move.w	#ArtTile_Tails_Tail_SS,obGfx(a0)
		move.w	obX(a2),obX(a0)
		move.w	obY(a2),obY(a0)
		move.b	obStatus(a2),d0
		andi.b	#1,d0
		move.b	d0,obStatus(a0)
		move.b	#1,obPriority(a0)			; behind the ball
		move.b	#tailani_Directional,obAnim(a0)
		bsr.w	TTail_Directional
		lea	(TailsTailSSDynPLC).l,a2
		move.l	#Art_TailsTailSS,d6
		move.w	#ArtTile_Tails_Tail_SS*tile_size,d4
		bsr.w	TTail_LoadGfxFrom
		jmp	(DisplaySprite).l

TTail_Hidden:
		move.b	#-1,tail_vramframe(a0)			; reload once the slot is free again

TTail_Return:
		rts

TTail_Delete:
		jmp	(DeleteObject).l

; ---------------------------------------------------------------------------
; Output d0 = tail animation for Tails' current animation and flight state.
; ---------------------------------------------------------------------------

TTail_SelectAnim:
		tst.b	(v_tails_flying).w
		beq.s	.byAnimation
		btst	#6,obStatus(a2)				; swimming draws its tails in the body art
		bne.s	.byAnimation
		moveq	#tailani_Fly,d0
		tst.w	(v_tails_flytime).w
		beq.s	.return					; exhausted flight keeps the slow rotor
		tst.w	obVelY(a2)
		bpl.s	.return
		moveq	#tailani_Ascend,d0
	.return:
		rts
	.byAnimation:
		moveq	#0,d0
		move.b	obAnim(a2),d0
		bne.s	.notWalk
		btst	#5,obStatus(a2)				; the walk script draws pushing (SAnim_Push)
		beq.s	.notWalk
		moveq	#tailani_Push,d0
		rts
	.notWalk:
		cmpi.b	#TTail_AniSelection_End-TTail_AniSelection,d0
		bhs.s	.blank
		move.b	TTail_AniSelection(pc,d0.w),d0
		rts
	.blank:
		moveq	#tailani_Blank,d0
		rts

; Tail animation for each of Tails' animation IDs (S3K Obj_Tails_Tail_AniSelection).
TTail_AniSelection:
		dc.b tailani_Blank		; Walk (tails are in the body art)
		dc.b tailani_Blank		; Run
		dc.b tailani_Directional	; Roll
		dc.b tailani_Directional	; Roll2
		dc.b tailani_Push		; Push
		dc.b tailani_Swish		; Wait
		dc.b tailani_Hang		; Balance
		dc.b tailani_Flick		; LookUp
		dc.b tailani_Swish		; Duck
		dc.b tailani_Blank		; Warp1
		dc.b tailani_Blank		; Warp2
		dc.b tailani_Blank		; Warp3
		dc.b tailani_Blank		; Warp4
		dc.b tailani_Skid		; Stop
		dc.b tailani_Blank		; Float1
		dc.b tailani_Blank		; Float2
		dc.b tailani_Blank		; Spring
		dc.b tailani_Blank		; Hang
		dc.b tailani_Blank		; Leap1
		dc.b tailani_Blank		; Leap2
		dc.b tailani_Blank		; Surf
		dc.b tailani_Blank		; GetAir
		dc.b tailani_Blank		; Burnt
		dc.b tailani_Blank		; Drown
		dc.b tailani_Blank		; Death
		dc.b tailani_Blank		; Shrink
		dc.b tailani_Blank		; Hurt
		dc.b tailani_Blank		; Slide
		dc.b tailani_Blank		; Null
		dc.b tailani_Blank		; Float3
		dc.b tailani_Blank		; Float4
		dc.b tailani_SpinDash		; SpinDash
		dc.b tailani_Blank		; Transform
		dc.b tailani_Blank		; Figure8
		dc.b tailani_Blank		; Fall
TTail_AniSelection_End:
		even

; ---------------------------------------------------------------------------
; Rolling: point the tails along the velocity, in eight headings, with a
; four-step swish (S3K's directional tails animation).
; ---------------------------------------------------------------------------

TTail_Directional:
		move.w	obVelX(a2),d1
		move.w	obVelY(a2),d2
		jsr	(CalcAngle).l
		cmpi.b	#id_Special,(v_gamemode).w		; the Special Stage turns around the player
		bne.s	.notRotated
		sub.b	(v_ssangle).w,d0
	.notRotated:
		btst	#0,obStatus(a2)
		beq.s	.heading
		neg.b	d0					; mirror the velocity into the body's local coordinates
		addi.b	#$80,d0
	.heading:
		addi.b	#$10,d0					; nearest of eight headings
		lsr.b	#5,d0
		andi.w	#7,d0
		add.w	d0,d0
		move.b	TTail_Headings(pc,d0.w),d1		; first frame of this heading
		move.b	TTail_Headings+1(pc,d0.w),d2		; local flips: bit 0 X, bit 1 Y
		move.w	(v_framecount).w,d0
		lsr.w	#2,d0
		andi.b	#3,d0
		add.b	d1,d0
		move.b	d0,obFrame(a0)
		andi.b	#~(sprite_xflip|sprite_yflip),obRender(a0)
		move.b	obStatus(a2),d0
		andi.b	#1,d0
		eor.b	d2,d0					; local flips on top of the player's facing
		andi.b	#sprite_xflip|sprite_yflip,d0
		or.b	d0,obRender(a0)
		rts

; Clockwise from right, before the player's X flip: horizontal, diagonal and
; vertical tail poses, with the flips that complete the eight headings.
TTail_Headings:
		dc.b 5,0, $11,3, $D,3, 9,3, 5,3, $11,0, $D,0, 9,0

; ---------------------------------------------------------------------------
; Return Z set when Tails' current body frame fits the first half of the
; player VRAM slot, so the tails' half is free.
; ---------------------------------------------------------------------------

TTail_BodyFitsHalf:
		moveq	#0,d0
		move.b	obFrame(a2),d0
		lea	(TailsDynPLC).l,a1
		add.w	d0,d0
		adda.w	(a1,d0.w),a1
		moveq	#0,d1
		move.b	(a1)+,d1				; DPLC entries
		moveq	#0,d2					; tiles
		bra.s	.next
	.entry:
		move.b	(a1),d0
		lsr.b	#4,d0
		addq.w	#1,d0
		add.w	d0,d2
		addq.l	#2,a1
	.next:
		dbf	d1,.entry
		cmpi.w	#Sonic_Slot_Tiles-Tails_Tail_Tiles,d2
		bhi.s	.large
		moveq	#0,d0
		rts
	.large:
		moveq	#1,d0
		rts

; ---------------------------------------------------------------------------
; Queue the tail frame's tiles when it changes (as Sonic_LoadGfx does).
; ---------------------------------------------------------------------------

TTail_LoadGfx:
		lea	(TailsTailDynPLC).l,a2
		move.l	#Art_TailsTail,d6
		move.w	#ArtTile_Tails_Tail*tile_size,d4

; Input a2 = DPLC table, d6 = art, d4 = VRAM address.
TTail_LoadGfxFrom:
		moveq	#0,d0
		move.b	obFrame(a0),d0
		cmp.b	tail_vramframe(a0),d0
		beq.s	.done
		move.b	d0,tail_vramframe(a0)
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		moveq	#0,d5
		move.b	(a2)+,d5
		subq.w	#1,d5
		bmi.s	.done
	.entry:
		moveq	#0,d1
		move.b	(a2)+,d1
		lsl.w	#8,d1
		move.b	(a2)+,d1
		move.w	d1,d3
		lsr.w	#8,d3
		andi.w	#$F0,d3
		addi.w	#$10,d3					; transfer size in words
		andi.w	#$FFF,d1
		lsl.l	#5,d1
		add.l	d6,d1					; source in ROM
		move.w	d4,d2					; destination in VRAM
		add.w	d3,d4
		add.w	d3,d4
		jsr	(QueueDMATransfer).l
		dbf	d5,.entry
	.done:
		rts

; ---------------------------------------------------------------------------
; Animation scripts (S3K AniTails_Tail).
; ---------------------------------------------------------------------------

tailani_Blank:		equ 0
tailani_Swish:		equ 1
tailani_Flick:		equ 2
tailani_Directional:	equ 3
tailani_SpinDash:	equ 4
tailani_Skid:		equ 5
tailani_Push:		equ 6
tailani_Hang:		equ 7
tailani_Fly:		equ 8
tailani_Ascend:		equ 9

Ani_TailsTail:
		dc.w .blank-Ani_TailsTail
		dc.w .swish-Ani_TailsTail
		dc.w .flick-Ani_TailsTail
		dc.w .blank-Ani_TailsTail		; directional, handled by TTail_Directional
		dc.w .spindash-Ani_TailsTail
		dc.w .skid-Ani_TailsTail
		dc.w .push-Ani_TailsTail
		dc.w .hang-Ani_TailsTail
		dc.w .fly-Ani_TailsTail
		dc.w .ascend-Ani_TailsTail
.blank:		dc.b $20, 0, afEnd
.swish:		dc.b 7, $22, $23, $24, $25, $26, afEnd
.flick:		dc.b 3, $22, $23, $24, $25, $26, afChange, tailani_Swish
.spindash:	dc.b 2, 1, 2, 3, 4, afEnd
.skid:		dc.b 2, $1A, $1B, $1C, $1D, afEnd
.push:		dc.b 9, $1E, $1F, $20, $21, afEnd
.hang:		dc.b 9, $29, $2A, $2B, $2C, afEnd
.fly:		dc.b 1, $27, $28, afEnd
.ascend:	dc.b 0, $27, $28, afEnd
		even
