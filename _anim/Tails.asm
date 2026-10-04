; Tails uses the shared gameplay animation IDs.
Ani_Tails:
        dc.w TailsAni_Walk-Ani_Tails
        dc.w TailsAni_Run-Ani_Tails
        dc.w TailsAni_Roll-Ani_Tails
        dc.w TailsAni_Roll2-Ani_Tails
        dc.w TailsAni_Push-Ani_Tails
        dc.w TailsAni_Wait-Ani_Tails
        dc.w TailsAni_Balance-Ani_Tails
        dc.w TailsAni_LookUp-Ani_Tails
        dc.w TailsAni_Duck-Ani_Tails
        dc.w TailsAni_Warp1-Ani_Tails
        dc.w TailsAni_Warp2-Ani_Tails
        dc.w TailsAni_Warp3-Ani_Tails
        dc.w TailsAni_Warp4-Ani_Tails
        dc.w TailsAni_Stop-Ani_Tails
        dc.w TailsAni_Float1-Ani_Tails
        dc.w TailsAni_Float2-Ani_Tails
        dc.w TailsAni_Spring-Ani_Tails
        dc.w TailsAni_Hang-Ani_Tails
        dc.w TailsAni_Leap1-Ani_Tails
        dc.w TailsAni_Leap2-Ani_Tails
        dc.w TailsAni_Surf-Ani_Tails
        dc.w TailsAni_GetAir-Ani_Tails
        dc.w TailsAni_Burnt-Ani_Tails
        dc.w TailsAni_Drown-Ani_Tails
        dc.w TailsAni_Death-Ani_Tails
        dc.w TailsAni_Shrink-Ani_Tails
        dc.w TailsAni_Hurt-Ani_Tails
        dc.w TailsAni_Slide-Ani_Tails
        dc.w TailsAni_Null-Ani_Tails
        dc.w TailsAni_Float3-Ani_Tails
        dc.w TailsAni_Float4-Ani_Tails
        dc.w TailsAni_SpinDash-Ani_Tails
        dc.w TailsAni_Transform-Ani_Tails ; $20
        dc.w TailsAni_Figure8-Ani_Tails
        dc.w TailsAni_Fall-Ani_Tails

TailsAni_Walk:	dc.b $FF
		dc.b fr_Walk11, fr_Walk12, fr_Walk13, fr_Walk14, fr_Walk15, fr_Walk16
		dc.b afEnd
		even

TailsAni_Run:	dc.b $FF
		dc.b fr_Run11,  fr_Run12,  fr_Run13,  fr_Run14,  afEnd,     afEnd
		dc.b afEnd
		even

TailsAni_Roll:	dc.b $FE
		dc.b fr_Roll1,  fr_Roll2,  fr_Roll3,  fr_Roll4,  fr_Roll5,  afEnd
		dc.b afEnd
		even

TailsAni_Roll2:	dc.b $FE
		dc.b fr_Roll1,  fr_Roll2,  fr_Roll5,  fr_Roll3,  fr_Roll4,  fr_Roll5
		dc.b afEnd
		even

TailsAni_Push:	dc.b $FD
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

TailsAni_Wait: dc.b 7,$80,$81,$82,$83,$84,afEnd
        even

TailsAni_Balance:	dc.b 9
		dc.b $8F,$90,$91,$92,$93,$94,$95,$96
		dc.b afEnd
		even

TailsAni_LookUp: dc.b 7,$85,$86,$87,$88,$89,afEnd
        even
TailsAni_Duck: dc.b 7,$8A,$8B,$8C,$8D,$8E,afEnd
        even

TailsAni_Warp1:	dc.b 63
		dc.b fr_Warp1
		dc.b afEnd
		even

TailsAni_Warp2:	dc.b 63
		dc.b fr_Warp2
		dc.b afEnd
		even

TailsAni_Warp3:	dc.b 63
		dc.b fr_Warp3
		dc.b afEnd
		even

TailsAni_Warp4:	dc.b 63
		dc.b fr_Warp4
		dc.b afEnd
		even

TailsAni_Stop:	dc.b 7
		dc.b fr_Stop1, fr_Stop2
		dc.b afEnd
		even

TailsAni_Float1:	dc.b 7
		dc.b fr_Float1, fr_Float4
		dc.b afEnd
		even

TailsAni_Float2:	dc.b 7
		dc.b fr_Float1, fr_Float2, fr_Float5, fr_Float3, fr_Float6
		dc.b afEnd
		even

TailsAni_Spring: dc.b 3
        dc.b fr_SpringTwirl1,fr_SpringTwirl2,fr_SpringTwirl3,fr_SpringTwirl4,fr_SpringTwirl5,afEnd
        even

TailsAni_Hang:	dc.b 4
		dc.b fr_Hang1, fr_Hang2
		dc.b afEnd
		even

TailsAni_Leap1:	dc.b 15
		dc.b fr_Leap1, fr_Leap1
		dc.b fr_Leap1 ; looped
		dc.b afBack, 1
		even

TailsAni_Leap2:	dc.b 15
		dc.b fr_Leap1
		dc.b fr_Leap2 ; looped
		dc.b afBack, 1
		even

TailsAni_Surf:	dc.b 63
		dc.b fr_Surf
		dc.b afEnd
		even

TailsAni_GetAir:	dc.b 11
		dc.b fr_GetAir, fr_GetAir, fr_Walk15, fr_Walk16
		dc.b afChange, id_Walk
		even

TailsAni_Burnt:	dc.b 32
		dc.b fr_Burnt
		dc.b afEnd
		even

TailsAni_Drown:	dc.b 47
		dc.b fr_Drown
		dc.b afEnd
		even

TailsAni_Death:	dc.b 3
		dc.b fr_Death
		dc.b afEnd
		even

TailsAni_Shrink:	dc.b 3
		dc.b fr_Shrink1, fr_Shrink2, fr_Shrink3, fr_Shrink4, fr_Shrink5
		dc.b fr_Null ; looped
		dc.b afBack, 1
		even

TailsAni_Hurt:	dc.b 3
		dc.b fr_Injury
		dc.b afEnd
		even

TailsAni_Slide:	dc.b 7
		dc.b fr_Injury, fr_Slide
		dc.b afEnd
		even

TailsAni_Null:	dc.b 119
		dc.b fr_Null
		dc.b afChange, id_Walk
		even

TailsAni_Float3:	dc.b 3
		dc.b fr_Float1, fr_Float2, fr_Float5, fr_Float3, fr_Float6
		dc.b afEnd
		even

TailsAni_Float4:	dc.b 3
		dc.b fr_Float1
		dc.b afChange, id_Walk
		even

TailsAni_SpinDash:
		dc.b 0, fr_SpinDash1, fr_SpinDash2, fr_SpinDash1, fr_SpinDash3
		dc.b fr_SpinDash1, fr_SpinDash4, fr_SpinDash1, fr_SpinDash5
		dc.b fr_SpinDash1, fr_SpinDash6, afEnd
		even

TailsAni_Figure8: dc.b $FF,fr_Run11,fr_Run12,fr_Run13,fr_Run14,afEnd,afEnd,afEnd
        even

; A relaxed walking cycle on spring descent; the S3K CB/CC poses are death.
TailsAni_Fall: dc.b 3,fr_Walk11,fr_Walk12,fr_Walk13,fr_Walk14,fr_Walk15,fr_Walk16,afEnd

; S3K Super transformation: curl, pose and flash (frames $EB-$ED).
TailsAni_Transform: dc.b 2,fr_TailsTransform,fr_TailsTransform,fr_TailsTransform+1,fr_TailsTransform+2,fr_TailsTransform+1,fr_TailsTransform+2,fr_TailsTransform+1,fr_TailsTransform+2,fr_TailsTransform+1,fr_TailsTransform+2,fr_TailsTransform+1,fr_TailsTransform+2,afChange,id_Walk
		even
	even
