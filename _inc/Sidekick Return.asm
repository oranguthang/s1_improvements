; CPU top speed increases only while catching a distant leader. Manual
; control and swimming keep their normal speed, acceleration and endurance.
; Return from above the camera in air or from below if the leader is swimming.
; Collision is restored close to the leader.
sidekick_below_screen: equ 224+32
Sidekick_ReturnFlight:
        jsr (Sidekick_SwapContext).l
        move.w (v_player+obX).w,d0
        subi.w #24,d0
        sub.w obX(a0),d0
        move.w d0,d4
        cmpi.w #128,d0
        ble.s .xDeltaMin
        move.w #128,d0
.xDeltaMin:
        cmpi.w #-128,d0
        bge.s .xDeltaReady
        move.w #-128,d0
.xDeltaReady:
        asl.w #4,d0
        cmpi.w #$800,d0
        ble.s .xMin
        move.w #$800,d0
.xMin:
        cmpi.w #-$800,d0
        bge.s .xSpeed
        move.w #-$800,d0
.xSpeed:
        move.w d0,obVelX(a0)
        move.w (v_player+obY).w,d0
        subi.w #40,d0
        btst #6,(v_player+obStatus).w
        beq.s .targetY
        move.w (v_waterpos1).w,d1
        addq.w #1,d1                  ; keep the swim target below the surface
        cmp.w d1,d0
        bge.s .targetY
        move.w d1,d0
.targetY:
        sub.w obY(a0),d0
        move.w d0,d5
        cmpi.w #64,d0
        ble.s .yDeltaMin
        move.w #64,d0
.yDeltaMin:
        cmpi.w #-64,d0
        bge.s .yDeltaReady
        move.w #-64,d0
.yDeltaReady:
        asl.w #4,d0
        cmpi.w #$400,d0
        ble.s .yMin
        move.w #$400,d0
.yMin:
        cmpi.w #-$400,d0
        bge.s .ySpeed
        move.w #-$400,d0
.ySpeed:
        move.w d0,obVelY(a0)
        bclr #0,obStatus(a0)
        tst.w obVelX(a0)
        bpl.s .facing
        bset #0,obStatus(a0)
.facing:
        jsr (SpeedToPos).l
        bclr #6,obStatus(a0)
        cmpi.b #id_LZ,(v_zone).w
        bne.s .pose
        move.w (v_waterpos1).w,d0
        cmp.w obY(a0),d0
        bge.s .pose
        bset #6,obStatus(a0)           ; use the swimming art and skip rotor SFX
.pose:
        move.b #1,(v_tails_flying).w
        move.w #480,(v_tails_flytime).w
        move.b #id_Float1,obAnim(a0)
        jsr (Sonic_Animate).l
        jsr (Tails_FlightPose).l
        addi.w #12,d4
        cmpi.w #24,d4
        bhi.s .timeout
        addi.w #12,d5
        cmpi.w #24,d5
        bhi.s .timeout
        clr.b (v_sidekick_state).w
        clr.w (v_sidekick_stuck).w
        clr.w obVelY(a0)
        ; Keep flying or swimming until native floor collision lands Tails.
        ; v_sidekick_returning separately prevents an automatic pickup.
        bra.s .draw
.timeout:
        subq.w #1,(v_sidekick_timer).w
        bpl.s .draw
        ; Use the current camera and position, not last frame's render flag.
        moveq #0,d1
        move.b obActWid(a0),d1
        move.w obX(a0),d0
        sub.w (v_screenposx).w,d0
        add.w d1,d0
        bmi.s .lost
        add.w d1,d1
        addi.w #320,d1
        cmp.w d1,d0
        bge.s .lost
        move.w obY(a0),d0
        sub.w (v_screenposy).w,d0
        addi.w #32,d0
        cmpi.w #224+64,d0
        bhs.s .lost
        clr.w (v_sidekick_timer).w      ; still visible, retry only after leaving the screen
        bra.s .draw
.lost:
        jsr (Sidekick_Lost).l
.draw:
        jsr (Sidekick_LoadGfx).l
        jsr (Sidekick_SwapContext).l
        jmp (DisplaySprite).l
