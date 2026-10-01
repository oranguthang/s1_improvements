; ---------------------------------------------------------------------------
; Public player options and unlockable title menu, adapted from Selbi's PSB/font approach.
; Unlock is independent of the legacy region-specific cheat sequences.
; ---------------------------------------------------------------------------
TitleMenu_ReadInput:
		move.b	(v_jpadpress1).w,d1
		andi.b	#btnDir+btnABC+btnStart,d1
		beq.w	.return
		move.w	#376,(v_generictimer).w	; user input restarts the existing idle interval
		btst	#6,(v_megadrive).w
		beq.s	.timerReady
		subi.w	#60,(v_generictimer).w
	.timerReady:
		tst.b	(v_title_unlocked).w
		bne.w	.menu
		andi.b	#btnDir,d1
		beq.w	.menu
		moveq	#0,d0
		move.b	(v_title_codepos).w,d0
		cmpi.b	#6,d0
		blo.s	.codeReady
		moveq	#0,d0
	.codeReady:
		lea	TitleMenu_Code(pc),a1
		cmp.b	(a1,d0.w),d1
		bne.s	.restartCode
		addq.b	#1,d0
		move.b	d0,(v_title_codepos).w
		cmpi.b	#6,d0
		bne.w	.menu
		move.b	#1,(v_title_unlocked).w
		clr.b	(v_title_menuitem).w
		clr.b	(v_title_codepos).w
		clr.b	(v_jpadpress1).w		; last Right cannot select/change anything
		jsr	(Settings_Save).l
		move.w	#sfx_Ring,d0
		jmp	(QueueSound2).l
	.restartCode:
		clr.b	(v_title_codepos).w
		cmpi.b	#btnUp,d1
		bne.w	.menu
		move.b	#1,(v_title_codepos).w	; a new Up starts another attempt
		bra.w .menu
	.menu:
		move.b (v_jpadpress1).w,d1
		moveq #1,d2
		tst.b (v_title_unlocked).w
		beq.s .menuCount
		moveq #3,d2
.menuCount:
		moveq	#0,d0
		move.b	(v_title_menuitem).w,d0
		btst	#bitUp,d1
		beq.s	.down
		subq.w	#1,d0
		bpl.s	.down
		move.w d2,d0
	.down:
		btst	#bitDn,d1
		beq.s	.store
		addq.w	#1,d0
		cmp.w d2,d0
		bls.s	.store
		moveq	#0,d0
	.store:
		move.b	d0,(v_title_menuitem).w
	.return:
		rts
TitleMenu_Code:
		dc.b btnUp,btnDn,btnDn,btnDn,btnL,btnR
		even

; d0 = 0 for no choice, 1..4 for the selected destination.
TitleMenu_Confirm:
		moveq	#0,d0
		move.b	(v_jpadpress1).w,d0
		andi.b	#btnA+btnC+btnStart,d0
		beq.s	.return
		move.b	(v_title_menuitem).w,d0
		addq.b	#1,d0
		clr.b	(v_jpadpress1).w
	.return:
		rts

Tit_MenuReturn:
		move.b	#1,(f_title_fast).w
		clr.b	(v_jpadpress1).w
		move.b	#id_Title,(v_gamemode).w
		rts

; PSBTM supplies the single DisplaySprite call after returning from here.
PSB_TitleMenu:
		move.l	#Map_TitleMenu,obMap(a0)
		move.w	#ArtTile_Title_Menu,obGfx(a0)
		move.w	#$80+64,obX(a0)
		move.w	#$80+170,obScreenY(a0)
		move.b	#0,obPriority(a0)		; no menu text behind the Sonic torso masks
		move.b (v_title_menuitem).w,obFrame(a0)
		tst.b (v_title_unlocked).w
		bne.s .draw
		addq.b #4,obFrame(a0)
.draw:
		rts

; All 80 text tiles are composed while display/interrupts are disabled at title load.
; No fresh DMA/VRAM writes are needed when unlocking or changing selection.
TitleMenu_LoadTextGraphics:
		lea	(vdp_data_port).l,a6
		locVRAM ArtTile_Title_Menu*tile_size,4(a6)
		lea	TitleMenu_Text(pc),a1
		moveq	#4*20-1,d2
	.char:
		moveq	#0,d0
		move.b	(a1)+,d0			; same font encoding as LevelMenuText
		bmi.s	.space
		lsl.w	#5,d0
		lea	(Art_Text).l,a3
		adda.w	d0,a3
		moveq	#8-1,d3
	.tile:
		move.l	(a3)+,(a6)
		dbf	d3,.tile
		bra.s	.next
	.space:
		moveq	#0,d0
		moveq	#8-1,d3
	.blank:
		move.l	d0,(a6)
		dbf	d3,.blank
	.next:
		dbf	d2,.char
		rts

; The title menu's cached sprites are still in the SAT when a submenu opens.
; Hide only those pieces so they cannot overlap the submenu text. Their art
; and the shared title palette remain untouched.
TitleMenu_HideForSubmenu:
		movem.l	d0-d1/a0,-(sp)
		moveq	#0,d1
		move.b	(v_spritecount).w,d1
		beq.s	.done
		subq.w	#1,d1
		lea	(v_spritetablebuffer+4).w,a0 ; art/palette word of first sprite
.loop:
		move.w	(a0),d0
		andi.w	#$7FF,d0			; keep only the tile index
		cmpi.w	#ArtTile_Title_Menu,d0
		blo.s	.next
		cmpi.w	#ArtTile_Title_Menu+Title_Menu_Tiles,d0
		bhs.s	.next
		clr.w	-4(a0)			; Y=0 puts this sprite above the visible screen
.next:
		addq.w	#8,a0
		dbf	d1,.loop
.done:
		movem.l	(sp)+,d0-d1/a0
		rts

	charset ' ', $FF
	charset '0','9',$00
	charset 'Y','Z',$0F
	charset 'A','X',$11
TitleMenu_Text:
		dc.b "     START GAME     "
		dc.b "      OPTIONS       "
		dc.b "    LEVEL SELECT    "
		dc.b "       CHEATS       "
TitleMenu_Text_end:
	charset
	if (TitleMenu_Text_end-TitleMenu_Text<>4*20)&(MOMPASS=1)
		fatal "Title menu labels must be exactly 20 characters each."
	endif
		even
