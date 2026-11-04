; All three transfers must fit atomically before the stars become visible.
; This replaces the shield tiles, so invalidate its DPLC key for restoration.
Sidekick_StarsGfx:
    if FeatureS2Stars
        move.w sr,-(sp)
        disableInts
        movea.w (VDP_Command_Buffer_Slot).w,a1
        adda.w #DMAEntry.len*3,a1
        cmpa.w #VDP_Command_Buffer_Slot,a1
        bhi.s .full
        clr.w (v_shieldartkey).w
        clr.b (v_sidekick_debug_ready).w
        lea (Sidekick_StarsDMAs).l,a2
        moveq #2,d5
.transfer:
        moveq #0,d1
        move.w (a2)+,d1
        addi.l #Art_SidekickStars,d1
        move.w (a2)+,d2
        move.w (a2)+,d3
        jsr (QueueDMATransfer).l
        dbf d5,.transfer
        st.b istar_ready(a0)
.full:
        move.w (sp)+,sr
    endif
        rts
