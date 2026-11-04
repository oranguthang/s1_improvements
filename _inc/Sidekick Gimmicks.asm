; Local movement features. Entry/exit keeps the leader's control context.
Sidekick_LZGimmicks:
        tst.w (v_sidekick_pole).w
        bne.w Sidekick_PoleMove
        cmpi.b #id_LZ,(v_zone).w
        bne.s .normal
        jsr (LZWindTunnels).l
        jsr (LZWaterSlides).l
        tst.b (f_wtunnelmode).w
        beq.s .normal
        clr.l (v_tails_flying).w
        moveq #1,d0
        rts
.normal:
        moveq #0,d0
        rts

Sidekick_Conveyor:
        movem.l d0-d7/a0-a6,-(sp)
        tst.b (v_sidekick_active).w
        beq.s .return
        tst.b (v_sidekick_state).w
        bne.s .return
        tst.w (f_demo).w
        bne.s .return
        tst.w (v_debuguse).w
        bne.s .return
        lea (v_sidekick_player).w,a1
        jsr (Conveyor_MovePlayer).l
.return:
        movem.l (sp)+,d0-d7/a0-a6
        rts

; ReactToItem has a0=companion, a1=target. Preserve its collision queue ABI.
Sidekick_Bumper:
        movem.l d1-d7/a0-a6,-(sp)
        exg a0,a1
        jsr (Bump_ApplyHit).l
        movem.l (sp)+,d1-d7/a0-a6
        moveq #-1,d0
        rts

Sidekick_GrabPole:
        tst.w (v_sidekick_pole).w
        bne.s .return
        cmpi.b #2,obRoutine(a1)
        bne.s .return
        tst.b obFrame(a1)
        bne.s .return
        move.w obX(a0),d0
        sub.w obX(a1),d0
        cmpi.w #20,d0
        bls.s .return
        move.w a1,(v_sidekick_pole).w
        moveq #0,d0
        move.b obSubtype(a1),d0
        mulu.w #60,d0
        move.w d0,(v_sidekick_poletimer).w
        clr.l obVelX(a0)
        clr.w obInertia(a0)
        clr.l (v_tails_flying).w
        bclr #2,obStatus(a0)
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        move.b #id_Hang,obAnim(a0)
        bset #1,obStatus(a0)
.return:
        moveq #-1,d0
        rts

Sidekick_PoleMove:
        movea.w (v_sidekick_pole).w,a1
        cmpi.b #id_Pole,obID(a1)
        bne.w .release
        cmpi.b #2,obRoutine(a1)
        bne.w .release
        cmpi.b #2,obRoutine(a0)
        bne.w .release
        tst.w (v_sidekick_poletimer).w
        beq.s .move
        subq.w #1,(v_sidekick_poletimer).w
        bne.s .move
        tst.b pole_grabbed(a1)
        beq.s .break
        move.w #1,pole_breaktime(a1)       ; let P1's handler release P1
        bra.w .release
.break:
        move.b #1,obFrame(a1)
        move.b #4,obRoutine(a1)
        clr.b obColType(a1)
        bra.w .release
.move:
        move.w obX(a1),obX(a0)
        addi.w #20,obX(a0)
        moveq #0,d0
        move.b (v_jpadhold2).w,d0
        btst #bitUp,d0
        beq.s .down
        subq.w #1,obY(a0)
.down:
        btst #bitDn,d0
        beq.s .bounds
        addq.w #1,obY(a0)
.bounds:
        move.w obY(a1),d0
        subi.w #24,d0
        cmp.w obY(a0),d0
        bls.s .bottom
        move.w d0,obY(a0)
.bottom:
        addi.w #36,d0
        cmp.w obY(a0),d0
        bhs.s .jump
        move.w d0,obY(a0)
.jump:
        move.b (v_jpadpress2).w,d0
        andi.b #btnABC,d0
        bne.s .jumpFree
        clr.l obVelX(a0)
        clr.w obInertia(a0)
        clr.b (f_wtunnelmode).w
        clr.l (v_tails_flying).w
        move.b #id_Hang,obAnim(a0)
        bclr #0,obStatus(a0)
        moveq #1,d0
        rts
.jumpFree:
        move.w #-$400,obVelY(a0)
        andi.b #~btnABC,(v_jpadpress2).w
.release:
        clr.w (v_sidekick_pole).w
        cmpi.b #2,obRoutine(a0)
        bne.s .notHanging
        move.b #id_Fall,obAnim(a0)
.notHanging:
        moveq #0,d0
        rts
