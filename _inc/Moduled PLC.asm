; Moduled Kosinski pattern loading. One module is decompressed between frames;
; its RAM buffer stays reserved until ProcessDMAQueue has issued its transfer.
; Art is tile-aligned, so every module is a multiple of 32 bytes.

AddPLC:
        movem.l a1-a2,-(sp)
        lea     (ArtLoadCues).l,a1
        add.w   d0,d0
        move.w  (a1,d0.w),d0
        lea     (a1,d0.w),a1
        lea     (v_plc_buffer).w,a2
.findspace:
        cmpa.l  #v_plc_buffer_only_end,a2
        bhs.s   PLC_CopyList
        tst.l   (a2)
        beq.s   PLC_CopyList
        addq.w  #plc_slot_size,a2
        bra.s   .findspace

PLC_CopyList:
        move.w  (a1)+,d0
        bmi.s   .return
.loop:
        cmpa.l  #v_plc_buffer_only_end,a2
        bhs.s   .overflow
        move.l  (a1)+,(a2)+
        move.w  (a1)+,(a2)+
        dbf     d0,.loop
        bra.s   .peak
.overflow:
        cmpi.b  #$FF,(v_plc_overflow).w
        beq.s   .peak
        addq.b  #1,(v_plc_overflow).w
.peak:
        move.l  a2,d0
        subi.l  #v_plc_buffer,d0
        divu.w  #plc_slot_size,d0
        cmp.b   (v_plc_peak).w,d0
        bls.s   .return
        move.b  d0,(v_plc_peak).w
.return:
        movem.l (sp)+,a1-a2
        rts

NewPLC:
        movem.l a1-a2,-(sp)
        lea     (ArtLoadCues).l,a1
        add.w   d0,d0
        move.w  (a1,d0.w),d0
        lea     (a1,d0.w),a1
        bsr.s   ClearPLC
        lea     (v_plc_buffer).w,a2
        bra.s   PLC_CopyList

; Keep v_plc_dma_pending: a module already queued for DMA still owns Art_Buffer.
ClearPLC:
        lea     (v_plc_buffer).w,a2
        moveq   #(v_plc_buffer_end-v_plc_buffer)/4-1,d0
.loop:
        clr.l   (a2)+
        dbf     d0,.loop
        rts

; Called once per main-loop frame. Finish a cue only *after* its last DMA.
RunPLC:
        tst.b   (v_plc_dma_pending).w
        bne.w   .return
        tst.l   (v_plc_buffer).w
        beq.w   .return
        movem.l d0-d7/a0-a3,-(sp)
        tst.l   (v_plc_artptr).w
        bne.s   .active
        movea.l (v_plc_buffer).w,a0
        move.w  (a0)+,(v_plc_patternsleft).w
        move.l  a0,(v_plc_artptr).w
.active:
        tst.w   (v_plc_patternsleft).w
        bne.s   .module
        bsr.w   PLC_ShiftCue
        clr.l   (v_plc_artptr).w
        bra.w   .done
.module:
        move.w  (v_plc_patternsleft).w,d5
        cmpi.w  #$1000,d5
        bls.s   .sizeReady
        move.w  #$1000,d5
.sizeReady:
        move.w  (v_plc_buffer_dest).w,d6
        tst.b   (v_gfxringslotstate).w
        beq.s   .ringFree
        cmpi.w  #(ArtTile_Explosion+96)*tile_size,d6
        bhs.s   .ringFree
        move.w  d6,d0
        add.w   d5,d0
        cmpi.w  #(ArtTile_Explosion-8)*tile_size,d0
        bls.s   .ringFree
        bra.w   .done                   ; postpone art that overlaps the ring slot
.ringFree:
        movea.l (v_plc_artptr).w,a0
        movea.l a0,a3                  ; module start for KosM padding
        lea     (Art_Buffer).w,a1
        movem.l d5-d6,-(sp)
        bsr.w   KosDec
        movem.l (sp)+,d5-d6
        move.w  (v_plc_patternsleft).w,d0
        cmp.w   d5,d0
        bls.s   .noPad
        move.l  a3,d0
        sub.l   a0,d0
        andi.l  #$F,d0
        adda.l  d0,a0
.noPad:
        move.w  sr,-(sp)
        disable_ints
        movea.w (VDP_Command_Buffer_Slot).w,a1
        cmpa.w  #VDP_Command_Buffer_Slot,a1
        beq.s   .queueFull
        move.l  #Art_Buffer,d1
        move.w  d6,d2
        move.w  d5,d3
        lsr.w   #1,d3
        jsr     (QueueDMATransfer).l
        move.l  a0,(v_plc_artptr).w
        add.w   d5,(v_plc_buffer_dest).w
        sub.w   d5,(v_plc_patternsleft).w
        st.b    (v_plc_dma_pending).w
        move.w  (sp)+,sr
        bra.s   .done
.queueFull:
        move.w  (sp)+,sr              ; retry this module next frame
.done:
        movem.l (sp)+,d0-d7/a0-a3
.return:
        rts

PLC_ShiftCue:
        lea     (v_plc_buffer).w,a0
        moveq   #(v_plc_buffer_only_end-v_plc_buffer-plc_slot_size)/4-1,d0
.loop:
        move.l  plc_slot_size(a0),(a0)+
        dbf     d0,.loop
        if (v_plc_buffer_only_end-v_plc_buffer-plc_slot_size)&2
            move.w plc_slot_size(a0),(a0)
        endif
        clr.l   (v_plc_buffer_only_end-plc_slot_size).w
        rts

; Synchronous path used while the screen is being initialized. Transfer each
; decompressed module directly so interrupts may remain masked by the caller.
QuickPLC:
        move.w  d0,-(sp)
        tst.b   (v_plc_dma_pending).w
        beq.s   .ready
        jsr     (ProcessDMAQueue).l ; retire Art_Buffer DMA before reusing it
.ready:
        move.w  (sp)+,d0
        movem.l d2-d7/a2-a4,-(sp)
        lea     (ArtLoadCues).l,a1
        add.w   d0,d0
        move.w  (a1,d0.w),d0
        lea     (a1,d0.w),a4
        move.w  (a4)+,d1
        bmi.s   .done
.entry:
        movea.l (a4)+,a0
        move.w  (a4)+,d7
        move.w  (a0)+,d6
.module:
        move.w  d6,d5
        cmpi.w  #$1000,d5
        bls.s   .sizeReady
        move.w  #$1000,d5
.sizeReady:
        movea.l a0,a3
        lea     (Art_Buffer).w,a1
        movem.l d1/d5-d6,-(sp)
        bsr.w   KosDec
        movem.l (sp)+,d1/d5-d6
        cmp.w   d5,d6
        bls.s   .noPad
        move.l  a3,d0
        sub.l   a0,d0
        andi.l  #$F,d0
        adda.l  d0,a0
.noPad:
        moveq   #0,d0
        move.w  d7,d0
        lsl.l   #2,d0
        lsr.w   #2,d0
        ori.w   #$4000,d0
        swap    d0
        move.l  d0,(vdp_control_port).l
        lea     (Art_Buffer).w,a2
        move.w  d5,d3
        lsr.w   #2,d3
        subq.w  #1,d3
.copy:
        move.l  (a2)+,(vdp_data_port).l
        dbf     d3,.copy
        add.w   d5,d7
        sub.w   d5,d6
        bne.s   .module
        dbf     d1,.entry
.done:
        movem.l (sp)+,d2-d7/a2-a4
        rts
