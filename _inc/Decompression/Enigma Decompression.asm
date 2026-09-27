; ===========================================================================
; ---------------------------------------------------------------------------
; Enigma decompression algorithm
;
; input:
;	d0 = starting art tile (added to each 8x8 before writing to destination)
;	a0 = source address (must be even)
;	a1 = destination address
;
; output:
;	a0 = even address after the end of the compressed data
;	all other registers are preserved
;
; usage:
;	lea	(source).l,a0
;	lea	(destination).l,a1
;	move.w	#arttile,d0
;	bsr.w	EniDec
;
; See http://www.segaretro.org/Enigma_compression for format description
;
; Optimized with ideas from Malachi's improved Enigma decompressor: the byte
; fetch is inlined in the main loop, format entries jump straight into $10 byte
; handler slots, and handlers return through a6.
;
; Register use:
;	d4 = incremental copy word
;	d5 = bitstream, d6 = number of unread bits in d5
;	a2 = PCCVH flags bitfield (shifted left by 3)
;	a3 = starting art tile
;	a4 = literal copy word
;	a5 = number of bits in inline copy value
;	a6 = Eni_Loop
; ---------------------------------------------------------------------------

EniDec:
		movem.l	d0-d7/a1-a6,-(sp)
		lea	Eni_Loop(pc),a6				; handlers return here
		movea.w	d0,a3					; store starting art tile
		move.b	(a0)+,d0
		ext.w	d0
		movea.w	d0,a5					; store number of bits in inline copy value
		move.b	(a0)+,d0
		lsl.b	#3,d0
		movea.w	d0,a2					; store PCCVH flags bitfield
		move.w	(a0)+,d4
		add.w	a3,d4					; store incremental copy word
		movea.w	(a0)+,a4
		adda.w	a3,a4					; store literal copy word
		move.w	(a0)+,d5				; get first word in format list
		moveq	#16,d6					; initial shift value
; loc_173E:
Eni_Loop:
		subq.w	#7,d6					; assume a format list entry is 7 bits
		move.w	d5,d1
		lsr.w	d6,d1
		move.w	d1,d2					; copy format list entry
		andi.w	#$70,d1					; keep the 3 high bits (handler slot offset)
		cmpi.w	#$40,d1					; is the high bit of the entry set?
		bhs.s	.sevenbitentry
		addq.w	#1,d6					; if it isn't, the entry is actually 6 bits
		lsr.w	#1,d2
; loc_1758:
.sevenbitentry:
		cmpi.w	#9,d6					; does a new byte need to be read?
		bhs.s	.gotbits				; if not, branch
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5
.gotbits:
		andi.w	#$F,d2					; get repeat count
		jmp	EniDec_00(pc,d1.w)
; End of function EniDec

; ===========================================================================
; Handlers are exactly $10 bytes apart, indexed by the 3 high bits of the
; format list entry. 6-bit entries (00 and 01) occupy two slots each.
; ---------------------------------------------------------------------------
; loc_1768:
EniDec_00:
.loop:		move.w	d4,(a1)+				; copy incremental copy word
		addq.w	#1,d4					; increment it
		dbf	d2,.loop				; repeat
		jmp	(a6)
		nop						; padding
		nop
		nop
	if (*-EniDec_00)<>$10
		fatal "EniDec_00 must be exactly $10 bytes, but it is $\{*-EniDec_00}"
	endif
; ===========================================================================

EniDec_00_Alt:
.loop:		move.w	d4,(a1)+				; copy incremental copy word
		addq.w	#1,d4					; increment it
		dbf	d2,.loop				; repeat
		jmp	(a6)
		nop						; padding
		nop
		nop
	if (*-EniDec_00_Alt)<>$10
		fatal "EniDec_00_Alt must be exactly $10 bytes, but it is $\{*-EniDec_00_Alt}"
	endif
; ===========================================================================
; loc_1772:
EniDec_01:
.loop:		move.w	a4,(a1)+				; copy literal copy word
		dbf	d2,.loop				; repeat
		jmp	(a6)
		nop						; padding
		nop
		nop
		nop
	if (*-EniDec_01)<>$10
		fatal "EniDec_01 must be exactly $10 bytes, but it is $\{*-EniDec_01}"
	endif
; ===========================================================================

EniDec_01_Alt:
.loop:		move.w	a4,(a1)+				; copy literal copy word
		dbf	d2,.loop				; repeat
		jmp	(a6)
		nop						; padding
		nop
		nop
		nop
	if (*-EniDec_01_Alt)<>$10
		fatal "EniDec_01_Alt must be exactly $10 bytes, but it is $\{*-EniDec_01_Alt}"
	endif
; ===========================================================================
; loc_177A:
EniDec_100:
		bsr.w	EniDec_FetchInlineValue
; loc_177E:
.loop:		move.w	d1,(a1)+				; copy inline value
		dbf	d2,.loop				; repeat
		jmp	(a6)
		nop						; padding
		nop
	if (*-EniDec_100)<>$10
		fatal "EniDec_100 must be exactly $10 bytes, but it is $\{*-EniDec_100}"
	endif
; ===========================================================================
; loc_1786:
EniDec_101:
		bsr.w	EniDec_FetchInlineValue
; loc_178A:
.loop:		move.w	d1,(a1)+				; copy inline value
		addq.w	#1,d1					; increment
		dbf	d2,.loop				; repeat
		jmp	(a6)
		nop						; padding
	if (*-EniDec_101)<>$10
		fatal "EniDec_101 must be exactly $10 bytes, but it is $\{*-EniDec_101}"
	endif
; ===========================================================================
; loc_1794:
EniDec_110:
		bsr.w	EniDec_FetchInlineValue
; loc_1798:
.loop:		move.w	d1,(a1)+				; copy inline value
		subq.w	#1,d1					; decrement
		dbf	d2,.loop				; repeat
		jmp	(a6)
		nop						; padding
	if (*-EniDec_110)<>$10
		fatal "EniDec_110 must be exactly $10 bytes, but it is $\{*-EniDec_110}"
	endif
; ===========================================================================
; loc_17A2:
EniDec_111:
		cmpi.w	#$F,d2
		beq.s	EniDec_Done
; loc_17A8:
.loop:		bsr.w	EniDec_FetchInlineValue			; fetch new inline value
		move.w	d1,(a1)+				; copy it
		dbf	d2,.loop				; and repeat
		jmp	(a6)
; ===========================================================================
; loc_17C4:
EniDec_Done:
		subq.w	#1,a0					; go back by one byte
		cmpi.w	#16,d6					; were we going to start on a completely new byte?
		bne.s	.notnewbyte				; if not, branch
		subq.w	#1,a0					; and another one if needed
; loc_17CE:
.notnewbyte:
		move.w	a0,d0
		lsr.w	#1,d0					; are we on an odd byte?
		bcc.s	.evenbyte				; if not, branch
		addq.w	#1,a0					; ensure we're on an even byte
; loc_17D6:
.evenbyte:
		movem.l	(sp)+,d0-d7/a1-a6
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Part of the Enigma decompressor
; Fetches an inline copy value and stores it in d1
; ---------------------------------------------------------------------------

; loc_17DC:
EniDec_FetchInlineValue:
		move.w	a3,d3					; copy starting art tile
		move.w	a2,d1					; copy PCCVH bitfield
		add.b	d1,d1					; is the priority bit set?
		bcc.s	.skippriority				; if not, branch
		subq.w	#1,d6
		btst	d6,d5					; is the priority bit set in the inline render flags?
		beq.s	.skippriority				; if not, branch
		ori.w	#$8000,d3				; otherwise set priority bit in art tile
; loc_17EE:
.skippriority:
		add.b	d1,d1					; is the high palette line bit set?
		bcc.s	.skiphighpal				; if not, branch
		subq.w	#1,d6
		btst	d6,d5
		beq.s	.skiphighpal
		addi.w	#$4000,d3				; set second palette line bit
; loc_17FC:
.skiphighpal:
		add.b	d1,d1					; is the low palette line bit set?
		bcc.s	.skiplowpal				; if not, branch
		subq.w	#1,d6
		btst	d6,d5
		beq.s	.skiplowpal
		addi.w	#$2000,d3				; set first palette line bit
; loc_180A:
.skiplowpal:
		add.b	d1,d1					; is the vertical flip flag set?
		bcc.s	.skipyflip				; if not, branch
		subq.w	#1,d6
		btst	d6,d5
		beq.s	.skipyflip
		ori.w	#$1000,d3				; set Y-flip bit
; loc_1818:
.skipyflip:
		add.b	d1,d1					; is the horizontal flip flag set?
		bcc.s	.skipxflip				; if not, branch
		subq.w	#1,d6
		btst	d6,d5
		beq.s	.skipxflip
		ori.w	#$800,d3				; set X-flip bit
; loc_1826:
.skipxflip:
		move.w	d5,d1
		move.w	d6,d7
		sub.w	a5,d7					; subtract length in bits of inline copy value
		bcc.s	.enoughbits				; branch if a new word doesn't need to be read
		move.w	d7,d6
		addi.w	#16,d6
		neg.w	d7					; calculate bit deficit
		lsl.w	d7,d1					; and make space for that many bits
		move.b	(a0),d5					; get next byte
		rol.b	d7,d5					; and rotate the required bits into the lowest positions
		add.w	d7,d7
		and.w	EniDec_Masks-2(pc,d7.w),d5
		add.w	d5,d1					; combine upper bits with lower bits
; loc_1844:
.maskvalue:
		move.w	a5,d0					; get length in bits of inline copy value
		add.w	d0,d0
		and.w	EniDec_Masks-2(pc,d0.w),d1		; mask value appropriately
		add.w	d3,d1					; add starting art tile
		move.b	(a0)+,-(sp)				; byte goes to the high byte of the stack word
		move.w	(sp)+,d5
		move.b	(a0)+,d5				; get next word
		rts
; ===========================================================================
; loc_1856:
.enoughbits:
		beq.s	.justenough				; if the word has been exactly exhausted, branch
		lsr.w	d7,d1					; get inline copy value
		move.w	a5,d0
		add.w	d0,d0
		and.w	EniDec_Masks-2(pc,d0.w),d1		; and mask it appropriately
		add.w	d3,d1					; add starting art tile
		move.w	d7,d6					; consume the inline copy value
		cmpi.w	#9,d6					; does a new byte need to be read?
		bhs.s	.locret					; if not, branch
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5
.locret:
		rts
; ===========================================================================
; loc_1868:
.justenough:
		moveq	#16,d6					; reset shift value
		bra.s	.maskvalue
; ===========================================================================
; word_186C:
EniDec_Masks:
		dc.w	 1,    3,    7,   $F
		dc.w   $1F,  $3F,  $7F,  $FF
		dc.w  $1FF, $3FF, $7FF, $FFF
		dc.w $1FFF,$3FFF,$7FFF,$FFFF
; End of function EniDec_FetchInlineValue
