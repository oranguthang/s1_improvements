; Dynamic character resources, adapted from Selbi's guide:
; https://info.sonicretro.org/SCHG_How-to:Add_Extra_Characters
; ROM pointers avoid a shared RAM cache that would mix two player selections.

; d0.w = slot (0/1), d1.b = form (0 normal/nonzero Super), output a3.
; Invalid slots/IDs fall back to Sonic. Preserve all other registers and CCR.
GetCharacterAssets:
        move.w sr,-(sp)
        movem.l d0-d2,-(sp)
        cmpi.w #1,d0
        bls.s .slot
        moveq #0,d0
.slot:
        lea (v_character_p1).w,a3
        moveq #0,d2
        move.b (a3,d0.w),d2
        cmpi.w #Character_Count,d2
        blo.s .valid
        moveq #Character_Sonic,d2
.valid:
        lsl.w #3,d2
        tst.b d1
        beq.s .normal
        addq.w #4,d2
.normal:
        lea (CharacterAssets).l,a3
        movea.l (a3,d2.w),a3
        movem.l (sp)+,d0-d2
        move.w (sp)+,ccr
        rts

GetPlayer1Assets_Normal:
        move.w sr,-(sp)
        movem.l d0-d1,-(sp)
        moveq #0,d0
        moveq #0,d1
        bra.s GetPlayer1Assets_Finish
GetPlayer1Assets_Super:
        move.w sr,-(sp)
        movem.l d0-d1,-(sp)
        moveq #0,d0
        moveq #1,d1
        bra.s GetPlayer1Assets_Finish
GetPlayer1Assets_Current:
        move.w sr,-(sp)
        movem.l d0-d1,-(sp)
        moveq #0,d0
        move.b (v_supersonic).w,d1
GetPlayer1Assets_Finish:
        bsr.w GetCharacterAssets
        movem.l (sp)+,d0-d1
        move.w (sp)+,ccr
        rts

; Output d0.w = normal palette ID. Preserve address registers.
GetPlayerPaletteID:
        move.l a3,-(sp)
        bsr.w GetPlayer1Assets_Normal
        moveq #0,d0
        move.b CharacterAsset_PaletteID(a3),d0
        movea.l (sp)+,a3
        rts

; Keep Sonic's per-act palette overrides; other characters own their palettes.
; Input a2 = act header. Output d0.w = normal underwater palette ID.
GetPlayerWaterPaletteID:
        moveq #0,d0
        move.b LevelHeader_WaterSonic(a2),d0
        cmpi.b #Character_Sonic,(v_character_p1).w
        beq.s .return
        cmpi.b #Character_Count,(v_character_p1).w
        bhs.s .return
        move.l a3,-(sp)
        bsr.w GetPlayer1Assets_Normal
        move.b CharacterAsset_WaterID(a3),d0
        cmpi.w #id_LZ_act4,(v_zone_act).w
        bne.s .restore
        move.b CharacterAsset_SBZ3ID(a3),d0
.restore:
        movea.l (sp)+,a3
.return:
        rts

LoadPlayerHUD:
        move.l a3,-(sp)
        bsr.w GetPlayer1Assets_Normal
        moveq #0,d0
        move.b CharacterAsset_HUD(a3),d0
        movea.l (sp)+,a3
        jmp (AddPLC).l

; Screens with their own palettes retain the shared colours and tint only fur.
ApplyPlayerFadeColours:
        cmpi.b #Character_Sonic,(v_character_p1).w
        beq.s .return
        movem.l a1/a3,-(sp)
        bsr.w GetPlayer1Assets_Normal
        movea.l CharacterAsset_Palette(a3),a1
        move.l 4(a1),(v_palette_fading+4).w
        move.l 8(a1),(v_palette_fading+8).w
        movem.l (sp)+,a1/a3
.return:
        rts

CharacterAssets:
        dc.l CharacterAssets_Sonic,CharacterAssets_SuperSonic
        dc.l CharacterAssets_Tails,CharacterAssets_Tails ; no Super Tails yet
        dc.l CharacterAssets_Knuckles,CharacterAssets_Knuckles ; no Super Knuckles yet
CharacterAssets_End:
        if (CharacterAssets_End-CharacterAssets)<>Character_Count*8
        fatal "Character table count mismatch"
        endif
CharacterAssets_Sonic:
        dc.l Art_Sonic,Map_Sonic,SonicDynPLC,Ani_Sonic
        dc.l Pal_Sonic,Pal_LZSonWater,Pal_SBZ3SonWat
        dc.l Pal_SuperSonicCycle,Pal_SuperSonicCycle_LZWater,Pal_SuperSonicCycle_SBZ3Water
        dc.l SonAni_Run,SonAni_Walk,SonAni_Roll,SonAni_Roll2,SonAni_Push,SonAni_Figure8
        dc.l Art_Sonic
        dc.b 0,0,palid_Sonic,palid_LZSonWater,palid_SBZ3SonWat,plcid_PlayerHUD
CharacterAssets_SuperSonic:
        dc.l Art_SuperSonic,Map_SuperSonic,SuperSonicDynPLC,Ani_SuperSonic
        dc.l Pal_SuperSonic,Pal_SuperSonicWater,Pal_SuperSonicSBZ3Water
        dc.l Pal_SuperSonicCycle,Pal_SuperSonicCycle_LZWater,Pal_SuperSonicCycle_SBZ3Water
        dc.l SupSonAni_Run,SupSonAni_Walk,SupSonAni_Roll,SupSonAni_Roll2,SupSonAni_Push,SonAni_Figure8
        dc.l Art_Sonic
        dc.b fr_SuperSpringTwirl1,fr_SuperAirPosesEnd
        dc.b palid_SuperSonic,palid_SuperSonicWater,palid_SuperSonicSBZ3Water,plcid_PlayerHUD
CharacterAssets_RecordsEnd:
        if (CharacterAssets_SuperSonic-CharacterAssets_Sonic)<>CharacterAsset_Size
        fatal "Normal character descriptor size mismatch"
        endif
        if (CharacterAssets_RecordsEnd-CharacterAssets_SuperSonic)<>CharacterAsset_Size
        fatal "Super character descriptor size mismatch"
        endif
CharacterAssets_Tails:
        dc.l Art_Tails,Map_Tails,TailsDynPLC,Ani_Tails
        dc.l Pal_Tails,Pal_TailsWater,Pal_TailsSBZ3Water
        dc.l Pal_SuperSonicCycle,Pal_SuperSonicCycle_LZWater,Pal_SuperSonicCycle_SBZ3Water
        dc.l TailsAni_Run,TailsAni_Walk,TailsAni_Roll,TailsAni_Roll2,TailsAni_Push,TailsAni_Figure8
        dc.l Art_Tails
        dc.b 0,0,palid_Tails,palid_TailsWater,palid_TailsSBZ3Water,plcid_TailsHUD
CharacterAssets_TailsEnd:
        if (CharacterAssets_TailsEnd-CharacterAssets_Tails)<>CharacterAsset_Size
        fatal "Tails character descriptor size mismatch"
        endif
CharacterAssets_Knuckles:
        dc.l Art_Knuckles,Map_Knuckles,KnucklesDynPLC,Ani_Knuckles
        dc.l Pal_Knuckles,Pal_KnucklesWater,Pal_KnucklesSBZ3Water
        dc.l Pal_SuperSonicCycle,Pal_SuperSonicCycle_LZWater,Pal_SuperSonicCycle_SBZ3Water
        dc.l KnucklesAni_Run,KnucklesAni_Walk,KnucklesAni_Roll,KnucklesAni_Roll2,KnucklesAni_Push,KnucklesAni_Figure8
        dc.l Art_Knuckles
        dc.b 0,0,palid_Knuckles,palid_KnucklesWater,palid_KnucklesSBZ3Water,plcid_KnucklesHUD
CharacterAssets_KnucklesEnd:
        if (CharacterAssets_KnucklesEnd-CharacterAssets_Knuckles)<>CharacterAsset_Size
        fatal "Knuckles character descriptor size mismatch"
        endif
        even
