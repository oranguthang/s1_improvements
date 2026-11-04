; Reuse the native spin/skid controller with an independent parent, art
; pool, generated absolute maps and private character context.
SidekickDust:
        move.l d7,-(sp)
        tst.b (v_sidekick_active).w
        beq.w .hidden
        tst.b (v_sidekick_state).w
        bne.w .hidden
        cmpi.b #6,(v_player+obRoutine).w
        bhs.w .hidden
        cmpi.b #id_GotThroughCard,(v_endcard+obID).w
        beq.w .hidden
        tst.b (v_player+victorypose).w
        bne.w .hidden
        cmpa.w #v_sidekick_dust,a0
        bne.s .animate
        cmpi.b #2,obRoutine(a0)
        bne.s .animate
        btst #0,(v_sidekick_player+spindash_flag).w
        bne.s .animate
        cmpi.b #id_Stop,(v_sidekick_player+obAnim).w
        beq.s .animate
        clr.w objoff_30(a0)
        bra.s .return
.animate:
        jsr (Sidekick_SwapEffectContext).l
        jsr (SpinDust).l
        jsr (Sidekick_SwapEffectContext).l
        bra.s .return
.hidden:
        cmpa.w #v_sidekick_dust,a0
        beq.s .return
        jsr (DeleteObject).l
.return:
        move.l (sp)+,d7
        rts

Sidekick_DustParent:
        lea (v_player).w,a2
        cmpi.b #id_SidekickDust,obID(a0)
        bne.s .return
        lea (v_sidekick_player).w,a2
.return:
        rts

; Output a3 points to the spin map / skid map / tile table record.
Sidekick_DustAssets:
        moveq #0,d0
        move.b (v_zone).w,d0
        cmpi.b #id_SBZ,d0
        bne.s .zone
        cmpi.b #2,(v_act).w
        bne.s .zone
        moveq #6,d0
.zone:
        mulu.w #12,d0
        lea (Sidekick_DustMapTable).l,a3
        adda.w d0,a3
        rts

Sidekick_DustMap:
        cmpi.b #id_SidekickDust,obID(a0)
        bne.s .return
        movem.l d0/a3,-(sp)
        bsr.s Sidekick_DustAssets
        move.l (a3),obMap(a0)
        clr.w obGfx(a0)
        movem.l (sp)+,d0/a3
.return:
        rts

Sidekick_DustSkidMap:
        cmpi.b #id_SidekickDust,obID(a0)
        bne.s .return
        movem.l d0/a3,-(sp)
        bsr.s Sidekick_DustAssets
        move.l 4(a3),obMap(a1)
        andi.w #Tile_Prio,obGfx(a1)
        movem.l (sp)+,d0/a3
.return:
        rts

Sidekick_SkidTransfer:
        cmpi.b #id_SidekickDust,obID(a0)
        bne.s .leader
        moveq #0,d2
        moveq #16,d3
        bra.w Sidekick_DustTransfer
.leader:
        jmp (QueueDMATransfer).l

Sidekick_LoadDustDynPLC:
        moveq #0,d0
        move.b obFrame(a0),d0
        lea (DustDynPLC).l,a2
        add.w d0,d0
        adda.w (a2,d0.w),a2
        moveq #0,d5
        move.b (a2)+,d5
        subq.w #1,d5
        bmi.s .return
        moveq #0,d4
.entry:
        moveq #0,d1
        move.b (a2)+,d1
        lsl.w #8,d1
        move.b (a2)+,d1
        move.w d1,d3
        lsr.w #8,d3
        lsr.w #4,d3
        addq.w #1,d3
        andi.l #$FFF,d1
        lsl.l #5,d1
        addi.l #Art_SpinDust,d1
        move.w d4,d2
        bsr.s Sidekick_DustTransfer
        add.w d3,d4
        dbf d5,.entry
.return:
        rts

; d1 = ROM source, d2 = virtual first tile, d3 = tile count. The same
; virtual-to-physical table generates both sprite pieces and these DMAs.
Sidekick_DustTransfer:
        movem.l d0-d7/a1-a3,-(sp)
        move.w d2,d4
        move.w d3,d5
        bsr.w Sidekick_DustAssets
        movea.l 8(a3),a3
        add.w d4,d4
        adda.w d4,a3
.run:
        moveq #0,d2
        move.w (a3)+,d2
        move.w d2,d6
        moveq #1,d3
        subq.w #1,d5
.contiguous:
        tst.w d5
        beq.s .queue
        addq.w #1,d6
        cmp.w (a3),d6
        bne.s .queue
        addq.w #2,a3
        addq.w #1,d3
        subq.w #1,d5
        bra.s .contiguous
.queue:
        lsl.w #5,d2
        lsl.w #4,d3
        movem.l d1/d3,-(sp)
        jsr (QueueDMATransfer).l
        movem.l (sp)+,d1/d3
        add.w d3,d3
        add.l d3,d1
        tst.w d5
        bne.s .run
        movem.l (sp)+,d0-d7/a1-a3
        rts
