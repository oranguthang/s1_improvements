; Companion globals are active on entry. The water palette belongs to the
; screen; movement, swimming endurance and air belong to each player.
Sidekick_Water:
        cmpi.b #id_LZ,(v_zone).w
        bne.w .dry
        move.w (v_waterpos1).w,d0
        cmp.w obY(a0),d0
        bge.w .dry
        bset #6,obStatus(a0)
        bne.s .underwater
        asr.w obVelX(a0)
        asr.w obVelY(a0)
        asr.w obVelY(a0)
        move.w #30,(v_air).w
        clr.w (v_sidekick_airframes).w
.underwater:
        addq.w #1,(v_sidekick_airframes).w
        cmpi.w #60,(v_sidekick_airframes).w
        blo.w .return
        clr.w (v_sidekick_airframes).w
        subq.w #1,(v_air).w
        bmi.s .drown
        jsr (Sidekick_SpawnAirBubble).l
        rts
.drown:
        move.b #4,(v_sidekick_state).w
        move.w #90,(v_sidekick_timer).w
        jsr (Sidekick_DropRider).l
        clr.b (v_sidekick_carry).w
        clr.b (v_sidekick_assist).w
        clr.w (v_sidekick_platform).w
        clr.l (v_tails_flying).w
        move.b #2,obStatus(a0)
        move.b #id_Drown,obAnim(a0)
        move.w #-$300,obVelY(a0)
        clr.w obVelX(a0)
        move.w #sfx_Drown,d0
        jsr (QueueSound2).l
        rts
.dry:
        bclr #6,obStatus(a0)
        beq.s .air
        btst #1,obStatus(a0)
        beq.s .air
        asl.w obVelY(a0)
        cmpi.w #-$1000,obVelY(a0)
        bge.s .air
        move.w #-$1000,obVelY(a0)
.air:
        move.w #30,(v_air).w
        clr.w (v_sidekick_airframes).w
.return:
        rts

Sidekick_SpeedSettings:
        move.w #son_maxspeed,(v_sonspeedmax).w
        move.w #son_acceleration,(v_sonspeedacc).w
        move.w #son_deceleration,(v_sonspeeddec).w
        tst.b (v_shoes).w
        beq.s .water
        tst.w shoetime(a0)
        beq.s .shoesExpired
        subq.w #1,shoetime(a0)
        move.w #son_maxspeed*2,(v_sonspeedmax).w
        move.w #son_acceleration*2,(v_sonspeedacc).w
        bra.s .water
.shoesExpired:
        clr.b (v_shoes).w
.water:
        btst #6,obStatus(a0)
        beq.s .catchup
        asr.w (v_sonspeedmax).w
        asr.w (v_sonspeedacc).w
        asr.w (v_sonspeeddec).w
        rts
.catchup:
        tst.w (v_sidekick_manual).w
        bne.s .return
        tst.b (v_shoes).w
        bne.s .return
        move.w (v_player+obX).w,d0
        sub.w obX(a0),d0
        bpl.s .absolute
        neg.w d0
.absolute:
        cmpi.w #80,d0
        blo.s .return
        move.w #$A00,(v_sonspeedmax).w
        move.w #$18,(v_sonspeedacc).w
.return:
        rts

Sidekick_Drowning:
        jsr (Sidekick_SwapContext).l
        jsr (SpeedToPos).l
        addi.w #$10,obVelY(a0)
        move.b #id_Drown,obAnim(a0)
        jsr (Sonic_Animate).l
        jsr (Sidekick_LoadGfx).l
        jsr (Sidekick_SwapContext).l
        subq.w #1,(v_sidekick_timer).w
        bmi.s .lost
        jmp (DisplaySprite).l
.lost:
        jmp (Sidekick_Lost).l

; P1 gets first refusal on a large bubble. Return Z clear only if Tails
; collected it; do not reset P1 air, drowning music or velocities.
Sidekick_TryBubble:
        movem.l d1-d7/a0-a6,-(sp)
        tst.w (f_demo).w
        bne.w .miss
        tst.b bub_inhalable(a0)
        beq.w .miss
        tst.b (v_sidekick_active).w
        beq.w .miss
        tst.b (v_sidekick_state).w
        bne.w .miss
        tst.w (v_debuguse).w
        bne.w .miss
        lea (v_sidekick_player).w,a1
        cmpi.b #4,obRoutine(a1)
        bhs.w .miss
        btst #6,obStatus(a1)
        beq.w .miss
        move.w obX(a1),d0
        sub.w obX(a0),d0
        addi.w #16,d0
        cmpi.w #32,d0
        bhs.w .miss
        move.w obY(a1),d0
        sub.w obY(a0),d0
        cmpi.w #16,d0
        bhi.w .miss
        move.w #30,(sk_ctx_air).w
        clr.w (v_sidekick_airframes).w
        clr.b (sk_ctx_flight+1).w
        clr.l obVelX(a1)
        clr.w obInertia(a1)
        move.b #id_GetAir,obAnim(a1)
        move.w #35,locktime(a1)
        clr.b jumping(a1)
        bclr #5,obStatus(a1)
        bclr #2,obStatus(a1)
        beq.s .sound
        move.b #sonic_height,obHeight(a1)
        move.b #sonic_width,obWidth(a1)
        subq.w #sonic_height-sonic_roll_height,obY(a1)
.sound:
        move.w #sfx_Bubble,d0
        jsr (QueueSound2).l
        moveq #1,d0
        bra.s .return
.miss:
        moveq #0,d0
.return:
        movem.l (sp)+,d1-d7/a0-a6
        rts

; Called only on the companion's one-second air tick, with private air active.
Sidekick_SpawnAirBubble:
        tst.w (f_demo).w
        bne.s .return
        movem.l d0-d7/a0-a6,-(sp)
        jsr (FindFreeObj).l
        bne.s .done
        move.b #id_SidekickAirBubble,obID(a1)
        move.w obX(a0),obX(a1)
        moveq #6,d0
        btst #0,obStatus(a0)
        beq.s .right
        neg.w d0
        move.b #$40,obAngle(a1)
.right:
        add.w d0,obX(a1)
        move.w obY(a0),obY(a1)
        move.b #6,obSubtype(a1)
        move.w (v_air).w,d0
        cmpi.w #12,d0
        bhs.s .done
        btst #0,d0
        beq.s .done
        lsr.w #1,d0
        move.b d0,obSubtype(a1)
        move.w #28,drown_numtime(a1)
.done:
        movem.l (sp)+,d0-d7/a0-a6
.return:
        rts

SidekickAirBubble:
        tst.b (v_sidekick_active).w
        beq.s .delete
        tst.w (v_debuguse).w
        bne.s .delete
        move.w (v_air).w,-(sp)
        move.w (sk_ctx_air).w,(v_air).w
        move.b (f_wtunnelmode).w,-(sp)
        move.b (sk_ctx_tunnel).w,(f_wtunnelmode).w
        jsr (DrownCount).l
        move.b (sp)+,(f_wtunnelmode).w
        move.w (sp)+,(v_air).w
        rts
.delete:
        jmp (DeleteObject).l
