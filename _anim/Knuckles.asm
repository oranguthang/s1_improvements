; Knuckles uses the shared gameplay animation IDs and packed S3K body art.
Ani_Knuckles:
        dc.w KnucklesAni_Walk-Ani_Knuckles
        dc.w KnucklesAni_Run-Ani_Knuckles
        dc.w KnucklesAni_Roll-Ani_Knuckles
        dc.w KnucklesAni_Roll2-Ani_Knuckles
        dc.w KnucklesAni_Push-Ani_Knuckles
        dc.w KnucklesAni_Wait-Ani_Knuckles
        dc.w KnucklesAni_Balance-Ani_Knuckles
        dc.w KnucklesAni_LookUp-Ani_Knuckles
        dc.w KnucklesAni_Duck-Ani_Knuckles
        dc.w KnucklesAni_Warp1-Ani_Knuckles
        dc.w KnucklesAni_Warp2-Ani_Knuckles
        dc.w KnucklesAni_Warp3-Ani_Knuckles
        dc.w KnucklesAni_Warp4-Ani_Knuckles
        dc.w KnucklesAni_Stop-Ani_Knuckles
        dc.w KnucklesAni_Float1-Ani_Knuckles
        dc.w KnucklesAni_Float2-Ani_Knuckles
        dc.w KnucklesAni_Spring-Ani_Knuckles
        dc.w KnucklesAni_Hang-Ani_Knuckles
        dc.w KnucklesAni_Leap1-Ani_Knuckles
        dc.w KnucklesAni_Leap2-Ani_Knuckles
        dc.w KnucklesAni_Surf-Ani_Knuckles
        dc.w KnucklesAni_GetAir-Ani_Knuckles
        dc.w KnucklesAni_Burnt-Ani_Knuckles
        dc.w KnucklesAni_Drown-Ani_Knuckles
        dc.w KnucklesAni_Death-Ani_Knuckles
        dc.w KnucklesAni_Shrink-Ani_Knuckles
        dc.w KnucklesAni_Hurt-Ani_Knuckles
        dc.w KnucklesAni_Slide-Ani_Knuckles
        dc.w KnucklesAni_Null-Ani_Knuckles
        dc.w KnucklesAni_Float3-Ani_Knuckles
        dc.w KnucklesAni_Float4-Ani_Knuckles
        dc.w KnucklesAni_SpinDash-Ani_Knuckles
        dc.w KnucklesAni_Transform-Ani_Knuckles ; $20
        dc.w KnucklesAni_Figure8-Ani_Knuckles
        dc.w KnucklesAni_Fall-Ani_Knuckles
        dc.w KnucklesAni_Victory-Ani_Knuckles

; The descriptor selects eight walking frames: Sonic_Animate adds 8 per
; floor orientation. The order follows S3K's walk script (7, 8, 1-6).
KnucklesAni_Walk:	dc.b $FF
		dc.b knux_walk_frame+6, knux_walk_frame+7, knux_walk_frame, knux_walk_frame+1
		dc.b knux_walk_frame+2, knux_walk_frame+3, knux_walk_frame+4, knux_walk_frame+5
		dc.b afEnd
		even

; Walk and run share the frame index, so the run pads to eight entries.
KnucklesAni_Run:	dc.b $FF
		dc.b fr_Run11,  fr_Run12,  fr_Run13,  fr_Run14,  afEnd,     afEnd, afEnd, afEnd
		dc.b afEnd
		even

KnucklesAni_Roll:	dc.b $FE
		dc.b fr_Roll1,  fr_Roll2,  fr_Roll3,  fr_Roll4,  fr_Roll5,  afEnd
		dc.b afEnd
		even

KnucklesAni_Roll2:	dc.b $FE
		dc.b fr_Roll1,  fr_Roll2,  fr_Roll5,  fr_Roll3,  fr_Roll4,  fr_Roll5
		dc.b afEnd
		even

KnucklesAni_Push:	dc.b $FD
		dc.b fr_Push1,  fr_Push2,  fr_Push3,  fr_Push4,  afEnd,     afEnd
		dc.b afEnd
		even

; ---------------------------------------------------------------------------
; --- Normal animations ---
; First byte denotes number of frames between each animation.
; Overview of animation flags (examples):
; 	dc.b afEnd  		; return to beginning of animation
; 	dc.b afBack, 5		; go back specified number of frames
; 	dc.b afChange, id_Surf	; switch to a different animation

	include "_anim/Knuckles - Wait.asm"	; S3K's foot tapping and dozing off (player knuckles)
; S3K's balance sequence, translated to the appended S1 frame IDs.
KnucklesAni_Balance: dc.b 3,$87,$87,$88,$88,$89,$89,$8A,$8A,$8B,$8B,$8C,$8C
        dc.b $8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D
        dc.b $8E,$8E,$8E,$8F,$8F,$8F,$90,$90,$91,$91,$92,$92,afBack,6
        even
KnucklesAni_LookUp: dc.b 5,$04,fr_LookUp,afBack,1	; raise the head once, then hold
        even
KnucklesAni_Duck: dc.b 5,fr_Duck,afEnd
        even

KnucklesAni_Warp1:	dc.b 63
		dc.b fr_Warp1
		dc.b afEnd
		even

KnucklesAni_Warp2:	dc.b 63
		dc.b fr_Warp2
		dc.b afEnd
		even

KnucklesAni_Warp3:	dc.b 63
		dc.b fr_Warp3
		dc.b afEnd
		even

KnucklesAni_Warp4:	dc.b 63
		dc.b fr_Warp4
		dc.b afEnd
		even

KnucklesAni_Stop:	dc.b 7
		dc.b fr_Stop1, fr_Stop2
		dc.b afEnd
		even

KnucklesAni_Float1:	dc.b 7
		dc.b fr_Float1, fr_Float4
		dc.b afEnd
		even

; Approximate water rotation with the ten S3K glide headings $C0..$C9.
KnucklesAni_Float2:	dc.b 3
		dc.b fr_Float1, fr_Float2, fr_Float5, fr_Float3, fr_Float6, fr_Float4, $93, $94, $95, $96
		dc.b afEnd
		even

KnucklesAni_Spring: dc.b 15,fr_Spring,afEnd
        even

KnucklesAni_Hang:	dc.b 4
		dc.b fr_Hang1, fr_Hang2
		dc.b afEnd
		even

KnucklesAni_Leap1:	dc.b 15
		dc.b fr_Leap1, fr_Leap1
		dc.b fr_Leap1 ; looped
		dc.b afBack, 1
		even

KnucklesAni_Leap2:	dc.b 15
		dc.b fr_Leap1
		dc.b fr_Leap2 ; looped
		dc.b afBack, 1
		even

KnucklesAni_Surf:	dc.b 63
		dc.b fr_Surf
		dc.b afEnd
		even

KnucklesAni_GetAir:	dc.b 11
		dc.b fr_GetAir, fr_GetAir, fr_Walk15, fr_Walk16
		dc.b afChange, id_Walk
		even

KnucklesAni_Burnt:	dc.b 32
		dc.b fr_Burnt
		dc.b afEnd
		even

KnucklesAni_Drown:	dc.b 47
		dc.b fr_Drown
		dc.b afEnd
		even

KnucklesAni_Death:	dc.b 3
		dc.b fr_Death
		dc.b afEnd
		even

KnucklesAni_Shrink:	dc.b 3
		dc.b fr_Shrink1, fr_Shrink2, fr_Shrink3, fr_Shrink4, fr_Shrink5
		dc.b fr_Null ; looped
		dc.b afBack, 1
		even

KnucklesAni_Hurt:	dc.b 3
		dc.b fr_Injury
		dc.b afEnd
		even

KnucklesAni_Slide:	dc.b 7
		dc.b fr_Injury, fr_Slide
		dc.b afEnd
		even

KnucklesAni_Null:	dc.b 119
		dc.b fr_Null
		dc.b afChange, id_Walk
		even

KnucklesAni_Float3:	dc.b 1
		dc.b fr_Float1, fr_Float2, fr_Float5, fr_Float3, fr_Float6, fr_Float4, $93, $94, $95, $96
		dc.b afEnd
		even

KnucklesAni_Float4:	dc.b 3
		dc.b fr_Float1
		dc.b afChange, id_Walk
		even

KnucklesAni_SpinDash:
		dc.b 0, fr_SpinDash1, fr_SpinDash2, fr_SpinDash1, fr_SpinDash3
		dc.b fr_SpinDash1, fr_SpinDash4, fr_SpinDash1, fr_SpinDash5
		dc.b fr_SpinDash1, fr_SpinDash6, afEnd
		even

KnucklesAni_Figure8: dc.b $FF,fr_Run11,fr_Run12,fr_Run13,fr_Run14,afEnd,afEnd,afEnd
        even

; A relaxed walking cycle on spring descent.
KnucklesAni_Fall: dc.b 3,fr_Walk11,fr_Walk12,fr_Walk13,fr_Walk14,fr_Walk15,fr_Walk16,afEnd

; S3K's victory: stand, punch, then hold the raised fist.
KnucklesAni_Victory: dc.b 5,knux_victory_frame,knux_victory_frame+1,knux_victory_frame+1,knux_victory_frame+1
	dc.b knux_victory_frame+2,knux_victory_frame+3,afBack,1

; S3K Super transformation: curl, pose and flash (frames $EB-$ED).
KnucklesAni_Transform: dc.b 2,knux_transform_frame,knux_transform_frame,knux_transform_frame+1,knux_transform_frame+2,knux_transform_frame+1,knux_transform_frame+2,knux_transform_frame+1,knux_transform_frame+2,knux_transform_frame+1,knux_transform_frame+2,knux_transform_frame+1,knux_transform_frame+2,afChange,id_Walk
		even
	even
