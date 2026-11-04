; Only rings, emeralds, bumpers and breakable glass affect the companion.
; GOAL, UP, DOWN and R remain solid without taking ownership of the stage.
; Recorded demos never modify the original layout.
Sidekick_SSItems:
        clr.b (v_sidekick_ss_impulse).w
        tst.w (f_demo).w
        bne.s .return
        clr.b sonss_ghoststate(a0)
        jsr (SonicSS_ChkItems_NonSolidActionBlock).l
        move.b sonss_touchedblock_id(a0),d0
        cmpi.b #id_SS_Bumper,d0
        beq.s .bumper
        cmpi.b #id_SS_Glass1_Blue,d0
        blo.s .return
        cmpi.b #id_SS_Glass4_Pink,d0
        bhi.s .return
        jmp (SonicSS_Glass).l
.bumper:
        st.b (v_sidekick_ss_impulse).w
        jmp (SonicSS_ChkBumper).l
.return:
        rts

; Save a clear starting point before either inertia or gravity moves Tails.
Sidekick_SSBegin:
        bsr.w Sidekick_SSBounds
        tst.b (v_sidekick_state).w
        bne.s .return
        tst.b (v_sidekick_ss_recheck).w
        beq.s .clear
        clr.b (v_sidekick_ss_recheck).w
        move.l obX(a0),d3
        move.l obY(a0),d2
        jsr (SonicSS_FindWall).l
        beq.s .clear
        ; A gate can close under Tails. Let him fly out from the current
        ; displayed position instead of teleporting to the leader or hiding.
        bra.w Sidekick_SSLost
.clear:
        move.l obX(a0),(v_sidekick_ss_oldx).w
        move.l obY(a0),(v_sidekick_ss_oldy).w
.return:
        rts

; Item reactions (especially bumpers) replace velocity AFTER native wall
; prediction. Validate the actual movement as eight short swept steps, so a
; launch cannot cross a wall or tunnel through a gate. Keep the new velocity
; for the native axis collision response on the next frame.
Sidekick_SSCommit:
        movem.l d0-d7/a1,-(sp)
        move.l obX(a0),d6
        sub.l (v_sidekick_ss_oldx).w,d6
        move.l obY(a0),d7
        sub.l (v_sidekick_ss_oldy).w,d7
        move.l d6,d4
        bpl.s .absY
        neg.l d4
.absY:
        move.l d7,d5
        bpl.s .distance
        neg.l d5
.distance:
        cmpi.l #8*$10000,d4
        bhi.s .sweep
        cmpi.l #8*$10000,d5
        bhi.s .sweep
        ; Both normal axis moves were already collision-tested. Only an
        ; item impulse can invalidate those predictions at ordinary speeds.
        tst.b (v_sidekick_ss_impulse).w
        beq.s .return
        move.l obX(a0),d3
        move.l obY(a0),d2
        jsr (SonicSS_FindWall).l
        beq.s .return
        move.l (v_sidekick_ss_oldx).w,obX(a0)
        move.l (v_sidekick_ss_oldy).w,obY(a0)
        clr.w obInertia(a0)
        bra.s .return
.sweep:
        asr.l #3,d6
        asr.l #3,d7
        move.l (v_sidekick_ss_oldx).w,d3
        move.l (v_sidekick_ss_oldy).w,d2
        moveq #8-1,d0
.step:
        add.l d6,d3
        add.l d7,d2
        jsr (SonicSS_FindWall).l
        bne.s .blocked
        dbf d0,.step
        bra.s .return
.blocked:
        sub.l d6,d3
        sub.l d7,d2
        move.l d3,obX(a0)
        move.l d2,obY(a0)
        clr.w obInertia(a0)
.return:
        movem.l (sp)+,d0-d7/a1
        rts

Sidekick_SSBounds:
        move.w obX(a0),d0
        cmpi.w #16,d0
        blo.s .lost
        cmpi.w #(ss_layout_rowlength/2)*ss_blocksize-64,d0
        bhs.s .lost
        sub.w (v_player+obX).w,d0
        cmpi.w #-384,d0
        blt.s .lost
        cmpi.w #384,d0
        bgt.s .lost
        move.w obY(a0),d0
        cmpi.w #16,d0
        blo.s .lost
        cmpi.w #(ss_layout_rowlength/2)*ss_blocksize-96,d0
        bhs.s .lost
        sub.w (v_player+obY).w,d0
        cmpi.w #-384,d0
        blt.s .lost
        cmpi.w #384,d0
        bgt.s .lost
        rts
.lost:
Sidekick_SSLost:
        jsr (SS_ProjectSprite).l
        move.w d3,d0
        subi.w #$80-32,d0
        cmpi.w #320+64,d0
        bhs.s .offScreen
        move.w d2,d0
        subi.w #$80-32,d0
        cmpi.w #224+64,d0
        bhs.s .offScreen
        bra.s Sidekick_SSSetupReturn
.offScreen:
        jmp (Sidekick_Lost).l

; Prefer a visible adjacent spawn, but never insert the companion into a
; wall. The leader's own collision-tested pose is the fallback in narrow
; passages. Arbitrary -24/-48 offsets can land on the far side of a wall.
Sidekick_SSPlace:
        movem.l d0-d7/a0-a6,-(sp)
        move.l (v_player+obX).w,obX(a0)
        move.l (v_player+obY).w,obY(a0)
        subi.w #24,obX(a0)
        cmpi.w #16,obX(a0)
        blo.s .right
        bsr.s Sidekick_SSPlace_check
        beq.s .done
.right:
        move.l (v_player+obX).w,obX(a0)
        addi.w #24,obX(a0)
        cmpi.w #(ss_layout_rowlength/2)*ss_blocksize-64,obX(a0)
        bhs.s .leader
        bsr.s Sidekick_SSPlace_check
        beq.s .done
.leader:
        move.l (v_player+obX).w,obX(a0)
.done:
        st.b (v_sidekick_ss_recheck).w
        clr.b sonss_touchedblock_id(a0)
        clr.l sonss_touchedblock_ram(a0)
        movem.l (sp)+,d0-d7/a0-a6
        rts
Sidekick_SSPlace_check:
        move.l obY(a0),d2
        move.l obX(a0),d3
        jmp (SonicSS_FindWall).l

; Fly above the rotating maze in screen coordinates. World collision and
; items resume only when the displayed origin reaches a clear spawn point.
Sidekick_SSStartReturn:
        move.w #$80+320/2-48,d3
        move.w #$80-32,d2
        bsr.s Sidekick_SSSetupReturn
        bra.s Sidekick_SSReturn

Sidekick_SSSetupReturn:
        move.b #sidekick_ss_return,(v_sidekick_state).w
        move.w d3,obX(a0)
        move.w d2,obScreenY(a0)
        clr.l obVelX(a0)
        clr.w obInertia(a0)
        move.w #ArtTile_Sidekick_SSReturn,obGfx(a0)
        move.b #fr_TailsSSReturn,obFrame(a0)
        andi.b #sprite_xflip,obRender(a0)
        rts

Sidekick_SSReturn:
        cmpi.b #2,(v_player+obRoutine).w
        bne.w .display                 ; leave the current pose during the exit spin
        tst.w (v_debuguse).w
        bne.w .draw
        move.w obX(a0),d6
        move.w obScreenY(a0),d7
        jsr (Sidekick_SSPlace).l
        jsr (SS_ProjectSprite).l
        move.w d3,d0
        move.w d6,d1
        bsr.w .approach
        cmp.w d6,d1
        beq.s .keepFacing
        slt d4
        andi.b #sprite_xflip,d4
        move.b d4,obRender(a0)
.keepFacing:
        move.w d1,d6
        move.w d2,d0
        move.w d7,d1
        bsr.w .approach
        move.w d1,d7
        cmp.w d3,d6
        bne.s .inFlight
        cmp.w d2,d7
        bne.s .inFlight
        bsr.w Sidekick_SSPlace_check   ; even the leader fallback must be clear
        bne.s .inFlight
        move.b #sprite_cam_ss,obRender(a0)
        move.w #ArtTile_Sidekick_SS,obGfx(a0)
        move.b #sonic_roll_height,obHeight(a0)
        move.b #sonic_roll_width,obWidth(a0)
        move.b #id_Roll,obAnim(a0)
        move.b #fr_Roll1,obFrame(a0)
        move.b #6,obStatus(a0)
        clr.b (v_sidekick_state).w
        clr.b (v_sidekick_returning).w
        clr.w (v_sidekick_stuck).w
        clr.l (sk_ctx_flight).w
        bra.s .draw
.inFlight:
        move.w d6,obX(a0)
        move.w d7,obScreenY(a0)
.draw:
        jsr (Sidekick_LoadGfx).l
.display:
        jmp (DisplaySprite).l

; d1 approaches d0 by up to five screen pixels.
.approach:
        sub.w d1,d0
        cmpi.w #5,d0
        ble.s .lower
        moveq #5,d0
.lower:
        cmpi.w #-5,d0
        bge.s .step
        moveq #-5,d0
.step:
        add.w d0,d1
        rts
