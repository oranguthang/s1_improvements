; Companion collision pass. Native helpers retain every register and CCR.
; Only the leader sets an object's P1 standing/pushing/routine flags. A private
; pointer + ID + last position belongs to Tails; this also prevents recycled
; object slots from moving him after a platform was deleted.

Sidekick_Solid:
        move.w sr,-(sp)
        movem.l d0-d7/a0-a6,-(sp)
        bsr.w Sidekick_CollisionEnabled
        beq.w .return
        bsr.w Sidekick_SolidPass
.return:
        movem.l (sp)+,d0-d7/a0-a6
        move.w (sp)+,ccr
        rts

Sidekick_Heightmap:
        move.w sr,-(sp)
        movem.l d0-d7/a0-a6,-(sp)
        bsr.w Sidekick_CollisionEnabled
        beq.w .return
        bsr.w Sidekick_HeightmapPass
.return:
        movem.l (sp)+,d0-d7/a0-a6
        move.w (sp)+,ccr
        rts

Sidekick_Platform:
        move.w sr,-(sp)
        movem.l d0-d7/a0-a6,-(sp)
        bsr.w Sidekick_CollisionEnabled
        beq.w .return
        bsr.w Sidekick_PlatformPass
.return:
        movem.l (sp)+,d0-d7/a0-a6
        move.w (sp)+,ccr
        rts

Sidekick_PlatformCustom:
        move.w sr,-(sp)
        movem.l d0-d7/a0-a6,-(sp)
        bsr.w Sidekick_CollisionEnabled
        beq.w .return
        bsr.w Sidekick_PlatformCustomPass
.return:
        movem.l (sp)+,d0-d7/a0-a6
        move.w (sp)+,ccr
        rts

Sidekick_Slope:
        move.w sr,-(sp)
        movem.l d0-d7/a0-a6,-(sp)
        bsr.w Sidekick_CollisionEnabled
        beq.w .return
        bsr.w Sidekick_SlopePass
.return:
        movem.l (sp)+,d0-d7/a0-a6
        move.w (sp)+,ccr
        rts

Sidekick_Ride:
        move.w sr,-(sp)
        movem.l d0-d7/a0-a6,-(sp)
        bsr.w Sidekick_CollisionEnabled
        beq.w .return
        bsr.w Sidekick_RidePass
.return:
        movem.l (sp)+,d0-d7/a0-a6
        move.w (sp)+,ccr
        rts

Sidekick_RideCustom:
        move.w sr,-(sp)
        movem.l d0-d7/a0-a6,-(sp)
        bsr.w Sidekick_CollisionEnabled
        beq.w .return
        bsr.w Sidekick_RideCustomPass
.return:
        movem.l (sp)+,d0-d7/a0-a6
        move.w (sp)+,ccr
        rts

Sidekick_CollisionEnabled:
        tst.b (v_sidekick_active).w
        beq.w .return
        tst.b (v_sidekick_state).w
        bne.w .off
        tst.b (v_sidekick_carry).w
        bne.w .off
        tst.w (v_debuguse).w
        bne.w .off
        cmpi.b #4,(v_sidekick_player+obRoutine).w
        bhs.w .off
        cmpi.b #6,(v_player+obRoutine).w
        bhs.w .off
        tst.b (v_sidekick_ring_entry).w
        bne.s .ringEntry
        tst.b (f_playerctrl).w
        bmi.w .off
.ringEntry:
        cmpi.b #id_CollapseLedge,obID(a0)
        beq.s .collapsible
        cmpi.b #id_CollapseFloor,obID(a0)
        bne.s .solidObject
.collapsible:
        btst #sprite_rawmappings_bit,obRender(a0)
        bne.w .off
.solidObject:
        lea (v_sidekick_player).w,a1
        cmpa.w (v_sidekick_platform).w,a0
        bne.s .ready
        btst #1,obStatus(a1)
        bne.s .ready
        move.w obX(a0),d0
        sub.w (v_sidekick_platform_x).w,d0
        add.w d0,obX(a1)
        move.w obY(a0),d0
        sub.w (v_sidekick_platform_y).w,d0
        add.w d0,obY(a1)
        add.w d0,(v_sidekick_prev_y).w
        move.w obX(a0),(v_sidekick_platform_x).w
        move.w obY(a0),(v_sidekick_platform_y).w
.ready:
        moveq #1,d0
.return:
        rts
.off:
        moveq #0,d0
        rts

; Apply movement accumulated after Tails ran in the previous frame.
; Contact hooks also apply movement made earlier in this frame, exactly once.
Sidekick_PlatformBegin:
        tst.b (v_sidekick_spring_delay).w
        beq.s .springReady
        subq.b #1,(v_sidekick_spring_delay).w
.springReady:
        move.w (v_sidekick_platform).w,d0
        beq.w .return
        movea.w d0,a2
        cmpi.b #id_CollapseLedge,obID(a2)
        beq.s .collapsible
        cmpi.b #id_CollapseFloor,obID(a2)
        bne.s .platform
.collapsible:
        btst #sprite_rawmappings_bit,obRender(a2)
        bne.w .detach
.platform:
        tst.b (v_sidekick_platform_seen).w
        beq.w .detach
        move.b obID(a2),d0
        cmp.b (v_sidekick_platform_id).w,d0
        bne.w .detach
        btst #1,obStatus(a0)
        bne.w .detach
        btst #3,obStatus(a0)
        beq.w .detach
        move.w obX(a2),d0
        sub.w (v_sidekick_platform_x).w,d0
        add.w d0,obX(a0)
        move.w obY(a2),d0
        sub.w (v_sidekick_platform_y).w,d0
        add.w d0,obY(a0)
        move.w obX(a2),(v_sidekick_platform_x).w
        move.w obY(a2),(v_sidekick_platform_y).w
        clr.b (v_sidekick_platform_seen).w
.return:
        rts
.detach:
        clr.w (v_sidekick_platform).w
        bclr #3,obStatus(a0)
        rts

; Common one-way platform top. d1 = half width, d6 = absolute surface Y.
Sidekick_PlatformPass:
        move.w obY(a0),d6
        subq.w #8,d6
        bra.w Sidekick_Top
Sidekick_PlatformCustomPass:
        move.w obY(a0),d6
        sub.w d3,d6
        bra.w Sidekick_Top
Sidekick_RidePass:
        moveq #9,d3
Sidekick_RideCustomPass:
        moveq #0,d1
        move.b obActWid(a0),d1
        move.w obY(a0),d6
        sub.w d3,d6
        bra.w Sidekick_Top

Sidekick_SlopePass:
        move.w obX(a1),d0
        sub.w obX(a0),d0
        add.w d1,d0
        bmi.w Sidekick_CollisionReturn
        move.w d1,d5
        add.w d5,d5
        cmp.w d5,d0
        bhs.w Sidekick_CollisionReturn
        btst #sprite_xflip_bit,obRender(a0)
        beq.s .sample
        not.w d0
        add.w d5,d0
.sample:
        lsr.w #1,d0
        moveq #0,d5
        move.b (a2,d0.w),d5
        move.w obY(a0),d6
        sub.w d5,d6
        bra.w Sidekick_Top

Sidekick_HeightmapPass:
        move.w obX(a1),d0
        sub.w obX(a0),d0
        add.w d1,d0
        bmi.w Sidekick_CollisionReturn
        move.w d1,d5
        add.w d5,d5
        cmp.w d5,d0
        bhi.w Sidekick_CollisionReturn
        btst #sprite_xflip_bit,obRender(a0)
        beq.s .sample
        not.w d0
        add.w d5,d0
.sample:
        lsr.w #1,d0
        moveq #0,d5
        move.b (a2,d0.w),d5
        sub.b (a2),d5
        move.w obY(a0),d6
        sub.w d5,d6
        sub.w d2,d6
        move.w d2,d3
        bra.s Sidekick_SolidSurface

Sidekick_SolidPass:
        move.w obY(a0),d6
        sub.w d2,d6
Sidekick_SolidSurface:
        ; The initial and standing heights can differ (springs, monitors).
        move.w d6,d7
        bsr.w Sidekick_Top
        tst.b d0
        bne.w Sidekick_CollisionReturn
        move.w obX(a1),d5
        sub.w obX(a0),d5
        move.w d5,d4
        bpl.s .absX
        neg.w d4
.absX:
        cmp.w d1,d4
        bhs.w Sidekick_CollisionReturn
        moveq #0,d0
        move.b obHeight(a1),d0
        move.w obY(a1),d6
        sub.w d0,d6
        move.w obY(a0),d2
        add.w d3,d2
        cmp.w d2,d6
        bge.w Sidekick_CollisionReturn
        move.w obY(a1),d6
        add.w d0,d6
        cmp.w d7,d6
        ble.w Sidekick_CollisionReturn
        ; Moving up through an underside: resolve vertically, not sideways.
        tst.w obVelY(a1)
        bpl.s .side
        move.w (v_sidekick_prev_y).w,d6
        sub.w d0,d6
        addq.w #4,d6
        cmp.w d2,d6
        blt.s .side
        add.w d0,d2
        move.w d2,obY(a1)
        clr.w obVelY(a1)
        moveq #3,d7
        bra.w Sidekick_SpringHit
.side:
        move.w obX(a0),d0
        tst.w d5
        bmi.s .left
        add.w d1,d0
        bra.s .clip
.left:
        sub.w d1,d0
.clip:
        move.w d0,obX(a1)
        clr.w obVelX(a1)
        clr.w obInertia(a1)
        bset #5,obStatus(a1)
        moveq #2,d7
        bra.w Sidekick_SpringHit

Sidekick_Top:
        move.w obX(a1),d5
        sub.w obX(a0),d5
        add.w d1,d5
        bmi.w .miss
        move.w d1,d4
        add.w d4,d4
        cmp.w d4,d5
        bhi.w .miss
        tst.w obVelY(a1)
        bmi.w .miss
        moveq #0,d0
        move.b obHeight(a1),d0
        move.w obY(a1),d5
        add.w d0,d5
        addq.w #4,d5
        cmp.w d6,d5
        blt.w .miss
        cmpa.w (v_sidekick_platform).w,a0
        beq.s .land
        move.w (v_sidekick_prev_y).w,d5
        add.w d0,d5
        subi.w #8,d5
        cmp.w d6,d5
        bgt.w .miss
.land:
        ; ResetOnFloor can enlarge a rolling hitbox. Set feet afterwards.
        btst #1,obStatus(a1)
        beq.s .standing
        movem.l d0-d7/a0-a6,-(sp)
        movea.l a1,a0
        jsr (Sidekick_SwapContext).l
        jsr (Sonic_ResetOnFloor).l
        clr.l (v_tails_flying).w
        jsr (Sidekick_SwapContext).l
        movem.l (sp)+,d0-d7/a0-a6
.standing:
        ; Solids use their explicit standing height after initial contact.
        ; One-way platforms already supplied their precise surface in d6.
        moveq #0,d0
        move.b obHeight(a1),d0
        sub.w d0,d6
        subq.w #1,d6
        move.w d6,obY(a1)
        clr.w obSubpixelY(a1)
        clr.w obVelY(a1)
        clr.b obAngle(a1)
        bclr #1,obStatus(a1)
        bset #3,obStatus(a1)
        move.w a0,(v_sidekick_platform).w
        move.b obID(a0),(v_sidekick_platform_id).w
        st.b (v_sidekick_platform_seen).w
        move.w obX(a0),(v_sidekick_platform_x).w
        move.w obY(a0),(v_sidekick_platform_y).w
        move.w a0,d0
        subi.w #v_objspace&$FFFF,d0
        lsr.w #object_size_bits,d0
        move.b d0,standonobject(a1)
        bsr.w Sidekick_TopTrigger
        moveq #1,d7
        bsr.w Sidekick_SpringHit
        moveq #1,d0
        rts
.miss:
        moveq #0,d0
Sidekick_CollisionReturn:
        rts

; d7: 1 top, 2 side, 3 underside. Do not touch the spring's P1 flags.
Sidekick_SpringHit:
        bsr.w Sidekick_SpikesHit
        cmpi.b #id_Springs,obID(a0)
        bne.w .return
        tst.b (v_sidekick_spring_delay).w
        bne.w .return
        move.b obSubtype(a0),d0
        btst #4,d0
        bne.s .horizontal
        btst #5,d0
        bne.s .down
        cmpi.b #1,d7
        bne.w .return
        move.w spring_pow(a0),obVelY(a1)
        move.b #id_Spring,obAnim(a1)
        bra.s .airborne
.down:
        cmpi.b #3,d7
        bne.w .return
        move.w spring_pow(a0),d0
        neg.w d0
        move.w d0,obVelY(a1)
        bra.s .airborne
.horizontal:
        cmpi.b #2,d7
        bne.w .return
        move.w spring_pow(a0),d0
        btst #0,obStatus(a0)
        bne.s .leftward
        cmpi.w #0,d5
        bmi.w .return
        neg.w d0
        bclr #0,obStatus(a1)
        bra.s .setX
.leftward:
        tst.w d5
        bpl.w .return
        bset #0,obStatus(a1)
.setX:
        move.w d0,obVelX(a1)
        move.w d0,obInertia(a1)
        move.w #15,locktime(a1)
        bclr #5,obStatus(a1)
        bra.s .launch
.airborne:
        bset #1,obStatus(a1)
        bclr #3,obStatus(a1)
        clr.w (v_sidekick_platform).w
.launch:
        clr.l (sk_ctx_flight).w
        move.b #10,(v_sidekick_spring_delay).w
        tst.w (f_demo).w
        bne.s .sound
        move.w a0,(v_sidekick_spring_object).w
.sound:
        move.w #sfx_Spring,d0
        jsr (QueueSound2).l
.return:
        rts

; Runs after the native spring handler, so simultaneous P1/P2 contact can
; never advance the animation routine twice.
Sidekick_SpringAnimation:
        move.w sr,-(sp)
        movem.l d0-d1,-(sp)
        cmpa.w (v_sidekick_spring_object).w,a0
        bne.w .return
        clr.w (v_sidekick_spring_object).w
        move.b obRoutine(a0),d0
        cmpi.b #2,d0
        beq.s .animate
        cmpi.b #8,d0
        beq.s .animate
        cmpi.b #$E,d0
        bne.w .return
.animate:
        addq.b #2,obRoutine(a0)
.return:
        movem.l (sp)+,d0-d1
        move.w (sp)+,ccr
        rts

; Same pointy-side policy as FixBugs spikes, with no P1 ring/life effects.
Sidekick_SpikesHit:
        cmpi.b #id_Spikes,obID(a0)
        bne.w .return
        tst.b (sk_ctx_invinc).w
        bne.w .return
        move.b obFrame(a0),d0
        cmpi.b #1,d0
        beq.s .side
        cmpi.b #5,d0
        beq.s .side
        cmpi.b #1,d7
        beq.s .top
        cmpi.b #3,d7
        bne.w .return
        btst #1,obStatus(a0)
        bne.s .hurt
        rts
.top:
        btst #1,obStatus(a0)
        beq.s .hurt
        rts
.side:
        cmpi.b #2,d7
        bne.w .return
        move.w obX(a1),d0
        sub.w obX(a0),d0
        btst #0,obStatus(a0)
        beq.s .pointy
        neg.w d0
.pointy:
        tst.w d0
        bpl.w .return
.hurt:
        movem.l d0-d7/a0-a6,-(sp)
        movea.l a0,a2
        movea.l a1,a0
        jsr (Sidekick_Hurt).l
        movem.l (sp)+,d0-d7/a0-a6
.return:
        rts

; Timers stay in the platform object. Tails starts collapse without changing
; the routine that assumes P1 is standing on it. Demo layouts remain intact.
Sidekick_TopTrigger:
        tst.w (f_demo).w
        bne.w .return
        cmpi.b #id_CollapseLedge,obID(a0)
        beq.s .collapse
        cmpi.b #id_CollapseFloor,obID(a0)
        bne.w .return
.collapse:
        move.b #1,collapsible_flag(a0)
.return:
        rts

; Like a native TST, preserves the caller's subtype index and all registers.
Sidekick_ButtonOnTop:
        movem.l d0,-(sp)
        moveq #0,d0
        tst.w (f_demo).w
        bne.s .done
        tst.b (v_sidekick_active).w
        beq.s .done
        tst.b (v_sidekick_state).w
        bne.s .done
        cmpa.w (v_sidekick_platform).w,a0
        bne.s .done
        btst #3,(v_sidekick_player+obStatus).w
        beq.s .done
        tst.b (v_sidekick_platform_seen).w
        beq.s .done
        moveq #1,d0
.done:
        tst.b d0
        movem.l (sp)+,d0
        rts

; Sample the same grouped log sprites as Bri_MoveSonic, at Tails' own X.
; P1's current log and bend win while both players stand on the bridge.
Sidekick_Bridge:
        move.w sr,-(sp)
        movem.l d0-d7/a0-a6,-(sp)
        bsr.w Sidekick_CollisionEnabled
        beq.w .return
        moveq #0,d1
        move.b bridge_children(a0),d1
        beq.w .return
        lsl.w #3,d1
        move.w obX(a1),d0
        sub.w obX(a0),d0
        add.w d1,d0
        addq.w #8,d0
        bmi.w .return
        move.w d1,d2
        add.w d2,d2
        cmp.w d2,d0
        bhs.w .return
        lsr.w #4,d0
        move.w d0,d7
        movea.l a0,a2
        sub.b bridge_split(a0),d0
        bhs.s .group
        add.b bridge_split(a0),d0
        moveq #0,d2
        move.b bridge_helper(a0),d2
        lsl.w #object_size_bits,d2
        lea (v_objspace).w,a2
        adda.w d2,a2
.group:
        move.w obY(a2),d6
        subq.b #1,d0
        bcs.s .surface
        move.w d0,d2
        add.w d0,d0
        add.w d2,d0
        move.b subspr_data+subspr_y(a2,d0.w),d2
        ext.w d2
        add.w d2,d6
.surface:
        subq.w #8,d6
        addq.w #8,d1
        move.w d7,-(sp)
        bsr.w Sidekick_Top
        move.w (sp)+,d7
        tst.b d0
        beq.w .return
        tst.w (f_demo).w
        bne.w .return
        btst #3,obStatus(a0)
        bne.w .return
        move.b d7,bridge_currentlog(a0)
        cmpi.b #$40,bridge_nudge(a0)
        bhs.w .return
        addq.b #8,bridge_nudge(a0)
        cmpi.b #$40,bridge_nudge(a0)
        bls.s .bend
        move.b #$40,bridge_nudge(a0)
.bend:
        jsr (Bri_Bend).l
.return:
        movem.l (sp)+,d0-d7/a0-a6
        move.w (sp)+,ccr
        rts

; Rolling Tails reaches React_Monitor before this object's update and breaks
; the box. An upright Tails may stand on it without changing P1's flags.
Sidekick_MonitorSolid:
        move.w sr,-(sp)
        movem.l d0-d7/a0-a6,-(sp)
        bsr.w Sidekick_CollisionEnabled
        beq.s .return
        cmpi.b #id_Roll,obAnim(a1)
        beq.s .return
        cmpi.b #id_SpinDash,obAnim(a1)
        beq.s .return
        move.w #15+sonic_solid_width,d1
        move.w #15,d2
        move.w #16,d3
        move.w obX(a0),d4
        bsr.w Sidekick_SolidPass
.return:
        movem.l (sp)+,d0-d7/a0-a6
        move.w (sp)+,ccr
        rts
