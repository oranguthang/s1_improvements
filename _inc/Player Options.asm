; Persistent play-mode selection and sound test.
Tit_EnterOptions:
        clr.b (v_jpadpress1).w
        clr.b (v_options_menuitem).w
        bsr.w LevSel_PrepareScreen
        bsr.w Options_Draw
        bsr.w LevSel_ShowScreen
.loop:
        move.b #id_VBlank_Title,(v_vblank_routine).w
        bsr.w WaitForVBlank
        btst #bitStart,(v_jpadpress1).w
        bne.w Tit_MenuReturn
        bsr.w Options_ReadInput
        beq.s .plc
        bsr.w Options_Draw
.plc:
        bsr.w RunPLC
        bra.s .loop

; Z clear when the selection changed and needs redrawing.
Options_ReadInput:
        move.b (v_jpadpress1).w,d1
        move.b d1,d0
        andi.b #btnUp+btnDn,d0
        beq.s .rowReady
        cmpi.b #btnUp+btnDn,d0
        beq.s .rowReady
        eori.b #1,(v_options_menuitem).w
        moveq #1,d0
        rts
.rowReady:
        tst.b (v_options_menuitem).w
        bne.s Options_SoundInput
        andi.b #btnL+btnR+btnABC,d1
        beq.s .unchanged
        jsr (GetPlayerOption).l
        moveq #1,d2
        btst #bitL,d1
        beq.s .step
        moveq #-1,d2
.step:
        add.w d2,d0
        bpl.s .notBelow
        moveq #PlayerOption_Count-1,d0
.notBelow:
        cmpi.w #PlayerOption_Count,d0
        blo.s .inRange
        moveq #0,d0
.inRange:
        lea (PlayerOptionsEnabled).l,a1
        tst.b (a1,d0.w)
        beq.s .step
        move.b d0,(v_character_selected).w
        jsr (Settings_Save).l
        moveq #1,d0
        rts
.unchanged:
        moveq #0,d0
        rts

Options_SoundInput:
        bsr.w SoundTest_Adjust
        bne.s .return
        move.b (v_jpadpress1).w,d1
        andi.b #btnB+btnC,d1
        beq.s .return
        move.w (v_levselsound).w,d0
        bsr.w SoundTest_Play
        moveq #0,d0
.return:
        rts

Options_Draw:
        lea (vdp_data_port).l,a6
        locVRAM vram_win+(9<<7)+(16<<1),4(a6)
        lea Options_Header(pc),a1
        move.w #levsel_white,d3
        moveq #7-1,d2
        bsr.w DevMenu_DrawText
        locVRAM vram_win+(11<<7)+(levsel_start_col<<1),4(a6)
        lea Options_Label(pc),a1
        move.w #levsel_white,d3
        tst.b (v_options_menuitem).w
        bne.s .characterColour
        move.w #levsel_yellow,d3
.characterColour:
        moveq #Options_Label_End-Options_Label-1,d2
        bsr.w DevMenu_DrawText
        jsr (GetPlayerOption).l
        mulu.w #18,d0
        lea Options_Names(pc),a1
        adda.w d0,a1
        moveq #18-1,d2
        bsr.w DevMenu_DrawText
        locVRAM vram_win+(12<<7)+(levsel_start_col<<1),4(a6)
        lea Options_SoundLabel(pc),a1
        move.w #levsel_white,d3
        tst.b (v_options_menuitem).w
        beq.s .soundColour
        move.w #levsel_yellow,d3
.soundColour:
        moveq #Options_SoundLabel_End-Options_SoundLabel-1,d2
        bsr.w DevMenu_DrawText
        bsr.w SoundTest_DrawID
        locVRAM vram_win+(14<<7)+(levsel_start_col<<1),4(a6)
        lea DevMenu_Hint(pc),a1
        move.w #levsel_white,d3
        moveq #19-1,d2
        bra.w DevMenu_DrawText

        charset ' ', $FF
        charset '0','9',$00
        charset 'Y','Z',$0F
        charset 'A','X',$11
Options_Header: dc.b "OPTIONS"
Options_Label:
        dc.b "CHARACTER   "
Options_Label_End:
Options_SoundLabel:
        dc.b "SOUND TEST  "
Options_SoundLabel_End:
Options_Names:
        dc.b "SONIC             ","TAILS             ","KNUCKLES          "
        dc.b "SONIC AND TAILS   ","KNUCKLES AND TAILS"
Options_Names_End:
        charset
        if (Options_Names_End-Options_Names)<>PlayerOption_Count*18
        fatal "Add an eighteen-character option name for each play mode."
        endif
        even
