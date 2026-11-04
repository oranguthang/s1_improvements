; Persistent solo and companion play-mode selection.
Tit_EnterOptions:
        clr.b (v_jpadpress1).w
        bsr.w LevSel_PrepareScreen
        bsr.w Options_Draw
        bsr.w LevSel_ShowScreen
.loop:
        move.b #id_VBlank_Title,(v_vblank_routine).w
        bsr.w WaitForVBlank
        btst #bitStart,(v_jpadpress1).w
        bne.w Tit_MenuReturn
        bsr.w Options_ReadInput
        tst.b d0
        beq.s .plc
        bsr.w Options_Draw
.plc:
        bsr.w RunPLC
        bra.s .loop

; d0 = 1 when the selection changed and needs redrawing.
Options_ReadInput:
        move.b (v_jpadpress1).w,d1
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

Options_Draw:
        lea (vdp_data_port).l,a6
        locVRAM vram_win+(9<<7)+(16<<1),4(a6)
        lea Options_Header(pc),a1
        move.w #levsel_white,d3
        moveq #7-1,d2
        bsr.w DevMenu_DrawText
        locVRAM vram_win+(11<<7)+(levsel_start_col<<1),4(a6)
        lea Options_Label(pc),a1
        move.w #levsel_yellow,d3
        moveq #16-1,d2
        bsr.w DevMenu_DrawText
        moveq #0,d0
        move.b (v_character_selected).w,d0
        mulu.w #18,d0
        lea Options_Names(pc),a1
        adda.w d0,a1
        moveq #18-1,d2
        bsr.w DevMenu_DrawText
        locVRAM vram_win+(13<<7)+(levsel_start_col<<1),4(a6)
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
        dc.b "CHARACTER       "
Options_Names:
        dc.b "SONIC             ","TAILS             ","KNUCKLES          "
        dc.b "SONIC AND TAILS   ","KNUCKLES AND TAILS"
Options_Names_End:
        charset
        if (Options_Names_End-Options_Names)<>PlayerOption_Count*18
        fatal "Add an eighteen-character option name for each play mode."
        endif
        even
