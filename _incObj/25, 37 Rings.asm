; ===========================================================================
; ---------------------------------------------------------------------------
; Object 25 - rings
; ---------------------------------------------------------------------------

Rings:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Ring_Index(pc,d0.w),d1
		jmp	Ring_Index(pc,d1.w)
; ===========================================================================
Ring_Index:	dc.w Ring_Main-Ring_Index	; 0
		dc.w Ring_Animate-Ring_Index	; 2
		dc.w Ring_Collect-Ring_Index	; 4
		dc.w Ring_Sparkle-Ring_Index	; 6
		dc.w Ring_Delete-Ring_Index	; 8

ring_origX:	 equ objoff_32
ring_respawnbit: equ objoff_34
; ===========================================================================

; Distances between rings (format: horizontal, vertical)
Ring_PosData:	dc.b  $10,   0		; $0 - right, short
		dc.b  $18,   0		; $1 - right, medium
		dc.b  $20,   0		; $2 - right, far

		dc.b    0, $10		; $3 - down, short
		dc.b    0, $18		; $4 - down, medium
		dc.b    0, $20		; $5 - down, far

		dc.b  $10, $10		; $6 - diagonal right, short
		dc.b  $18, $18		; $7 - diagonal right, medium
		dc.b  $20, $20		; $8 - diagonal right, far

		dc.b -$10, $10		; $9 - diagonal left, short
		dc.b -$18, $18		; $A - diagonal left, medium
		dc.b -$20, $20		; $B - diagonal left, far

		dc.b  $10,   8		; $C - diagonal right-right, short
		dc.b  $18, $10		; $D - diagonal right-right, medium

		dc.b -$10,   8		; $E - diagonal left-left, short
		dc.b -$18, $10		; $F - diagonal left-left, medium
; ===========================================================================

Ring_Main:	; Routine 0

		; Ring respawn table data arrangement (in bits): R7654321
		;   R = respawn block flag for entire ring group
		;   # = "ring collected" flag per ring, set to 1 if collected
		moveq	#0,d4					; debug-created rings have no respawn entry
		respawn_entry.s	.noentry
		move.b	(a2),d4					; collected rings and loaded flag
	.noentry:
		moveq	#0,d0

		; Rings are stored in groups within the level layouts, with the subtype dictating
		; how many there are, and what distance/angle between individual rings to pick.
		; The format is as follows: $ON
		;   O = (Orientation) which entry in Ring_PosData to pick
		;   N = (Number) amount of rings to spawn plus 1 (so 0 is one ring)
		move.b	obSubtype(a0),d1			; get subtype for ring group
		move.b	d1,d0					; remember for later
		andi.w	#7,d1					; limit to 1-8 rings

		; The following check prevents an 8th ring from spawning, which would corrupt
		; the MSB in the respawn data byte (respawn block flag, reserved by object loader).
		; It is a bit odd, since ideally no ring groups with 8 rings should be placed to begin
		; with (and aren't anywhere), so this likely was used as a quick fix during development.
		cmpi.w	#7,d1					; is this a group with 8 rings?
		bne.s	.not8					; if not, branch
		moveq	#6,d1					; spawn 7 rings instead
	; loc_9B80:
	.not8:

		swap	d1					; store count in upper word (spawner will alternate between both words in d1)
		move.w	#0,d1					; clear lower word
		lsr.b	#4,d0					; shift orientation nybble to lower nybble
		add.w	d0,d0					; double for word-based indexing
		move.b	Ring_PosData+0(pc,d0.w),d5		; load ring spacing data for X-axis
		ext.w	d5					; extend to word for coordinates
		move.b	Ring_PosData+1(pc,d0.w),d6		; load ring spacing data for Y-axis
		ext.w	d6					; extend to word for coordinates

		movea.l	a0,a1					; load first actual ring into current RAM location
		move.w	obX(a0),d2				; remember base X-position
		move.w	obY(a0),d3				; remember base Y-position
		lsr.b	#1,d4					; shift out first ring collected bit
		bcs.s	Ring_NextRing				; has the first ring already been collected? if yes, skip spawning it
		bra.s	Ring_SpawnRing				; spawn first ring object
; ===========================================================================

Ring_MakeRings:
		swap	d1					; swap to respawn index bit
		lsr.b	#1,d4					; shift out next remembered ring respawn bit
		bcs.s	Ring_NextRing				; has this ring already been collected? if yes, branch

		bsr.w	FindFreeObj				; find a free RAM slot for the new ring
		bne.s	Ring_SpawningDone			; if object RAM is full, branch

; loc_9BBA:
Ring_SpawnRing:
		_move.b	#id_Rings,obID(a1)			; load new ring object
		addq.b	#2,obRoutine(a1)			; set to Ring_Animate
		move.w	d2,obX(a1)				; set x-axis position based on d2
		move.w	obX(a0),ring_origX(a1)			; remember original X-position for despawn logic
		move.w	d3,obY(a1)				; set y-axis position based on d3
		move.l	#Map_Ring,obMap(a1)			; set mappings
		move.w	#ArtTile_Ring|Tile_Pal2,obGfx(a1)	; set art tile and palette line
		move.b	#sprite_cam_field,obRender(a1)		; set to playfield-positioned mode
		move.b	#2,obPriority(a1)			; set sprite priority
		move.b	#col_12x12|col_item,obColType(a1)	; set to power-up collision type and hitbox 12x12 (=$47)
		move.b	#16/2,obActWid(a1)			; set sprite display width
		move.w	respawn_index(a0),respawn_index(a1)	; share the group's state entry
		move.b	d1,ring_respawnbit(a1)			; remember "ring collected" index bit in respawn data

; loc_9C02:
Ring_NextRing:
		addq.w	#1,d1					; advance index bit for next ring
		add.w	d5,d2					; add ring X-spacing value to d2
		add.w	d6,d3					; add ring Y-spacing value to d3
		swap	d1					; swap to repeat count (dbf is for low word)
		dbf	d1,Ring_MakeRings			; repeat for number of rings

; loc_9C0E:
Ring_SpawningDone:
		; If ring 0 was collected, this slot remained the group spawner.
		; Other rings may have been created, but this slot is not a drawable ring.
		respawn_entry.s	Ring_Animate
		btst	#0,(a2)
		bne.w	DeleteObject
; ---------------------------------------------------------------------------

Ring_Animate:	; Routine 2
		clr.b	obFrame(a0)				; ordinary ring slot; its rotation is DMA'd by RingArt_Update

		out_of_range.s	Ring_Delete,ring_origX(a0)
		tst.b	(v_ringart_static).w			; is the ordinary ring frame in VRAM?
		bpl.w	DisplaySprite				; if yes, display
		rts						; otherwise stay hidden until it has been queued
; ===========================================================================

Ring_Collect:	; Routine 4 (set from ReactToItem)
		addq.b	#2,obRoutine(a0)			; advance to Ring_Sparkle
		move.b	#col_none,obColType(a0)			; prevent ring from being collected again
		move.b	#1,obPriority(a0)			; make ring sparkles appear in front of Sonic's sprites
		bsr.w	CollectRing				; add 1 ring

		respawn_entry.s	Ring_Sparkle
		move.b	ring_respawnbit(a0),d1
		bset	d1,(a2)					; remember collected ring in its group's state
; ---------------------------------------------------------------------------

Ring_Sparkle:	; Routine 6
		lea	(Ani_Ring).l,a1				; get ring animation script
		bsr.w	AnimateSprite				; advance ring animation
		bra.w	DisplaySprite				; display ring sprite
; ===========================================================================

Ring_Delete:	; Routine 8
		bra.w	DeleteObject				; delete this ring


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to add 1 ring, update ring HUD, and maybe add an extra life
; ---------------------------------------------------------------------------

CollectRing:
		moveq	#1,d0					; add 1 ring
		bsr.s	AddRings				; add it and award any 100-ring lives
		bne.s	.playSound				; if a life was awarded, play extra life music
		move.w	#sfx_Ring,d0				; otherwise play ring sound

	.playSound:
		jmp	(QueueSound2).l				; play selected sound
; End of function CollectRing

; ---------------------------------------------------------------------------
; Subroutine to add rings, capped at 999, and award one extra life for every
; multiple of 100 reached. The low 7 bits of v_lifecount count how many
; 100-ring lives this ring total has already paid out, so gains larger than
; one ring can neither skip nor repeat a threshold. Bit 7 is the Special
; Stage continue flag. The count is cleared together with the rings (level
; start, Special Stage start, ring loss) and saved with them at lampposts.
;
; input:
;	d0.w = rings to add
; output:
;	d0.w = bgm_ExtraLife if a life was awarded, otherwise 0 (Z set);
;	       a threshold reached at 99 lives is consumed without a life
; ---------------------------------------------------------------------------

AddRings:
		movem.l	d1-d2,-(sp)				; callers only expect d0 to change
		add.w	(v_rings).w,d0				; add current rings
		cmpi.w	#999,d0					; is the result above the counter limit?
		bls.s	.belowmax				; if not, branch
		move.w	#999,d0					; cap at 999 rings
	.belowmax:
		move.w	d0,(v_rings).w				; set new ring count
		ori.b	#1,(f_ringcount).w			; update the rings counter

		moveq	#0,d2					; no threshold reached yet
	.chkThreshold:
		moveq	#$7F,d1
		and.b	(v_lifecount).w,d1			; get 100-ring lives already awarded
		addq.w	#1,d1					; next multiple to reach
		mulu.w	#100,d1					; convert to rings
		cmp.w	d1,d0					; has it been reached?
		blo.s	.done					; if not, branch
		addq.b	#1,(v_lifecount).w			; remember this multiple (at most 9, never touches bit 7)
		cmpi.b	#99,(v_lives).w				; is the lives counter full?
		bhs.s	.chkThreshold				; if yes, consume the multiple without a life (2-digit HUD)
		addq.b	#1,(v_lives).w				; add 1 to the number of lives you have
		addq.b	#1,(f_lifecount).w			; update the lives counter
		moveq	#1,d2					; play extra life music
		bra.s	.chkThreshold				; check the next multiple too
; ---------------------------------------------------------------------------

	.done:
		moveq	#0,d0					; assume no threshold reached
		tst.b	d2					; was one reached?
		beq.s	.return					; if not, branch
		move.w	#bgm_ExtraLife,d0			; return extra life music
	.return:
		movem.l	(sp)+,d1-d2				; restore registers (flags unaffected)
		tst.w	d0					; set Z if no threshold was reached
		rts
; End of function AddRings


; ===========================================================================
; ---------------------------------------------------------------------------
; Object 37 - rings flying out of Sonic when he's hit
; ---------------------------------------------------------------------------

RingLoss:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	RLoss_Index(pc,d0.w),d1
		jmp	RLoss_Index(pc,d1.w)
; ===========================================================================
RLoss_Index:	dc.w RLoss_Count-RLoss_Index	; 0
		dc.w RLoss_Bounce-RLoss_Index	; 2
		dc.w RLoss_Collect-RLoss_Index	; 4
		dc.w RLoss_Sparkle-RLoss_Index	; 6
		dc.w RLoss_Delete-RLoss_Index	; 8

rloss_spread:	equ (2<<8)+$80+8	; (=$288) boost byte + angle fanning out + base angle variation
rloss_frame:	equ 9			; Map_Ring frame for the lost ring slot (ArtTile_Ring_Lost)
; ===========================================================================

RLoss_Count:	; Routine 0
		movea.l	a0,a1					; load first bouncing ring into current object RAM slot
		moveq	#0,d5					; clear d5
		move.w	(v_rings).w,d5				; check number of rings you have
		moveq	#32,d0					; spawn at most 32 rings
		cmp.w	d0,d5					; do you have 32 or more?
		blo.s	.belowmax				; if not, branch
		move.w	d0,d5					; if yes, cap number of rings to spawn to 32

	.belowmax:
		tst.w	d5
		beq.w	DeleteObject				; debug-placed ring loss with no rings
		subq.w	#1,d5					; first ring uses the existing object
		lea	(v_lvlobjspace).w,a2			; scan each dynamic slot only once
		lea	(RLoss_VelocitiesAir).l,a3
		tst.b	(f_water).w
		beq.s	.velocitiesReady
		move.w	(v_waterpos1).w,d0
		cmp.w	obY(a0),d0
		bgt.s	.velocitiesReady
		lea	(RLoss_VelocitiesWater).l,a3		; preserve arithmetic rounding underwater
.velocitiesReady:
		bra.s	.makerings
.loop:
		cmpa.w	#v_lvlobjend,a2
		bhs.w	.resetcounter
		tst.b	obID(a2)
		beq.s	.freeSlot
		lea	object_size(a2),a2
		bra.s	.loop
.freeSlot:
		movea.l	a2,a1
		lea	object_size(a2),a2
.makerings:
		_move.b	#id_RingLoss,obID(a1)			; load bouncing ring object
		addq.b	#2,obRoutine(a1)			; set to RLoss_Animate
		move.b	#16/2,obHeight(a1)			; set ring height
		move.b	#16/2,obWidth(a1)			; set right width
		move.w	obX(a0),obX(a1)				; spawn at same X-position
		move.w	obY(a0),obY(a1)				; spawn at same Y-position
		move.l	#Map_Ring,obMap(a1)			; set mappings
		move.w	#ArtTile_Ring|Tile_Pal2,obGfx(a1)	; set art tile and palette line
		move.b	#sprite_cam_field,obRender(a1)		; set to playfield-positioned mode
		move.b	#3,obPriority(a1)			; set sprite priority (1 lower than normal rings)
		move.b	#col_12x12|col_item,obColType(a1)	; set to power-up collision type and hitbox 12x12 (=$47)
		move.b	#16/2,obActWid(a1)			; set sprite display width
	if FixBugs=0
		; This resets the timer for all spilled rings,
		; even if they were already close to getting deleted
		; https://info.sonicretro.org/SCHG_How-to:Fix_Ring_Timers
		move.b	#255,(v_ani3_time).w			; set bouncy ring animation timer to 255 frames
	endif

		move.l	(a3)+,obVelX(a1)			; exact precomputed X/Y pair

		dbf	d5,.loop				; repeat for number of rings (max 31)

.resetcounter:
		move.w	#0,(v_rings).w				; reset number of rings to zero
		move.b	#$80,(f_ringcount).w			; update ring counter ($80 means all digits should be reset to __0)
		move.b	#0,(v_lifecount).w			; reset the 100-ring extra life count along with the rings

	if FixBugs
		; Fix Ring Timers
		; https://info.sonicretro.org/SCHG_How-to:Fix_Ring_Timers
		move.b	#255,d0					; set both timers to 255 frames
		move.b	d0,obDelayAni(a0)			; set ring despawn timer
		move.b	d0,(v_ani3_time).w			; set animation timer
	endif

		move.w	#sfx_RingLoss,d0			; set ring loss sound
		jsr	(QueueSound2).l				; play it
; ---------------------------------------------------------------------------

RLoss_Bounce:	; Routine 2
		move.b	#rloss_frame,obFrame(a0)		; lost ring slot; its rotation is DMA'd by RingArt_Update

		bsr.w	SpeedToPos				; update ring position based on speed
		addi.w	#$18,obVelY(a0)				; make ring fall faster
		tst.b	(f_water).w				; does this level have water?
		beq.s	.airGravity
		move.w	(v_waterpos1).w,d6			; get the water surface
		cmp.w	obY(a0),d6				; is this ring above the water?
		bgt.s	.airGravity
		subi.w	#$E,obVelY(a0)			; use reduced gravity underwater
.airGravity:
		bmi.s	.chkdel					; is ring still going upwards? if yes, skip floor collision check

		move.b	(v_vblank_byte).w,d0			; get VBlank counter byte
		add.b	d7,d0					; add object RAM index as crude spreading-out of collision check over multiple frames
		andi.b	#3,d0					; only check for floor collision every 4th frame
		bne.s	.chkdel					; if on any other frame, branch

		jsr	(ObjFloorDist).l			; calculate distance between this ring and the floor
		tst.w	d1					; has ring hit the floor?
		bpl.s	.chkdel					; if not, branch
		add.w	d1,obY(a0)				; ring hit the floor, align it to the surface
		move.w	obVelY(a0),d0				; get current ring fall speed
		asr.w	#2,d0					; divide it by 4
		sub.w	d0,obVelY(a0)				; subtract that result from the previous speed to make it bounce less
		neg.w	obVelY(a0)				; negate fall speed to make ring bounce up

.chkdel:
	if FixBugs
		; Fix Ring Timers
		; https://info.sonicretro.org/SCHG_How-to:Fix_Ring_Timers
		subq.b	#1,obDelayAni(a0)			; decrement remaining time for bouncing ring
		beq.w	DeleteObject				; if time reached zero, delete ring
	else
		tst.b	(v_ani3_time).w				; has global lost rings animation timer expired?
		beq.s	RLoss_Delete				; if yes, delete ring
	endif

		tst.w	(v_limittop2).w			; looping levels have no bottom despawn plane
		bmi.s	.keepLostRing
		move.w	(v_limitbtm2).w,d0			; get current bottom level boundary
		addi.w	#224,d0					; add vertical screen height
		cmp.w	obY(a0),d0				; has object moved below the bottom level boundary?
	if FixBugs
		; Fix accidental deletion of scattered rings at the top of the screen.
		; The cause is using an unsigned check instead of a signed one.
		blt.s	RLoss_Delete				; if yes, delete ring
	else
		blo.s	RLoss_Delete				; if yes, delete ring
	endif
.keepLostRing:
		tst.b	(v_ringart_lost).w			; is the lost ring frame in VRAM?
		bpl.s	.artReady				; if yes, branch
		rts						; otherwise stay hidden until it has been queued
	.artReady:
	if FixBugs
		; Flash scattered rings during their last 80 frames.
		cmpi.b	#80,obDelayAni(a0)
		bhi.w	DisplaySprite
		btst	#0,obDelayAni(a0)
		beq.w	DisplaySprite
		rts
	else
		bra.w	DisplaySprite				; display this ring
	endif
; ===========================================================================

RLoss_Collect:	; Routine 4
		addq.b	#2,obRoutine(a0)			; advance to RLoss_Sparkle
		move.b	#col_none,obColType(a0)			; prevent ring from being collected again
		move.b	#1,obPriority(a0)			; make ring sparkles appear in front of Sonic's sprites
		bsr.w	CollectRing				; add 1 ring
; ---------------------------------------------------------------------------

RLoss_Sparkle:	; Routine 6
		lea	(Ani_Ring).l,a1				; get ring animation script
		bsr.w	AnimateSprite				; advance ring animation
		bra.w	DisplaySprite				; display ring sprite
; ===========================================================================

RLoss_Delete:	; Routine 8
		bra.w	DeleteObject				; delete this ring


	include "_incObj/Ring Loss Velocities.asm"
