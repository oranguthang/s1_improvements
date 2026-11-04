; When the companion is visible, debug coordinates use a resident font in
; the inactive shield slot instead of overwriting the companion's art.
; As with the existing invincibility exclusion, shield/Super effects own
; their tiles and temporarily hide this extra debug row, including during
; item placement, so Tails can keep his own art.
Sidekick_DebugWanted:
        jsr (Sidekick_PaletteActive).l
        beq.s .return
        tst.b (v_sidekick_active).w
        beq.s .return
        moveq #1,d0
.return:
        rts

; a1 = one-frame mapping table, NZ if handled; all other registers kept.
Sidekick_DebugMap:
        bsr.s Sidekick_DebugWanted
        beq.w .notHandled
        movem.l d0-d7/a0-a6,-(sp)
        tst.b (v_shield).w
        bne.w .power
        tst.b (v_invinc).w
        bne.w .power
        tst.b (v_supersonic).w
        bne.w .power
        tst.w (v_sidekick_debugmap).w
        bne.s .mapReady
        lea (Map_SidekickDebugTemplate).l,a0
        lea (v_sidekick_debugmap).w,a1
        moveq #108/4-1,d0
.copy:
        move.l (a0)+,(a1)+
        dbf d0,.copy
.mapReady:
        tst.b (v_sidekick_debug_ready).w
        bne.s .fontReady
        move.w sr,-(sp)
        disableInts
        movea.w (VDP_Command_Buffer_Slot).w,a1
        adda.w #DMAEntry.len*2,a1
        cmpa.w #VDP_Command_Buffer_Slot,a1
        bhi.s .full
        clr.w (v_shieldartkey).w
        move.l #Art_SidekickDebugFont,d1
        move.w #ArtTile_Shield*tile_size,d2
        move.w #18*16,d3
        jsr (QueueDMATransfer).l
        move.l #Art_SidekickDebugFont+18*tile_size,d1
        move.w #$55A*tile_size,d2
        move.w #16,d3
        jsr (QueueDMATransfer).l
        st.b (v_sidekick_debug_ready).w
        move.w (sp)+,sr
.fontReady:
        lea (v_sidekick_debugmap+5).w,a1
        move.w (v_screenposx).w,d1
        bsr.w Sidekick_DebugHex
        move.w (v_player+obX).w,d1
        bsr.w Sidekick_DebugHex
        move.w (v_screenposy).w,d1
        bsr.w Sidekick_DebugHex
        move.w (v_player+obY).w,d1
        bsr.w Sidekick_DebugHex
        lea (v_sidekick_debugmap+5+19*5).w,a1
        moveq #0,d1
        move.b (v_spritecount).w,d1
        divu.w #10,d1
        move.w d1,d2
        bsr.w Sidekick_DebugGlyph
        swap d1
        move.w d1,d2
        bsr.w Sidekick_DebugGlyph
        movem.l (sp)+,d0-d7/a0-a6
        lea (v_sidekick_debugmap).w,a1
        moveq #1,d0
        rts
.full:
        move.w (sp)+,sr
        bra.s .blank
.power:
        clr.b (v_sidekick_debug_ready).w
.blank:
        movem.l (sp)+,d0-d7/a0-a6
        lea (Map_SidekickHidden).l,a1
        moveq #1,d0
        rts
.notHandled:
        moveq #0,d0
        rts

Sidekick_DebugHex:
        moveq #3,d6
.digit:
        rol.w #4,d1
        move.w d1,d2
        andi.w #$F,d2
        bsr.s Sidekick_DebugGlyph
        dbf d6,.digit
        rts

; S1 mapping attributes are unaligned. Write their two bytes separately.
Sidekick_DebugGlyph:
        addi.w #ArtTile_Shield|Tile_Prio,d2
        move.b d2,1(a1)
        lsr.w #8,d2
        move.b d2,(a1)
        addq.w #5,a1
        rts

Map_SidekickHidden: dc.w 2
        dc.b 0
        even
