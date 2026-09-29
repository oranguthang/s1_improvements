; Replenish air; resume the actual act/overlay only when countdown was playing.
ResumeMusic:
        cmpi.w #12,(v_air).w
        bhi.s .replenishAir
        move.w #30,(v_air).w
        jsr (GetSonicMusic).l
        jsr (QueueSound1).l
.replenishAir:
        move.w #30,(v_air).w
        clr.b (v_sonicbubbles+bub_time).w
        rts
