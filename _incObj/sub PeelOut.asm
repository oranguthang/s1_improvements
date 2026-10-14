; ---------------------------------------------------------------------------
; Selbi's Super Peel-Out, adapted to our Spin Dash and solid-object code.
; Charge stays separate from inertia: solids may zero inertia every frame.
; The move launches an upright runner, not an attacking roll.
; ---------------------------------------------------------------------------
PeelOut_ChargeStep: equ 100
PeelOut_MinCharge: equ $600
PeelOut_MaxCharge: equ $1000

Sonic_PeelOut:
	if FeaturePeelOut=0
		rts						; Super Peel-Out disabled
	endif
		tst.w	(f_demo).w				; demo inputs were recorded for the original controls
		beq.s	.notDemo
		rts
	.notDemo:
        btst    #1,spindash_flag(a0)
        bne.w   .charge
        btst    #0,spindash_flag(a0)
        bne.s   .return
        tst.b   (f_slidemode).w
        bne.s   .return
        tst.w   locktime(a0)
        bne.s   .return
        tst.w   obInertia(a0)
        bne.s   .return
        move.b  (v_jpadhold2).w,d0
        andi.b  #btnUp|btnDn,d0
        cmpi.b  #btnUp,d0
        bne.s   .return
        moveq   #btnABC,d0
        and.b   (v_jpadpress2).w,d0
        beq.s   .return
        bset    #1,spindash_flag(a0)
        clr.w   spindash_count(a0)
        clr.w   obVelX(a0)
        clr.w   obVelY(a0)
        move.b  #id_Walk,obAnim(a0)
        bclr    #5,obStatus(a0)
        move.w  #sfx_PeelCharge,d0
        jsr     (QueueSound2).l
        bra.w   .stationary
.return:
        rts

.charge:
        btst    #bitUp,(v_jpadhold2).w
        beq.s   .release
        move.w  (v_sonspeedmax).w,d0
        add.w   d0,d0
        cmpi.w  #PeelOut_MaxCharge,d0
        bls.s   .maxReady
        move.w  #PeelOut_MaxCharge,d0
.maxReady:
        addi.w  #PeelOut_ChargeStep,spindash_count(a0)
        cmp.w   spindash_count(a0),d0
        bhs.s   .stationary
        move.w  d0,spindash_count(a0)
.stationary:
        clr.w   obInertia(a0)
        clr.w   obVelX(a0)
        clr.w   obVelY(a0)
        move.b  #id_Walk,obAnim(a0)
        bclr    #5,obStatus(a0)
        move.w  #$60,(v_lookshift).w
        bsr.w   Sonic_LevelBound
        bsr.w   Sonic_AnglePos
        addq.l  #4,sp                    ; return directly to Sonic_Control
        rts

.release:
        move.w  spindash_count(a0),d2
        bclr    #1,spindash_flag(a0)
        clr.w   spindash_count(a0)
        cmpi.w  #PeelOut_MinCharge,d2
        blo.s   .cancel
        btst    #0,obStatus(a0)
        beq.s   .directionReady
        neg.w   d2
.directionReady:
        move.w  d2,obInertia(a0)
        bclr    #5,obStatus(a0)
        move.b  #id_Walk,obAnim(a0)
        bsr.w   Sonic_AngleSpeed          ; includes layout-wall clipping on launch
        move.w  #sfx_Teleport,d0
        jsr     (QueueSound2).l
        bsr.w   Sonic_LevelBound
        jsr     (SpeedToPos).l
        bsr.w   Sonic_AnglePos
        bsr.w   Sonic_SlopeRepel
        addq.l  #4,sp                    ; no jump/charge/further acceleration this frame
        rts
.cancel:
        clr.w   obInertia(a0)
        move.b  #id_Wait,obAnim(a0)
        move.w  #sfx_PeelStop,d0
        jsr     (QueueSound2).l
        addq.l  #4,sp                    ; an ABC edge cannot cancel and jump together
        rts

; All interruption paths share this cleanup. Preserve registers: death/solid
; callers may retain their killing-object pointer and collision parameters.
Sonic_CancelCharge:
        jsr (Sonic_CancelLightDash).l
        btst    #1,spindash_flag(a0)
        beq.s   .clear
        movem.l d0-d1/a0-a1,-(sp)
        move.w  #sfx_PeelStop,d0
        jsr     (QueueSound2).l
        movem.l (sp)+,d0-d1/a0-a1
.clear:
        andi.b  #~3,spindash_flag(a0)
        clr.w   spindash_count(a0)
        rts
