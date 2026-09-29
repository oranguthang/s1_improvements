; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3B - purple rock (GHZ)
; ---------------------------------------------------------------------------

PurpleRock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Rock_Index(pc,d0.w),d1
		jmp	Rock_Index(pc,d1.w)
; ===========================================================================
Rock_Index:	dc.w Rock_Main-Rock_Index
		dc.w Rock_Solid-Rock_Index
		dc.w Rock_Fragment-Rock_Index
; ===========================================================================

Rock_SmashableBit: equ 0
rock_impact_x: equ objoff_30
rock_impact_y: equ objoff_32
rock_attack: equ objoff_34

Rock_Main:	; Routine 0
        btst #Rock_SmashableBit,obSubtype(a0)
        beq.s .notBroken
        respawn_entry.s .notBroken
        btst #0,(a2)
        bne.w DeleteObject
.notBroken:
		addq.b	#2,obRoutine(a0)			; advance to Rock_Solid
		move.l	#Map_PRock,obMap(a0)			; set mappings
		move.w	#ArtTile_GHZ_Purple_Rock|Tile_Pal4,obGfx(a0) ; set art tile and palette line
		move.b	#sprite_cam_field,obRender(a0)		; set to playfield-positioned mode
	if FixBugs
		; This should be 48 pixels, otherwise it gets culled too soon.
		; However, due to a minor conflict with SolidObject, the GHZ1 demo expects obActWid to be set to 38/2,
		; otherwise it will desync once Sonic touches the second purple rock in the level. We can fix this
		; by selectively fixing the width based on the demo flag (although it's not exactly pretty).
		moveq	#48/2,d0				; sprite display width (corrected)
		tst.w	(f_demo).w				; is a demo currently being played?
		beq.s	.setSpriteWidth				; if not, branch
		moveq	#38/2,d0				; use incorrect width anyway, so that GHZ demo doesn't desync
	.setSpriteWidth:
		move.b	d0,obActWid(a0)				; set final sprite display width
	else
		move.b	#38/2,obActWid(a0)			; set sprite display width (too small)
	endif
		move.b	#4,obPriority(a0)			; set sprite priority
; ---------------------------------------------------------------------------

Rock_Solid:	; Routine 2
        clr.b rock_attack(a0)
        btst #Rock_SmashableBit,obSubtype(a0)
        beq.s .solid
        ; Save attack/impact before SolidObject can unroll Sonic or stop him.
        lea (v_player).w,a1
        cmpi.b #2,obRoutine(a1)
        bne.s .solid
        tst.b (f_playerctrl).w
        bne.s .solid
        move.b spindash_flag(a1),d0
        andi.b #3,d0
        bne.s .solid                 ; charging is not an impact
        cmpi.b #id_Roll,obAnim(a1)
        bne.s .solid                 ; Peel-Out/upright Super are still running
        move.b #1,rock_attack(a0)
        move.w obVelX(a1),rock_impact_x(a0)
        move.w obVelY(a1),rock_impact_y(a0)
.solid:
		move.w	#32/2+sonic_solid_width,d1		; SolidObject input: width
		move.w	#32/2,d2				; SolidObject input: height (initial)
		move.w	#32/2,d3				; SolidObject input: height (stood-on)
		move.w	obX(a0),d4				; SolidObject input: object X-position (stood-on)
		bsr.w	SolidObject				; make rock solid for Sonic
        tst.b rock_attack(a0)
        beq.w Rock_Display
        cmpi.b #2,obRoutine(a1)
        bne.w Rock_Display
        btst #3,obStatus(a0)
        bne.s .top
        cmpi.l #1,d4
        bne.w Rock_Display
        move.w rock_impact_x(a0),d0
        bpl.s .absImpact
        neg.w d0
.absImpact:
        cmpi.w #$480,d0             ; same side-impact threshold as a GHZ wall
        blo.w Rock_Display
        move.w rock_impact_x(a0),obVelX(a1)
        move.w rock_impact_x(a0),obInertia(a1)
        bclr #5,obStatus(a1)
        bclr #5,obStatus(a0)
        bra.s Rock_Smash
.top:
        tst.w rock_impact_y(a0)
        bmi.w Rock_Display
        bset #1,obStatus(a1)
        bset #2,obStatus(a1)
        bclr #3,obStatus(a1)
        move.b #sonic_roll_height,obHeight(a1)
        move.b #sonic_roll_width,obWidth(a1)
        move.b #id_Roll,obAnim(a1)
        move.w #-$300,obVelY(a1)
        bclr #3,obStatus(a0)
        clr.b obSolid(a0)
        bra.s Rock_Smash

Rock_Display:

	if FixBugs
		; Objects shouldn't call DisplaySprite and DeleteObject in
		; the same frame or else cause a null-pointer dereference.
		; This same bugfix can be found in Sonic 2's unused copy of
		; this object.
		out_of_range.w	DeleteObject			; has object gone out of range? if yes, delete it
		bra.w	DisplaySprite				; otherwise, display object
	else
		bsr.w	DisplaySprite				; display object
		out_of_range.w	DeleteObject			; has object gone out of range? if yes, delete it
		rts						; return
	endif

; Broken state belongs only to the placed root, never to spawned fragments.
Rock_Smash:
        respawn_entry.s .noEntry
        bset #0,(a2)
.noEntry:
        clr.w respawn_index(a0)
        move.b #1,obFrame(a0)
        lea Rock_FragmentSpeeds(pc),a4
        moveq #4-1,d1
        move.w #gravity,d2
        jsr (SmashObject).l
        moveq #10,d0               ; 100 points, even when no points slot is free
        jsr (AddPoints).l
        jsr (FindFreeObj).l
        bne.s Rock_Fragment
        _move.b #id_Points,obID(a1)
        move.w obX(a0),obX(a1)
        move.w obY(a0),obY(a1)
        clr.b obFrame(a1)
Rock_Fragment:
        jsr (ObjectFall).l
        tst.b obRender(a0)
        bpl.w DeleteObject
        bra.w DisplaySprite
Rock_FragmentSpeeds:
        dc.w -$200,-$200,-$100,-$100,$100,-$100,$200,-$200
        even
