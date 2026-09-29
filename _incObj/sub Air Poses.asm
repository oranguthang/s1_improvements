; ---------------------------------------------------------------------------
; Cosmetic spring/fall transitions. Never change collision size, rolling state,
; jump/homing flags, velocity, gravity, music or input. New actions replace the
; animation themselves, so only the spring and its following fall are handled.
; ---------------------------------------------------------------------------
Sonic_UpdateAirPose:
        tst.b (v_lightdash).w
        bne.s .return
        cmpi.b #2,obRoutine(a0)
        bne.s .return
        tst.b (f_playerctrl).w
        bne.s .return
        tst.w (v_debuguse).w
        bne.s .return
        cmpi.b #1,(v_superpal_state).w
        beq.s .return
        move.b obAnim(a0),d0
        cmpi.b #id_Spring,d0
        beq.s .eligible
        cmpi.b #id_Fall,d0
        beq.s .eligible
        bra.s .return                   ; ordinary ledge falls keep their animation
.eligible:
        btst #1,obStatus(a0)
        beq.s .grounded
        bclr #5,obStatus(a0)             ; never re-enter pushing while in the air
        tst.w obVelY(a0)
        bmi.s .ascending
        move.b #id_Fall,obAnim(a0)       ; apex/downward spring only
.return:
        rts
.ascending:
        cmpi.b #id_Fall,d0
        bne.s .return
        move.b #id_Walk,obAnim(a0)       ; an external upward launch replaced the fall
        rts
.grounded:
        cmpi.b #id_Spring,d0
        beq.s .walk
        cmpi.b #id_Fall,d0
        bne.s .return
.walk:
        move.b #id_Walk,obAnim(a0)       ; also covers object landings with FixBugs=0
        rts
