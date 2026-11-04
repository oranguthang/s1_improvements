; Nonzero/Z clear only while a paired regular level uses the combined
; player palette. Special Stages have their own existing layered palettes.
Sidekick_PaletteActive:
        movem.l d0,-(sp)
        moveq #0,d0
    if FeatureSidekick&FeatureTails
        cmpi.b #Character_Tails,(v_character_p2).w
        bne.s .done
        move.b (v_gamemode).w,d0
        andi.b #$7F,d0
        cmpi.b #id_Level,d0
        beq.s .yes
        cmpi.b #id_Demo,d0
        beq.s .yes
        moveq #0,d0
        bra.s .done
.yes:
        moveq #1,d0
    endif
.done:
        tst.b d0
        movem.l (sp)+,d0
        rts

; a0=compressed ROM source -> matching paired source, other regs/CCR kept.
Sidekick_RemapPLC:
        move.w sr,-(sp)
        movem.l d0/a1,-(sp)
        jsr (Sidekick_PaletteActive).l
        beq.s .done
        cmpa.l #KosM_Points,a0
        bne.s .variants
        lea (KosM_SidekickPointsCompact).l,a0
        bra.s .done
.variants:
        cmpa.l #KosM_SpinPform,a0
        bne.s .other
        lea (KosM_SidekickSpinPlatform).l,a0
        bra.s .done
.other:
        cmpa.l #KosM_SYZ,a0
        bne.s .ordinary
        lea (KosM_SidekickSYZ).l,a0
        bra.s .done
.ordinary:
        lea (Sidekick_PLCVariants).l,a1
.loop:
        move.l (a1)+,d0
        beq.s .done
        cmpa.l d0,a0
        beq.s .found
        addq.w #4,a1
        bra.s .loop
.found:
        movea.l (a1),a0
.done:
        movem.l (sp)+,d0/a1
        move.w (sp)+,ccr
        rts

; DMA raw art can start inside a source sheet. Preserve its offset. Ignore
; RAM and newly generated/buddy resources before walking the source ranges.
Sidekick_RemapDMA:
        move.w sr,-(sp)
        cmpi.l #Sidekick_GeneratedAssets,d1
        bhs.s .return
        movem.l d0/a0,-(sp)
        jsr (Sidekick_PaletteActive).l
        beq.s .done
        lea (Sidekick_DMAVariants).l,a0
.loop:
        move.l (a0)+,d0
        beq.s .done
        cmp.l d0,d1
        blo.s .next
        cmp.l (a0),d1
        bhs.s .next
        sub.l d0,d1
        add.l 4(a0),d1
        bra.s .done
.next:
        addq.w #8,a0
        bra.s .loop
.done:
        movem.l (sp)+,d0/a0
.return:
        move.w (sp)+,ccr
        rts


Sidekick_SpinPlatformMap:
        move.w sr,-(sp)
        movem.l d0,-(sp)
        move.l obMap(a0),d0
        andi.l #$FFFFFF,d0
        cmpi.l #Map_Spin,d0
        bne.s .return
        jsr (Sidekick_PaletteActive).l
        beq.s .return
        andi.l #$FF000000,obMap(a0)
        ori.l #Map_SidekickSpinPlatform,obMap(a0)
.return:
        movem.l (sp)+,d0
        move.w (sp)+,ccr
        rts

; Called after loading the header's ROM pointers and secondary art cue.
Sidekick_LevelData:
        movem.l d0-d7/a0-a6,-(sp)
        jsr (Sidekick_PaletteActive).l
        beq.s .return
        cmpi.l #Blk16_SYZ,(v_rom_blocks).w
        bne.s .chain
        move.l #Blk16_SidekickSYZ,(v_rom_blocks).w
.chain:
        cmpi.b #id_GHZ,(v_zone).w
        bne.s .return
        lea (PLC_SidekickBossChain).l,a1
        jsr (AddPLCFromAddress).l
.return:
        movem.l (sp)+,d0-d7/a0-a6
        rts

; The GHZ boss uses chain art with line 0, normal platforms with line 2.
Sidekick_BossChainTile:
        move.w sr,-(sp)
        jsr (Sidekick_PaletteActive).l
        beq.s .return
        move.w #$3E8,obGfx(a1)
.return:
        move.w (sp)+,ccr
        rts

; Direct VDP art writers use a1, while queued DMA uses d1.
Sidekick_RemapRawA1:
        move.w sr,-(sp)
        movem.l d1,-(sp)
        move.l a1,d1
        jsr (Sidekick_RemapDMA).l
        movea.l d1,a1
        movem.l (sp)+,d1
        move.w (sp)+,ccr
        rts
