; Carried leader input: ABC jumps free, Up asks CPU Tails to climb.
; A second controller always overrides the CPU pilot. No camera or scripted
; lock flag is borrowed to keep the leader hanging.
sidekick_carry_y equ $1D                  ; rider hangs below Tails

Sidekick_RequestAssist:
        tst.b (v_sidekick_active).w
        beq.s .return
        tst.w (f_demo).w
        bne.s .return
        tst.b (f_playerctrl).w
        bne.s .return
        tst.b (f_lockctrl).w
        bne.s .return
        btst #1,obStatus(a0)
        beq.s .return
        btst #bitUp,(v_jpadhold2).w
        beq.s .return
        move.b (v_jpadpress2).w,d0
        andi.b #btnABC,d0
        beq.s .return
        move.b #180,(v_sidekick_assist).w
        clr.w (v_sidekick_manual).w
        andi.b #~btnABC,(v_jpadpress2).w
.return:
        rts

Sidekick_CarriedMovement:
        tst.b (v_sidekick_carry).w
        beq.w .inactive
        tst.b (v_sidekick_active).w
        beq.w .release
        tst.b (v_sidekick_state).w
        bne.w .release
        tst.b (sk_ctx_flight).w
        beq.w .release
        tst.b (f_playerctrl).w
        bne.w .release
        tst.b (f_lockctrl).w
        bne.w .release
        tst.w (v_debuguse).w
        bne.w .release
        cmpi.b #2,(v_sidekick_player+obRoutine).w
        bne.w .release
        tst.w (v_sidekick_carrydelay).w
        beq.s .jumpCheck
        subq.w #1,(v_sidekick_carrydelay).w
        bra.s .position
.jumpCheck:
        move.b (v_jpadpress2).w,d0
        andi.b #btnABC,d0
        beq.s .position
        clr.b (v_sidekick_carry).w
        move.w #30,(v_sidekick_carrydelay).w
        andi.b #~btnABC,(v_jpadpress2).w
        move.w #-$600,obVelY(a0)
        move.b #id_Roll,obAnim(a0)
        bset #2,obStatus(a0)
        move.b #sonic_roll_height,obHeight(a0)
        move.b #sonic_roll_width,obWidth(a0)
        move.b #1,jumping(a0)
        moveq #0,d0
        rts
.position:
        ; Level objects run after both players. If one displaced the rider,
        ; keep that collision result rather than pulling him back through it.
        move.w obX(a0),d0
        sub.w (v_sidekick_rider_x).w,d0
        addq.w #2,d0
        cmpi.w #4,d0
        bhi.w .collisionRelease
        move.w obY(a0),d0
        sub.w (v_sidekick_rider_y).w,d0
        addq.w #2,d0
        cmpi.w #4,d0
        bhi.w .collisionRelease
        move.w (v_sidekick_player+obX).w,obX(a0)
        move.w (v_sidekick_player+obY).w,obY(a0)
        addi.w #sidekick_carry_y,obY(a0)
        ; S2 mirrors both hanging sprites together, otherwise the hands
        ; miss when the pilot turns and the rider keeps facing the old way.
        andi.b #~sprite_xflip,obRender(a0)
        bclr #0,obStatus(a0)
        move.b (v_sidekick_player+obStatus).w,d0
        andi.b #sprite_xflip,d0
        or.b d0,obRender(a0)
        or.b d0,obStatus(a0)
        move.w (v_sidekick_player+obVelX).w,obVelX(a0)
        move.w (v_sidekick_player+obVelY).w,obVelY(a0)
        clr.w obInertia(a0)
        clr.b obAngle(a0)
        bset #1,obStatus(a0)
        bclr #3,obStatus(a0)
        jsr (Sonic_LevelBound).l
        cmpi.b #2,obRoutine(a0)
        bne.s .collisionRelease
        jsr (Sonic_Floor).l
        jsr (Sonic_FindCeiling).l
        tst.w d1
        bpl.s .headClear
        sub.w d1,obY(a0)
        clr.w obVelY(a0)
        bra.s .collisionRelease
.headClear:
        btst #1,obStatus(a0)
        beq.s .landed
        move.w obX(a0),d0
        sub.w (v_sidekick_player+obX).w,d0
        addq.w #2,d0
        cmpi.w #4,d0
        bhi.s .collisionRelease
        move.w obY(a0),d0
        sub.w (v_sidekick_player+obY).w,d0
        subi.w #sidekick_carry_y-2,d0
        cmpi.w #4,d0
        bhi.s .collisionRelease
        move.b #id_Carry,obAnim(a0)
        move.w obX(a0),(v_sidekick_rider_x).w
        move.w obY(a0),(v_sidekick_rider_y).w
        moveq #1,d0
        rts
.collisionRelease:
        cmpi.b #2,obRoutine(a0)
        bne.s .landed
        move.b #id_Fall,obAnim(a0)
.landed:
        clr.b (v_sidekick_carry).w
        move.w #30,(v_sidekick_carrydelay).w
        moveq #1,d0
        rts
.release:
        clr.b (v_sidekick_carry).w
        move.w #30,(v_sidekick_carrydelay).w
        move.b #id_Fall,obAnim(a0)
        bset #1,obStatus(a0)
.inactive:
        moveq #0,d0
        rts

; Called with leader globals active, after the companion's movement.
Sidekick_UpdateCarry:
        movem.l d0-d7/a0-a6,-(sp)
        tst.b (v_sidekick_carry).w
        bne.w .attached
        tst.w (v_sidekick_carrydelay).w
        beq.s .check
        subq.w #1,(v_sidekick_carrydelay).w
        bra.w .return
.check:
        tst.w (v_debuguse).w
        bne.w .return
        tst.b (v_sidekick_returning).w
        bne.w .return
        cmpi.b #id_Special,(v_gamemode).w
        beq.w .return
        tst.w (f_demo).w
        bne.w .return
        tst.b (v_sidekick_state).w
        bne.w .return
        tst.b (sk_ctx_flight).w
        beq.w .return
        tst.w (sk_ctx_flight+2).w
        beq.w .return
        cmpi.b #2,obRoutine(a0)
        bne.w .return
        btst #1,obStatus(a0)
        beq.w .return
        tst.b (f_playerctrl).w
        bne.w .return
        tst.b (f_lockctrl).w
        bne.w .return
        tst.b (v_lightdash).w
        bne.w .return
        lea (v_player).w,a1
        cmpi.b #2,obRoutine(a1)
        bne.w .return
        tst.b victorypose(a1)
        bne.w .return
        move.w obX(a1),d0
        sub.w obX(a0),d0
        addi.w #12,d0
        cmpi.w #24,d0
        bhi.w .return
        move.w obY(a1),d0
        sub.w obY(a0),d0
        subi.w #20,d0
        cmpi.w #20,d0
        bhi.w .return
        ; A summoned CPU pilot may collect the caller after the short
        ; summoning hop has landed. Only catch from below while ascending;
        ; the rider's normal terrain sensors check the resulting position.
        btst #1,obStatus(a1)
        bne.s .catch
        tst.b (v_sidekick_assist).w
        beq.w .return
        cmpi.w #sidekick_carry_y-20,d0   ; never pull a grounded rider down
        blo.w .return
        tst.w obVelY(a0)
        bpl.w .return
.catch:
        movea.l a1,a0
        jsr (Knuckles_EndAbility).l
        jsr (Sonic_CancelCharge).l
        bclr #2,obStatus(a0)
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        clr.b jumping(a0)
        move.w obX(a0),(v_sidekick_rider_x).w
        move.w obY(a0),(v_sidekick_rider_y).w
        st.b (v_sidekick_carry).w
        clr.b (v_sidekick_assist).w
        move.w #10,(v_sidekick_carrydelay).w
        jsr (Sidekick_CarriedMovement).l
        tst.b (v_sidekick_carry).w
        beq.s .return
        ; P1 already ran this frame. Draw the hanging pose on contact.
        jsr (Sonic_Animate).l
        jsr (Sonic_LoadGfx).l
        bra.s .return
.attached:
        lea (v_player).w,a0
        cmpi.b #2,obRoutine(a0)
        bne.s .cancel
        tst.b (sk_ctx_flight).w
        beq.s .cancel
        jsr (Sidekick_CarriedMovement).l
        bra.s .return
.cancel:
        jsr (Sidekick_DropRider).l
        clr.b (v_sidekick_carry).w
        move.w #30,(v_sidekick_carrydelay).w
.return:
        movem.l (sp)+,d0-d7/a0-a6
        rts

; d7 = handled, d0 = held. These inputs go through the normal flight code.
Sidekick_AssistControls:
        moveq #0,d7
        cmpi.b #id_Special,(v_gamemode).w
        beq.w .return
        tst.b (v_sidekick_carry).w
        bne.s .pilot
        tst.b (v_sidekick_assist).w
        beq.w .return
        subq.b #1,(v_sidekick_assist).w
        move.w (v_player+obX).w,d3
        sub.w obX(a0),d3
        moveq #0,d0
        cmpi.w #8,d3
        ble.s .left
        moveq #btnR,d0
        bra.s .height
.left:
        cmpi.w #-8,d3
        bge.s .height
        moveq #btnL,d0
.height:
        move.w (v_player+obY).w,d3
        subi.w #sidekick_carry_y,d3
        sub.w obY(a0),d3
        btst #1,obStatus(a0)
        beq.s .flap
        tst.b (sk_ctx_flight).w
        bne.s .airborne
        ; Release the ground jump before generating the second press.
        move.b (v_framecount+1).w,d1
        andi.b #3,d1
        bne.s .handled
        ori.b #btnA,d0
        bra.s .handled
.airborne:
        tst.w d3
        bpl.s .handled
.flap:
        move.b (v_framecount+1).w,d1
        andi.b #$F,d1
        bne.s .handled
        ori.b #btnA,d0
        bra.s .handled
.pilot:
        move.b (v_jpadhold1).w,d0
        andi.b #btnL|btnR,d0
        btst #bitUp,(v_jpadhold1).w
        beq.s .handled
        move.b (v_framecount+1).w,d1
        andi.b #$F,d1
        bne.s .handled
        ori.b #btnA,d0
.handled:
        moveq #1,d7
.return:
        rts

; May be called with either physics context active. Only object fields are
; touched, and a damage/death/script pose always takes priority over hanging.
Sidekick_DropRider:
        clr.b (v_sidekick_carry).w
        cmpi.b #2,(v_player+obRoutine).w
        bne.s .return
        cmpi.b #id_Carry,(v_player+obAnim).w
        bne.s .return
        move.b #id_Fall,(v_player+obAnim).w
        bset #1,(v_player+obStatus).w
.return:
        rts

; During results the bonus digits leave 18 body tiles at $55E-$56F.
; Only use the compact landing and victory frames and retire the separate tail.
Sidekick_FinishScene:
        tst.b (v_sidekick_active).w
        beq.s .return
        jsr (Sidekick_DropRider).l
        move.l #Map_SidekickHidden,(v_sidekick_tail+obMap).w
        clr.b (v_sidekick_tail+obFrame).w
        tst.b (v_sidekick_state).w
        beq.s .land
        cmpi.b #3,(v_sidekick_state).w ; the companion is still flying back
        bne.s Sidekick_HideResults
        clr.b (v_sidekick_state).w
        clr.b (v_sidekick_returning).w
.land:
        movem.l d0-d7/a0-a6,-(sp)
        lea (v_sidekick_player).w,a0
        st.b victorypose(a0)
        clr.l obVelX(a0)
        clr.w obInertia(a0)
        clr.l (sk_ctx_flight).w
        bclr #2,obStatus(a0)
        beq.s .normalSize
        subq.w #sonic_height-sonic_roll_height,obY(a0)
.normalSize:
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        jsr (Sidekick_SwapContext).l
        bsr.s Sidekick_VictoryArt       ; also update the sprite queued before the card
        jsr (Sidekick_SwapContext).l
        movem.l (sp)+,d0-d7/a0-a6
.return:
        rts

Sidekick_HideResults:
        clr.b (v_sidekick_active).w
        move.l #Map_SidekickHidden,(v_sidekick_player+obMap).w
        clr.b (v_sidekick_player+obFrame).w
        rts

; SBZ2 resumes gameplay after the last tally has left the screen.
Sidekick_ResumeAfterResults:
        tst.b (v_sidekick_active).w
        beq.s .return
        clr.b (v_sidekick_player+victorypose).w
        clr.b (v_sidekick_tail+obRoutine).w ; restore its mappings and reload tail tiles
.return:
        rts

Sidekick_Victory:
        jsr (Sidekick_SwapContext).l
        btst #1,obStatus(a0)
        beq.s .draw
        jsr (SpeedToPos).l
        addi.w #$38,obVelY(a0)
        jsr (Sonic_Floor).l
.draw:
        bsr.s Sidekick_VictoryArt
        jsr (Sidekick_SwapContext).l
        jmp (DisplaySprite).l

Sidekick_VictoryArt:
        move.b #id_Victory,obAnim(a0)
        btst #1,obStatus(a0)
        beq.s .animate
        move.b #id_Spring,obAnim(a0)   ; upright descent, 16 tiles
.animate:
        jsr (Sonic_Animate).l
        jmp (Sidekick_LoadGfx).l

; The leader disappearing into a ring does not remove his companion.
; Continue the stage during the white fade while keeping fade counters and
; its palette intact. VBlank_PaletteFade transfers sprites and queued DMA.
Sidekick_RingFadeFrame:
        tst.b (v_sidekick_ring_entry).w
        beq.s .return
        tst.b (v_sidekick_active).w
        beq.s .return
        movem.l d0-d7/a0-a6,-(sp)
        move.w (v_gamemode).w,-(sp)
        move.b #id_Level,(v_gamemode).w
        addq.w #1,(v_framecount).w
        jsr (ExecuteObjects).l
        jsr (BuildSprites).l
        move.w (sp)+,(v_gamemode).w
        movem.l (sp)+,d0-d7/a0-a6
.return:
        rts
