; Per-act resources. Each entry names actual PLC lists (including level art),
; uncompressed maps, collision index and palettes. No asset copies are needed.
LevelHeader_MainPLC: equ 0
LevelHeader_SecondPLC: equ 4
LevelHeader_Blocks: equ 8
LevelHeader_Chunks: equ $C
LevelHeader_Collision: equ $10
LevelHeader_Palette: equ $14
LevelHeader_WaterPalette: equ $15
LevelHeader_WaterSonic: equ $16
LevelHeader_Music: equ $17
LevelHeader_Size: equ $18

lhead: macro plc1,plc2,sixteen,twofivesix,collision,pal,water,sonwater,music
    dc.l plc1,plc2,sixteen,twofivesix,collision
    dc.b pal,water,sonwater,music
    endm

; zone * four acts + act. Unused fourth-act slots alias the third act.
LevelHeaderIndex:
    dc.l Header_GHZ1,Header_GHZ2,Header_GHZ3,Header_GHZ3
    dc.l Header_LZ1,Header_LZ2,Header_LZ3,Header_SBZ3
    dc.l Header_MZ1,Header_MZ2,Header_MZ3,Header_MZ3
    dc.l Header_SLZ1,Header_SLZ2,Header_SLZ3,Header_SLZ3
    dc.l Header_SYZ1,Header_SYZ2,Header_SYZ3,Header_SYZ3
    dc.l Header_SBZ1,Header_SBZ2,Header_FZ,Header_FZ
    zonewarning LevelHeaderIndex,16
    dc.l Header_Ending,Header_Ending,Header_Ending,Header_Ending
LevelHeaderIndex_end:

Header_GHZ1: lhead PLC_GHZ,PLC_GHZ2,Blk16_GHZ,Blk256_GHZ,Col_GHZ,palid_GHZ,0,0,bgm_GHZ
Header_GHZ2: lhead PLC_GHZ,PLC_GHZ2,Blk16_GHZ,Blk256_GHZ,Col_GHZ,palid_GHZ,0,0,bgm_GHZ
Header_GHZ3: lhead PLC_GHZ,PLC_GHZ2,Blk16_GHZ,Blk256_GHZ,Col_GHZ,palid_GHZ,0,0,bgm_GHZ
Header_LZ1: lhead PLC_LZ,PLC_LZ2,Blk16_LZ,Blk256_LZ,Col_LZ,palid_LZ,palid_LZWater,palid_LZSonWater,bgm_LZ
Header_LZ2: lhead PLC_LZ,PLC_LZ2,Blk16_LZ,Blk256_LZ,Col_LZ,palid_LZ,palid_LZWater,palid_LZSonWater,bgm_LZ
Header_LZ3: lhead PLC_LZ,PLC_LZ2,Blk16_LZ,Blk256_LZ,Col_LZ,palid_LZ,palid_LZWater,palid_LZSonWater,bgm_LZ
Header_MZ1: lhead PLC_MZ,PLC_MZ2,Blk16_MZ,Blk256_MZ,Col_MZ,palid_MZ,0,0,bgm_MZ
Header_MZ2: lhead PLC_MZ,PLC_MZ2,Blk16_MZ,Blk256_MZ,Col_MZ,palid_MZ,0,0,bgm_MZ
Header_MZ3: lhead PLC_MZ,PLC_MZ2,Blk16_MZ,Blk256_MZ,Col_MZ,palid_MZ,0,0,bgm_MZ
Header_SLZ1: lhead PLC_SLZ,PLC_SLZ2,Blk16_SLZ,Blk256_SLZ,Col_SLZ,palid_SLZ,0,0,bgm_SLZ
Header_SLZ2: lhead PLC_SLZ,PLC_SLZ2,Blk16_SLZ,Blk256_SLZ,Col_SLZ,palid_SLZ,0,0,bgm_SLZ
Header_SLZ3: lhead PLC_SLZ,PLC_SLZ2,Blk16_SLZ,Blk256_SLZ,Col_SLZ,palid_SLZ,0,0,bgm_SLZ
Header_SYZ1: lhead PLC_SYZ,PLC_SYZ2,Blk16_SYZ,Blk256_SYZ,Col_SYZ,palid_SYZ,0,0,bgm_SYZ
Header_SYZ2: lhead PLC_SYZ,PLC_SYZ2,Blk16_SYZ,Blk256_SYZ,Col_SYZ,palid_SYZ,0,0,bgm_SYZ
Header_SYZ3: lhead PLC_SYZ,PLC_SYZ2,Blk16_SYZ,Blk256_SYZ,Col_SYZ,palid_SYZ,0,0,bgm_SYZ
Header_SBZ1: lhead PLC_SBZ,PLC_SBZ2,Blk16_SBZ,Blk256_SBZ,Col_SBZ,palid_SBZ1,0,0,bgm_SBZ
Header_SBZ2: lhead PLC_SBZ,PLC_SBZ2,Blk16_SBZ,Blk256_SBZ,Col_SBZ,palid_SBZ2,0,0,bgm_SBZ
Header_SBZ3: lhead PLC_LZ,PLC_LZ2,Blk16_LZ,Blk256_LZ,Col_LZ,palid_SBZ3,palid_SBZ3Water,palid_SBZ3SonWat,bgm_SBZ
Header_FZ: lhead PLC_SBZ,PLC_SBZ2,Blk16_SBZ,Blk256_SBZ,Col_SBZ,palid_SBZ2,0,0,bgm_FZ
; Ending's art is prepared by its own PLC; its palette/layout context is separate.
Header_Ending: lhead 0,0,Blk16_GHZ,Blk256_GHZ,Col_GHZ,palid_Ending,0,0,bgm_Ending
    even

; Output a2=current act header, d0=index offset. Other registers are untouched.
GetLevelHeader:
    moveq #0,d0
    move.w (v_zone_act).w,d0
GetLevelHeaderFor:             ; d0.w=explicit zone/act, for cutscenes/tools
    ror.b #2,d0
    lsr.w #4,d0
    lea (LevelHeaderIndex).l,a2
    movea.l (a2,d0.w),a2
    rts
