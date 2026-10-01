; Public solo character selection.
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
        moveq #0,d0
        move.b (v_character_selected).w,d0
        btst #bitL,d1
        beq.s .next
        subq.w #1,d0
        bpl.s .store
        moveq #Character_Count-1,d0
        bra.s .store
.next:
        addq.w #1,d0
        cmpi.w #Character_Count,d0
        blo.s .store
        moveq #0,d0
.store:
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
        mulu.w #8,d0
        lea Options_Names(pc),a1
        adda.w d0,a1
        moveq #8-1,d2
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
        dc.b "SONIC   ","TAILS   ","KNUCKLES"
Options_Names_End:
        charset
        if (Options_Names_End-Options_Names)<>Character_Count*8
        fatal "Add an eight-character option name for each character."
        endif
        even
