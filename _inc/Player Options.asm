; Player selection is public; the second player remains unavailable.
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
        andi.b #btnUp+btnDn,d1
        beq.s .change
        eori.b #1,(v_options_menuitem).w
        bra.s .changed
.change:
        tst.b (v_options_menuitem).w
        bne.s .unchanged               ; P2: OFF cannot be toggled
        move.b (v_jpadpress1).w,d1
        andi.b #btnL+btnR+btnABC,d1
        beq.s .unchanged
        moveq #0,d0
        move.b (v_character_p1).w,d0
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
        move.b d0,(v_character_p1).w
        jsr (Settings_Save).l
.changed:
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
        locVRAM vram_win+(11<<7)+(levsel_start_col<<1),d4
        lea Options_Labels(pc),a1
        moveq #0,d1
.row:
        move.l d4,4(a6)
        move.w #levsel_white,d3
        cmp.b (v_options_menuitem).w,d1
        bne.s .label
        move.w #levsel_yellow,d3
.label:
        moveq #16-1,d2
        bsr.w DevMenu_DrawText
        move.l a1,-(sp)
        lea Options_Off(pc),a1
        tst.w d1
        bne.s .value
        moveq #0,d0
        move.b (v_character_p1).w,d0
        mulu.w #8,d0
        lea Options_Names(pc),a1
        adda.w d0,a1
.value:
        moveq #8-1,d2
        bsr.w DevMenu_DrawText
        movea.l (sp)+,a1
        addi.l #$00800000,d4
        addq.w #1,d1
        cmpi.w #2,d1
        blo.s .row
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
Options_Labels:
        dc.b "PLAYER 1        "
        dc.b "PLAYER 2        "
Options_Names:
        dc.b "SONIC   ","TAILS   "
Options_Names_End:
Options_Off: dc.b "OFF     "
        charset
        if (Options_Names_End-Options_Names)<>Character_Count*8
        fatal "Add an eight-character option name for each character."
        endif
        even
