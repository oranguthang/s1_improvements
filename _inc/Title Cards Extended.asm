; ===========================================================================
; ---------------------------------------------------------------------------
; Extended title cards: the full alphabet, per-act names typed as text, and
; only the letters in use are loaded. Adapted from "Extend Title Cards in
; Sonic 1" (https://info.sonicretro.org/SCHG_How-to:Extend_Title_Cards_in_Sonic_1):
; main system by Selbi, AS port and result screens by RobiWanKenobi. Font:
; lowercase from "Yuu Yuu Hakusho: Makyou Toitsusen", missing uppercase
; JQVWX by SameyTheHedgie, title-case "Act" and lowercase "a" by MDTravis,
; act "4" by Cinossu.
;
; This project adds the solo character names to the end-of-act card, gray
; copies of both ovals so level cards do not follow the player's fur colours,
; and the effective emerald count for the Special Stage results text.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Title card text. Uppercase and lowercase English letters and spaces are
; allowed, at most 20 characters. "ZONE" takes at most 5 letters, and a solo
; name with " HAS" at most 11 letters.
; ---------------------------------------------------------------------------

TitleCard_GHZ1:	equ "GREEN HILL"
TitleCard_GHZ2:	equ "GREEN HILL"
TitleCard_GHZ3:	equ "GREEN HILL"
TitleCard_GHZ4:	equ "GREEN HILL"

TitleCard_LZ1:	equ "LABYRINTH"
TitleCard_LZ2:	equ "LABYRINTH"
TitleCard_LZ3:	equ "LABYRINTH"
TitleCard_LZ4:	equ "SCRAP BRAIN"		; LZ4 is SBZ3

TitleCard_MZ1:	equ "MARBLE"
TitleCard_MZ2:	equ "MARBLE"
TitleCard_MZ3:	equ "MARBLE"
TitleCard_MZ4:	equ "MARBLE"

TitleCard_SLZ1:	equ "STAR LIGHT"
TitleCard_SLZ2:	equ "STAR LIGHT"
TitleCard_SLZ3:	equ "STAR LIGHT"
TitleCard_SLZ4:	equ "STAR LIGHT"

TitleCard_SYZ1:	equ "SPRING YARD"
TitleCard_SYZ2:	equ "SPRING YARD"
TitleCard_SYZ3:	equ "SPRING YARD"
TitleCard_SYZ4:	equ "SPRING YARD"

TitleCard_SBZ1:	equ "SCRAP BRAIN"
TitleCard_SBZ2:	equ "SCRAP BRAIN"
TitleCard_SBZ3:	equ "FINAL"			; SBZ3 is FZ
TitleCard_SBZ4:	equ "SCRAP BRAIN"

TitleCard_Zone:	equ "ZONE"
TitleCard_UseLowerAct: equ 0			; 0 = "ACT", 1 = "Act"

TitleCard_SonicHas:	equ "SONIC HAS"
TitleCard_TailsHas:	equ "TAILS HAS"
TitleCard_KnucklesHas:	equ "KNUCKLES HAS"
TitleCard_Passed:	equ "PASSED"

TitleCard_SpecialStage:	equ "SPECIAL STAGE"
TitleCard_ChaosEmeralds: equ "CHAOS EMERALDS"
TitleCard_GotThemAll:	equ "SONIC GOT THEM ALL"
TitleCard_TailsGotThemAll: equ "TAILS GOT THEM ALL"
; Knuckles' line is wider than one card can reach (sprite pieces sit at most
; 128 pixels from the object), so it takes two lines.
TitleCard_KnucklesName:	equ "KNUCKLES"
TitleCard_GotThemAllEnd: equ "GOT THEM ALL"

; ---------------------------------------------------------------------------
; Art layout: A-Z, the act numbers in the gap before a-z, "ACT"/"Act", the
; oval, "BONU" and the small oval, then this project's gray copies of both ovals.
; ---------------------------------------------------------------------------

TTL_LetterTiles:	equ 4	; one 16x16 letter
TTL_NumberTiles:	equ 6	; one 16x24 act number
TTL_ActTxtTiles:	equ 3	; "ACT", 24x8
TTL_OvalTiles:		equ 16
TTL_SmallOvalTiles:	equ 2
TTL_BonuTiles:		equ 8

TTL_Numbers:		equ ("Z"-"A"+1)*TTL_LetterTiles*tile_size
TTL_ActText:		equ (("z"-"A"+1)*TTL_LetterTiles+TTL_ActTxtTiles*TitleCard_UseLowerAct)*tile_size
TTL_BlueOval:		equ (("z"-"A"+1)*TTL_LetterTiles+TTL_ActTxtTiles*2)*tile_size
TTL_EOL:		equ TTL_BlueOval+TTL_OvalTiles*tile_size	; "BONU", then the small oval
TTL_GrayOval:		equ TTL_EOL+(TTL_BonuTiles+TTL_SmallOvalTiles)*tile_size
TTL_GraySmallOval:	equ TTL_GrayOval+TTL_OvalTiles*tile_size

; VRAM tiles relative to ArtTile_Title_Card. Level and end-of-act cards:
TTL_CardActTile:	equ TTL_OvalTiles
TTL_CardNumberTile:	equ TTL_CardActTile+TTL_ActTxtTiles
TTL_CardZoneTile:	equ TTL_CardNumberTile+TTL_NumberTiles
TTL_CardNameTile:	equ TTL_CardZoneTile+strlen(TitleCard_Zone)*TTL_LetterTiles
TTL_GotNameLetters:	equ 11	; longest solo name with "HAS", spaces excluded
TTL_GotPassedTile:	equ TTL_CardZoneTile+TTL_GotNameLetters*TTL_LetterTiles
TTL_BONU:		equ TTL_GotPassedTile+strlen(TitleCard_Passed)*TTL_LetterTiles
TTL_SmOval:		equ TTL_BONU+TTL_BonuTiles
; Special Stage results: the oval, the header text, then "BONU" and small oval.
TTL_SSRTextTile:	equ TTL_OvalTiles
TTL_SSRBonuTile:	equ 118
TTL_SmOvalSSR:		equ TTL_SSRBonuTile+TTL_BonuTiles

	if TTL_SmOval+TTL_SmallOvalTiles>$80
		fatal "End-of-act title card art exceeds the 128-tile title card slot"
	endif

; ---------------------------------------------------------------------------
; Load the level title card: gray oval, "ACT", act number, "ZONE" and name.
; ---------------------------------------------------------------------------

TitleCards_LoadArt:
		move.w	sr,-(sp)
		disable_ints
		lea	(Unc_TitleCard+TTL_GrayOval).l,a1
		bsr.w	TTL_LoadMainPatterns
		lea	TTLCard_Zone_Array(pc),a2
		bsr.w	TTL_WriteLetters
		moveq	#0,d0
		move.b	(v_zone).w,d0
		add.w	d0,d0
		add.w	d0,d0
		add.b	(v_act).w,d0
		lsl.w	#3,d0
		lea	TTL_ConData(pc),a2
		movea.l	4(a2,d0.w),a2				; letter array for this act
		bsr.w	TTL_WriteLetters
		move.w	(sp)+,sr
		rts

; ---------------------------------------------------------------------------
; Load the end-of-act card: gray oval, act, the player's name, "PASSED",
; "BONU" and the gray small oval.
; ---------------------------------------------------------------------------

Got_LoadArt:
		move.w	sr,-(sp)
		disable_ints
		lea	(Unc_TitleCard+TTL_GrayOval).l,a1
		bsr.w	TTL_LoadMainPatterns
		lea	TTLCard_Got_SonicHas_Array(pc),a2
		cmpi.b	#Character_Tails,(v_character_p1).w
		bne.s	.notTails
		lea	TTLCard_Got_TailsHas_Array(pc),a2
	.notTails:
		cmpi.b	#Character_Knuckles,(v_character_p1).w
		bne.s	.nameReady
		lea	TTLCard_Got_KnucklesHas_Array(pc),a2
	.nameReady:
		bsr.w	TTL_WriteLetters
		locVRAM	(ArtTile_Title_Card+TTL_GotPassedTile)*tile_size
		lea	TTLCard_Got_Passed_Array(pc),a2
		bsr.w	TTL_WriteLetters
		locVRAM	(ArtTile_Title_Card+TTL_BONU)*tile_size
		lea	(Unc_TitleCard+TTL_EOL).l,a1
		moveq	#TTL_BonuTiles-1,d1
		bsr.w	TTL_LoadTiles
		lea	(Unc_TitleCard+TTL_GraySmallOval).l,a1
		moveq	#TTL_SmallOvalTiles-1,d1
		bsr.w	TTL_LoadTiles
		move.w	(sp)+,sr
		rts

; ---------------------------------------------------------------------------
; Load the Special Stage results card. This screen has its own palette, so it
; keeps the original yellow ovals.
; ---------------------------------------------------------------------------

SpecStagResults_LoadArt:
		move.w	sr,-(sp)
		disable_ints
		lea	(vdp_data_port).l,a6
		locVRAM	ArtTile_Title_Card*tile_size
		lea	(Unc_TitleCard+TTL_BlueOval).l,a1
		moveq	#TTL_OvalTiles-1,d1
		bsr.w	TTL_LoadTiles
		jsr	(GetEffectiveEmeraldCount).l		; ALL EMERALDS counts as all six
		lea	TTLCard_SSR_SpeStage_Array(pc),a2	; no emeralds
		tst.b	d0
		beq.s	.loadText
		lea	TTLCard_SSR_Chaos_Array(pc),a2		; some emeralds
		cmpi.b	#ss_emeralds_num,d0
		blo.s	.loadText
		lea	TTLCard_SSR_GotAll_Array(pc),a2		; all emeralds: the selected character's line
		jsr	(GetSelectedCharacter).l
		cmpi.b	#Character_Tails,d0
		bne.s	.notTails
		lea	TTLCard_SSR_TailsGotAll_Array(pc),a2
		bra.s	.loadText
	.notTails:
		cmpi.b	#Character_Knuckles,d0
		bne.s	.loadText
		lea	TTLCard_SSR_KnucklesName_Array(pc),a2	; Knuckles' name, then "GOT THEM ALL" right after it
		bsr.s	TTL_WriteLetters
		lea	TTLCard_SSR_GotAllEnd_Array(pc),a2
	.loadText:
		bsr.s	TTL_WriteLetters
		locVRAM	(ArtTile_Title_Card+TTL_SSRBonuTile)*tile_size
		lea	(Unc_TitleCard+TTL_EOL).l,a1
		moveq	#TTL_BonuTiles+TTL_SmallOvalTiles-1,d1
		bsr.s	TTL_LoadTiles
		move.w	(sp)+,sr
		rts

; ---------------------------------------------------------------------------
; Helpers. a6 = VDP data port with the target VRAM address already set.
; ---------------------------------------------------------------------------

; a2 = zero-terminated letters; spaces take no tiles.
TTL_WriteLetters:
		move.l	#Unc_TitleCard,d4
	.loop:
		moveq	#0,d2
		move.b	(a2)+,d2
		beq.s	.done
		cmpi.b	#' ',d2
		beq.s	.loop
		subi.b	#'A',d2					; letters are 0-based from "A"
		lsl.l	#7,d2					; four tiles per letter
		add.l	d4,d2
		movea.l	d2,a1
		moveq	#TTL_LetterTiles-1,d1
		bsr.s	TTL_LoadTiles
		bra.s	.loop
	.done:
		rts

; a1 = source tiles, d1 = tile count minus 1.
TTL_LoadTiles:
		rept	tile_size/4
		move.l	(a1)+,(a6)
		endm
		dbf	d1,TTL_LoadTiles
		rts

; a1 = oval art. Loads the oval, "ACT" and the act number from tile 0.
TTL_LoadMainPatterns:
		lea	(vdp_data_port).l,a6
		locVRAM	ArtTile_Title_Card*tile_size
		moveq	#TTL_OvalTiles-1,d1
		bsr.s	TTL_LoadTiles
		lea	(Unc_TitleCard+TTL_ActText).l,a1
		moveq	#TTL_ActTxtTiles-1,d1
		bsr.s	TTL_LoadTiles
		lea	(Unc_TitleCard+TTL_Numbers).l,a1
		moveq	#0,d0
		move.b	(v_act).w,d0
		cmpi.w	#id_LZ_act4,(v_zone_act).w		; SBZ3 (LZ4) shows act 3
		bne.s	.number
		subq.b	#1,d0
	.number:
		mulu.w	#TTL_NumberTiles*tile_size,d0
		adda.w	d0,a1
		moveq	#TTL_NumberTiles-1,d1
		bra.s	TTL_LoadTiles

; ---------------------------------------------------------------------------
; Generate a text card: sprite mappings, the letter array (label_Array) and
; the level card movement data (label_ConData). firstTile is the VRAM tile of
; the first letter; xAdjust moves the whole text horizontally.
; ---------------------------------------------------------------------------

maketitlecard:	macro textline,hideAct,firstTile,xAdjust,{INTLABEL}
__LABEL__:	label *
		set len, strlen(textline)
		if len>20
			fatal "maximum length is 20 characters"
		endif

		; total width, retried with 8-pixel spaces if it does not fit
		set useSmallSpaces, 0
		set sizeX, $00
		set spaces, 0
		set i, 0
		while (i<len)
			set char, substr(textline,i,1)
			set sizeX, sizeX+$10
			if (char=' ')
				if (useSmallSpaces)
					set sizeX, sizeX-$08
				endif
				set spaces, spaces+1
			elseif (char='I')
				set sizeX, sizeX-8
			elseif (char>='a')&(char<='z')
				if (char='i')|(char='j')|(char='l')
					set sizeX, sizeX-7
				else
					set sizeX, sizeX-2
				endif
			endif
			set i, i+1
			if ((sizeX>$FF)&(useSmallSpaces<>1))
				set useSmallSpaces, 1
				set sizeX, $00
				set spaces, 0
				set i, 0
			endif
		endm
		dc.b len-spaces

		; one 16x16 sprite piece per letter
		set tile, firstTile
		set x, $08-(sizeX/2)
		set x, (x+(xAdjust))&$FF
		set i, 0
		while (i<len)
			set char, substr(textline,i,1)
			set addX, $10
			if (char=' ')
				if (useSmallSpaces)
					set addX, addX-8
				endif
			elseif ((char>='A')&(char<='Z'))|((char>='a')&(char<='z'))
				set yOffset, 0
				if (char='p')|(char='q')|(char='y')
					set yOffset, 5
				elseif (char='g')
					set yOffset, 2
				endif
				dc.b ($F8+yOffset)&$FF, $05, $00, tile, x
				set tile, tile+TTL_LetterTiles
				if (char>='a')&(char<='z')
					if (char='i')|(char='j')|(char='l')
						set addX, addX-7
					else
						set addX, addX-2
					endif
				elseif (char='I')
					set addX, 8
				endif
			else
				fatal "illegal char '\{char}' in \{textline}"
			endif
			set x, (x+addX)&$FF
			set i, i+1
		endm
		even

__LABEL___Array: label *
		set i, 0
		while (i<len)
			set char, substr(textline,i,1)
			dc.b char
			set i, i+1
		endm
		dc.b 0
		even

__LABEL___ConData: label *
		if hideAct<>0
			set noActAdjust, $10
		else
			set noActAdjust, 0
		endif
		set name_target, $0120
		set name_start, $0000
		set zone_target, $00F0+(sizeX/2)+noActAdjust
		set zone_start, zone_target-$0240
		set oval_target, zone_target+$0018-noActAdjust
		set oval_start, oval_target+$00C0
		if hideAct<>0
			set act_target, $03EC
			set act_start, act_target
		else
			set act_target, oval_target
			set act_start, act_target+$02C0
		endif
		; Cards leave at $20 pixels per frame and stop only on the exact
		; start position. Level startup waits for all of them to leave.
		if ((zone_target-zone_start)|(act_target-act_start)|(oval_target-oval_start)|(name_target-name_start))&$1F
			fatal "title card travel for \{textline} must be a multiple of $20"
		endif
		dc.w name_start&$FFFF, name_target&$FFFF
		dc.w zone_start&$FFFF, zone_target&$FFFF
		dc.w act_start&$FFFF, act_target&$FFFF
		dc.w oval_start&$FFFF, oval_target&$FFFF
	endm

; ---------------------------------------------------------------------------
; Level title cards: one frame per act in zone ID order, then ZONE, the act
; number and the oval (see Card_ItemData).
; ---------------------------------------------------------------------------

Map_Card:	mappingsTable
	mappingsTableEntry.w	TTLCard_GHZ1
	mappingsTableEntry.w	TTLCard_GHZ2
	mappingsTableEntry.w	TTLCard_GHZ3
	mappingsTableEntry.w	TTLCard_GHZ4
	mappingsTableEntry.w	TTLCard_LZ1
	mappingsTableEntry.w	TTLCard_LZ2
	mappingsTableEntry.w	TTLCard_LZ3
	mappingsTableEntry.w	TTLCard_LZ4	; SBZ3
	mappingsTableEntry.w	TTLCard_MZ1
	mappingsTableEntry.w	TTLCard_MZ2
	mappingsTableEntry.w	TTLCard_MZ3
	mappingsTableEntry.w	TTLCard_MZ4
	mappingsTableEntry.w	TTLCard_SLZ1
	mappingsTableEntry.w	TTLCard_SLZ2
	mappingsTableEntry.w	TTLCard_SLZ3
	mappingsTableEntry.w	TTLCard_SLZ4
	mappingsTableEntry.w	TTLCard_SYZ1
	mappingsTableEntry.w	TTLCard_SYZ2
	mappingsTableEntry.w	TTLCard_SYZ3
	mappingsTableEntry.w	TTLCard_SYZ4
	mappingsTableEntry.w	TTLCard_SBZ1
	mappingsTableEntry.w	TTLCard_SBZ2
	mappingsTableEntry.w	TTLCard_SBZ3	; FZ
	mappingsTableEntry.w	TTLCard_SBZ4
	zonewarning Map_Card,4*2
	mappingsTableEntry.w	TTLCard_Zone
	mappingsTableEntry.w	TTLCard_Act
	mappingsTableEntry.w	TTLCard_Oval

TTLCard_GHZ1:	maketitlecard TitleCard_GHZ1,0,TTL_CardNameTile,-8
TTLCard_GHZ2:	maketitlecard TitleCard_GHZ2,0,TTL_CardNameTile,-8
TTLCard_GHZ3:	maketitlecard TitleCard_GHZ3,0,TTL_CardNameTile,-8
TTLCard_GHZ4:	maketitlecard TitleCard_GHZ4,0,TTL_CardNameTile,-8
TTLCard_LZ1:	maketitlecard TitleCard_LZ1,0,TTL_CardNameTile,-8
TTLCard_LZ2:	maketitlecard TitleCard_LZ2,0,TTL_CardNameTile,-8
TTLCard_LZ3:	maketitlecard TitleCard_LZ3,0,TTL_CardNameTile,-8
TTLCard_LZ4:	maketitlecard TitleCard_LZ4,0,TTL_CardNameTile,-8
TTLCard_MZ1:	maketitlecard TitleCard_MZ1,0,TTL_CardNameTile,-8
TTLCard_MZ2:	maketitlecard TitleCard_MZ2,0,TTL_CardNameTile,-8
TTLCard_MZ3:	maketitlecard TitleCard_MZ3,0,TTL_CardNameTile,-8
TTLCard_MZ4:	maketitlecard TitleCard_MZ4,0,TTL_CardNameTile,-8
TTLCard_SLZ1:	maketitlecard TitleCard_SLZ1,0,TTL_CardNameTile,-8
TTLCard_SLZ2:	maketitlecard TitleCard_SLZ2,0,TTL_CardNameTile,-8
TTLCard_SLZ3:	maketitlecard TitleCard_SLZ3,0,TTL_CardNameTile,-8
TTLCard_SLZ4:	maketitlecard TitleCard_SLZ4,0,TTL_CardNameTile,-8
TTLCard_SYZ1:	maketitlecard TitleCard_SYZ1,0,TTL_CardNameTile,-8
TTLCard_SYZ2:	maketitlecard TitleCard_SYZ2,0,TTL_CardNameTile,-8
TTLCard_SYZ3:	maketitlecard TitleCard_SYZ3,0,TTL_CardNameTile,-8
TTLCard_SYZ4:	maketitlecard TitleCard_SYZ4,0,TTL_CardNameTile,-8
TTLCard_SBZ1:	maketitlecard TitleCard_SBZ1,0,TTL_CardNameTile,-8
TTLCard_SBZ2:	maketitlecard TitleCard_SBZ2,0,TTL_CardNameTile,-8
TTLCard_SBZ3:	maketitlecard TitleCard_SBZ3,1,TTL_CardNameTile,-8	; FZ hides the act
TTLCard_SBZ4:	maketitlecard TitleCard_SBZ4,0,TTL_CardNameTile,-8
TTLCard_Zone:	maketitlecard TitleCard_Zone,1,TTL_CardZoneTile,-8

TTLCard_Act:	spriteHeader	; "ACT" and the act number
	spritePiece	-$14, 4, 3, 1, TTL_CardActTile, 0, 0, 0, 0
	spritePiece	$08, -$C, 2, 3, TTL_CardNumberTile, 0, 0, 0, 0
TTLCard_Act_End

TTLCard_Oval:	spriteHeader	; oval, rearranged for this font's tile layout
	spritePiece	-$C, -$1C, 4, 1, $00, 0, 0, 0, 0
	spritePiece	$14, -$1C, 1, 3, $04, 0, 0, 0, 0
	spritePiece	-$14, -$14, 2, 1, $07, 0, 0, 0, 0
	spritePiece	-$1C, -$C, 2, 2, $09, 0, 0, 0, 0
	spritePiece	-$14, $14, 4, 1, $00, 1, 1, 0, 0
	spritePiece	-$1C, 4, 1, 3, $04, 1, 1, 0, 0
	spritePiece	4, $C, 2, 1, $07, 1, 1, 0, 0
	spritePiece	$C, -4, 2, 2, $09, 1, 1, 0, 0
	spritePiece	-4, -$14, 3, 1, $0D, 0, 0, 0, 0
	spritePiece	-$C, -$C, 4, 1, $0C, 0, 0, 0, 0
	spritePiece	-$C, -4, 3, 1, $0C, 0, 0, 0, 0
	spritePiece	-$14, 4, 4, 1, $0C, 0, 0, 0, 0
	spritePiece	-$14, $C, 3, 1, $0C, 0, 0, 0, 0
TTLCard_Oval_End
	even

; Movement data and letter array per act (8 bytes each).
TTL_ConData:
	dc.l TTLCard_GHZ1_ConData, TTLCard_GHZ1_Array
	dc.l TTLCard_GHZ2_ConData, TTLCard_GHZ2_Array
	dc.l TTLCard_GHZ3_ConData, TTLCard_GHZ3_Array
	dc.l TTLCard_GHZ4_ConData, TTLCard_GHZ4_Array
	dc.l TTLCard_LZ1_ConData, TTLCard_LZ1_Array
	dc.l TTLCard_LZ2_ConData, TTLCard_LZ2_Array
	dc.l TTLCard_LZ3_ConData, TTLCard_LZ3_Array
	dc.l TTLCard_LZ4_ConData, TTLCard_LZ4_Array
	dc.l TTLCard_MZ1_ConData, TTLCard_MZ1_Array
	dc.l TTLCard_MZ2_ConData, TTLCard_MZ2_Array
	dc.l TTLCard_MZ3_ConData, TTLCard_MZ3_Array
	dc.l TTLCard_MZ4_ConData, TTLCard_MZ4_Array
	dc.l TTLCard_SLZ1_ConData, TTLCard_SLZ1_Array
	dc.l TTLCard_SLZ2_ConData, TTLCard_SLZ2_Array
	dc.l TTLCard_SLZ3_ConData, TTLCard_SLZ3_Array
	dc.l TTLCard_SLZ4_ConData, TTLCard_SLZ4_Array
	dc.l TTLCard_SYZ1_ConData, TTLCard_SYZ1_Array
	dc.l TTLCard_SYZ2_ConData, TTLCard_SYZ2_Array
	dc.l TTLCard_SYZ3_ConData, TTLCard_SYZ3_Array
	dc.l TTLCard_SYZ4_ConData, TTLCard_SYZ4_Array
	dc.l TTLCard_SBZ1_ConData, TTLCard_SBZ1_Array
	dc.l TTLCard_SBZ2_ConData, TTLCard_SBZ2_Array
	dc.l TTLCard_SBZ3_ConData, TTLCard_SBZ3_Array
	dc.l TTLCard_SBZ4_ConData, TTLCard_SBZ4_Array
	zonewarning TTL_ConData,4*2*4

; ---------------------------------------------------------------------------
; End-of-act cards, one mappings table per solo character.
; ---------------------------------------------------------------------------

gotmappings:	macro name
		mappingsTableEntry.w	name
		mappingsTableEntry.w	TTLCard_Got_Passed
		mappingsTableEntry.w	TTLCard_Got_Score
		mappingsTableEntry.w	TTLCard_Got_TBonus
		mappingsTableEntry.w	TTLCard_Got_RBonus
		mappingsTableEntry.w	TTLCard_Oval
		mappingsTableEntry.w	TTLCard_Act
		mappingsTableEntry.w	TTLCard_Act
		mappingsTableEntry.w	TTLCard_Act
		mappingsTableEntry.w	TTLCard_Act
		endm

Map_Got:	mappingsTable
	gotmappings	TTLCard_Got_SonicHas
Map_Got_Tails:	mappingsTable
	gotmappings	TTLCard_Got_TailsHas
Map_Got_Knuckles: mappingsTable
	gotmappings	TTLCard_Got_KnucklesHas

TTLCard_Got_SonicHas:	maketitlecard TitleCard_SonicHas,1,TTL_CardZoneTile,-8
TTLCard_Got_TailsHas:	maketitlecard TitleCard_TailsHas,1,TTL_CardZoneTile,-8
TTLCard_Got_KnucklesHas: maketitlecard TitleCard_KnucklesHas,1,TTL_CardZoneTile,-8
TTLCard_Got_Passed:	maketitlecard TitleCard_Passed,1,TTL_GotPassedTile,0

	if strlen(TitleCard_KnucklesHas)-1>TTL_GotNameLetters
		fatal "A solo name on the end-of-act card is too long"
	endif

; SCORE, TIME and RINGS come from the HUD art and use its palette line.
TTLCard_Got_Score:	spriteHeader
	spritePiece	-$50, -8, 4, 2, $14A, 0, 0, 1, 0		; "SCOR"
	spritePiece	-$30, -8, 1, 2, $162, 0, 0, 1, 0		; "E"
	spritePiece	-$33, -9, 2, 1, TTL_SmOval, 0, 0, 0, 0		; small oval (upper half)
	spritePiece	-$34, -1, 2, 1, TTL_SmOval, 1, 1, 0, 0		; small oval (lower half)
	spritePiece	$18, -8, 3, 2, $164, 0, 0, 0, 0			; tally (first four digits)
	spritePiece	$30, -8, 4, 2, $16A, 0, 0, 0, 0			; tally (last four digits)
TTLCard_Got_Score_End

TTLCard_Got_TBonus:	spriteHeader
	spritePiece	-$50, -8, 4, 2, $15A, 0, 0, 1, 0		; "TIME"
	spritePiece	-$27, -7, 4, 2, TTL_BONU, 0, 0, 0, 0		; "BONU"
	spritePiece	-7, -8, 1, 2, $14A, 0, 0, 1, 0			; "S"
	spritePiece	-$A, -9, 2, 1, TTL_SmOval, 0, 0, 0, 0		; small oval (upper half)
	spritePiece	-$B, -1, 2, 1, TTL_SmOval, 1, 1, 0, 0		; small oval (lower half)
	spritePiece	$28, -8, 4, 2, -$10, 0, 0, 0, 0			; tally (first four digits)
	spritePiece	$48, -8, 1, 2, $170, 0, 0, 0, 0			; tally (last digit)
TTLCard_Got_TBonus_End

TTLCard_Got_RBonus:	spriteHeader
	spritePiece	-$50, -8, 4, 2, $152, 0, 0, 1, 0		; "RING"
	spritePiece	-$27, -7, 4, 2, TTL_BONU, 0, 0, 0, 0		; "BONU"
	spritePiece	-7, -8, 1, 2, $14A, 0, 0, 1, 0			; "S"
	spritePiece	-$A, -9, 2, 1, TTL_SmOval, 0, 0, 0, 0		; small oval (upper half)
	spritePiece	-$B, -1, 2, 1, TTL_SmOval, 1, 1, 0, 0		; small oval (lower half)
	spritePiece	$28, -8, 4, 2, -8, 0, 0, 0, 0			; tally (first four digits)
	spritePiece	$48, -8, 1, 2, $170, 0, 0, 0, 0			; tally (last digit)
TTLCard_Got_RBonus_End
	even

; ---------------------------------------------------------------------------
; Special Stage results.
; ---------------------------------------------------------------------------

Map_SSR:	mappingsTable
	mappingsTableEntry.w	TTLCard_SSR_Chaos	; "CHAOS EMERALDS"
	mappingsTableEntry.w	TTLCard_SSR_Score	; score tally
	mappingsTableEntry.w	TTLCard_SSR_Ring	; ring bonus tally
	mappingsTableEntry.w	TTLCard_Oval		; oval
	mappingsTableEntry.w	TTLCard_SSR_ContSon1	; continue tally, mini Sonic foot down
	mappingsTableEntry.w	TTLCard_SSR_ContSon2	; continue tally, mini Sonic foot up
	mappingsTableEntry.w	TTLCard_SSR_Continue	; continue tally without mini Sonic
	mappingsTableEntry.w	TTLCard_SSR_SpeStage	; "SPECIAL STAGE"
	mappingsTableEntry.w	TTLCard_SSR_GotAll	; "SONIC GOT THEM ALL"
	mappingsTableEntry.w	TTLCard_SSR_Continue	; (keeps the next two an even/odd pair)
	mappingsTableEntry.w	TTLCard_SSR_ContIcon1	; continue tally, selected character (foot down)
	mappingsTableEntry.w	TTLCard_SSR_ContIcon2	; continue tally, selected character (foot up)
	mappingsTableEntry.w	TTLCard_SSR_TailsGotAll	; "TAILS GOT THEM ALL"
	mappingsTableEntry.w	TTLCard_SSR_KnucklesName ; "KNUCKLES", upper line of Knuckles' text
	mappingsTableEntry.w	TTLCard_SSR_GotAllEnd	; "GOT THEM ALL", lower line of Knuckles' text

TTLCard_SSR_Chaos:	maketitlecard TitleCard_ChaosEmeralds,1,TTL_SSRTextTile,-8
TTLCard_SSR_SpeStage:	maketitlecard TitleCard_SpecialStage,1,TTL_SSRTextTile,-8
TTLCard_SSR_GotAll:	maketitlecard TitleCard_GotThemAll,1,TTL_SSRTextTile,-8
TTLCard_SSR_TailsGotAll: maketitlecard TitleCard_TailsGotThemAll,1,TTL_SSRTextTile,-8
; Knuckles' two lines, each on its own object (SSR_KnucklesGotAll)
TTLCard_SSR_KnucklesName: maketitlecard TitleCard_KnucklesName,1,TTL_SSRTextTile,-8
TTLCard_SSR_GotAllEnd:	maketitlecard TitleCard_GotThemAllEnd,1,TTL_SSRTextTile+strlen(TitleCard_KnucklesName)*TTL_LetterTiles,-8

	if TTL_SSRTextTile+(strlen(TitleCard_GotThemAll)-3)*TTL_LetterTiles>TTL_SSRBonuTile
		fatal "Special Stage results text overlaps BONU"
	endif
	if TTL_SSRTextTile+(strlen(TitleCard_KnucklesName)+strlen(TitleCard_GotThemAllEnd)-2)*TTL_LetterTiles>TTL_SSRBonuTile
		fatal "Knuckles' Special Stage results text overlaps BONU"
	endif

TTLCard_SSR_Score:	spriteHeader
	spritePiece	-$50, -8, 4, 2, $14A, 0, 0, 0, 0		; "SCOR"
	spritePiece	-$30, -8, 1, 2, $162, 0, 0, 0, 0		; "E"
	spritePiece	-$33, -9, 2, 1, TTL_SmOvalSSR, 0, 0, 0, 0	; small oval (upper half)
	spritePiece	-$34, -1, 2, 1, TTL_SmOvalSSR, 1, 1, 0, 0	; small oval (lower half)
	spritePiece	$18, -8, 3, 2, $164, 0, 0, 0, 0			; tally (first four digits)
	spritePiece	$30, -8, 4, 2, $16A, 0, 0, 0, 0			; tally (last four digits)
TTLCard_SSR_Score_End

TTLCard_SSR_Ring:	spriteHeader
	spritePiece	-$50, -8, 4, 2, $152, 0, 0, 0, 0		; "RING"
	spritePiece	-$27, -7, 4, 2, TTL_SSRBonuTile, 0, 0, 0, 0	; "BONU"
	spritePiece	-7, -8, 1, 2, $14A, 0, 0, 0, 0			; "S"
	spritePiece	-$A, -9, 2, 1, TTL_SmOvalSSR, 0, 0, 0, 0	; small oval (upper half)
	spritePiece	-$B, -1, 2, 1, TTL_SmOvalSSR, 1, 1, 0, 0	; small oval (lower half)
	spritePiece	$28, -8, 4, 2, -8, 0, 0, 0, 0			; tally (first four digits)
	spritePiece	$48, -8, 1, 2, $170, 0, 0, 0, 0			; tally (last digit)
TTLCard_SSR_Ring_End

TTLCard_SSR_ContSon1:	spriteHeader
	spritePiece	-$50, -8, 4, 2, -$2F, 0, 0, 0, 0		; "CONT"
	spritePiece	-$30, -8, 4, 2, -$27, 0, 0, 0, 0		; "INUE" and small oval (left half)
	spritePiece	-$10, -8, 1, 2, -$1F, 0, 0, 0, 0		; small oval (right half)
	spritePiece	$40, -8, 2, 3, -$1D, 0, 0, 1, 0			; mini Sonic (foot down)
TTLCard_SSR_ContSon1_End

TTLCard_SSR_ContSon2:	spriteHeader
	spritePiece	-$50, -8, 4, 2, -$2F, 0, 0, 0, 0		; "CONT"
	spritePiece	-$30, -8, 4, 2, -$27, 0, 0, 0, 0		; "INUE" and small oval (left half)
	spritePiece	-$10, -8, 1, 2, -$1F, 0, 0, 0, 0		; small oval (right half)
	spritePiece	$40, -8, 2, 3, -$17, 0, 0, 1, 0			; mini Sonic (foot up)
TTLCard_SSR_ContSon2_End
; Mini Tails or Knuckles (LoadSSResultContinueIcon) use line 2
TTLCard_SSR_ContIcon1:	spriteHeader
	spritePiece	-$50, -8, 4, 2, -$2F, 0, 0, 0, 0		; "CONT"
	spritePiece	-$30, -8, 4, 2, -$27, 0, 0, 0, 0		; "INUE" and small oval (left half)
	spritePiece	-$10, -8, 1, 2, -$1F, 0, 0, 0, 0		; small oval (right half)
	spritePiece	$40, -8, 2, 3, -$1D, 0, 0, 2, 0			; mini character (foot down)
TTLCard_SSR_ContIcon1_End
TTLCard_SSR_ContIcon2:	spriteHeader
	spritePiece	-$50, -8, 4, 2, -$2F, 0, 0, 0, 0		; "CONT"
	spritePiece	-$30, -8, 4, 2, -$27, 0, 0, 0, 0		; "INUE" and small oval (left half)
	spritePiece	-$10, -8, 1, 2, -$1F, 0, 0, 0, 0		; small oval (right half)
	spritePiece	$40, -8, 2, 3, -$17, 0, 0, 2, 0			; mini character (foot up)
TTLCard_SSR_ContIcon2_End

TTLCard_SSR_Continue:	spriteHeader
	spritePiece	-$50, -8, 4, 2, -$2F, 0, 0, 0, 0		; "CONT"
	spritePiece	-$30, -8, 4, 2, -$27, 0, 0, 0, 0		; "INUE" and small oval (left half)
	spritePiece	-$10, -8, 1, 2, -$1F, 0, 0, 0, 0		; small oval (right half)
TTLCard_SSR_Continue_End
	even

Unc_TitleCard:	binclude	"artunc/Title Cards Extended.unc"	; generated by s1tools player ui
Unc_TitleCard_End:
	even
	if Unc_TitleCard_End-Unc_TitleCard<>TTL_GraySmallOval+TTL_SmallOvalTiles*tile_size
		fatal "artunc/Title Cards Extended.unc does not match the title card layout"
	endif
