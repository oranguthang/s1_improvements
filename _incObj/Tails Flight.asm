; Solo Tails flight/swimming, using the S3K ascent pulses and eight-second
; endurance. A/B/C supplies a second jump; A takes Light Dash first when a
; ring chain is in reach, as Sonic_LightDashStart runs before this check.
; a0 = player. d0 = 1 when this routine has advanced movement, otherwise 0.
Tails_FlightControl:
        cmpi.b #Character_Tails,(v_character_p1).w
        bne.w .inactive
        tst.b (f_playerctrl).w
        bne.w .cancel
        tst.b (f_lockctrl).w
        bne.w .cancel
        btst #1,obStatus(a0)
        beq.w .cancel
        tst.b (v_lightdash).w
        bne.w .cancel
        cmpi.b #id_GetAir,obAnim(a0)
        beq.w .breathing              ; bubble inhalation has priority over flight input
        jsr (Sonic_LightDashStart).l
        tst.b (v_lightdash).w
        bne.w .cancel
        tst.b (v_tails_flying).w
        bne.s .flying
        move.b (v_jpadpress2).w,d0
        andi.b #btnABC,d0
        beq.w .inactive
        move.b #1,(v_tails_flying).w
        move.w #8*60,(v_tails_flytime).w
        clr.b (v_tails_flap).w
        bclr #2,obStatus(a0)
        beq.s .size
        subq.w #sonic_height-sonic_roll_height,obY(a0)
.size:
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        bclr #4,obStatus(a0)
        bclr #5,obStatus(a0)
        clr.b jumping(a0)
        move.w #-$100,obVelY(a0)
        move.b #id_Float1,obAnim(a0)
.flying:
        tst.w (v_tails_flytime).w
        beq.s .gravity
        subq.w #1,(v_tails_flytime).w
        move.b (v_jpadpress2).w,d0
        andi.b #btnABC,d0
        beq.s .pulse
        cmpi.w #-$100,obVelY(a0)
        blt.s .pulse
        move.b #30,(v_tails_flap).w
.pulse:
        tst.b (v_tails_flap).w
        beq.s .gravity
        subq.b #1,(v_tails_flap).w
        cmpi.w #-$100,obVelY(a0)
        ble.s .gravity
        subi.w #$20,obVelY(a0)
        bra.s .move
.gravity:
        addq.w #8,obVelY(a0)
        cmpi.w #$400,obVelY(a0)
        ble.s .move
        move.w #$400,obVelY(a0)
.move:
        move.w (v_limittop2).w,d0
        addi.w #16,d0
        cmp.w obY(a0),d0
        blt.s .bounds
        tst.w obVelY(a0)
        bpl.s .bounds
        clr.w obVelY(a0)
.bounds:
        cmpi.b #id_GetAir,obAnim(a0)
        beq.s .levelBound
        jsr (Sonic_JumpDirection).l
.levelBound:
        jsr (Sonic_LevelBound).l
        cmpi.b #2,obRoutine(a0)
        bne.s .cancel
        jsr (SpeedToPos).l
        jsr (Sonic_JumpAngle).l
        jsr (Sonic_Floor).l
        btst #1,obStatus(a0)
        bne.s .moved
        clr.b (v_tails_flying).w
        clr.b (v_tails_flap).w
        move.b #id_Walk,obAnim(a0)
.moved:
        moveq #1,d0
        rts
.breathing:
        tst.b (v_tails_flying).w
        beq.s .inactive
        clr.b (v_tails_flap).w
        tst.w locktime(a0)
        beq.s .breathTime
        subq.w #1,locktime(a0)
.breathTime:
        tst.w (v_tails_flytime).w
        beq.w .gravity
        subq.w #1,(v_tails_flytime).w
        bra.w .gravity
.cancel:
        clr.b (v_tails_flying).w
        clr.b (v_tails_flap).w
.inactive:
        moveq #0,d0
        rts

; S3K's directional rolling tail follows velocity, with a four-tick swish.
; Composite mappings keep it in the same player DMA slot as the body.
Tails_RollPose:
        cmpi.b #Character_Tails,(v_character_p1).w
        bne.w .return
        tst.b (v_lightdash).w
        bne.w .return
        cmpi.b #id_Roll,obAnim(a0)
        beq.s .rolling
        cmpi.b #id_Roll2,obAnim(a0)
        bne.w .return
.rolling:
        moveq #0,d4
        move.b obFrame(a0),d4
        cmpi.w #fr_TailsRollFirst,d4
        blo.s .bodyFrame
        cmpi.w #fr_TailsRollEnd,d4
        bhs.w .return
        subi.w #fr_TailsRollFirst,d4
        lsr.w #5,d4                    ; recover body phase on animation delay frames
        bra.s .direction
.bodyFrame:
        subi.w #fr_Roll1,d4
        cmpi.w #fr_Roll5-fr_Roll1,d4
        bhi.w .return
        move.b .bodyPhases(pc,d4.w),d4
.direction:
        move.w obVelX(a0),d1
        move.w obVelY(a0),d2
        jsr (CalcAngle).l
        btst #0,obStatus(a0)
        beq.s .heading
        neg.b d0                      ; mirror velocity into the body's local coordinates
        addi.b #$80,d0
.heading:
        addi.b #$10,d0                 ; round to the nearest of eight headings
        lsr.b #5,d0
        andi.w #7,d0
        lsl.w #2,d0
        lsl.w #5,d4
        add.w d4,d0
        move.w (v_framecount).w,d1
        lsr.w #2,d1
        andi.w #3,d1
        add.w d1,d0
        addi.w #fr_TailsRollFirst,d0
        move.b d0,obFrame(a0)
        andi.b #~(sprite_xflip|sprite_yflip),obRender(a0)
        move.b obStatus(a0),d0
        andi.b #sprite_xflip,d0
        or.b d0,obRender(a0)
.return:
        rts
.bodyPhases:
        dc.b 0,1,2,0,1
        even

; The tail rotor is packed with the body in the same bounded player DMA slot.
Tails_FlightPose:
        cmpi.b #Character_Tails,(v_character_p1).w
        bne.w .return
        tst.b (v_tails_flying).w
        beq.s .return
        btst #1,obStatus(a0)
        beq.s .cancel
        cmpi.b #2,obRoutine(a0)
        bne.s .cancel
        tst.b (v_lightdash).w
        bne.s .cancel
        cmpi.b #id_GetAir,obAnim(a0)
        beq.s .return                  ; let Sonic_Animate finish the inhalation script
        move.b #id_Float1,obAnim(a0)
        moveq #0,d0
        move.w (v_framecount).w,d0
        btst #6,obStatus(a0)
        bne.s .swim
        lsr.w #1,d0
        andi.w #1,d0
        addi.b #$75,d0
        tst.w obVelY(a0)
        bpl.s .fatigue
        addq.b #2,d0
.fatigue:
        tst.w (v_tails_flytime).w
        bne.s .frame
        move.w (v_framecount).w,d0
        lsr.w #3,d0
        andi.w #1,d0
        addi.b #$7E,d0
        bra.s .frame
.swim:
        lsr.w #2,d0
        divu.w #5,d0
        swap d0
        addi.b #$79,d0
.frame:
        move.b d0,obFrame(a0)
        andi.b #~(sprite_xflip|sprite_yflip),obRender(a0)
        move.b obStatus(a0),d0
        andi.b #sprite_xflip,d0
        or.b d0,obRender(a0)
.return:
        rts
.cancel:
        clr.b (v_tails_flying).w
        clr.b (v_tails_flap).w
        rts
