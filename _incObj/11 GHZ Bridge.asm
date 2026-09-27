; ===========================================================================
; ---------------------------------------------------------------------------
; Object 11 - GHZ bridge (the main object, for the stumps refer to Object 1C)
; ---------------------------------------------------------------------------

Bridge:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Bri_Index(pc,d0.w),d1
		jmp	Bri_Index(pc,d1.w)
; ===========================================================================
Bri_Index:	dc.w Bri_Main-Bri_Index		; 0
		dc.w Bri_Action-Bri_Index	; 2
		dc.w Bri_StoodOn-Bri_Index	; 4
		dc.w Bri_Delete-Bri_Index	; 6
		dc.w Bri_Delete-Bri_Index	; 8
		dc.w Bri_ChildLog-Bri_Index	; A

; The logs are no longer one object each. They form two groups of consecutive
; logs, each drawn by one object as its own frame plus sub-sprites (#104):
;	helper - logs 0 to bridge_split-1, anchored on log 0 (routine $A)
;	parent - logs bridge_split to bridge_children-1, anchored on its own log
; Every anchor's obY is its log's Y-position and every sub-sprite Y offset is
; relative to it, so each log lands on the same Y as the old child objects.
; A 16-log bridge takes 2 object slots instead of 16.

bridge_children:	equ obSubtype		; number of logs Sonic can stand on, initially retrieved from subtype ($28)
bridge_origY:		equ obAnim		; initial Y-position (2 bytes, $1C-$1D; the bridge never animates)
bridge_helper:		equ obTimeFrame		; RAM index of the helper object drawing the left logs (0 = none)
bridge_split:		equ obDelayAni		; number of logs drawn by the helper (logs left of the parent)
bridge_nudge:		equ objoff_3E		; general nudge Y-offset while Sonic is on bridge
bridge_currentlog:	equ objoff_3F		; 0-based index of log Sonic is currently standing on
bridge_maxlogs:		equ 16			; the bend tables cover up to 16 logs

	if bridge_nudge<subspr_data+subspr_size*subspr_max
		fatal "GHZ bridge variables overlap the sub-sprite entries."
	endif
	if (subspr_x<>0)||(subspr_y<>1)||(subspr_frame<>2)||(subspr_size<>3)
		fatal "Bri_InitGroup and Bri_MoveSonic assume X/Y/frame sub-sprite entries of 3 bytes."
	endif
	if (bridge_maxlogs/2>subspr_max+1)||(bridge_maxlogs-bridge_maxlogs/2>subspr_max+1)
		fatal "A GHZ bridge group has more logs than one object can draw."
	endif
; ===========================================================================

Bri_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)			; advance to Bri_Action
		move.l	#Map_Bri,obMap(a0)			; set mappings
		move.w	#ArtTile_GHZ_Bridge|Tile_Pal3,obGfx(a0)	; set art tile and palette line
		move.b	#sprite_cam_field|sprite_subsprites,obRender(a0) ; set to playfield-positioned mode, draw right logs as sub-sprites
		move.b	#3,obPriority(a0)			; set sprite priority
		move.b	#16/2,obActWid(a0)			; set sprite display width (one log, widened by Bri_InitGroup)
		move.w	obY(a0),bridge_origY(a0)		; remember initial Y-position

		moveq	#0,d1					; clear d1
		move.b	bridge_children(a0),d1			; get subtype for bridge
		clr.b	bridge_children(a0)			; not solid unless the helper gets loaded
		cmpi.b	#bridge_maxlogs,d1			; is the bridge longer than the bend tables?
		bls.s	.countOk				; if not, branch
		moveq	#bridge_maxlogs,d1			; clamp (longer bridges overran the SST in the original)
	.countOk:
		move.w	d1,d2					; copy bridge log count to d2
		lsr.w	#1,d2					; d2 = number of logs left of the parent
		beq.w	Bri_Action				; branch if bridge only has 1 log (the parent)
		cmpi.w	#2,d1					; does the bridge have 2 logs?
		bne.s	.findHelper				; if not, branch
		moveq	#1,d1					; only the left log is solid and bends, as in the original

	.findHelper:
	if FixBugs
		; If an object is allocated before the parent object, then
		; when the child is deleted, it will have already been queued
		; for display, which is a display-and-delete bug.
		bsr.w	FindNextFreeObj				; find next free object RAM slot
	else
		bsr.w	FindFreeObj				; find any free object RAM slot
	endif
		bne.w	Bri_Action				; if object RAM is full, keep only the parent log (like the original)
		move.b	d1,bridge_children(a0)			; set number of logs
		move.b	d2,bridge_split(a0)			; set number of logs drawn by the helper
		move.w	a1,d0					; get helper address
		subi.w	#v_objspace&$FFFF,d0			; make helper address 0-based
		lsr.w	#object_size_bits,d0			; divide by $40 (object_size)
		andi.w	#$7F,d0					; d0 = index of helper in object RAM
		move.b	d0,bridge_helper(a0)			; remember it

		move.b	#$A,obRoutine(a1)			; set helper to Bri_ChildLog (display only)
		_move.b	obID(a0),d0				; get parent object ID
		_move.b	d0,obID(a1)				; copy object ID to helper
		move.w	d2,d0					; copy number of left logs
		lsl.w	#4,d0					; multiply by $10 (16px per log)
		neg.w	d0					; make it a leftwards offset
		add.w	obX(a0),d0				; d0 = X-position of leftmost log
		move.w	d0,obX(a1)				; anchor helper on the leftmost log
		move.w	obY(a0),obY(a1)				; copy Y-position from parent
		move.l	#Map_Bri,obMap(a1)			; set mappings
		move.w	#ArtTile_GHZ_Bridge|Tile_Pal3,obGfx(a1)	; set art tile and palette line
		move.b	#sprite_cam_field|sprite_subsprites,obRender(a1) ; set to playfield-positioned mode, draw logs as sub-sprites
		move.b	#3,obPriority(a1)			; set sprite priority
		sub.w	d2,d1					; d1 = parent's own log and the logs right of it
		subq.w	#1,d2					; the helper's own frame is log 0
		bsr.w	Bri_InitGroup				; set up helper sub-sprites

		movea.l	a0,a1					; now the parent
		move.w	d1,d2					; copy number of parent logs
		subq.w	#1,d2					; the parent's own frame is its log
		bmi.s	Bri_Action				; branch if the parent isn't one of the logs (2-log bridge)
		bsr.w	Bri_InitGroup				; set up parent sub-sprites
; ---------------------------------------------------------------------------

Bri_Action:	; Routine 2
		bsr.s	Bri_CheckOnBridge			; allow stepping on bridge (sets obRoutine = 4 (Bri_StoodOn) on enter)

		tst.b	bridge_nudge(a0)			; has bridge nudge gone back to 0?
		beq.s	.display				; if yes, branch
		subq.b	#4,bridge_nudge(a0)			; reduce nudging while Sonic isn't on bridge
		bsr.w	Bri_Bend				; update bridge bend for nudge

.display:
	if FixBugs=0
		; This has been moved to prevent a display-after-free bug.
		bsr.w	DisplaySprite				; display main bridge object
	endif
		bra.w	Bri_ChkDel				; delete main bridge object and all child logs if out of range

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to check if Sonic is on bridge platform
; ---------------------------------------------------------------------------

; Bri_Solid:
Bri_CheckOnBridge:
		moveq	#0,d1					; clear d1
		move.b	bridge_children(a0),d1			; get number of logs in bridge
		lsl.w	#3,d1					; multiply by 8
		move.w	d1,d2					; copy for right-side check
		addq.w	#8,d1					; d1 = left edge of bridge
		add.w	d2,d2					; d2 = right edge of bridge
		lea	(v_player).w,a1				; load Sonic player object
		tst.w	obVelY(a1)				; is Sonic moving upwards?
		bmi.w	Plat_Exit				; if yes, ignore bridge interaction

		move.w	obX(a1),d0				; get Sonic's current X-position
		sub.w	obX(a0),d0				; d0 = Sonic's distance from center of bridge
		add.w	d1,d0					; add left edge of bridge
		bmi.w	Plat_Exit				; branch if Sonic is left of the bridge
		cmp.w	d2,d0					; is Sonic within right edge of the bridge?
		bhs.w	Plat_Exit				; if not, branch

		bra.s	Plat_NoXCheck				; continue with regular platform check, assume height is 8px
; End of function Bri_CheckOnBridge

; ===========================================================================

	; Allow Sonic stepping on platforms. This is sandwiched in here,
	; likely for being the first platform object created for the game.
	include	"_incObj/sub PlatformObject & SlopeObject.asm"

; ===========================================================================

; Bri_Platform:
Bri_StoodOn:	; Routine 4
		bsr.s	Bri_WalkOff				; allow exiting bridge (sets obRoutine = 2 (Bri_Action) on exit)

	if FixBugs=0
		; This has been moved to prevent a display-after-free bug.
		bsr.w	DisplaySprite				; display main bridge object
	endif
		bra.w	Bri_ChkDel				; delete main bridge object and all child logs if out of range

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk off a bridge
; ---------------------------------------------------------------------------

Bri_WalkOff:
		moveq	#0,d1					; clear d1
		move.b	bridge_children(a0),d1			; get number of logs in bridge
		lsl.w	#3,d1					; multiply by 8
		move.w	d1,d2					; d2 = half-width for right-side check
		addq.w	#8,d1					; d1 = half-width for left-side check
		bsr.s	ExitPlatform2				; allow Sonic exiting the bridge
		bcc.s	.return					; has Sonic exited bridge? if yes, branch

		lsr.w	#4,d0					; divide Sonic's distance from left edge by $10 (i.e. 16px per log)
		move.b	d0,bridge_currentlog(a0)		; store index of log Sonic is currently standing on

		move.b	bridge_nudge(a0),d0			; get current bridge nudge value (0-$40)
		cmpi.b	#$40,d0					; has bridge fully nudged down?
		beq.s	.bridgeBehavior				; if yes, don't depress it further
		addq.b	#4,bridge_nudge(a0)			; nudge bridge down as Sonic stands on it

	.bridgeBehavior:
		bsr.w	Bri_Bend				; update bridge bend for nudge
		bsr.w	Bri_MoveSonic				; vertically align Sonic with bridge bend

	.return:
		rts						; return
; End of function Bri_WalkOff
; ===========================================================================

	; Allow Sonic exiting platforms. This is sandwiched in here,
	; likely for being the first platform object created.
	include	"_incObj/sub ExitPlatform.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to vertically align Sonic with log he is currently standing on
; ---------------------------------------------------------------------------

Bri_MoveSonic:
		moveq	#0,d0					; clear d0
		move.b	bridge_currentlog(a0),d0		; get index of log Sonic is currently standing on
		movea.l	a0,a2					; assume a log of the parent group
		sub.b	bridge_split(a0),d0			; d0 = index within the parent group
		bhs.s	.gotGroup				; branch if Sonic is on the parent group
		add.b	bridge_split(a0),d0			; d0 = index within the helper group
		moveq	#0,d1					; clear d1
		move.b	bridge_helper(a0),d1			; get RAM index of helper
		lsl.w	#object_size_bits,d1			; multiply by $40 (object_size)
		addi.l	#v_objspace&$FFFFFF,d1			; add base object RAM offset
		movea.l	d1,a2					; a2 = helper

	.gotGroup:
		move.w	obY(a2),d1				; get Y-position of the group's anchor log
		subq.b	#1,d0					; is Sonic on the anchor log itself?
		bcs.s	.gotY					; if yes, branch
		move.w	d0,d2					; get sub-sprite index
		add.w	d0,d0
		add.w	d2,d0					; multiply by subspr_size (3)
		move.b	subspr_data+subspr_y(a2,d0.w),d2	; get log's Y offset from the anchor
		ext.w	d2
		add.w	d2,d1					; d1 = Y-position of log Sonic is standing on

	.gotY:
		lea	(v_player).w,a1				; load Sonic player object
		move.w	d1,d0					; get current Y-position of log Sonic is standing on
		subq.w	#8,d0					; align by 8px upwards
		moveq	#0,d1					; clear d1
		move.b	obHeight(a1),d1				; get Sonic's current collision height
		sub.w	d1,d0					; adjust upwards by Sonic's collision height
		move.w	d0,obY(a1)				; vertically align Sonic with currently stood-on log
		rts						; return
; End of function Bri_MoveSonic

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to bend the bridge by vertically aligning all log objects
; to the left and right of the one Sonic is currently standing on.
; ---------------------------------------------------------------------------

Bri_Bend:
		move.b	bridge_nudge(a0),d0			; get current bridge nudge value (0-$40)
		bsr.w	CalcSine				; convert it into a sine for smooth movement
		move.w	d0,d4					; backup sine result for later

		lea	(Bri_Data_Align).l,a4			; load values used to align logs to the left/right of the one being stood on
		moveq	#0,d0					; clear d0
		move.b	bridge_children(a0),d0			; get bridge log count
		lsl.w	#4,d0					; multiply by $10 bytes per data row
		moveq	#0,d3					; clear d3
		move.b	bridge_currentlog(a0),d3		; get index of log Sonic is currently standing on
		move.w	d3,d2					; d2 = number of logs to the left of Sonic (dbf count)
		add.w	d0,d3					; d3 = index in Bri_Data_Y_Max for current log
		moveq	#0,d5					; clear d5
		lea	(Bri_Data_Y_Max).l,a5			; load max Y-bend distance array
		move.b	(a5,d3.w),d5				; d5 = max Y-bend distance based on current log
		andi.w	#$F,d3					; clear upper nybble in d3
		lsl.w	#4,d3					; multiply by $10 bytes per data row
		lea	(a4,d3.w),a3				; a3 = start index in align data array for current log
		lea	-bridge_maxlogs(sp),sp			; make room for the bend of every log
		movea.l	sp,a2					; a2 = log bends (0-16px below initial Y-position)

	.loopLeftLogs:
		moveq	#0,d0					; clear d0
		move.b	(a3)+,d0				; retrieve next byte value from align data array
		addq.w	#1,d0					; increment by 1 (max ROM value is $FF, probably to save space)
		mulu.w	d5,d0					; multiply align value by max Y-bend distance
		mulu.w	d4,d0					; multiply that by the sine of the current nudge distance
		swap	d0					; move integer result into lower word
		move.b	d0,(a2)+				; store bend for current log
		dbf	d2,.loopLeftLogs			; repeat for all logs left of the one Sonic is standing on
; ---------------------------------------------------------------------------

		moveq	#0,d0					; clear d0
		move.b	bridge_children(a0),d0			; get bridge log count
		moveq	#0,d3					; clear d3
		move.b	bridge_currentlog(a0),d3		; get index of log Sonic is currently standing on
		addq.b	#1,d3					; add 1 for total subtraction
		sub.b	d0,d3					; subtract total log count from current log index
		neg.b	d3					; make result positive again
		bmi.s	.apply					; if result is still negative, skip the right side
		move.w	d3,d2					; backup result
		lsl.w	#4,d3					; multiply by $10 bytes per data row
		lea	(a4,d3.w),a3				; load row in Bri_Data_Align
		adda.w	d2,a3					; advance to first right-side log inside data row
		subq.w	#1,d2					; undo earlier +1 for dbf
		bcs.s	.apply					; if underflowed, Sonic is already standing on the rightmost log

	.loopRightLogs:
		moveq	#0,d0					; clear d0
		move.b	-(a3),d0				; retrieve PREVIOUS byte value from align data array
		addq.w	#1,d0					; increment by 1 (max ROM value is $FF, probably to save space)
		mulu.w	d5,d0					; multiply align value by max Y-bend distance
		mulu.w	d4,d0					; multiply that by the sine of the current nudge distance
		swap	d0					; move integer result into lower word
		move.b	d0,(a2)+				; store bend for current log
		dbf	d2,.loopRightLogs			; repeat for all logs right of the one Sonic is standing on
; ---------------------------------------------------------------------------

	.apply:
		movea.l	sp,a2					; a2 = bend of log 0
		moveq	#0,d1					; clear d1
		move.b	bridge_split(a0),d1			; get number of helper logs
		beq.s	.parentLogs				; branch if there is no helper
		moveq	#0,d0					; clear d0
		move.b	bridge_helper(a0),d0			; get RAM index of helper
		lsl.w	#object_size_bits,d0			; multiply by $40 (object_size)
		addi.l	#v_objspace&$FFFFFF,d0			; add base object RAM offset
		movea.l	d0,a1					; a1 = helper
		bsr.s	Bri_BendGroup				; move helper logs

	.parentLogs:
		moveq	#0,d1					; clear d1
		move.b	bridge_children(a0),d1			; get bridge log count
		sub.b	bridge_split(a0),d1			; d1 = number of parent logs
		bls.s	.return					; branch if the parent isn't one of the logs
		movea.l	a0,a1					; a1 = parent
		bsr.s	Bri_BendGroup				; move parent logs

	.return:
		lea	bridge_maxlogs(sp),sp			; free the bends
		rts						; return
; End of function Bri_Bend

; ---------------------------------------------------------------------------
; Subroutine to move one group of logs to their bends
;
; input:
;	d1.w = number of logs in group (anchor and sub-sprites, at least 1)
;	a1 = group object (helper or parent)
;	a2 = bend of the group's first log (advanced past the group)
; ---------------------------------------------------------------------------

Bri_BendGroup:
		move.b	(a2)+,d2				; get bend of anchor log
		moveq	#0,d0					; clear d0
		move.b	d2,d0					; copy bend
		add.w	bridge_origY(a0),d0			; add initial Y-position
		move.w	d0,obY(a1)				; update Y-position for anchor log
		lea	subspr_data+subspr_y(a1),a3		; a3 = Y offset of first sub-sprite log
		subq.w	#2,d1					; -1 for anchor, -1 for dbf
		bcs.s	.return					; branch if the anchor is the only log

	.loopLogs:
		move.b	(a2)+,d0				; get bend of next log
		sub.b	d2,d0					; make it relative to the anchor log
		move.b	d0,(a3)					; update Y offset for current log
		addq.w	#subspr_size,a3				; next sub-sprite
		dbf	d1,.loopLogs				; repeat for the rest of the group

	.return:
		rts						; return
; End of function Bri_BendGroup

; ---------------------------------------------------------------------------
; GHZ bridge-bending data
; (Defines how the bridge bends when Sonic walks across it)
; ---------------------------------------------------------------------------

_ = 0	; for readability of out-of-bounds bytes

; Obj11_BendData:
Bri_Data_Y_Max:	; Y-distance each log is moved down when stood on (only 12 logs are ever used in-game)
		dc.b _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _	; 0 logs (invalid)
		dc.b 2,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _	; 1 log
		dc.b 2,  2,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _	; 2 logs
		dc.b 2,  4,  2,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _	; 3 logs
		dc.b 2,  4,  4,  2,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _	; 4 logs
		dc.b 2,  4,  6,  4,  2,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _	; 5 logs
		dc.b 2,  4,  6,  6,  4,  2,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _	; 6 logs
		dc.b 2,  4,  6,  8,  6,  4,  2,  _,  _,  _,  _,  _,  _,  _,  _,  _	; 7 logs
		dc.b 2,  4,  6,  8,  8,  6,  4,  2,  _,  _,  _,  _,  _,  _,  _,  _	; 8 logs
		dc.b 2,  4,  6,  8, 10,  8,  6,  4,  2,  _,  _,  _,  _,  _,  _,  _	; 9 logs
		dc.b 2,  4,  6,  8, 10, 10,  8,  6,  4,  2,  _,  _,  _,  _,  _,  _	; 10 logs
		dc.b 2,  4,  6,  8, 10, 12, 10,  8,  6,  4,  2,  _,  _,  _,  _,  _	; 11 logs
		dc.b 2,  4,  6,  8, 10, 12, 12, 10,  8,  6,  4,  2,  _,  _,  _,  _	; 12 logs
		dc.b 2,  4,  6,  8, 10, 12, 14, 12, 10,  8,  6,  4,  2,  _,  _,  _	; 13 logs
		dc.b 2,  4,  6,  8, 10, 12, 14, 14, 12, 10,  8,  6,  4,  2,  _,  _	; 14 logs
		dc.b 2,  4,  6,  8, 10, 12, 14, 16, 14, 12, 10,  8,  6,  4,  2,  _	; 15 logs
		dc.b 2,  4,  6,  8, 10, 12, 14, 16, 16, 14, 12, 10,  8,  6,  4,  2	; 16 logs
		even

; Obj11_BendData2:
Bri_Data_Align:	; Values used to align logs to the left & right of the one being stood on
		dc.b $FF,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _	; standing on log 0
		dc.b $B5, $FF,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _	; standing on log 1
		dc.b $7E, $DB, $FF,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _	; standing on log 2
		dc.b $61, $B5, $EC, $FF,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _	; standing on log 3
		dc.b $4A, $93, $CD, $F3, $FF,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _	; standing on log 4
		dc.b $3E, $7E, $B0, $DB, $F6, $FF,   _,   _,   _,   _,   _,   _,   _,   _,   _,   _	; standing on log 5
		dc.b $38, $6D, $9D, $C5, $E4, $F8, $FF,   _,   _,   _,   _,   _,   _,   _,   _,   _	; standing on log 6
		dc.b $31, $61, $8E, $B5, $D4, $EC, $FB, $FF,   _,   _,   _,   _,   _,   _,   _,   _	; standing on log 7
		dc.b $2B, $56, $7E, $A2, $C1, $DB, $EE, $FB, $FF,   _,   _,   _,   _,   _,   _,   _	; standing on log 8
		dc.b $25, $4A, $73, $93, $B0, $CD, $E1, $F3, $FC, $FF,   _,   _,   _,   _,   _,   _	; standing on log 9
		dc.b $1F, $44, $67, $88, $A7, $BD, $D4, $E7, $F4, $FD, $FF,   _,   _,   _,   _,   _	; standing on log 10
		dc.b $1F, $3E, $5C, $7E, $98, $B0, $C9, $DB, $EA, $F6, $FD, $FF,   _,   _,   _,   _	; standing on log 11
		dc.b $19, $38, $56, $73, $8E, $A7, $BD, $D1, $E1, $EE, $F8, $FE, $FF,   _,   _,   _	; standing on log 12
		dc.b $19, $38, $50, $6D, $83, $9D, $B0, $C5, $D8, $E4, $F1, $F8, $FE, $FF,   _,   _	; standing on log 13
		dc.b $19, $31, $4A, $67, $7E, $93, $A7, $BD, $CD, $DB, $E7, $F3, $F9, $FE, $FF,   _	; standing on log 14
		dc.b $19, $31, $4A, $61, $78, $8E, $A2, $B5, $C5, $D4, $E1, $EC, $F4, $FB, $FE, $FF	; standing on log 15
		even

; ===========================================================================

Bri_ChkDel:
		out_of_range.w	.deleteBridge			; has bridge gone out of range? if yes, delete it with all child logs
	if FixBugs
		; This has been moved to prevent a display-after-free bug.
		bra.w	DisplaySprite				; display main bridge object
	else
		rts						; return
	endif
; ---------------------------------------------------------------------------

.deleteBridge:
		moveq	#0,d0					; clear d0
		move.b	bridge_helper(a0),d0			; get RAM index of helper
		beq.s	.deleteParentLog			; branch if there is no helper
		lsl.w	#object_size_bits,d0			; multiply by $40 (object_size)
		addi.l	#v_objspace&$FFFFFF,d0			; add base object RAM offset
		movea.l	d0,a1					; move result to a1 as input for DeleteChild
		bsr.w	DeleteChild				; delete helper

	.deleteParentLog:
		bsr.w	DeleteObject				; finally, delete main parent log itself
		rts						; return
; ===========================================================================

Bri_Delete:	; Routine 6/8 (unused?)
		bsr.w	DeleteObject				; delete object
		rts						; return
; ===========================================================================

; Bri_Display:
Bri_ChildLog:	; Routine $A
		; Note: The helper is updated and deleted through the parent object!
		bsr.w	DisplaySprite				; just display helper logs
		rts						; return

; ---------------------------------------------------------------------------
; Subroutine to lay out a flat group of logs as sub-sprites, 16px apart to
; the right of the anchor log, and widen the display width to cover them
;
; input:
;	d2.w = number of sub-sprite logs (0-7)
;	a1 = group object (helper or parent)
; ---------------------------------------------------------------------------

Bri_InitGroup:
		move.b	d2,obSubSprites(a1)			; set number of sub-sprite logs
		move.w	d2,d0					; copy it
		lsl.w	#4,d0					; multiply by $10 (16px per log)
		addq.w	#16/2,d0				; add half a log
		move.b	d0,obActWid(a1)				; set sprite display width to reach the last log
		lea	subspr_data(a1),a2			; a2 = first sub-sprite entry
		moveq	#0,d0					; X offset of the anchor log
		bra.s	.next					; start with the count check
	; ---------------------------------------------------------------------------

	.loopLogs:
		addi.b	#16,d0					; position next log 16px further to the right
		move.b	d0,(a2)+				; set X offset
		clr.b	(a2)+					; set Y offset (flat until Sonic steps on)
		clr.b	(a2)+					; set log frame
	.next:
		dbf	d2,.loopLogs				; repeat for all sub-sprite logs
		rts						; return
; End of function Bri_InitGroup

; ===========================================================================

Map_Bri:	include	"_maps/Bridge.asm"
