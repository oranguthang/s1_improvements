; ===========================================================================
; ---------------------------------------------------------------------------
; Object 05 - Spin Dash Dust
; ---------------------------------------------------------------------------
SpinDust_VRAM	equ $F400
SpinDust_Frames	equ 7
; ---------------------------------------------------------------------------

SpinDust:
		moveq	#0,d0				; clear d0
		move.b	obRoutine(a0),d0		; get routine index
		move.w	SpinDust_Index(pc,d0.w),d1	; find routine in table
		jmp	SpinDust_Index(pc,d1.w)		; jump to that routine
; ===========================================================================
SpinDust_Index:	dc.w SpinDust_Init-SpinDust_Index	; [0] initialize dust object
		dc.w SpinDust_Main-SpinDust_Index	; [2] main dust object logic
; ===========================================================================

SpinDust_Init:
		addq.b	#2,obRoutine(a0)		; set to SpinDust_Main
		move.l	#Map_SpinDust,obMap(a0)		; set sprite mapping location
		ori.b	#4,obRender(a0)			; set to playfield coordinate mode
		move.b	#1,obPriority(a0)		; set sprite priority to 1 (in front of Sonic)
		move.b	#$10,obActWid(a0)		; set width to $10
		move.w	#(SpinDust_VRAM/$20),obGfx(a0)	; set VRAM location to $F400 (tile offset $7A0)

SpinDust_Main:
		lea	(v_player).w,a2			; load Sonic object to a2
		btst	#0,spindash_flag(a2)		; is a Spin Dash currently active?
		beq.s	SpinDust_Hide			; if not, don't make dust
		btst	#1,obStatus(a2)			; is Sonic airborne?
		bne.s	SpinDust_Hide			; if yes, don't make dust
		cmpi.b	#4,obRoutine(a2)		; is Sonic hurt or dying?
		bhs.s	SpinDust_Hide			; if yes, don't make dust

		move.w	obX(a2),obX(a0)			; copy Sonic's X-position to the dust object
		move.w	obY(a2),obY(a0)			; copy Sonic's Y-position to the dust object
		move.b	obRender(a2),obRender(a0)	; copy Sonic's render flags (X-flip, high-plane, etc.)

		btst	#0,(v_framebyte).w		; is this an odd frame?
		bne.s	.display			; if yes, don't advance animation (i.e. slow down by 50%)
		move.b	obFrame(a0),d0			; get current spin dust frame ID
		addq.b	#1,d0				; advance to next frame
		cmpi.b	#SpinDust_Frames,d0		; are we past the last frame now?
		blo.s	.ok				; if not, branch
		moveq	#0,d0				; reset to first frame
	.ok:	move.b	d0,obFrame(a0)			; set new frame ID

		bsr.s	LoadDustDynPLC			; update dust tiles in VRAM if necessary

	.display:
		jmp	(DisplaySprite).l		; display dust sprite
; ===========================================================================

SpinDust_Hide:
		rts					; don't display dust sprite

; ===========================================================================
; ---------------------------------------------------------------------------
; SpinDust DPLC loading subroutine, ported from Sonic 2, adapted for Sonic 1
; ---------------------------------------------------------------------------
; 	d1	Source address
; 	d2	Destination address
; 	d3	Transfer length
; ---------------------------------------------------------------------------

LoadDustDynPLC:
		moveq	#0,d0				; clear d0
		move.b	obFrame(a0),d0			; load frame number
		lea	(DustDynPLC).l,a2 		; load DPLC script
		add.w	d0,d0				; double ID (for word-based indexing)
		adda.w	(a2,d0.w),a2			; find current DPLC entry
		moveq	#0,d5				; clear d5
		move.b	(a2)+,d5			; get number of tasks in this DPLC entry
		subq.w	#1,d5				; subtract 1 from number of tasks (will be the loop count)
		bmi.w	.end				; if it underflowed, this is an empty entry, nothing to do
		move.w	#SpinDust_VRAM,d4		; load target VRAM address
	.loop:
		moveq	#0,d1				; clear d1
		move.b	(a2)+,d1			; get first byte of DPLC task
		lsl.w	#8,d1				; move it to upper byte
		move.b	(a2)+,d1			; get second byte of DPLC task
		move.w	d1,d3				; copy to d3
		lsr.w	#8,d3				; shift upper byte to lower byte
		andi.w	#$F0,d3				; only look at upper nybble
		addi.w	#$10,d3				; add 1 to that nybble
		andi.w	#$FFF,d1			; mask out that nybble in the other part
		lsl.l	#5,d1				; multiply by 32
		addi.l	#Art_SpinDust,d1		; add spin dust art location
		move.w	d4,d2				; set target VRAM location
		add.w	d3,d4				; prepare next VRAM location
		add.w	d3,d4				; prepare next VRAM location
		jsr	(QueueDMATransfer).l		; queue DMA transfer (also known as "DMA_68KtoVRAM")
		dbf	d5,.loop			; repeat for number of entries
	.end:
		rts					; return

; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - Spin Dash Dust
; ---------------------------------------------------------------------------

Map_SpinDust:	mappingsTable
	mappingsTableEntry.w Map_SpinDust_0
	mappingsTableEntry.w Map_SpinDust_1
	mappingsTableEntry.w Map_SpinDust_2
	mappingsTableEntry.w Map_SpinDust_3
	mappingsTableEntry.w Map_SpinDust_4
	mappingsTableEntry.w Map_SpinDust_5
	mappingsTableEntry.w Map_SpinDust_6

Map_SpinDust_0:	spriteHeader
	spritePiece -32, 4, 4, 2, 0, 0, 0, 0, 0
Map_SpinDust_0_End

Map_SpinDust_1:	spriteHeader
	spritePiece -32, 4, 4, 2, 0, 0, 0, 0, 0
Map_SpinDust_1_End

Map_SpinDust_2:	spriteHeader
	spritePiece -32, 4, 4, 2, 0, 0, 0, 0, 0
Map_SpinDust_2_End

Map_SpinDust_3:	spriteHeader
	spritePiece -24, -12, 1, 2, 0, 0, 0, 0, 0
	spritePiece -32, 4, 4, 2, 2, 0, 0, 0, 0
Map_SpinDust_3_End

Map_SpinDust_4:	spriteHeader
	spritePiece -24, -12, 2, 2, 0, 0, 0, 0, 0
	spritePiece -32, 4, 4, 2, 4, 0, 0, 0, 0
Map_SpinDust_4_End

Map_SpinDust_5:	spriteHeader
	spritePiece -32, -12, 3, 2, 0, 0, 0, 0, 0
	spritePiece -32, 4, 4, 2, 6, 0, 0, 0, 0
Map_SpinDust_5_End

Map_SpinDust_6:	spriteHeader
	spritePiece -32, -12, 3, 2, 0, 0, 0, 0, 0
	spritePiece -32, 4, 4, 2, 6, 0, 0, 0, 0
Map_SpinDust_6_End

	even

; ===========================================================================
; ---------------------------------------------------------------------------
; Dynamic Pattern Loading Cues - Spin Dash Dust
; ---------------------------------------------------------------------------

DustDynPLC:	mappingsTable
	mappingsTableEntry.w DustDynPLC_0
	mappingsTableEntry.w DustDynPLC_1
	mappingsTableEntry.w DustDynPLC_2
	mappingsTableEntry.w DustDynPLC_3
	mappingsTableEntry.w DustDynPLC_4
	mappingsTableEntry.w DustDynPLC_5
	mappingsTableEntry.w DustDynPLC_6

DustDynPLC_0:	dplcHeader
	dplcEntry	8, 0
DustDynPLC_0_End

DustDynPLC_1:	dplcHeader
	dplcEntry	8, 8
DustDynPLC_1_End

DustDynPLC_2:	dplcHeader
	dplcEntry	8, 16
DustDynPLC_2_End

DustDynPLC_3:	dplcHeader
	dplcEntry	10, 24
DustDynPLC_3_End

DustDynPLC_4:	dplcHeader
	dplcEntry	12, 34
DustDynPLC_4_End

DustDynPLC_5:	dplcHeader
	dplcEntry	14, 46
DustDynPLC_5_End

DustDynPLC_6:	dplcHeader
	dplcEntry	14, 60
DustDynPLC_6_End

	even
