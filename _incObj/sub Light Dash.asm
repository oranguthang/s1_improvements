; ---------------------------------------------------------------------------
; Ordinary ring-chain Light Dash. The only targets are the level ring manager's
; ROM positions and 512 status bytes. No ring objects or parallel status table.
; ---------------------------------------------------------------------------
LightDash_StartRadius: equ 64
LightDash_MaxGap: equ 72
LightDash_Speed: equ $C00
LightDash_WaterSpeed: equ $600
LightDash_ExitSpeed: equ LightDash_Speed
LightDash_WaterExitSpeed: equ LightDash_WaterSpeed
LightDash_Substeps: equ 8
LightDash_MaxFrames: equ 384
LightDash_StallFrames: equ 3

; Called in the airborne modes before their normal A action. A failed search
; leaves the press intact. Success skips the rest of the calling mode.
Sonic_LightDashStart:
	if FeatureLightDash=0
		rts						; Light Dash disabled
	endif
        tst.b (v_lightdash).w
        bne.w .return
        btst #bitA,(v_jpadpress2).w
        beq.w .return
        btst #1,obStatus(a0)             ; grounded A always belongs to jumping
        beq.w .return
        bsr.w LightDash_Allowed
        tst.b d0
        beq.w .return
        cmpi.w #90,flashtime(a0)
        bhs.w .return
        move.b spindash_flag(a0),d0
        andi.b #3,d0
        bne.w .return
        clr.l (v_lightdash_exclude_first).w
        clr.l (v_lightdash_exclude_second).w
        clr.b (v_lightdash_near_ground).w
        clr.b (v_lightdash_have_last_ring).w
        clr.w (v_lightdash_exit_x).w
        clr.w (v_lightdash_exit_y).w
        move.b #1,(v_lightdash_initial_search).w
        move.w obX(a0),(v_lightdash_probe_x).w
        move.w obY(a0),(v_lightdash_probe_y).w
        move.w #LightDash_StartRadius,d6
        bsr.w LightDash_FindTarget
        clr.b (v_lightdash_initial_search).w
        tst.l d0
        beq.w .return
        bsr.w LightDash_SetTarget
        ; Require three reachable, uncollected placed rings before taking A.
        ; Preview the next two links without changing their collection states.
        move.l a2,(v_lightdash_exclude_first).w
        move.w (a2),(v_lightdash_probe_x).w
        move.w 2(a2),(v_lightdash_probe_y).w
        move.w #LightDash_MaxGap,d6
        bsr.w LightDash_FindTarget
        tst.l d0
        beq.w .noChain
        move.l a2,(v_lightdash_exclude_second).w
        move.w (a2),(v_lightdash_probe_x).w
        move.w 2(a2),(v_lightdash_probe_y).w
        bsr.w LightDash_FindTarget
        tst.l d0
        beq.w .noChain
        clr.l (v_lightdash_exclude_first).w
        clr.l (v_lightdash_exclude_second).w
        cmpi.b #1,(v_superpal_state).w
        bne.s .poseReady
        move.b #3,(v_superpal_state).w    ; let Super dash while its palette still fades
.poseReady:
        ; A successful dash replaces flight/gliding. Clear their attack and
        ; pose flags before this routine skips the ability caller's return.
        jsr (Knuckles_EndAbility).l
        clr.b (v_tails_flying).w
        clr.b (v_tails_flap).w
        move.b #1,(v_lightdash).w
        move.w (v_zone_act).w,(v_lightdash_act).w
        move.w #LightDash_MaxFrames,(v_lightdash_timer).w
        bset #1,obStatus(a0)             ; collision/hitbox/rolling state is otherwise unchanged
        bclr #3,obStatus(a0)
        bclr #5,obStatus(a0)
        move.b #id_Float1,obAnim(a0)
        clr.w (v_lightdash_full_x).w
        clr.w (v_lightdash_full_y).w
        bclr #bitA,(v_jpadpress2).w
        jsr (Sonic_LightDashUpdate).l
        addq.l #4,sp                    ; return directly to Sonic_Control
        bra.s .return
.noChain:
        clr.l (v_lightdash_exclude_first).w
        clr.l (v_lightdash_exclude_second).w
        clr.l (v_lightdash_target_rom).w
        clr.w (v_lightdash_target_state).w
.return:
        rts

; Return d0=1 if the frame was handled, 0 if normal physics may run instead.
Sonic_LightDashUpdate:
        move.l d7,-(sp)                   ; ExecuteObjects owns its object-slot counter
        bsr.w LightDash_Allowed
        tst.b d0
        beq.w .cancelBeforeMove
        move.w (v_zone_act).w,d0
        cmp.w (v_lightdash_act).w,d0
        bne.w .cancelBeforeMove
        btst #5,obStatus(a0)
        bne.w .cancelBeforeMove
        ; Placed solids run after Sonic. Their velocity cancellation must stop
        ; the next dash frame; water's nonzero halving is still allowed.
        move.w (v_lightdash_full_x).w,d0
        bpl.s .absX
        neg.w d0
.absX:
        cmpi.w #$100,d0
        blo.s .checkY
        tst.w obVelX(a0)
        beq.w .cancelBeforeMove
.checkY:
        btst #1,obStatus(a0)
        beq.s .timer                     ; landing may have stopped vertical velocity
        move.w (v_lightdash_full_y).w,d0
        bpl.s .absY
        neg.w d0
.absY:
        cmpi.w #$100,d0
        blo.s .timer
        tst.w obVelY(a0)
        beq.w .cancelBeforeMove
.timer:
        subq.w #1,(v_lightdash_timer).w
        bmi.w .cancelBeforeMove
        movea.w (v_lightdash_target_state).w,a4
        tst.b (a4)
        bne.w .nextTarget               ; a normal earlier pickup never awards twice
        bsr.w LightDash_TargetDelta
        move.w d1,d3
        muls.w d3,d3
        move.w d2,d4
        muls.w d4,d4
        add.l d4,d3
        move.w #LightDash_Speed/256,d5
        btst #6,obStatus(a0)
        beq.s .speedReady
        move.w #LightDash_WaterSpeed/256,d5
.speedReady:
        move.w d5,d4
        muls.w d4,d4
        cmp.l d4,d3
        bhi.s .fullSpeed
        lsl.w #8,d1                     ; reach a near target exactly over eight substeps
        lsl.w #8,d2
        move.w d1,(v_lightdash_full_x).w
        move.w d2,(v_lightdash_full_y).w
        bra.s .substeps
.fullSpeed:
        jsr (CalcAngle).l
        jsr (CalcSine).l
        muls.w d5,d1
        muls.w d5,d0
        move.w d1,(v_lightdash_full_x).w
        move.w d0,(v_lightdash_full_y).w
.substeps:
        move.b #1,(v_lightdash_hitframe).w
        move.w (v_lightdash_full_x).w,d0
        asr.w #3,d0
        move.w d0,(v_lightdash_step_x).w
        move.w (v_lightdash_full_y).w,d0
        asr.w #3,d0
        move.w d0,(v_lightdash_step_y).w
        moveq #LightDash_Substeps-1,d7
.step:
        move.w (v_lightdash_step_x).w,obVelX(a0)
        move.w (v_lightdash_step_y).w,obVelY(a0)
        move.l d7,-(sp)
        jsr (SpeedToPos).l
        btst #1,obStatus(a0)
        bne.s .airCollision
        tst.w (v_lightdash_step_y).w
        bmi.s .takeOff                   ; follow a rising chain back into the air
        move.w (v_lightdash_step_x).w,obInertia(a0)
        jsr (Sonic_AnglePos).l           ; follow the ground and its collisions
        bra.s .collisionDone
.takeOff:
        bset #1,obStatus(a0)
.airCollision:
        jsr (Sonic_Floor).l              ; airborne walls, floor and ceiling
.collisionDone:
        jsr (Sonic_LevelBound).l
        move.l (sp)+,d7
        tst.b (v_lightdash).w            ; a death or event may have cancelled it
        beq.w .handled
        cmpi.b #2,obRoutine(a0)
        bne.w .cancelAfterMove
        btst #1,obStatus(a0)
        beq.s .groundContact
        move.w (v_lightdash_step_x).w,d0
        cmp.w obVelX(a0),d0
        bne.w .cancelAfterMove
        move.w (v_lightdash_step_y).w,d0
        cmp.w obVelY(a0),d0
        bne.w .cancelAfterMove
        bra.s .stepDone
.groundContact:
        tst.w (v_lightdash_step_x).w
        beq.s .stepDone
        tst.w obVelX(a0)
        beq.w .cancelAfterMove           ; a wall stopped the grounded dash
.stepDone:
        dbf d7,.step
        move.w (v_lightdash_full_x).w,obVelX(a0)
        btst #1,obStatus(a0)
        bne.s .stillAirborne
        clr.w obVelY(a0)
        move.w obVelX(a0),obInertia(a0)
        bra.s .movementReady
.stillAirborne:
        move.w (v_lightdash_full_y).w,obVelY(a0)
.movementReady:
        move.b #id_Float1,obAnim(a0)
        bsr.w LightDash_TargetDelta
        ; Match Touch_Rings' Sonic hitbox against the ring's 12px diameter.
        ; Its centre can stay out of reach after landing on the floor.
        tst.w d1
        bpl.s .absRingX
        neg.w d1
.absRingX:
        cmpi.w #sonic_react_width+6,d1
        bhi.s .checkProgress
        tst.w d2
        bpl.s .absRingY
        neg.w d2
.absRingY:
        moveq #0,d3
        move.b obHeight(a0),d3
        addq.w #3,d3                   ; (height - 3) + ring radius 6
        cmp.w d3,d2
        bhi.s .checkProgress
        movea.w (v_lightdash_target_state).w,a4
        jsr (RingsManager_CollectRing).l  ; shared state, sparkle, lives and sound
        bra.s .nextTarget
.checkProgress:
        move.w obX(a0),d1
        cmp.w (v_lightdash_last_x).w,d1
        bne.s .progressed
        move.w obY(a0),d1
        cmp.w (v_lightdash_last_y).w,d1
        bne.s .progressed
        addq.b #1,(v_lightdash_stall).w
        cmpi.b #LightDash_StallFrames,(v_lightdash_stall).w
        bhs.s .cancelAfterMove          ; genuinely stopped by terrain or an object
        bra.s .handled
.progressed:
        move.w obX(a0),(v_lightdash_last_x).w
        move.w obY(a0),(v_lightdash_last_y).w
        clr.b (v_lightdash_stall).w
        bra.s .handled
.nextTarget:
        movea.l (v_lightdash_target_rom).w,a1
        move.w (a1),(v_lightdash_probe_x).w
        move.w 2(a1),(v_lightdash_probe_y).w
        bsr.w LightDash_RecordRing
        clr.b (v_lightdash_near_ground).w
        btst #1,obStatus(a0)
        beq.s .nearGround
        jsr (Sonic_FindFloor).l         ; also cover flight just above the ground
        cmpi.w #12,d1
        bhi.s .findNext
        cmpi.w #-8,d1
        blt.s .findNext
.nearGround:
        move.b #1,(v_lightdash_near_ground).w
.findNext:
        move.w #LightDash_MaxGap,d6
        bsr.w LightDash_FindTarget
        tst.l d0
        beq.s .finishChain
        bsr.w LightDash_SetTarget
        bra.s .handled
.finishChain:
        bsr.w Sonic_FinishLightDash
.handled:
        moveq #1,d0
        move.l (sp)+,d7
        rts
.cancelAfterMove:
        bsr.w Sonic_CancelLightDash
        bra.s .handled
.cancelBeforeMove:
        bsr.w Sonic_CancelLightDash
        moveq #0,d0
        move.l (sp)+,d7
        rts

; Routine/scene guards are shared by start and continued movement.
LightDash_Allowed:
        moveq #0,d0
        cmpi.b #2,obRoutine(a0)
        bne.s .return
        move.b (v_gamemode).w,d0
        andi.b #$7F,d0
        cmpi.b #id_Level,d0
        bne.s .deny
        tst.w (f_demo).w
        bne.s .deny
        tst.w (v_debuguse).w
        bne.s .deny
        tst.b (f_lockctrl).w
        bne.s .deny
        tst.b (f_playerctrl).w
        bne.s .deny
        cmpi.b #1,(v_superpal_state).w
        bne.s .checkRings
        tst.b (v_lightdash).w
        bne.s .deny                     ; transforming during an active dash cancels it
.checkRings:
        tst.l (v_lightdash_ringbase).w
        beq.s .deny
        moveq #1,d0
        rts
.deny:
        moveq #0,d0
.return:
        rts

; d6 = search radius, probe = previous ring center (Sonic's position on start).
; Return d0=pointer, a2=ROM entry, a3=state byte; zero if no target. Only scan
; rings in the X radius; sorted ROM data allows early exit. End marker + the
; 512-byte state limit bound the scan even for an invalid modded layout.
LightDash_FindTarget:
        move.l d7,-(sp)                   ; also called before the dash starts
        moveq #0,d0
        suba.l a2,a2
        suba.l a3,a3
        movea.l (v_lightdash_ringbase).w,a1
        lea (v_ringstates).w,a4
        move.w d6,d5
        muls.w d5,d5
        addq.l #1,d5
        moveq #0,d7
        move.w #512-1,d7
.scan:
        cmpi.w #$FFFF,(a1)
        beq.w .done
        move.w (a1),d1
        sub.w (v_lightdash_probe_x).w,d1
        cmp.w d6,d1
        bgt.w .done
        move.w d6,d0
        neg.w d0
        cmp.w d0,d1
        blt.w .next
        tst.b (a4)
        bne.w .next
        cmpa.l (v_lightdash_exclude_first).w,a1
        beq.w .next
        cmpa.l (v_lightdash_exclude_second).w,a1
        beq.w .next
        tst.b (v_lightdash_initial_search).w
        beq.s .directionReady
        btst #0,obStatus(a0)             ; the first ring must be on the facing side
        bne.s .facingLeft
        tst.w d1
        bmi.w .next
        bra.s .directionReady
.facingLeft:
        tst.w d1
        bgt.w .next
.directionReady:
        move.w 2(a1),d2
        sub.w (v_lightdash_probe_y).w,d2
        bsr.w LightDash_WrapDeltaY
        cmp.w d6,d2
        bgt.s .next
        cmp.w d0,d2
        blt.s .next
        ; Near a floor, don't reverse along the same row for a missed ring.
        ; A new row of a pyramid can still turn back while airborne.
        tst.b (v_lightdash_near_ground).w
        beq.s .candidateReady
        move.w d2,d4
        bpl.s .absCandidateY
        neg.w d4
.absCandidateY:
        cmpi.w #16,d4
        bhs.s .candidateReady
        btst #0,obStatus(a0)
        bne.s .candidateLeft
        move.w (a1),d4
        cmp.w obX(a0),d4
        blt.s .next
        bra.s .candidateReady
.candidateLeft:
        move.w (a1),d4
        cmp.w obX(a0),d4
        bgt.s .next
.candidateReady:
        move.w d1,d3
        muls.w d3,d3
        move.w d2,d4
        muls.w d4,d4
        add.l d4,d3
        cmp.l d5,d3
        bhs.s .next
        move.l d3,d5
        movea.l a1,a2
        movea.l a4,a3
.next:
        addq.w #4,a1
        addq.w #1,a4
        dbf d7,.scan
.done:
        move.l a2,d0
        move.l (sp)+,d7
        rts

LightDash_SetTarget:
        move.l a2,(v_lightdash_target_rom).w
        move.w a3,(v_lightdash_target_state).w
        move.w obX(a0),(v_lightdash_last_x).w
        move.w obY(a0),(v_lightdash_last_y).w
        clr.b (v_lightdash_stall).w
        rts

; Keep the most recent nonzero ring-to-ring direction for a natural exit.
LightDash_RecordRing:
        tst.b (v_lightdash_have_last_ring).w
        beq.s .store
        move.w (v_lightdash_probe_x).w,d1
        sub.w (v_lightdash_last_ring_x).w,d1
        move.w (v_lightdash_probe_y).w,d2
        sub.w (v_lightdash_last_ring_y).w,d2
        bsr.w LightDash_WrapDeltaY
        move.w d1,d3
        or.w d2,d3
        beq.s .store                   ; coincident rings keep the last real direction
        jsr (CalcAngle).l
        jsr (CalcSine).l
        move.w #LightDash_ExitSpeed/256,d5
        btst #6,obStatus(a0)
        beq.s .speedReady
        move.w #LightDash_WaterExitSpeed/256,d5
.speedReady:
        muls.w d5,d1
        muls.w d5,d0
        move.w d1,(v_lightdash_exit_x).w
        move.w d0,(v_lightdash_exit_y).w
.store:
        move.w (v_lightdash_probe_x).w,(v_lightdash_last_ring_x).w
        move.w (v_lightdash_probe_y).w,(v_lightdash_last_ring_y).w
        move.b #1,(v_lightdash_have_last_ring).w
        rts

; Natural end: hand momentum to the ordinary ground/air physics.
Sonic_FinishLightDash:
        bsr.w Sonic_CancelLightDash
        cmpi.b #2,obRoutine(a0)
        bne.s .return
        tst.b (f_playerctrl).w
        bne.s .return
        move.w (v_lightdash_exit_x).w,obVelX(a0)
        move.w (v_lightdash_exit_y).w,obVelY(a0)
        btst #1,obStatus(a0)
        bne.s .return                  ; airborne flight keeps both components
        tst.w obVelY(a0)
        bpl.s .grounded
        bset #1,obStatus(a0)          ; an upward final link lifts off again
        bra.s .return
.grounded:
        clr.w obVelY(a0)             ; no downward motion through the floor
        move.w obVelX(a0),obInertia(a0)
.return:
        rts

LightDash_TargetDelta:
        movea.l (v_lightdash_target_rom).w,a1
        move.w (a1),d1
        sub.w obX(a0),d1
        move.w 2(a1),d2
        sub.w obY(a0),d2
        ; Fall through to the shared vertical-wrap helper.
LightDash_WrapDeltaY:
        tst.w (v_limittop2).w
        bpl.s .return
        andi.w #$7FF,d2
        cmpi.w #$400,d2
        blo.s .return
        subi.w #$800,d2
.return:
        rts

; Display-only eight-way pose. Never put the flight angle in obAngle: that
; angle belongs to floor collision. Status facing still owns target admission.
Sonic_LightDashPose:
        tst.b (v_lightdash).w
        beq.s .return
        cmpi.b #id_Float1,obAnim(a0)
        bne.s .return
        move.w obVelX(a0),d1
        move.w obVelY(a0),d2
        move.w d1,d0
        or.w d2,d0
        beq.s .return
        jsr (CalcAngle).l
        addi.b #$10,d0
        lsr.b #5,d0
        andi.w #7,d0                    ; right, down-right, down, ..., up-right
        lea .flips(pc),a1
        andi.b #~(sprite_xflip|sprite_yflip),obRender(a0)
        move.b (a1,d0.w),d1
        or.b d1,obRender(a0)
        add.w d0,d0
        moveq #0,d1
        move.b obAniFrame(a0),d1        ; Float1's existing two-frame cadence
        subq.w #1,d1
        andi.w #1,d1
        add.w d1,d0
        lea .normalFrames(pc),a1
        cmpi.b #Character_Knuckles,(v_character_p1).w
        beq.s .knuckles
        tst.b (v_supersonic).w
        beq.s .frameReady
        cmpi.b #Character_Sonic,(v_character_p1).w
        bne.s .frameReady               ; Super Tails keeps his own frame numbers
        lea .superFrames(pc),a1
        bra.s .frameReady
.knuckles:
        lea .knucklesFrames(pc),a1
.frameReady:
        move.b (a1,d0.w),obFrame(a0)
.return:
        rts
.flips:
        dc.b 0,3,3,3,1,0,0,0
.normalFrames:
        dc.b fr_Float1,fr_Float4,fr_Run41,fr_Run42
        dc.b fr_Run31,fr_Run32,fr_Run21,fr_Run22
        dc.b fr_Float1,fr_Float4,fr_Run41,fr_Run42
        dc.b fr_Run31,fr_Run32,fr_Run21,fr_Run22
.superFrames:
        dc.b $B5,$B9,$B8,$BC,$B7,$BB,$B6,$BA
        dc.b $B5,$B9,$B8,$BC,$B7,$BB,$B6,$BA
.knucklesFrames:
        ; Horizontal travel uses the actual glide, not the shared Float frames.
        ; Retain the rotated run poses and flips for the other six directions.
        dc.b knux_glide_frame,knux_glide_frame,fr_Run41,fr_Run42
        dc.b fr_Run31,fr_Run32,fr_Run21,fr_Run22
        dc.b knux_glide_frame,knux_glide_frame,fr_Run41,fr_Run42
        dc.b fr_Run31,fr_Run32,fr_Run21,fr_Run22
        even

; Preserve all registers and event/hurt animations. A completed dash loses its
; attack pose; an airborne Sonic must press jump again to curl into a ball.
Sonic_CancelLightDash:
        tst.b (v_lightdash).w
        beq.s .return
        clr.b (v_lightdash).w
        clr.w (v_lightdash_timer).w
        clr.l (v_lightdash_target_rom).w
        clr.w (v_lightdash_target_state).w
        cmpi.b #2,obRoutine(a0)
        bne.s .return
        tst.b (f_playerctrl).w
        bne.s .return
        cmpi.b #id_Transform,obAnim(a0)
        bne.s .checkDashPose
        clr.w obVelY(a0)                 ; a Super toggle must not inherit dash lift
        rts
.checkDashPose:
        cmpi.b #id_Float1,obAnim(a0)
        bne.s .return
        clr.w obVelY(a0)                 ; never carry dash lift into ordinary flight
        btst #1,obStatus(a0)
        beq.s .grounded
        btst #2,obStatus(a0)
        beq.s .restoreAnim
        bclr #2,obStatus(a0)
        cmpi.b #sonic_roll_height,obHeight(a0)
        bne.s .restoreSize
        subq.w #sonic_height-sonic_roll_height,obY(a0)
.restoreSize:
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        bra.s .restoreAnim
.grounded:
        move.w obVelX(a0),obInertia(a0)   ; resume a run when the chain ends on land
.restoreAnim:
        move.b #id_Walk,obAnim(a0)
.return:
        rts
