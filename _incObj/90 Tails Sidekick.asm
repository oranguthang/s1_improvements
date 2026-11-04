; Tails companion. The leader keeps camera, lives and scene ownership.
; Physics is the same S1 terrain code, with an explicit reversible context
; for globals historically owned by the single-player engine.

Sidekick_Spawn:
        movem.l d0-d7/a0-a6,-(sp)
        lea (v_sidekick_ram).w,a1
        moveq #0,d0
        move.w #(v_sidekick_ram_end-v_sidekick_ram)/2-1,d1
.clear:
        move.w d0,(a1)+
        dbf d1,.clear
    if FeatureSidekick&FeatureTails
        cmpi.b #Character_Tails,(v_character_p2).w
        bne.w .return
        move.b (v_gamemode).w,d0
        andi.b #$7F,d0
        cmpi.b #id_Level,d0
        beq.s .spawn
        cmpi.b #id_Demo,d0
        beq.s .spawn
        cmpi.b #id_Special,d0
        bne.w .return
.spawn:
        st.b (v_sidekick_active).w
        move.b #Character_Tails,(sk_ctx_character).w
        move.w #$600,(sk_ctx_speeds).w
        move.w #$C,(sk_ctx_speeds+2).w
        move.w #$80,(sk_ctx_speeds+4).w
        move.w #$60,(sk_ctx_camera_y).w
        move.w #30,(sk_ctx_air).w
        move.b #-1,(v_sidekick_lastframe).w
        clr.w (v_trackpos).w
        lea (v_tracksonic).w,a1
        moveq #63,d0
.trackFill:
        move.w (v_player+obX).w,(a1)+
        move.w (v_player+obY).w,(a1)+
        dbf d0,.trackFill
        lea (v_sidekick_player).w,a1
        moveq #object_size/4-1,d0
.bodyClear:
        clr.l (a1)+
        dbf d0,.bodyClear
        lea (v_sidekick_tail).w,a1
        moveq #object_size/4-1,d0
.tailClear:
        clr.l (a1)+
        dbf d0,.tailClear
        lea (v_sidekick_dust).w,a1
        moveq #object_size/4-1,d0
.dustClear:
        clr.l (a1)+
        dbf d0,.dustClear
        lea (v_sidekick_player).w,a1
        move.b #id_SidekickTails,obID(a1)
        move.b #2,obRoutine(a1)
        move.b #sonic_height,obHeight(a1)
        move.b #sonic_width,obWidth(a1)
        move.b #24,obActWid(a1)
        move.b #2,obPriority(a1)
        move.b #sprite_cam_field,obRender(a1)
        move.w #ArtTile_Sidekick,obGfx(a1)
        move.l #Map_Tails,obMap(a1)
        move.w (v_player+obX).w,obX(a1)
        subi.w #24,obX(a1)
        move.w (v_player+obY).w,obY(a1)
        move.b (v_player+obStatus).w,d0
        andi.b #3,d0
        move.b d0,obStatus(a1)
        cmpi.b #id_Special,(v_gamemode).w
        bne.s .tails
        move.b #sprite_cam_ss,obRender(a1)
        move.w #ArtTile_Sidekick_SS,obGfx(a1)
        move.l #Map_TailsSS,obMap(a1)
        move.b #sonic_roll_height,obHeight(a1)
        move.b #sonic_roll_width,obWidth(a1)
        clr.b obPriority(a1)
        move.b #id_Roll,obAnim(a1)
        ori.b #6,obStatus(a1)
.tails:
        cmpi.b #id_Special,(v_gamemode).w
        bne.s .companionPositionReady
        move.l a0,-(sp)
        movea.l a1,a0
        jsr (Sidekick_SSPlace).l
        movea.l (sp)+,a0
.companionPositionReady:
        move.b #id_SidekickTail,(v_sidekick_tail+obID).w
        cmpi.b #id_Special,(v_gamemode).w
        beq.s .noDust
        move.b #id_SidekickDust,(v_sidekick_dust+obID).w
.noDust:
        move.w obX(a1),(v_sidekick_lastx).w
    endif
.return:
        movem.l (sp)+,d0-d7/a0-a6
        rts

; Swap the listed single-player globals with the companion's persistent
; context. The same operation enters and leaves; no leader state is copied
; into or out of the actual player object. Preserve the caller's CCR/regs.
Sidekick_SwapContext:
        move.w sr,-(sp)
        movem.l d0-d2/a1-a3,-(sp)
        lea Sidekick_ContextFields(pc),a3
.field:
        move.w (a3)+,d2
        beq.s .done
        movea.w d2,a1
        movea.w (a3)+,a2
        move.w (a3)+,d2
.long:
        cmpi.w #3,d2
        blt.s .word
        move.l (a1),d0
        move.l (a2),(a1)+
        move.l d0,(a2)+
        subq.w #4,d2
        bra.s .long
.word:
        cmpi.w #1,d2
        blt.s .byte
        move.w (a1),d0
        move.w (a2),(a1)+
        move.w d0,(a2)+
        subq.w #2,d2
.byte:
        tst.w d2
        bmi.s .field
        move.b (a1),d0
        move.b (a2),(a1)+
        move.b d0,(a2)+
        bra.s .field
.done:
        not.b (v_sidekick_incontext).w
        movem.l (sp)+,d0-d2/a1-a3
        move.w (sp)+,ccr
        rts

; Word/long swaps must be aligned on real 68000 hardware. Unicorn's
; memory model is more permissive, so enforce this in every ROM build.
sidekick_context: macro original,private,count
        if (count)>0
        if ((original)|(private))&1
        fatal "Unaligned companion context field"
        endif
        endif
        dc.w original,private,count
        endm

Sidekick_ContextFields:
        sidekick_context v_character_p1,sk_ctx_character,0
        sidekick_context v_supersonic,sk_ctx_super,0
        sidekick_context v_superpal_state,sk_ctx_superpal,0
        sidekick_context v_dev_god,sk_ctx_god,0
        sidekick_context v_jpadhold2,sk_ctx_controls,1
        sidekick_context v_tails_flying,sk_ctx_flight,3
        sidekick_context v_knux_state,sk_ctx_knux,7
        sidekick_context v_sonspeedmax,sk_ctx_speeds,5
        sidekick_context v_lookshift,sk_ctx_camera_y,1
        sidekick_context v_cam_y_delay,sk_ctx_camera_delay,0
        sidekick_context v_cam_x_delay,sk_ctx_camera_x,1
        sidekick_context f_playerctrl,sk_ctx_playerctrl,0
        sidekick_context f_slidemode,sk_ctx_slide,0
        sidekick_context f_wtunnelmode,sk_ctx_tunnel,0
        sidekick_context f_lockctrl,sk_ctx_lockctrl,0
        sidekick_context v_shield,sk_ctx_shield,0
        sidekick_context v_invinc,sk_ctx_invinc,0
        sidekick_context v_shoes,sk_ctx_shoes,0
        sidekick_context v_lightdash_hitframe,sk_ctx_lightdash,0
        sidekick_context v_lightdash,sk_ctx_lightdash_active,0
        sidekick_context v_debuguse,sk_ctx_debug,1
        sidekick_context f_debugmode,sk_ctx_debugmode,1
        sidekick_context v_anglebuffer,sk_ctx_angle1,0
        sidekick_context v_anglebuffer2,sk_ctx_angle2,0
        sidekick_context v_itembonus,sk_ctx_itembonus,1
        sidekick_context v_air,sk_ctx_air,1
        dc.w 0

; ExecuteObjects owns d7 across every OST call. AI/SS helpers may use it
; as scratch, so keep the loop counter around the entire companion update.
SidekickTails:
        move.l d7,-(sp)
        bsr.w Sidekick_Run
        move.l (sp)+,d7
        rts

Sidekick_Run:
        tst.b (v_sidekick_active).w
        beq.w .delete
        tst.b (v_player+obID).w
        bne.s .leaderPresent
        tst.b (v_sidekick_ring_entry).w
        beq.w .return
.leaderPresent:
        cmpi.b #sidekick_ss_return,(v_sidekick_state).w
        beq.w Sidekick_SSReturn
        btst #sprite_cam_bg_bit,obRender(a0)
        beq.s .levelScene
        cmpi.b #2,(v_player+obRoutine).w
        beq.s .normalScene
        blo.w .return
        ; Keep the last world position while the labyrinth spins and fades.
        tst.b (v_sidekick_state).w
        beq.w .visible
        rts
.levelScene:
        cmpi.b #6,(v_player+obRoutine).w
        bhs.w .return
        move.b #2,obPriority(a0)       ; default level priority, including return flights
        tst.b victorypose(a0)
        bne.w Sidekick_Victory
.normalScene:
        cmpi.b #id_GotThroughCard,(v_endcard+obID).w
        beq.w .return
        tst.b (v_player+victorypose).w
        bne.w .return
        cmpi.b #2,(v_sidekick_state).w
        beq.w .wait
        cmpi.b #3,(v_sidekick_state).w
        beq.w Sidekick_ReturnFlight
        cmpi.b #4,(v_sidekick_state).w
        beq.w Sidekick_Drowning
        jsr (Sidekick_PlatformBegin).l
        jsr (Sidekick_ReadControls).l
        jsr (Sidekick_SwapContext).l
        cmpi.b #id_Special,(v_gamemode).w
        beq.w .special
        jsr (Sidekick_Water).l
        cmpi.b #4,(v_sidekick_state).w
        bne.s .notDrowning
        jsr (Sonic_Animate).l
        bra.w .draw
.notDrowning:
        jsr (Sidekick_SpeedSettings).l
        jsr (Sidekick_LZGimmicks).l
        tst.b d0
        bne.s .animated
        cmpi.b #4,obRoutine(a0)
        beq.s .hurt
        jsr (Tails_FlightControl).l
        tst.b d0
        bne.s .animated
        moveq #0,d0
        move.b obStatus(a0),d0
        andi.w #6,d0
        lea (Sonic_Modes).l,a1
        move.w (a1,d0.w),d1
        jsr (a1,d1.w)
        bra.s .animated
.hurt:
        jsr (SpeedToPos).l
        addi.w #$30,obVelY(a0)
        jsr (Sidekick_LevelBound).l
        jsr (Sonic_Floor).l
        btst #1,obStatus(a0)
        bne.s .animated
        move.b #2,obRoutine(a0)
.animated:
        btst #1,obStatus(a0)
        bne.s .stillAirborne
        clr.b (v_sidekick_returning).w
.stillAirborne:
        move.b (v_anglebuffer).w,angleright(a0)
        move.b (v_anglebuffer2).w,angleleft(a0)
        jsr (Sonic_UpdateAirPose).l
        jsr (Sonic_Animate).l
        tst.w (f_demo).w
        bne.s .demoCollision
        jsr (ReactToItem).l
.demoCollision:
        jsr (Sonic_Loops).l
        bra.s .draw
.special:
        jsr (Sidekick_SSBegin).l
        tst.b (v_sidekick_state).w
        bne.w .draw
        clr.b sonss_touchedblock_id(a0)
        btst #1,obStatus(a0)
        bne.s .ssAir
        jsr (SonicSS_Jump).l
        bra.s .ssMove
.ssAir:
        jsr (SonicSS_JumpHeight).l
.ssMove:
        jsr (SonicSS_Move).l
        jsr (SonicSS_Fall).l
        jsr (Sidekick_SSItems).l
        jsr (SpeedToPos).l
        jsr (Sidekick_SSCommit).l
        jsr (Sidekick_SSBounds).l
        tst.b (v_sidekick_state).w
        bne.s .draw
        jsr (Sonic_Animate).l
.draw:
        jsr (Sidekick_SwapContext).l
        cmpi.b #id_Special,(v_gamemode).w
        beq.s .ssGraphics             ; rolling SS art has no flight/carry pose
        jsr (Sidekick_UpdateCarry).l
        jsr (Sidekick_SwapEffectContext).l
        jsr (Tails_FlightPose).l
        jsr (Sidekick_LoadGfx).l
        jsr (Sidekick_SwapEffectContext).l
        bra.s .graphicsReady
.ssGraphics:
        cmpi.b #sidekick_ss_return,(v_sidekick_state).w
        beq.w Sidekick_SSReturn
        jsr (Sidekick_LoadGfx).l
.graphicsReady:
        tst.b (v_sidekick_state).w
        bne.w .return
        cmpi.b #id_Special,(v_gamemode).w
        beq.s .visible
        tst.w flashtime(a0)
        beq.s .visible
        subq.w #1,flashtime(a0)
        btst #2,flashtime+1(a0)
        bne.w .return
.visible:
        jmp (DisplaySprite).l
.wait:
        subq.w #1,(v_sidekick_timer).w
        bpl.w .return
        move.w (v_player+obX).w,obX(a0)
        subi.w #24,obX(a0)
        move.w (v_player+obY).w,obY(a0)
        subi.w #48,obY(a0)
        clr.l obVelX(a0)
        clr.w obInertia(a0)
        move.b #2,obStatus(a0)
        move.b #2,obRoutine(a0)
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        clr.w locktime(a0)
        clr.w flashtime(a0)
        clr.b spindash_flag(a0)
        clr.b jumping(a0)
        move.b #id_Fall,obAnim(a0)
        cmpi.b #id_Special,(v_gamemode).w
        bne.w .returnFlying
        jmp (Sidekick_SSStartReturn).l
.returnFlying:
        move.b #3,(v_sidekick_state).w
        move.w (v_screenposy).w,obY(a0)
        subi.w #32,obY(a0)
        move.w #240,(v_sidekick_timer).w
        clr.b (sk_ctx_shield).w
        clr.b (sk_ctx_invinc).w
        clr.b (sk_ctx_shoes).w
        move.w #30,(sk_ctx_air).w
.return:
        rts
.delete:
        jmp (DeleteObject).l

; S2 delayed input replay with positional steering. Fresh P2 input takes
; ownership for ten seconds; demo inputs never hand control to a real pad.
Sidekick_ReadControls:
        moveq #0,d0
        moveq #0,d1
        tst.w (f_demo).w
        bne.s .cpu
        move.b (v_jpadhold_p2).w,d0
        andi.b #btnL|btnR|btnUp|btnDn|btnABC,d0
        beq.s .manualTimer
        move.w #600,(v_sidekick_manual).w
.manualTimer:
        tst.w (v_sidekick_manual).w
        beq.s .cpu
        subq.w #1,(v_sidekick_manual).w
        move.b (v_jpadpress_p2).w,d1
        bra.w .store
.cpu:
        tst.w (v_debuguse).w
        beq.s .assist
        moveq #0,d0                    ; the item cursor does not record player input
        bra.w .pressed
.assist:
        jsr (Sidekick_AssistControls).l
        tst.b d7
        bne.w .pressed
        ; S2 reads the record 16 frames behind the most recently written
        ; entry (the ring-buffer cursor already points at the NEXT entry).
        move.w (v_trackpos).w,d2
        subi.b #17*4,d2
        andi.w #$FC,d2
        lea (v_sidekick_history).w,a1
        move.b (a1,d2.w),d0
        cmpi.b #id_Special,(v_gamemode).w
        beq.w .pressed                 ; no world-X chasing in a rotating maze
        lea (v_tracksonic).w,a1
        move.w (a1,d2.w),d3
        sub.w obX(a0),d3
        cmpi.w #16,d3
        bge.s .right
        cmpi.w #-16,d3
        bgt.s .jump
        andi.b #~btnR,d0
        ori.b #btnL,d0
        tst.w obInertia(a0)
        bpl.s .jump
        subq.w #1,obX(a0)              ; S2's small moving catch-up correction
        bra.s .jump
.right:
        andi.b #~btnL,d0
        ori.b #btnR,d0
        tst.w obInertia(a0)
        ble.s .jump
        addq.w #1,obX(a0)
.jump:
        move.w obX(a0),d2
        cmp.w (v_sidekick_lastx).w,d2
        bne.s .notStuck
        tst.b d0
        beq.s .notStuck
        ; Wait on Eggman's collapsing floor instead of jumping at its right wall.
        tst.w (v_sidekick_platform).w
        beq.s .stuckTimer
        cmpi.b #id_FalseFloor,(v_sidekick_platform_id).w
        beq.s .notStuck
.stuckTimer:
        addq.w #1,(v_sidekick_stuck).w
        cmpi.w #45,(v_sidekick_stuck).w
        blo.s .pressed
        andi.w #31,(v_sidekick_stuck).w
        ori.b #btnA,d0
        bra.s .pressed
.notStuck:
        clr.w (v_sidekick_stuck).w
.pressed:
        move.b (v_sidekick_prevheld).w,d1
        not.b d1
        and.b d0,d1
.store:
        cmpi.b #id_Special,(v_gamemode).w
        bne.s .controlsReady
        andi.b #btnL|btnR|btnABC,d0
        andi.b #btnL|btnR|btnABC,d1
.controlsReady:
        move.b d0,(v_sidekick_prevheld).w
        move.b d0,(sk_ctx_controls).w
        move.b d1,(sk_ctx_controls+1).w
        move.w obX(a0),(v_sidekick_lastx).w
        move.w obY(a0),(v_sidekick_prev_y).w
        rts

Sidekick_RecordInput:
        movem.l d1/a1,-(sp)
        lea (v_sidekick_history).w,a1
        move.w (v_trackpos).w,d0
        move.b (v_jpadhold2).w,d1
        andi.b #btnL|btnR|btnUp|btnDn|btnABC,d1
        move.b d1,(a1,d0.w)
        movem.l (sp)+,d1/a1
        rts

Sidekick_LevelBound:
        move.w (v_limitleft2).w,d0
        addi.w #16,d0
        cmp.w obX(a0),d0
        ble.s .notLeft
        move.w d0,obX(a0)
        clr.w obSubpixelX(a0)
        clr.w obVelX(a0)
        clr.w obInertia(a0)
.notLeft:
        move.w obX(a0),d0
        sub.w (v_screenposx).w,d0
        cmpi.w #-192,d0
        blt.s Sidekick_Lost
        cmpi.w #512,d0
        bgt.s Sidekick_Lost
        move.w obY(a0),d0
        sub.w (v_screenposy).w,d0
        cmpi.w #320,d0
        bgt.s Sidekick_Lost
        cmpi.w #-320,d0
        blt.s Sidekick_Lost
        rts

Sidekick_Lost:
        st.b (v_sidekick_returning).w
        clr.w (v_sidekick_pole).w
        jsr (Sidekick_DropRider).l
        clr.w (v_sidekick_platform).w
        move.b #2,(v_sidekick_state).w
        move.w #90,(v_sidekick_timer).w
        clr.b (v_sidekick_carry).w
        clr.b (v_sidekick_assist).w
        rts

Sidekick_Hurt:
        tst.w flashtime(a0)
        bne.w .return
        jsr (Sidekick_DropRider).l
        clr.b (v_sidekick_carry).w
        clr.b (v_sidekick_assist).w
        move.b #4,obRoutine(a0)
        move.w #120,flashtime(a0)
        move.w #-$400,obVelY(a0)
        move.w #-$200,obVelX(a0)
        btst #6,obStatus(a0)
        beq.s .direction
        move.w #-$200,obVelY(a0)
        move.w #-$100,obVelX(a0)
.direction:
        move.w obX(a0),d0
        cmp.w obX(a2),d0
        blo.s .size
        neg.w obVelX(a0)
.size:
        bclr #2,obStatus(a0)
        beq.s .standing
        subq.w #sonic_height-sonic_roll_height,obY(a0)
.standing:
        move.b #sonic_height,obHeight(a0)
        move.b #sonic_width,obWidth(a0)
        clr.b spindash_flag(a0)
        clr.b jumping(a0)
        bset #1,obStatus(a0)
        bclr #3,obStatus(a0)
        move.b #id_Hurt,obAnim(a0)
        tst.b (v_sidekick_incontext).w
        beq.s .outsideContext
        clr.l (v_tails_flying).w
        bra.s .hurtSound
.outsideContext:
        clr.l (sk_ctx_flight).w
.hurtSound:
        move.w #sfx_Death,d0
        cmpi.b #id_Spikes,obID(a2)
        beq.s .spikeSound
        cmpi.b #id_Harpoon,obID(a2)
        bne.s .playSound
.spikeSound:
        move.w #sfx_HitSpikes,d0
.playSound:
        jsr (QueueSound2).l
.return:
        moveq #-1,d0
        rts

Sidekick_LoadGfx:
        moveq #0,d0
        move.b obFrame(a0),d0
        cmp.b (v_sidekick_lastframe).w,d0
        beq.w .return
        move.b d0,(v_sidekick_lastframe).w
        lea (TailsDynPLC).l,a2
        move.l #Art_SidekickTails,d6
        cmpi.b #id_Special,(v_gamemode).w
        bne.s .selected
        lea (TailsSSDynPLC).l,a2
        move.l #Art_TailsSS,d6
.selected:
        add.w d0,d0
        adda.w (a2,d0.w),a2
        moveq #0,d5
        move.b (a2)+,d5
        subq.w #1,d5
        bmi.w .return
        move.w obGfx(a0),d4
        andi.w #$7FF,d4
        lsl.w #5,d4
.entry:
        moveq #0,d1
        move.b (a2)+,d1
        lsl.w #8,d1
        move.b (a2)+,d1
        move.w d1,d3
        lsr.w #8,d3
        andi.w #$F0,d3
        addi.w #$10,d3
        andi.l #$FFF,d1
        lsl.l #5,d1
        add.l d6,d1
        move.w d4,d2
        add.w d3,d4
        add.w d3,d4
        jsr (QueueDMATransfer).l
        dbf d5,.entry
.return:
        rts

SidekickTail:
        tst.b (v_player+obID).w
        bne.s .leaderPresent
        tst.b (v_sidekick_ring_entry).w
        beq.w .return
.leaderPresent:
        tst.b (v_sidekick_active).w
        beq.s .delete
        cmpi.b #id_GotThroughCard,(v_endcard+obID).w
        beq.w .return
        tst.b (v_player+victorypose).w
        bne.w .return
        cmpi.b #4,(v_sidekick_state).w
        beq.w .return
        cmpi.b #2,(v_sidekick_state).w
        beq.w .return
        tst.b (v_sidekick_player+victorypose).w
        bne.w .return                  ; the victory frames include the tails
        btst #sprite_cam_bg_bit,(v_sidekick_player+obRender).w
        bne.s .animate
        cmpi.b #6,(v_player+obRoutine).w
        bhs.w .return
.animate:
        jsr (Sidekick_SwapEffectContext).l
        jsr (TailsTail).l
        jsr (Sidekick_SwapEffectContext).l
.return:
        rts
.delete:
        jmp (DeleteObject).l

Sidekick_TailParent:
        lea (v_player).w,a2
        cmpa.w #v_sidekick_tail,a0
        bne.w .return
        lea (v_sidekick_player).w,a2
.return:
        rts

Sidekick_TailTile:
        cmpa.w #v_sidekick_tail,a0
        bne.w .return
        andi.w #~$7FF,d0
        btst #sprite_cam_bg_bit,(v_sidekick_player+obRender).w
        beq.s .normalTail
        ori.w #ArtTile_SidekickTail_SS,d0
        rts
.normalTail:
        ori.w #ArtTile_SidekickTail,d0
.return:
        rts

; Visual attachments read only character/flight/slide state. Physics globals
; stay with P1; avoid six full context copies per frame for tail and dust.
Sidekick_SwapEffectContext:
        move.w sr,-(sp)
        movem.l d0,-(sp)
        move.b (v_character_p1).w,d0
        move.b (sk_ctx_character).w,(v_character_p1).w
        move.b d0,(sk_ctx_character).w
        move.l (v_tails_flying).w,d0
        move.l (sk_ctx_flight).w,(v_tails_flying).w
        move.l d0,(sk_ctx_flight).w
        move.b (v_knux_state).w,d0
        move.b (sk_ctx_knux).w,(v_knux_state).w
        move.b d0,(sk_ctx_knux).w
        move.b (v_lightdash).w,d0
        move.b (sk_ctx_lightdash_active).w,(v_lightdash).w
        move.b d0,(sk_ctx_lightdash_active).w
        movem.l (sp)+,d0
        move.w (sp)+,ccr
        rts
