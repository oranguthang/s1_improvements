; One source for act music: the byte in its resource header. Only d0 changes.
GetActMusic:
        moveq #0,d0
        move.w (v_zone_act).w,d0
GetActMusicFor:                  ; d0.w=explicit zone/act, does not change live act
        move.l a2,-(sp)
        jsr (GetLevelHeaderFor).l
        moveq #0,d0
        move.b LevelHeader_Music(a2),d0
        movea.l (sp)+,a2
        rts

; Select the current overlay, excluding drowning (caller controls when to resume).
; Boss phase beats invincibility; FZ keeps its configured act track during combat.
GetSonicMusic:
        tst.b (v_supersonic).w
        bne.s .super
        tst.b (f_bossmusic).w
        bne.s .boss
        tst.b (v_invinc).w
        bne.s .invincible
        bra.w GetActMusic
.boss:
        cmpi.w #id_FZ,(v_zone_act).w
        beq.w GetActMusic
        move.w #bgm_Boss,d0
        rts
.super:
        move.w #bgm_Super,d0
        rts
.invincible:
        move.w #bgm_Invincible,d0
        rts

; A defeated boss returns to the act even while Sonic is still Super. Keep an
; active drowning song until air is replenished, using the same restore rule.
PlayActMusic:
    if FeatureCDDrowning=0
        cmpi.w #12,(v_air).w
        bls.s .return
    endif
        bsr.w GetActMusic
        jmp (QueueSound1).l
.return:
        rts

; Restore a song without restarting it or interrupting a 1-up over that song.
; A pending BGM takes precedence over the playing song; SFX and the 1-up do not.
; d0.b = requested BGM. Preserve all other registers.
QueueMusicIfChanged:
        movem.l d1/a1,-(sp)
        move.b (v_snddriver_ram.v_soundqueue0).w,d1
        cmpi.b #bgm_ExtraLife,d1
        beq.s .playing
        cmpi.b #bgm__First,d1
        blo.s .playing
        cmpi.b #bgm__Last,d1
        bls.s .compare
.playing:
        lea (v_snddriver_ram).w,a1
        tst.b SMPS_RAM.f_1up_playing(a1)
        beq.s .current
        lea SMPS_RAM.v_1up_ram_copy(a1),a1
.current:
        move.b SMPS_RAM.v_current_music(a1),d1
.compare:
        cmp.b d1,d0
        movem.l (sp)+,d1/a1
        beq.s .return
        jmp (QueueSound1).l
.return:
        rts
