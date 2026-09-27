; ===========================================================================
; ---------------------------------------------------------------------------
; Object code execution subroutine
;
; The reserved objects (Sonic first) run before the collision response queue
; is reset, so Sonic's ReactToItem still sees the queue built on the previous
; frame. Every level object that still has a non-zero obColType after its own
; code ran is then appended to v_colqueue in RAM order. ReactToItem keeps doing
; the original render flag and obColType checks on each entry.
;
; output:
;	d7.l = OST index of last object (must not be changed by any object)
;	a0 = address of OST of last object
; ---------------------------------------------------------------------------

	; Each level object slot is executed (and thus queued) at most once per pass.
	if colqueue_entries<>(v_lvlobjend-v_lvlobjspace)/object_size
		fatal "v_colqueue must hold one entry per level object slot."
	endif

ExecuteObjects:
		lea	(v_objspace).w,a0			; set address for object RAM
		moveq	#(v_lvlobjspace-v_objspace)/object_size-1,d7 ; run the 32 reserved objects first
		moveq	#0,d0					; clear d0
		cmpi.b	#6,(v_player+obRoutine).w		; is Sonic dying?
		bhs.w	.sonic_dead				; if yes, branch to alternate logic
		bsr.s	.run_object				; execute reserved objects (Sonic reacts using last frame's queue)

		move.w	#v_colqueue,(v_colqueue_ptr).w		; reset collision response queue
		clr.b	(f_colqueue_fullscan).w			; clear full scan request
		moveq	#(v_lvlobjend-v_lvlobjspace)/object_size-1,d7 ; run the 96 level objects

.run_level_object:
		move.b	(a0),d0					; load object ID from RAM
		beq.s	.next_level_object			; if ID is 0, this is an empty object slot, branch
		add.w	d0,d0					; quadruple for...
		add.w	d0,d0					; ...long-based indexing
		movea.l	Obj_Index-4(pc,d0.w),a1			; find relevant object pointer (minus -4 because entries skip ID 00)
		jsr	(a1)					; run the object's code
		moveq	#0,d0					; clear d0 for next loop
		tst.b	obColType(a0)				; can the object interact with Sonic?
		beq.s	.next_level_object			; if not, branch
		movea.w	(v_colqueue_ptr).w,a1			; get next free queue entry
		move.w	a0,(a1)+				; queue object
		move.w	a1,(v_colqueue_ptr).w			; set next free queue entry

	.next_level_object:
		lea	object_size(a0),a0			; increase a0 to go to next object entry ($40 bytes)
		dbf	d7,.run_level_object			; loop until all objects have been executed
		rts						; return
; ===========================================================================

; loc_D348:
.run_object:
		move.b	(a0),d0					; load object ID from RAM
		beq.s	.next_object				; if ID is 0, this is an empty object slot, branch
		add.w	d0,d0					; quadruple for...
		add.w	d0,d0					; ...long-based indexing
		movea.l	Obj_Index-4(pc,d0.w),a1			; find relevant object pointer (minus -4 because entries skip ID 00)
		jsr	(a1)					; run the object's code
		moveq	#0,d0					; clear d0 for next loop

	; loc_D358:
	.next_object:
		lea	object_size(a0),a0			; increase a0 to go to next object entry ($40 bytes)
		dbf	d7,.run_object				; loop until all objects have been executed
		rts						; return
; ===========================================================================

; Separate logic while Sonic is dying, used to freeze level objects in place
; while still executing reserved objects normally (mainly Sonic himself).

; loc_D362:
.sonic_dead:
		bsr.s	.run_object				; run first 32 objects normally (reserved objects like Sonic)
		clr.w	(v_colqueue_ptr).w			; frozen objects are not queued, so invalidate the queue (forces a full scan)

		moveq	#(v_lvlobjend-v_lvlobjspace)/object_size-1,d7 ; run the remaining 96 objects in display-only mode
; loc_D368:
.display_object:
		moveq	#0,d0					; clear d0
		move.b	obID(a0),d0				; load object ID from RAM
		beq.s	.next_object_displayonly		; if ID is 0, this is an empty object slot, branch
		cmpi.b	#id_Splats,d0				; Game/Time Over art reuses part of Splats' slot
		bne.s	.frozen_art_valid
		tst.b	(v_gameovertext1).w
		bne.s	.next_object_displayonly
		tst.b	(v_gameovertext2).w
		bne.s	.next_object_displayonly
.frozen_art_valid:
		tst.b	obRender(a0)				; was object on-screen as Sonic died?
		bpl.s	.next_object_displayonly		; if not, branch
		bsr.w	DisplaySprite				; keep displaying the object as Sonic dies but don't execute it

	; loc_D378:
	.next_object_displayonly:
		lea	object_size(a0),a0			; increase a0 to go to next object entry ($40 bytes)
		dbf	d7,.display_object			; loop until all objects have been executed
		rts						; return
; End of function ExecuteObjects
