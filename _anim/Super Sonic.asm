; ---------------------------------------------------------------------------
; Animation scripts - Super Sonic
; Frame numbers refer to the Sonic 2 mappings imported by
; the Super Sonic resource importer. The table order matches Sonic 1.
; ---------------------------------------------------------------------------

Ani_SuperSonic:
		dc.w SupSonAni_Walk-Ani_SuperSonic	; 00
		dc.w SupSonAni_Run-Ani_SuperSonic	; 01
		dc.w SupSonAni_Roll-Ani_SuperSonic	; 02
		dc.w SupSonAni_Roll2-Ani_SuperSonic	; 03
		dc.w SupSonAni_Push-Ani_SuperSonic	; 04
		dc.w SupSonAni_Stand-Ani_SuperSonic	; 05
		dc.w SupSonAni_Balance-Ani_SuperSonic	; 06
		dc.w SupSonAni_LookUp-Ani_SuperSonic	; 07
		dc.w SupSonAni_Duck-Ani_SuperSonic	; 08
		dc.w SupSonAni_Warp1-Ani_SuperSonic	; 09
		dc.w SupSonAni_Warp2-Ani_SuperSonic	; 0A
		dc.w SupSonAni_Warp3-Ani_SuperSonic	; 0B
		dc.w SupSonAni_Warp4-Ani_SuperSonic	; 0C
		dc.w SupSonAni_Stop-Ani_SuperSonic	; 0D
		dc.w SupSonAni_Float1-Ani_SuperSonic	; 0E
		dc.w SupSonAni_Float2-Ani_SuperSonic	; 0F
		dc.w SupSonAni_Spring-Ani_SuperSonic	; 10
		dc.w SupSonAni_Hang-Ani_SuperSonic	; 11
		dc.w SupSonAni_Leap1-Ani_SuperSonic	; 12
		dc.w SupSonAni_Leap2-Ani_SuperSonic	; 13
		dc.w SupSonAni_Surf-Ani_SuperSonic	; 14
		dc.w SupSonAni_GetAir-Ani_SuperSonic	; 15
		dc.w SupSonAni_Burnt-Ani_SuperSonic	; 16
		dc.w SupSonAni_Drown-Ani_SuperSonic	; 17
		dc.w SupSonAni_Death-Ani_SuperSonic	; 18
		dc.w SupSonAni_Shrink-Ani_SuperSonic	; 19
		dc.w SupSonAni_Hurt-Ani_SuperSonic	; 1A
		dc.w SupSonAni_Slide-Ani_SuperSonic	; 1B
		dc.w SupSonAni_Null-Ani_SuperSonic	; 1C
		dc.w SupSonAni_Float3-Ani_SuperSonic	; 1D
		dc.w SupSonAni_Float4-Ani_SuperSonic	; 1E
		dc.w SupSonAni_SpinDash-Ani_SuperSonic	; 1F
		dc.w SupSonAni_Transform-Ani_SuperSonic	; 20
		dc.w SupSonAni_Figure8-Ani_SuperSonic	; 21

; Walk, run, roll and push are handled by Sonic_Animate's speed-sensitive path.
SupSonAni_Walk:	dc.b $FF,$77,$78,$79,$7A,$7B,$7C,$75,$76,$FF
		even
SupSonAni_Run:		dc.b $FF,$B5,$B9,$FF,$FF,$FF,$FF,$FF,$FF,$FF
		even
SupSonAni_Roll:	dc.b $FE,$3D,$41,$3E,$41,$3F,$41,$40,$41,$FF
		even
SupSonAni_Roll2:	dc.b $FE,$3D,$41,$3E,$41,$3F,$41,$40,$41,$FF
		even
SupSonAni_Push:	dc.b $FD,$BD,$BE,$BF,$C0,$FF,$FF,$FF,$FF,$FF
		even

SupSonAni_Stand:	dc.b 7,$72,$73,$74,$73,$FF
		even
SupSonAni_Balance:	dc.b 9,$C2,$C3,$C4,$C3,$C5,$C6,$C7,$C6,$FF
		even
SupSonAni_LookUp:	dc.b 5,$B,$C,$FE,1
		even
SupSonAni_Duck:	dc.b 5,$C1,$FF
		even
SupSonAni_Warp1:	dc.b 63,$3D,$FF
		even
SupSonAni_Warp2:	dc.b 63,$3E,$FF
		even
SupSonAni_Warp3:	dc.b 63,$3F,$FF
		even
SupSonAni_Warp4:	dc.b 63,$40,$FF
		even
SupSonAni_Stop:	dc.b 5,$D2,$D3,$D4,$D5,$FD,id_Walk
		even
SupSonAni_Float1:	dc.b 7,$54,$59,$FF
		even
SupSonAni_Float2:	dc.b 7,$54,$55,$56,$57,$58,$FF
		even
SupSonAni_Spring:	dc.b 47,$5B,$FD,id_Walk
		even
SupSonAni_Hang:	dc.b 4,$50,$51,$FF
		even
SupSonAni_Leap1:	dc.b 15,$43,$43,$43,$FE,1
		even
SupSonAni_Leap2:	dc.b 15,$43,$44,$FE,1
		even
SupSonAni_Surf:	dc.b 63,$6B,$6C,$FF
		even
SupSonAni_GetAir:	dc.b 11,$5A,$5A,$11,$12,$FD,id_Walk
		even
SupSonAni_Burnt:	dc.b 32,$5E,$FF
		even
SupSonAni_Drown:	dc.b 47,$5D,$FF
		even
SupSonAni_Death:	dc.b 3,$5C,$FF
		even
SupSonAni_Shrink:	dc.b 3,$5C,$5C,$5C,$5C,$5C,0,$FE,1
		even
SupSonAni_Hurt:	dc.b 3,$4E,$FF
		even
SupSonAni_Slide:	dc.b 7,$4E,$4F,$FF
		even
SupSonAni_Null:	dc.b 119,0,$FD,id_Walk
		even
SupSonAni_Float3:	dc.b 3,$54,$55,$56,$57,$58,$FF
		even
SupSonAni_Float4:	dc.b 3,$54,$FD,id_Walk
		even
SupSonAni_SpinDash:	dc.b 0,$42,$43,$42,$44,$42,$45,$42,$46,$42,$47,$FF
		even
SupSonAni_Transform:	dc.b 2,$6D,$6D,$6E,$6E,$6F,$70,$71,$70,$71,$70,$71,$70,$71,$FD,id_Walk
		even

SupSonAni_Figure8: dc.b $FF,$D6,$D7,$D8,$D9,$FF,$FF,$FF
	even
