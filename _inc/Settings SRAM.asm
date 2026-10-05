; ---------------------------------------------------------------------------
; Settings SRAM, format 2. Logical bytes occupy odd addresses $200001..$20001F.
; 00..03 "S1DV", 04 version, 05 payload length, 06..12 seven settings,
; 13 legacy unused player-2 byte (always $FF),
; 14..15 additive big-endian checksum of bytes 00..13. Format 1 is migrated.
; Only configuration is persistent: earned emeralds and cursors are not saved.
; The write invalidates the signature first and commits its first byte last.
; ---------------------------------------------------------------------------
settings_sram_size: equ 16
settings_sram_version: equ 2
settings_sram_payload: equ 8


; Z = all six effectively owned. No general registers are changed.
HasAllEmeralds:
		tst.b	(v_dev_all_emeralds).w
		beq.s	.earned
		cmpi.b	#1,(v_dev_all_emeralds).w
		rts
	.earned:
		cmpi.b	#ss_emeralds_num,(v_emeralds).w
		rts

; d0.w = effective count, genuine v_emeralds/v_emldlist never modified.
GetEffectiveEmeraldCount:
		moveq	#ss_emeralds_num,d0
		tst.b	(v_dev_all_emeralds).w
		bne.s	.return
		moveq	#0,d0
		move.b	(v_emeralds).w,d0
	.return:
		rts

; Clamp each setting independently, then resolve the zero/drain constraint.
Settings_Normalize:
		movem.l	d0-d1/a0-a1,-(sp)
		lea	Settings_BoolFields(pc),a0
		moveq	#4-1,d1
	.loop:
		movea.w	(a0)+,a1
		cmpi.b	#1,(a1)
		bls.s	.next
		clr.b	(a1)
	.next:
		dbf	d1,.loop
		cmpi.b	#1,(v_dev_superdrain).w
		bls.s	.rings
		move.b	#1,(v_dev_superdrain).w	; invalid drain uses the normal default
	.rings:
		move.b	(v_dev_superrings).w,d0
		beq.s	.noDrain
		cmpi.b	#10,d0
		beq.s	.done
		cmpi.b	#50,d0
		beq.s	.done
		move.b	#50,(v_dev_superrings).w
		bra.s	.done
	.noDrain:
		clr.b	(v_dev_superdrain).w
	.done:
		cmpi.b #Character_Count,(v_character_selected).w
	if FeatureTails&FeatureKnuckles
		blo.s .characterValid
	else
		bhs.s .characterInvalid
		moveq	#0,d0
		move.b	(v_character_selected).w,d0
		lea	(CharacterEnabled).l,a0
		tst.b	(a0,d0.w)			; a saved character may be left out of this build
		bne.s	.characterValid
.characterInvalid:
	endif
		clr.b (v_character_selected).w
.characterValid:
		move.b #Character_Off,(v_character_p2).w ; legacy SRAM field stays $FF
		movem.l	(sp)+,d0-d1/a0-a1
		rts
Settings_BoolFields:
		dc.w v_title_unlocked&$FFFF, v_dev_all_emeralds&$FFFF
		dc.w v_dev_debug&$FFFF, v_dev_god&$FFFF

Settings_Fields:
		dc.w v_title_unlocked&$FFFF, v_dev_all_emeralds&$FFFF
		dc.w v_dev_debug&$FFFF, v_dev_superrings&$FFFF
		dc.w v_dev_superdrain&$FFFF, v_dev_god&$FFFF
		dc.w v_character_selected&$FFFF, v_character_p2&$FFFF

; d0.w = sum of 14 bytes at a0. Clobbers d1/a0.
Settings_Checksum:
		moveq	#0,d0
		moveq	#14-1,d1
	.loop:
		add.b	(a0)+,d0
		bcc.s	.next
		addi.w	#$100,d0		; carry from low byte into high byte
	.next:
		dbf	d1,.loop
		rts

Settings_Load:
		movem.l	d0-d2/a0-a2,-(sp)
		bsr.w	Settings_Defaults		; a cold/invalid save gets safe values
		clr.b	(v_title_menuitem).w
		clr.b	(v_title_codepos).w
		clr.b	(v_ss_selected).w
		clr.b	(v_ss_override).w
		clr.b	(v_ss_manual).w
		suba.w	#settings_sram_size,sp
		lea	(sram_start).l,a0
		movea.l	sp,a1
		moveq	#settings_sram_size-1,d1
		move.w	sr,-(sp)
		ori.w	#$700,sr			; no VBlank while SRAM bank is selected
		move.b	#1,(sram_port).l
	.read:
		move.b	(a0),(a1)+
		addq.l	#2,a0				; odd-byte SRAM bus
		dbf	d1,.read
		move.b	#0,(sram_port).l
		move.w	(sp)+,sr
		cmpi.l	#"S1DV",(sp)
		bne.s	.done
		moveq #settings_sram_payload,d2
		cmpi.w #(settings_sram_version<<8)|settings_sram_payload,4(sp)
		beq.s .checkChecksum
		cmpi.w #$0106,4(sp)               ; preserve unlock/cheats from older saves
		bne.s .done
		tst.w 12(sp)
		bne.s .done
		moveq #6,d2
.checkChecksum:
		movea.l	sp,a0
		bsr.w	Settings_Checksum
		cmp.w	14(sp),d0
		bne.s	.done
		lea	6(sp),a0
		lea	Settings_Fields(pc),a2
		move.w d2,d1
		subq.w #1,d1
	.fields:
		movea.w	(a2)+,a1
		move.b	(a0)+,(a1)
		dbf	d1,.fields
		bsr.w	Settings_Normalize
	.done:
		adda.w	#settings_sram_size,sp
		movem.l	(sp)+,d0-d2/a0-a2
		rts

Settings_Save:
		movem.l	d0-d2/a0-a2,-(sp)
		bsr.w	Settings_Normalize
		suba.w	#settings_sram_size,sp
		move.l	#"S1DV",(sp)
		move.w	#(settings_sram_version<<8)|settings_sram_payload,4(sp)
		clr.w	12(sp)
		lea	6(sp),a0
		lea	Settings_Fields(pc),a2
		moveq	#settings_sram_payload-1,d1
	.fields:
		movea.w	(a2)+,a1
		move.b	(a1),(a0)+
		dbf	d1,.fields
		movea.l	sp,a0
		bsr.w	Settings_Checksum
		move.w	d0,14(sp)
		lea	(sram_start).l,a0
		movea.l	sp,a1
		moveq	#settings_sram_size-2,d1
		move.w	sr,-(sp)
		ori.w	#$700,sr
		move.b	#1,(sram_port).l
		clr.b	(a0)				; invalidate until every other byte is written
		addq.l	#1,a1
		addq.l	#2,a0
	.write:
		move.b	(a1)+,(a0)
		addq.l	#2,a0
		dbf	d1,.write
		move.b	#"S",(sram_start).l		; commit record last
		move.b	#0,(sram_port).l
		move.w	(sp)+,sr
		adda.w	#settings_sram_size,sp
		movem.l	(sp)+,d0-d2/a0-a2
		rts
Settings_SRAM_end:
	if (Settings_SRAM_end>=$200000)&(MOMPASS=1)
		fatal "Settings code must remain below the SRAM bank window."
	endif
