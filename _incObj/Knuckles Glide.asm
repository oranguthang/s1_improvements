; Solo Knuckles abilities, adapted to S1 terrain collision from S3K.
; B/C starts a glide in the air; A remains the Light Dash button.
; a0 = player. d0 = 1 if movement was handled, otherwise 0.
knux_glide_frame: equ $75
knux_fall_frame: equ $7A
knux_slide_frame: equ $7C
knux_climb_frame: equ $7E
knux_ledge_frame: equ $84

Knuckles_GlideControl:
        cmpi.b #Character_Knuckles,(v_character_p1).w
        bne.w .inactive
        tst.b (f_playerctrl).w
        bne.w .cancel
        tst.b (f_lockctrl).w
        bne.w .cancel
        tst.b (v_lightdash).w
        bne.w .cancel
        cmpi.b #id_GetAir,obAnim(a0)
        beq.w .cancel
        cmpi.b #5,(v_knux_state).w
        beq.w Knuckles_Slide
        btst #1,obStatus(a0)
        beq.w .cancel
        ; This call stays directly below Sonic_Control. Light Dash's successful
        ; activation removes its caller's return address to skip normal physics.
        jsr (Sonic_LightDashStart).l
        moveq #0,d0
        move.b (v_knux_state).w,d0
        cmpi.b #3,d0
        beq.w Knuckles_Climb
        cmpi.b #4,d0
        beq.w Knuckles_Ledge
        cmpi.b #2,d0
        beq.w Knuckles_Fall
        tst.b d0
        bne.w .glide
        move.b (v_jpadpress2).w,d0
        andi.b #btnB|btnC,d0
        beq.w .inactive
        move.b #1,(v_knux_state).w
        move.w #$400,(v_knux_speed).w
        clr.b (v_knux_turn).w
        btst #0,obStatus(a0)
        beq.w .start
        move.b #$80,(v_knux_turn).w
.start:
        bclr #2,obStatus(a0)
        bclr #4,obStatus(a0)
        bclr #5,obStatus(a0)
        move.b #10,obHeight(a0)
        move.b #10,obWidth(a0)
        clr.b jumping(a0)
        clr.b obAngle(a0)
        addi.w #$200,obVelY(a0)
        bpl.w .glide
        clr.w obVelY(a0)
.glide:
        move.b (v_jpadhold2).w,d0
        andi.b #btnB|btnC,d0
        beq.w Knuckles_ReleaseGlide
        move.w (v_knux_speed).w,d0
        cmpi.w #$400,d0
        bhs.w .medium
        addq.w #8,d0
        bra.w .speed
.medium:
        cmpi.w #$1800,d0
        bhs.w .speed
        move.b (v_knux_turn).w,d1
        andi.b #$7F,d1
        bne.w .speed
        addq.w #4,d0
.speed:
        move.w d0,(v_knux_speed).w
        move.b (v_knux_turn).w,d0
        btst #bitL,(v_jpadhold2).w
        beq.w .right
        cmpi.b #$80,d0
        beq.w .heading
        tst.b d0
        bpl.w .turn
        neg.b d0
        bra.w .turn
.right:
        btst #bitR,(v_jpadhold2).w
        beq.w .noDirection
        tst.b d0
        beq.w .heading
        bmi.w .turn
        neg.b d0
        bra.w .turn
.noDirection:
        move.b d0,d1
        andi.b #$7F,d1
        beq.w .heading
.turn:
        addq.b #2,d0
.heading:
        move.b d0,(v_knux_turn).w
        jsr (CalcSine).l
        muls.w (v_knux_speed).w,d1
        asr.l #8,d1
        move.w d1,obVelX(a0)
        cmpi.w #$80,obVelY(a0)
        blt.w .gravity
        subi.w #$20,obVelY(a0)
        bra.w .move
.gravity:
        addi.w #$20,obVelY(a0)
.move:
        jsr (Sonic_LevelBound).l
        cmpi.b #2,obRoutine(a0)
        bne.w .cancel
        jsr (SpeedToPos).l
        ; Resolve the wall before Sonic_Floor clears horizontal speed. Only
        ; level terrain is climbable; moving solid objects use normal collision.
        tst.w obVelX(a0)
        beq.w .floor
        bmi.w .leftWall
        bclr #0,obStatus(a0)
        jsr (Sonic_FindWallRight_Quick_UsePos).l
        tst.w d1
        bgt.w .floor
        add.w d1,obX(a0)
        cmpi.b #$C0,d3
        beq.w Knuckles_GrabWall
        bra.w .floor
.leftWall:
        bset #0,obStatus(a0)
        jsr (Sonic_FindWallLeft_Quick_UsePos).l
        tst.w d1
        bgt.w .floor
        sub.w d1,obX(a0)
        cmpi.b #$40,d3
        beq.w Knuckles_GrabWall
.floor:
        jsr (Sonic_Floor).l
        btst #1,obStatus(a0)
        bne.w .moved
        move.b #5,(v_knux_state).w
        move.b #knux_slide_frame,(v_knux_frame).w
        move.w obInertia(a0),obVelX(a0)
.moved:
        move.b #id_Float1,obAnim(a0)
        moveq #1,d0
        rts
.cancel:
        jsr (Knuckles_EndAbility).l
.inactive:
        moveq #0,d0
        rts

Knuckles_ReleaseGlide:
        asr.w obVelX(a0)
        asr.w obVelX(a0)
        move.b #2,(v_knux_state).w
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        ; Keep the airborne origin, as in S3K. The floor sensors establish the
        ; standing origin at landing; raising it here would make gliding jump.
Knuckles_Fall:
        jsr (Sonic_JumpDirection).l
        jsr (Sonic_LevelBound).l
        cmpi.b #2,obRoutine(a0)
        bne.w .cancel
        jsr (ObjectFall).l
        btst #6,obStatus(a0)
        beq.w .floor
        subi.w #gravity-$10,obVelY(a0)
.floor:
        jsr (Sonic_Floor).l
        btst #1,obStatus(a0)
        beq.w .cancel
        move.b #id_Float2,obAnim(a0)
        moveq #1,d0
        rts
.cancel:
        jsr (Knuckles_EndAbility).l
        moveq #1,d0
        rts

Knuckles_GrabWall:
        move.b #3,(v_knux_state).w
        move.b #knux_climb_frame,(v_knux_frame).w
        clr.b (v_knux_timer).w
        move.w obX(a0),(v_knux_wall_x).w
        clr.w obVelX(a0)
        clr.w obVelY(a0)
        clr.w obInertia(a0)
        moveq #1,d0
        rts

; d0.w = vertical sensor offset. d1 = wall distance; d3.b = angle.
Knuckles_WallDistance:
        move.w obY(a0),d2
        add.w d0,d2
        move.w obX(a0),d3
        btst #0,obStatus(a0)
        bne.w .left
        jmp (Sonic_FindWallRight_Quick).l
.left:
        jmp (Sonic_FindWallLeft_Quick).l

Knuckles_Climb:
        btst #3,obStatus(a0)
        bne.w Knuckles_Detach
        move.w obX(a0),d0
        cmp.w (v_knux_wall_x).w,d0
        bne.w Knuckles_Detach
        clr.w obVelX(a0)
        clr.w obVelY(a0)
        clr.w obInertia(a0)
        move.b (v_jpadpress2).w,d0
        andi.b #btnB|btnC,d0
        bne.w Knuckles_WallJump
        btst #bitL,(v_jpadhold2).w
        beq.w .awayRight
        btst #0,obStatus(a0)
        beq.w Knuckles_Detach
.awayRight:
        btst #bitR,(v_jpadhold2).w
        beq.w .vertical
        btst #0,obStatus(a0)
        bne.w Knuckles_Detach
.vertical:
        moveq #0,d0
        btst #bitUp,(v_jpadhold2).w
        bne.w .up
        btst #bitDn,(v_jpadhold2).w
        bne.w .down
        jsr (Knuckles_WallDistance).l
        cmpi.w #4,d1
        bge.w Knuckles_Detach
        jsr (Sonic_FindFloor).l
        tst.w d1
        bmi.w Knuckles_ClimbFloor
        bra.w .moved
.up:
        moveq #-11,d0
        jsr (Knuckles_WallDistance).l
        cmpi.w #4,d1
        bge.w Knuckles_StartLedge
        cmpi.w #-4,d1
        blt.w .moved
        jsr (Sonic_FindCeiling).l
        tst.w d1
        bmi.w .moved
        move.w (v_limittop2).w,d0
        addi.w #16,d0
        cmp.w obY(a0),d0
        bge.w .moved
        subq.w #1,obY(a0)
        moveq #1,d0
        bra.w .animate
.down:
        moveq #11,d0
        jsr (Knuckles_WallDistance).l
        cmpi.w #4,d1
        bge.w Knuckles_Detach
        jsr (Sonic_FindFloor).l
        tst.w d1
        ble.w Knuckles_ClimbFloor
        addq.w #1,obY(a0)
        moveq #-1,d0
.animate:
        tst.b (v_knux_timer).w
        beq.w .nextFrame
        subq.b #1,(v_knux_timer).w
        bra.w .moved
.nextFrame:
        move.b #3,(v_knux_timer).w
        add.b d0,(v_knux_frame).w
        cmpi.b #knux_climb_frame,(v_knux_frame).w
        bhs.w .upperFrame
        move.b #knux_climb_frame+5,(v_knux_frame).w
.upperFrame:
        cmpi.b #knux_climb_frame+5,(v_knux_frame).w
        bls.w .moved
        move.b #knux_climb_frame,(v_knux_frame).w
.moved:
        move.b #id_Float1,obAnim(a0)
        moveq #1,d0
        rts

Knuckles_WallJump:
        jsr (Knuckles_EndAbility).l
        bchg #0,obStatus(a0)
        move.w #$400,obVelX(a0)
        btst #0,obStatus(a0)
        beq.w .right
        neg.w obVelX(a0)
.right:
        move.w #-$380,obVelY(a0)
        move.b #sonic_roll_height,obHeight(a0)
        move.b #sonic_roll_width,obWidth(a0)
        bset #2,obStatus(a0)
        move.b #id_Roll,obAnim(a0)
        move.b #1,jumping(a0)
        move.w #sfx_Jump,d0
        jsr (QueueSound2).l
        moveq #1,d0
        rts

Knuckles_Detach:
        move.b #2,(v_knux_state).w
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        move.b #id_Float2,obAnim(a0)
        moveq #1,d0
        rts

Knuckles_ClimbFloor:
        add.w d1,obY(a0)
        jsr (Sonic_ResetOnFloor).l
        jsr (Knuckles_EndAbility).l
        move.b #id_Wait,obAnim(a0)
        moveq #1,d0
        rts

Knuckles_StartLedge:
        ; Find the top of the same wall before advancing onto it. A large hole
        ; or sloped wall detaches Knuckles instead of stepping through terrain.
        move.w obX(a0),d3
        addi.w #sonic_quick_size+2,d3
        btst #0,obStatus(a0)
        beq.w .floor
        subi.w #(sonic_quick_size+2)*2,d3
.floor:
        move.w obY(a0),d2
        subi.w #32,d2
        lea (v_anglebuffer).w,a4
        movea.w #$10,a3
        moveq #0,d6
        moveq #$D,d5
        jsr (FindFloor).l
        cmpi.w #32,d1
        bhs.w Knuckles_Detach
        move.b #4,(v_knux_state).w
        move.b #knux_ledge_frame,(v_knux_frame).w
        move.b #6,(v_knux_timer).w
        ; Pin to the located ledge, using the original S3K transition offsets.
        add.w d1,obY(a0)
        subi.w #23,obY(a0)
        moveq #3,d0
        btst #0,obStatus(a0)
        beq.w .shift
        neg.w d0
.shift:
        add.w d0,obX(a0)
        moveq #1,d0
        rts

Knuckles_Ledge:
        subq.b #1,(v_knux_timer).w
        bne.w .moved
        move.b #6,(v_knux_timer).w
        addq.b #1,(v_knux_frame).w
        moveq #8,d0
        moveq #-10,d1
        cmpi.b #knux_ledge_frame+1,(v_knux_frame).w
        beq.w .shift
        moveq #-8,d0
        moveq #-12,d1
        cmpi.b #knux_ledge_frame+2,(v_knux_frame).w
        beq.w .shift
        moveq #8,d0
        moveq #-5,d1
.shift:
        btst #0,obStatus(a0)
        beq.w .right
        neg.w d0
.right:
        add.w d0,obX(a0)
        add.w d1,obY(a0)
        cmpi.b #knux_ledge_frame+3,(v_knux_frame).w
        blo.w .moved
        ; The offsets already establish the standing origin: don't raise it a
        ; second time when restoring the hitbox after the ledge animation.
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        jsr (Sonic_ResetOnFloor).l
        jsr (Knuckles_EndAbility).l
        move.b #id_Wait,obAnim(a0)
.moved:
        moveq #1,d0
        rts

Knuckles_Slide:
        btst #1,obStatus(a0)
        bne.w Knuckles_Detach
        move.b (v_jpadhold2).w,d0
        andi.b #btnB|btnC,d0
        beq.w .stop
        tst.w obVelX(a0)
        bmi.w .left
        subi.w #$20,obVelX(a0)
        bmi.w .stop
        bra.w .move
.left:
        addi.w #$20,obVelX(a0)
        bpl.w .stop
.move:
        move.w obVelX(a0),obInertia(a0)
        jsr (Sonic_LevelBound).l
        jsr (SpeedToPos).l
        jsr (Sonic_AnglePos).l
        moveq #1,d0
        rts
.stop:
        clr.w obVelX(a0)
        clr.w obInertia(a0)
        jsr (Knuckles_EndAbility).l
        move.b #id_Wait,obAnim(a0)
        moveq #1,d0
        rts

Knuckles_EndAbility:
        tst.b (v_knux_state).w
        beq.w .return
        clr.b (v_knux_state).w
        btst #1,obStatus(a0)
        bne.w .size
        moveq #0,d0
        move.b obHeight(a0),d0
        subi.w #sonic_height,d0
        add.w d0,obY(a0)
.size:
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
.return:
        rts

Knuckles_GlidePose:
        cmpi.b #Character_Knuckles,(v_character_p1).w
        bne.w .return
        cmpi.b #2,obRoutine(a0)
        bne.w .return
        moveq #0,d0
        move.b (v_knux_state).w,d0
        beq.w .return
        cmpi.b #1,d0
        beq.w .glide
        cmpi.b #2,d0
        beq.w .fall
        move.b (v_knux_frame).w,obFrame(a0)
        bra.w .flip
.glide:
        moveq #0,d0
        move.b (v_knux_turn).w,d0
        addi.b #$10,d0
        lsr.w #5,d0
        andi.w #7,d0
        move.b .frames(pc,d0.w),obFrame(a0)
        bclr #0,obStatus(a0)
        cmpi.w #4,d0
        bne.w .flip
        bset #0,obStatus(a0)
        bra.w .flip
.fall:
        move.b (v_framecount+1).w,d0
        lsr.b #3,d0
        andi.b #1,d0
        addi.b #knux_fall_frame,d0
        move.b d0,obFrame(a0)
.flip:
        move.b obStatus(a0),d0
        andi.b #1,d0
        andi.b #$FC,obRender(a0)
        or.b d0,obRender(a0)
.return:
        rts
.frames: dc.b knux_glide_frame,knux_glide_frame+1,knux_glide_frame+2,knux_glide_frame+3
         dc.b knux_glide_frame,knux_glide_frame+3,knux_glide_frame+2,knux_glide_frame+1
        even
