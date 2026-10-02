; Runtime-selected roll composites, separate from animation commands.
fr_TailsRollFirst equ $97
fr_TailsRollEnd equ $F7

; S3K Tails, repacked for the S1 player frame IDs.
TailsMap_internal: mappingsTable
	mappingsTableEntry.w TailsMap_00
	mappingsTableEntry.w TailsMap_01
	mappingsTableEntry.w TailsMap_02
	mappingsTableEntry.w TailsMap_03
	mappingsTableEntry.w TailsMap_04
	mappingsTableEntry.w TailsMap_05
	mappingsTableEntry.w TailsMap_06
	mappingsTableEntry.w TailsMap_07
	mappingsTableEntry.w TailsMap_08
	mappingsTableEntry.w TailsMap_09
	mappingsTableEntry.w TailsMap_0A
	mappingsTableEntry.w TailsMap_0B
	mappingsTableEntry.w TailsMap_0C
	mappingsTableEntry.w TailsMap_0D
	mappingsTableEntry.w TailsMap_0E
	mappingsTableEntry.w TailsMap_0F
	mappingsTableEntry.w TailsMap_10
	mappingsTableEntry.w TailsMap_11
	mappingsTableEntry.w TailsMap_12
	mappingsTableEntry.w TailsMap_13
	mappingsTableEntry.w TailsMap_14
	mappingsTableEntry.w TailsMap_15
	mappingsTableEntry.w TailsMap_16
	mappingsTableEntry.w TailsMap_17
	mappingsTableEntry.w TailsMap_18
	mappingsTableEntry.w TailsMap_19
	mappingsTableEntry.w TailsMap_1A
	mappingsTableEntry.w TailsMap_1B
	mappingsTableEntry.w TailsMap_1C
	mappingsTableEntry.w TailsMap_1D
	mappingsTableEntry.w TailsMap_1E
	mappingsTableEntry.w TailsMap_1F
	mappingsTableEntry.w TailsMap_20
	mappingsTableEntry.w TailsMap_21
	mappingsTableEntry.w TailsMap_22
	mappingsTableEntry.w TailsMap_23
	mappingsTableEntry.w TailsMap_24
	mappingsTableEntry.w TailsMap_25
	mappingsTableEntry.w TailsMap_26
	mappingsTableEntry.w TailsMap_27
	mappingsTableEntry.w TailsMap_28
	mappingsTableEntry.w TailsMap_29
	mappingsTableEntry.w TailsMap_2A
	mappingsTableEntry.w TailsMap_2B
	mappingsTableEntry.w TailsMap_2C
	mappingsTableEntry.w TailsMap_2D
	mappingsTableEntry.w TailsMap_2E
	mappingsTableEntry.w TailsMap_2F
	mappingsTableEntry.w TailsMap_30
	mappingsTableEntry.w TailsMap_31
	mappingsTableEntry.w TailsMap_32
	mappingsTableEntry.w TailsMap_33
	mappingsTableEntry.w TailsMap_34
	mappingsTableEntry.w TailsMap_35
	mappingsTableEntry.w TailsMap_36
	mappingsTableEntry.w TailsMap_37
	mappingsTableEntry.w TailsMap_38
	mappingsTableEntry.w TailsMap_39
	mappingsTableEntry.w TailsMap_3A
	mappingsTableEntry.w TailsMap_3B
	mappingsTableEntry.w TailsMap_3C
	mappingsTableEntry.w TailsMap_3D
	mappingsTableEntry.w TailsMap_3E
	mappingsTableEntry.w TailsMap_3F
	mappingsTableEntry.w TailsMap_40
	mappingsTableEntry.w TailsMap_41
	mappingsTableEntry.w TailsMap_42
	mappingsTableEntry.w TailsMap_43
	mappingsTableEntry.w TailsMap_44
	mappingsTableEntry.w TailsMap_45
	mappingsTableEntry.w TailsMap_46
	mappingsTableEntry.w TailsMap_47
	mappingsTableEntry.w TailsMap_48
	mappingsTableEntry.w TailsMap_49
	mappingsTableEntry.w TailsMap_4A
	mappingsTableEntry.w TailsMap_4B
	mappingsTableEntry.w TailsMap_4C
	mappingsTableEntry.w TailsMap_4D
	mappingsTableEntry.w TailsMap_4E
	mappingsTableEntry.w TailsMap_4F
	mappingsTableEntry.w TailsMap_50
	mappingsTableEntry.w TailsMap_51
	mappingsTableEntry.w TailsMap_52
	mappingsTableEntry.w TailsMap_53
	mappingsTableEntry.w TailsMap_54
	mappingsTableEntry.w TailsMap_55
	mappingsTableEntry.w TailsMap_56
	mappingsTableEntry.w TailsMap_57
	mappingsTableEntry.w TailsMap_58
	mappingsTableEntry.w TailsMap_59
	mappingsTableEntry.w TailsMap_5A
	mappingsTableEntry.w TailsMap_5B
	mappingsTableEntry.w TailsMap_5C
	mappingsTableEntry.w TailsMap_5D
	mappingsTableEntry.w TailsMap_5E
	mappingsTableEntry.w TailsMap_5F
	mappingsTableEntry.w TailsMap_60
	mappingsTableEntry.w TailsMap_61
	mappingsTableEntry.w TailsMap_62
	mappingsTableEntry.w TailsMap_63
	mappingsTableEntry.w TailsMap_64
	mappingsTableEntry.w TailsMap_65
	mappingsTableEntry.w TailsMap_66
	mappingsTableEntry.w TailsMap_67
	mappingsTableEntry.w TailsMap_68
	mappingsTableEntry.w TailsMap_69
	mappingsTableEntry.w TailsMap_6A
	mappingsTableEntry.w TailsMap_6B
	mappingsTableEntry.w TailsMap_6C
	mappingsTableEntry.w TailsMap_6D
	mappingsTableEntry.w TailsMap_6E
	mappingsTableEntry.w TailsMap_6F
	mappingsTableEntry.w TailsMap_70
	mappingsTableEntry.w TailsMap_71
	mappingsTableEntry.w TailsMap_72
	mappingsTableEntry.w TailsMap_73
	mappingsTableEntry.w TailsMap_74
	mappingsTableEntry.w TailsMap_75
	mappingsTableEntry.w TailsMap_76
	mappingsTableEntry.w TailsMap_77
	mappingsTableEntry.w TailsMap_78
	mappingsTableEntry.w TailsMap_79
	mappingsTableEntry.w TailsMap_7A
	mappingsTableEntry.w TailsMap_7B
	mappingsTableEntry.w TailsMap_7C
	mappingsTableEntry.w TailsMap_7D
	mappingsTableEntry.w TailsMap_7E
	mappingsTableEntry.w TailsMap_7F
	mappingsTableEntry.w TailsMap_80
	mappingsTableEntry.w TailsMap_81
	mappingsTableEntry.w TailsMap_82
	mappingsTableEntry.w TailsMap_83
	mappingsTableEntry.w TailsMap_84
	mappingsTableEntry.w TailsMap_85
	mappingsTableEntry.w TailsMap_86
	mappingsTableEntry.w TailsMap_87
	mappingsTableEntry.w TailsMap_88
	mappingsTableEntry.w TailsMap_89
	mappingsTableEntry.w TailsMap_8A
	mappingsTableEntry.w TailsMap_8B
	mappingsTableEntry.w TailsMap_8C
	mappingsTableEntry.w TailsMap_8D
	mappingsTableEntry.w TailsMap_8E
	mappingsTableEntry.w TailsMap_8F
	mappingsTableEntry.w TailsMap_90
	mappingsTableEntry.w TailsMap_91
	mappingsTableEntry.w TailsMap_92
	mappingsTableEntry.w TailsMap_93
	mappingsTableEntry.w TailsMap_94
	mappingsTableEntry.w TailsMap_95
	mappingsTableEntry.w TailsMap_96
	mappingsTableEntry.w TailsMap_97
	mappingsTableEntry.w TailsMap_98
	mappingsTableEntry.w TailsMap_99
	mappingsTableEntry.w TailsMap_9A
	mappingsTableEntry.w TailsMap_9B
	mappingsTableEntry.w TailsMap_9C
	mappingsTableEntry.w TailsMap_9D
	mappingsTableEntry.w TailsMap_9E
	mappingsTableEntry.w TailsMap_9F
	mappingsTableEntry.w TailsMap_A0
	mappingsTableEntry.w TailsMap_A1
	mappingsTableEntry.w TailsMap_A2
	mappingsTableEntry.w TailsMap_A3
	mappingsTableEntry.w TailsMap_A4
	mappingsTableEntry.w TailsMap_A5
	mappingsTableEntry.w TailsMap_A6
	mappingsTableEntry.w TailsMap_A7
	mappingsTableEntry.w TailsMap_A8
	mappingsTableEntry.w TailsMap_A9
	mappingsTableEntry.w TailsMap_AA
	mappingsTableEntry.w TailsMap_AB
	mappingsTableEntry.w TailsMap_AC
	mappingsTableEntry.w TailsMap_AD
	mappingsTableEntry.w TailsMap_AE
	mappingsTableEntry.w TailsMap_AF
	mappingsTableEntry.w TailsMap_B0
	mappingsTableEntry.w TailsMap_B1
	mappingsTableEntry.w TailsMap_B2
	mappingsTableEntry.w TailsMap_B3
	mappingsTableEntry.w TailsMap_B4
	mappingsTableEntry.w TailsMap_B5
	mappingsTableEntry.w TailsMap_B6
	mappingsTableEntry.w TailsMap_B7
	mappingsTableEntry.w TailsMap_B8
	mappingsTableEntry.w TailsMap_B9
	mappingsTableEntry.w TailsMap_BA
	mappingsTableEntry.w TailsMap_BB
	mappingsTableEntry.w TailsMap_BC
	mappingsTableEntry.w TailsMap_BD
	mappingsTableEntry.w TailsMap_BE
	mappingsTableEntry.w TailsMap_BF
	mappingsTableEntry.w TailsMap_C0
	mappingsTableEntry.w TailsMap_C1
	mappingsTableEntry.w TailsMap_C2
	mappingsTableEntry.w TailsMap_C3
	mappingsTableEntry.w TailsMap_C4
	mappingsTableEntry.w TailsMap_C5
	mappingsTableEntry.w TailsMap_C6
	mappingsTableEntry.w TailsMap_C7
	mappingsTableEntry.w TailsMap_C8
	mappingsTableEntry.w TailsMap_C9
	mappingsTableEntry.w TailsMap_CA
	mappingsTableEntry.w TailsMap_CB
	mappingsTableEntry.w TailsMap_CC
	mappingsTableEntry.w TailsMap_CD
	mappingsTableEntry.w TailsMap_CE
	mappingsTableEntry.w TailsMap_CF
	mappingsTableEntry.w TailsMap_D0
	mappingsTableEntry.w TailsMap_D1
	mappingsTableEntry.w TailsMap_D2
	mappingsTableEntry.w TailsMap_D3
	mappingsTableEntry.w TailsMap_D4
	mappingsTableEntry.w TailsMap_D5
	mappingsTableEntry.w TailsMap_D6
	mappingsTableEntry.w TailsMap_D7
	mappingsTableEntry.w TailsMap_D8
	mappingsTableEntry.w TailsMap_D9
	mappingsTableEntry.w TailsMap_DA
	mappingsTableEntry.w TailsMap_DB
	mappingsTableEntry.w TailsMap_DC
	mappingsTableEntry.w TailsMap_DD
	mappingsTableEntry.w TailsMap_DE
	mappingsTableEntry.w TailsMap_DF
	mappingsTableEntry.w TailsMap_E0
	mappingsTableEntry.w TailsMap_E1
	mappingsTableEntry.w TailsMap_E2
	mappingsTableEntry.w TailsMap_E3
	mappingsTableEntry.w TailsMap_E4
	mappingsTableEntry.w TailsMap_E5
	mappingsTableEntry.w TailsMap_E6
	mappingsTableEntry.w TailsMap_E7
	mappingsTableEntry.w TailsMap_E8
	mappingsTableEntry.w TailsMap_E9
	mappingsTableEntry.w TailsMap_EA
	mappingsTableEntry.w TailsMap_EB
	mappingsTableEntry.w TailsMap_EC
	mappingsTableEntry.w TailsMap_ED
	mappingsTableEntry.w TailsMap_EE
	mappingsTableEntry.w TailsMap_EF
	mappingsTableEntry.w TailsMap_F0
	mappingsTableEntry.w TailsMap_F1
	mappingsTableEntry.w TailsMap_F2
	mappingsTableEntry.w TailsMap_F3
	mappingsTableEntry.w TailsMap_F4
	mappingsTableEntry.w TailsMap_F5
	mappingsTableEntry.w TailsMap_F6

TailsMap_00: spriteHeader
TailsMap_00_End

TailsMap_01: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -21, -4, 2, 3, 12, 0, 0, 0, 0
TailsMap_01_End

TailsMap_02: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 12, 0, 0, 0, 0
TailsMap_02_End

TailsMap_03: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 12, 0, 0, 0, 0
TailsMap_03_End

TailsMap_04: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, 4, 3, 2, 12, 0, 0, 0, 0
TailsMap_04_End

TailsMap_05: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 12, 0, 0, 0, 0
TailsMap_05_End

TailsMap_06: spriteHeader
	spritePiece -28, 4, 3, 2, 0, 0, 0, 0, 0
	spritePiece -7, -16, 2, 1, 6, 0, 0, 0, 0
	spritePiece -15, -8, 3, 2, 8, 0, 0, 0, 0
	spritePiece -15, 8, 4, 2, 14, 0, 0, 0, 0
TailsMap_06_End

TailsMap_07: spriteHeader
	spritePiece -30, 4, 3, 2, 0, 0, 0, 0, 0
	spritePiece -19, -12, 4, 2, 6, 0, 0, 0, 0
	spritePiece -19, 4, 3, 1, 14, 0, 0, 0, 0
	spritePiece -19, 12, 4, 1, 17, 0, 0, 0, 0
TailsMap_07_End

TailsMap_08: spriteHeader
	spritePiece -28, 2, 3, 2, 0, 0, 0, 0, 0
	spritePiece -16, -12, 4, 2, 6, 0, 0, 0, 0
	spritePiece -16, 4, 3, 1, 14, 0, 0, 0, 0
	spritePiece -16, 12, 4, 1, 17, 0, 0, 0, 0
TailsMap_08_End

TailsMap_09: spriteHeader
	spritePiece -28, 4, 3, 2, 0, 0, 0, 0, 0
	spritePiece -8, -16, 2, 1, 6, 0, 0, 0, 0
	spritePiece -16, -8, 3, 2, 8, 0, 0, 0, 0
	spritePiece -16, 8, 4, 2, 14, 0, 0, 0, 0
TailsMap_09_End

TailsMap_0A: spriteHeader
	spritePiece -28, 4, 3, 2, 0, 0, 0, 0, 0
	spritePiece -16, -12, 4, 2, 6, 0, 0, 0, 0
	spritePiece -16, 4, 3, 1, 14, 0, 0, 0, 0
	spritePiece -16, 12, 4, 1, 17, 0, 0, 0, 0
TailsMap_0A_End

TailsMap_0B: spriteHeader
	spritePiece -28, 2, 3, 2, 0, 0, 0, 0, 0
	spritePiece -16, -12, 4, 2, 6, 0, 0, 0, 0
	spritePiece -16, 4, 3, 1, 14, 0, 0, 0, 0
	spritePiece -16, 12, 4, 1, 17, 0, 0, 0, 0
TailsMap_0B_End

TailsMap_0C: spriteHeader
	spritePiece -17, -15, 2, 1, 0, 0, 0, 0, 0
	spritePiece -17, -7, 4, 2, 2, 0, 0, 0, 0
	spritePiece -9, 9, 3, 1, 10, 0, 0, 0, 0
	spritePiece -17, 17, 3, 1, 13, 0, 0, 0, 0
TailsMap_0C_End

TailsMap_0D: spriteHeader
	spritePiece -18, -13, 3, 4, 0, 0, 0, 0, 0
	spritePiece 6, -5, 2, 3, 12, 0, 0, 0, 0
	spritePiece -18, 19, 3, 1, 18, 0, 0, 0, 0
TailsMap_0D_End

TailsMap_0E: spriteHeader
	spritePiece -13, -14, 2, 1, 0, 0, 0, 0, 0
	spritePiece -21, -6, 4, 4, 2, 0, 0, 0, 0
	spritePiece 11, 2, 1, 1, 18, 0, 0, 0, 0
TailsMap_0E_End

TailsMap_0F: spriteHeader
	spritePiece -17, -16, 3, 1, 0, 0, 0, 0, 0
	spritePiece -17, -8, 4, 2, 3, 0, 0, 0, 0
	spritePiece -17, 8, 3, 2, 11, 0, 0, 0, 0
TailsMap_0F_End

TailsMap_10: spriteHeader
	spritePiece -12, -11, 2, 1, 0, 0, 0, 0, 0
	spritePiece -20, -3, 3, 4, 2, 0, 0, 0, 0
	spritePiece 4, 5, 2, 2, 14, 0, 0, 0, 0
TailsMap_10_End

TailsMap_11: spriteHeader
	spritePiece -7, -17, 1, 1, 0, 0, 0, 0, 0
	spritePiece -15, -9, 3, 2, 1, 0, 0, 0, 0
	spritePiece -15, 7, 4, 1, 7, 0, 0, 0, 0
	spritePiece -23, 15, 4, 1, 11, 0, 0, 0, 0
TailsMap_11_End

TailsMap_12: spriteHeader
	spritePiece -8, 6, 2, 3, 0, 0, 0, 0, 0
	spritePiece -4, -18, 2, 1, 6, 0, 0, 0, 0
	spritePiece -20, -10, 4, 3, 8, 0, 0, 0, 0
TailsMap_12_End

TailsMap_13: spriteHeader
	spritePiece -8, 4, 2, 3, 0, 0, 0, 0, 0
	spritePiece -20, -14, 4, 3, 6, 0, 0, 0, 0
	spritePiece 4, 10, 1, 1, 18, 0, 0, 0, 0
TailsMap_13_End

TailsMap_14: spriteHeader
	spritePiece -8, 6, 2, 3, 0, 0, 0, 0, 0
	spritePiece -20, -12, 4, 3, 6, 0, 0, 0, 0
TailsMap_14_End

TailsMap_15: spriteHeader
	spritePiece -8, 4, 2, 3, 0, 0, 0, 0, 0
	spritePiece -4, -19, 2, 1, 6, 0, 0, 0, 0
	spritePiece -20, -11, 4, 3, 8, 0, 0, 0, 0
TailsMap_15_End

TailsMap_16: spriteHeader
	spritePiece -8, 6, 2, 3, 0, 0, 0, 0, 0
	spritePiece -20, -12, 4, 3, 6, 0, 0, 0, 0
TailsMap_16_End

TailsMap_17: spriteHeader
	spritePiece -8, 2, 2, 3, 0, 0, 0, 0, 0
	spritePiece -20, -12, 4, 3, 6, 0, 0, 0, 0
TailsMap_17_End

TailsMap_18: spriteHeader
	spritePiece -14, -20, 3, 1, 0, 0, 0, 0, 0
	spritePiece -14, -12, 4, 3, 3, 0, 0, 0, 0
	spritePiece -22, -4, 1, 2, 15, 0, 0, 0, 0
TailsMap_18_End

TailsMap_19: spriteHeader
	spritePiece -11, -27, 2, 1, 0, 0, 0, 0, 0
	spritePiece -11, -19, 3, 1, 2, 0, 0, 0, 0
	spritePiece -19, -11, 4, 3, 5, 0, 0, 0, 0
	spritePiece 13, -11, 1, 3, 17, 0, 0, 0, 0
TailsMap_19_End

TailsMap_1A: spriteHeader
	spritePiece -5, -25, 1, 1, 0, 0, 0, 0, 0
	spritePiece -13, -17, 4, 4, 1, 0, 0, 0, 0
	spritePiece -21, -9, 1, 2, 17, 0, 0, 0, 0
TailsMap_1A_End

TailsMap_1B: spriteHeader
	spritePiece -12, -20, 2, 1, 0, 0, 0, 0, 0
	spritePiece -20, -12, 4, 3, 2, 0, 0, 0, 0
	spritePiece 12, -12, 1, 3, 14, 0, 0, 0, 0
TailsMap_1B_End

TailsMap_1C: spriteHeader
	spritePiece -3, -26, 1, 1, 0, 0, 0, 0, 0
	spritePiece -3, -18, 2, 1, 1, 0, 0, 0, 0
	spritePiece -11, -10, 4, 3, 3, 0, 0, 0, 0
	spritePiece -19, -10, 1, 2, 15, 0, 0, 0, 0
TailsMap_1C_End

TailsMap_1D: spriteHeader
	spritePiece 1, -23, 1, 1, 0, 0, 0, 0, 0
	spritePiece -15, -15, 4, 3, 1, 0, 0, 0, 0
	spritePiece -23, -7, 1, 1, 13, 0, 0, 0, 0
	spritePiece 9, 9, 1, 1, 14, 0, 0, 0, 0
TailsMap_1D_End

TailsMap_1E: spriteHeader
	spritePiece -22, -12, 2, 4, 0, 0, 0, 0, 0
	spritePiece -8, -12, 3, 2, 8, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 14, 0, 0, 0, 0
	spritePiece -16, 12, 2, 1, 18, 0, 0, 0, 0
TailsMap_1E_End

TailsMap_1F: spriteHeader
	spritePiece -22, 0, 2, 1, 0, 0, 0, 0, 0
	spritePiece -8, -12, 3, 2, 2, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 8, 0, 0, 0, 0
	spritePiece -16, 12, 2, 1, 12, 0, 0, 0, 0
TailsMap_1F_End

TailsMap_20: spriteHeader
	spritePiece -22, -4, 2, 2, 0, 0, 0, 0, 0
	spritePiece -8, -12, 3, 2, 4, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 10, 0, 0, 0, 0
	spritePiece -16, 12, 2, 1, 14, 0, 0, 0, 0
TailsMap_20_End

TailsMap_21: spriteHeader
	spritePiece -22, -12, 2, 4, 0, 0, 0, 0, 0
	spritePiece -8, -12, 3, 2, 8, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 14, 0, 0, 0, 0
	spritePiece -16, 12, 2, 1, 18, 0, 0, 0, 0
TailsMap_21_End

TailsMap_22: spriteHeader
	spritePiece -27, -1, 3, 4, 0, 0, 0, 0, 0
	spritePiece -11, -17, 2, 1, 12, 0, 0, 0, 0
	spritePiece -19, -9, 3, 2, 14, 0, 0, 0, 0
	spritePiece -11, 7, 2, 2, 20, 0, 0, 0, 0
TailsMap_22_End

TailsMap_23: spriteHeader
	spritePiece -31, 3, 3, 2, 0, 0, 0, 0, 0
	spritePiece -11, -16, 2, 1, 6, 0, 0, 0, 0
	spritePiece -19, -8, 3, 2, 8, 0, 0, 0, 0
	spritePiece -11, 8, 2, 2, 14, 0, 0, 0, 0
TailsMap_23_End

TailsMap_24: spriteHeader
	spritePiece -19, 3, 2, 2, 0, 0, 0, 0, 0
	spritePiece -11, -17, 2, 1, 4, 0, 0, 0, 0
	spritePiece -19, -9, 3, 2, 6, 0, 0, 0, 0
	spritePiece -11, 7, 2, 2, 12, 0, 0, 0, 0
TailsMap_24_End

TailsMap_25: spriteHeader
	spritePiece -20, 3, 2, 3, 0, 0, 0, 0, 0
	spritePiece -11, -16, 2, 1, 6, 0, 0, 0, 0
	spritePiece -19, -8, 3, 2, 8, 0, 0, 0, 0
	spritePiece -11, 8, 2, 2, 14, 0, 0, 0, 0
TailsMap_25_End

TailsMap_26: spriteHeader
	spritePiece -20, 6, 4, 2, 0, 0, 0, 0, 0
	spritePiece -20, -16, 3, 2, 8, 0, 0, 0, 0
	spritePiece -20, 0, 4, 1, 14, 0, 0, 0, 0
	spritePiece -4, 8, 2, 1, 18, 0, 0, 0, 0
TailsMap_26_End

TailsMap_27: spriteHeader
	spritePiece -8, 6, 1, 2, 0, 0, 0, 0, 0
	spritePiece -20, -16, 3, 2, 2, 0, 0, 0, 0
	spritePiece -20, 0, 4, 1, 8, 0, 0, 0, 0
	spritePiece -4, 8, 2, 1, 12, 0, 0, 0, 0
TailsMap_27_End

TailsMap_28: spriteHeader
	spritePiece -12, 6, 2, 2, 0, 0, 0, 0, 0
	spritePiece -20, -16, 3, 2, 4, 0, 0, 0, 0
	spritePiece -20, 0, 4, 1, 10, 0, 0, 0, 0
	spritePiece -4, 8, 2, 1, 14, 0, 0, 0, 0
TailsMap_28_End

TailsMap_29: spriteHeader
	spritePiece -20, 6, 4, 2, 0, 0, 0, 0, 0
	spritePiece -20, -16, 3, 2, 8, 0, 0, 0, 0
	spritePiece -20, 0, 4, 1, 14, 0, 0, 0, 0
	spritePiece -4, 8, 2, 1, 18, 0, 0, 0, 0
TailsMap_29_End

TailsMap_2A: spriteHeader
	spritePiece -12, -7, 4, 3, 0, 0, 0, 0, 0
	spritePiece -23, -11, 4, 2, 12, 0, 0, 0, 0
	spritePiece 9, -11, 1, 2, 20, 0, 0, 0, 0
	spritePiece -15, 5, 2, 1, 22, 0, 0, 0, 0
TailsMap_2A_End

TailsMap_2B: spriteHeader
	spritePiece -7, -5, 2, 3, 0, 0, 0, 0, 0
	spritePiece -24, -11, 4, 2, 6, 0, 0, 0, 0
	spritePiece 8, -11, 1, 2, 14, 0, 0, 0, 0
	spritePiece -16, 5, 2, 1, 16, 0, 0, 0, 0
TailsMap_2B_End

TailsMap_2C: spriteHeader
	spritePiece -8, -6, 2, 2, 0, 0, 0, 0, 0
	spritePiece -23, -11, 4, 2, 4, 0, 0, 0, 0
	spritePiece 9, -11, 1, 2, 12, 0, 0, 0, 0
	spritePiece -15, 5, 2, 1, 14, 0, 0, 0, 0
TailsMap_2C_End

TailsMap_2D: spriteHeader
	spritePiece -9, -7, 3, 2, 0, 0, 0, 0, 0
	spritePiece -24, -11, 4, 2, 6, 0, 0, 0, 0
	spritePiece 8, -11, 1, 2, 14, 0, 0, 0, 0
	spritePiece -16, 5, 2, 1, 16, 0, 0, 0, 0
TailsMap_2D_End

TailsMap_2E: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_2E_End

TailsMap_2F: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_2F_End

TailsMap_30: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_30_End

TailsMap_31: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_31_End

TailsMap_32: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_32_End

TailsMap_33: spriteHeader
	spritePiece -10, -19, 3, 3, 0, 0, 0, 0, 0
	spritePiece -26, -3, 2, 1, 9, 0, 0, 0, 0
	spritePiece -26, 5, 4, 1, 11, 0, 0, 0, 0
	spritePiece -10, 13, 2, 2, 15, 0, 0, 0, 0
TailsMap_33_End

TailsMap_34: spriteHeader
	spritePiece -20, -20, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -20, 1, 1, 16, 0, 0, 0, 0
	spritePiece -12, 12, 3, 1, 17, 0, 0, 0, 0
TailsMap_34_End

TailsMap_35: spriteHeader
	spritePiece -10, -19, 3, 2, 0, 0, 0, 0, 0
	spritePiece -26, -3, 4, 2, 6, 0, 0, 0, 0
	spritePiece -10, 13, 2, 2, 14, 0, 0, 0, 0
TailsMap_35_End

TailsMap_36: spriteHeader
	spritePiece -11, -19, 3, 2, 0, 0, 0, 0, 0
	spritePiece -19, -3, 4, 1, 6, 0, 0, 0, 0
	spritePiece -19, 5, 3, 1, 10, 0, 0, 0, 0
	spritePiece -11, 13, 2, 2, 13, 0, 0, 0, 0
TailsMap_36_End

TailsMap_37: spriteHeader
	spritePiece -16, -12, 3, 2, 0, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 6, 0, 0, 0, 0
	spritePiece -8, 12, 3, 1, 10, 0, 0, 0, 0
	spritePiece -29, 2, 3, 2, 13, 0, 0, 0, 0
TailsMap_37_End

TailsMap_38: spriteHeader
	spritePiece -16, -12, 3, 2, 0, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 6, 0, 0, 0, 0
	spritePiece -8, 12, 3, 1, 10, 0, 0, 0, 0
	spritePiece -29, 2, 3, 2, 13, 0, 0, 0, 0
TailsMap_38_End

TailsMap_39: spriteHeader
	spritePiece -6, -4, 3, 3, 0, 0, 0, 0, 0
	spritePiece -21, -4, 2, 3, 9, 0, 0, 0, 0
TailsMap_39_End

TailsMap_3A: spriteHeader
	spritePiece -14, -12, 3, 1, 0, 0, 0, 0, 0
	spritePiece -22, -4, 4, 2, 3, 0, 0, 0, 0
	spritePiece -14, 12, 2, 1, 11, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_3A_End

TailsMap_3B: spriteHeader
	spritePiece -15, -12, 3, 2, 0, 0, 0, 0, 0
	spritePiece -23, 4, 4, 1, 6, 0, 0, 0, 0
	spritePiece -23, 12, 3, 1, 10, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_3B_End

TailsMap_3C: spriteHeader
	spritePiece 0, -12, 1, 1, 0, 0, 0, 0, 0
	spritePiece -24, -4, 4, 2, 1, 0, 0, 0, 0
	spritePiece 8, -4, 2, 2, 9, 0, 0, 0, 0
TailsMap_3C_End

TailsMap_3D: spriteHeader
	spritePiece -4, -12, 3, 3, 0, 0, 0, 0, 0
	spritePiece -20, -4, 2, 2, 9, 0, 0, 0, 0
TailsMap_3D_End

TailsMap_3E: spriteHeader
	spritePiece -16, -12, 4, 3, 0, 0, 0, 0, 0
TailsMap_3E_End

TailsMap_3F: spriteHeader
	spritePiece -20, -12, 3, 3, 0, 1, 0, 0, 0
	spritePiece 4, -4, 2, 2, 9, 1, 0, 0, 0
TailsMap_3F_End

TailsMap_40: spriteHeader
	spritePiece -7, -19, 2, 2, 0, 0, 0, 0, 0
	spritePiece -15, -3, 3, 4, 4, 0, 0, 0, 0
TailsMap_40_End

TailsMap_41: spriteHeader
	spritePiece -26, -14, 2, 4, 0, 0, 0, 0, 0
	spritePiece -10, -6, 3, 3, 8, 0, 0, 0, 0
TailsMap_41_End

TailsMap_42: spriteHeader
	spritePiece -18, -14, 2, 1, 0, 0, 0, 0, 0
	spritePiece -26, -6, 4, 3, 2, 0, 0, 0, 0
	spritePiece 6, -6, 1, 3, 14, 0, 0, 0, 0
TailsMap_42_End

TailsMap_43: spriteHeader
	spritePiece -28, 4, 3, 2, 0, 0, 0, 0, 0
	spritePiece -7, -16, 2, 1, 6, 0, 0, 0, 0
	spritePiece -15, -8, 3, 2, 8, 0, 0, 0, 0
	spritePiece -15, 8, 4, 2, 14, 0, 0, 0, 0
TailsMap_43_End

TailsMap_44: spriteHeader
	spritePiece -30, 4, 3, 2, 0, 0, 0, 0, 0
	spritePiece -19, -12, 4, 2, 6, 0, 0, 0, 0
	spritePiece -19, 4, 3, 1, 14, 0, 0, 0, 0
	spritePiece -19, 12, 4, 1, 17, 0, 0, 0, 0
TailsMap_44_End

TailsMap_45: spriteHeader
	spritePiece -10, -12, 3, 3, 0, 0, 0, 0, 0
	spritePiece -18, 12, 4, 1, 9, 0, 0, 0, 0
	spritePiece -29, 1, 3, 2, 13, 0, 0, 0, 0
TailsMap_45_End

TailsMap_46: spriteHeader
	spritePiece -10, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -29, 1, 3, 2, 12, 0, 0, 0, 0
TailsMap_46_End

TailsMap_47: spriteHeader
	spritePiece -10, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -29, 1, 3, 2, 12, 0, 0, 0, 0
TailsMap_47_End

TailsMap_48: spriteHeader
	spritePiece -10, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -29, 1, 3, 2, 12, 0, 0, 0, 0
TailsMap_48_End

TailsMap_49: spriteHeader
	spritePiece -11, -19, 3, 2, 0, 0, 0, 0, 0
	spritePiece -11, -3, 4, 2, 6, 0, 0, 0, 0
TailsMap_49_End

TailsMap_4A: spriteHeader
	spritePiece -10, -11, 3, 1, 0, 0, 0, 0, 0
	spritePiece -18, -3, 4, 2, 3, 0, 0, 0, 0
	spritePiece -18, 13, 3, 1, 11, 0, 0, 0, 0
TailsMap_4A_End

TailsMap_4B: spriteHeader
	spritePiece -15, -12, 4, 4, 0, 0, 0, 0, 0
TailsMap_4B_End

TailsMap_4C: spriteHeader
	spritePiece -15, -12, 4, 4, 0, 0, 0, 0, 0
TailsMap_4C_End

TailsMap_4D: spriteHeader
	spritePiece -15, -12, 4, 4, 0, 0, 0, 0, 0
TailsMap_4D_End

TailsMap_4E: spriteHeader
	spritePiece -10, -19, 3, 3, 0, 0, 0, 0, 0
	spritePiece -26, -3, 2, 1, 9, 0, 0, 0, 0
	spritePiece -26, 5, 4, 1, 11, 0, 0, 0, 0
	spritePiece -10, 13, 2, 2, 15, 0, 0, 0, 0
TailsMap_4E_End

TailsMap_4F: spriteHeader
	spritePiece -20, -20, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -20, 1, 1, 16, 0, 0, 0, 0
	spritePiece -12, 12, 3, 1, 17, 0, 0, 0, 0
TailsMap_4F_End

TailsMap_50: spriteHeader
	spritePiece -10, -19, 3, 2, 0, 0, 0, 0, 0
	spritePiece -26, -3, 4, 2, 6, 0, 0, 0, 0
	spritePiece -10, 13, 2, 2, 14, 0, 0, 0, 0
TailsMap_50_End

TailsMap_51: spriteHeader
	spritePiece -11, -19, 3, 2, 0, 0, 0, 0, 0
	spritePiece -19, -3, 4, 1, 6, 0, 0, 0, 0
	spritePiece -19, 5, 3, 1, 10, 0, 0, 0, 0
	spritePiece -11, 13, 2, 2, 13, 0, 0, 0, 0
TailsMap_51_End

TailsMap_52: spriteHeader
	spritePiece -11, -19, 3, 2, 0, 0, 0, 0, 0
	spritePiece -19, -3, 4, 1, 6, 0, 0, 0, 0
	spritePiece -19, 5, 3, 1, 10, 0, 0, 0, 0
	spritePiece -11, 13, 2, 2, 13, 0, 0, 0, 0
TailsMap_52_End

TailsMap_53: spriteHeader
	spritePiece -8, -12, 1, 1, 0, 1, 0, 0, 0
	spritePiece -8, -4, 4, 2, 1, 1, 0, 0, 0
	spritePiece -24, -4, 2, 2, 9, 1, 0, 0, 0
TailsMap_53_End

TailsMap_54: spriteHeader
	spritePiece -12, -12, 2, 1, 0, 0, 0, 0, 0
	spritePiece -20, -4, 4, 2, 2, 0, 0, 0, 0
	spritePiece 12, -4, 1, 2, 10, 0, 0, 0, 0
TailsMap_54_End

TailsMap_55: spriteHeader
	spritePiece -16, -12, 4, 4, 0, 0, 0, 0, 0
TailsMap_55_End

TailsMap_56: spriteHeader
	spritePiece -10, -11, 3, 1, 0, 0, 0, 0, 0
	spritePiece -18, -3, 4, 2, 3, 0, 0, 0, 0
	spritePiece -18, 13, 3, 1, 11, 0, 0, 0, 0
TailsMap_56_End

TailsMap_57: spriteHeader
	spritePiece -16, -12, 4, 4, 0, 0, 0, 0, 0
TailsMap_57_End

TailsMap_58: spriteHeader
	spritePiece -8, -3, 4, 1, 0, 0, 0, 0, 0
	spritePiece -8, 5, 3, 2, 4, 0, 0, 0, 0
	spritePiece -30, 1, 3, 2, 10, 0, 0, 0, 0
TailsMap_58_End

TailsMap_59: spriteHeader
	spritePiece -8, -3, 4, 2, 0, 0, 0, 0, 0
	spritePiece -8, 13, 3, 1, 8, 0, 0, 0, 0
	spritePiece -30, 1, 3, 2, 11, 0, 0, 0, 0
TailsMap_59_End

TailsMap_5A: spriteHeader
	spritePiece -8, -3, 4, 1, 0, 0, 0, 0, 0
	spritePiece -8, 5, 3, 2, 4, 0, 0, 0, 0
	spritePiece -30, 1, 3, 2, 10, 0, 0, 0, 0
TailsMap_5A_End

TailsMap_5B: spriteHeader
	spritePiece -8, -3, 4, 1, 0, 0, 0, 0, 0
	spritePiece -8, 5, 3, 2, 4, 0, 0, 0, 0
	spritePiece -30, 1, 3, 2, 10, 0, 0, 0, 0
TailsMap_5B_End

TailsMap_5C: spriteHeader
	spritePiece -8, -3, 4, 2, 0, 0, 0, 0, 0
	spritePiece -8, 13, 3, 1, 8, 0, 0, 0, 0
	spritePiece -30, 1, 3, 2, 11, 0, 0, 0, 0
TailsMap_5C_End

TailsMap_5D: spriteHeader
	spritePiece -8, -3, 4, 1, 0, 0, 0, 0, 0
	spritePiece -8, 5, 3, 2, 4, 0, 0, 0, 0
	spritePiece -30, 1, 3, 2, 10, 0, 0, 0, 0
TailsMap_5D_End

TailsMap_5E: spriteHeader
	spritePiece -22, -12, 2, 4, 0, 0, 0, 0, 0
	spritePiece -8, -12, 3, 2, 8, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 14, 0, 0, 0, 0
	spritePiece -16, 12, 2, 1, 18, 0, 0, 0, 0
TailsMap_5E_End

TailsMap_5F: spriteHeader
	spritePiece -22, 0, 2, 1, 0, 0, 0, 0, 0
	spritePiece -8, -12, 3, 2, 2, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 8, 0, 0, 0, 0
	spritePiece -16, 12, 2, 1, 12, 0, 0, 0, 0
TailsMap_5F_End

TailsMap_60: spriteHeader
	spritePiece -22, -4, 2, 2, 0, 0, 0, 0, 0
	spritePiece -8, -12, 3, 2, 4, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 10, 0, 0, 0, 0
	spritePiece -16, 12, 2, 1, 14, 0, 0, 0, 0
TailsMap_60_End

TailsMap_61: spriteHeader
	spritePiece -22, -12, 2, 4, 0, 0, 0, 0, 0
	spritePiece -8, -12, 3, 2, 8, 0, 0, 0, 0
	spritePiece -16, 4, 4, 1, 14, 0, 0, 0, 0
	spritePiece -16, 12, 2, 1, 18, 0, 0, 0, 0
TailsMap_61_End

TailsMap_62: spriteHeader
	spritePiece -27, -1, 3, 4, 0, 0, 0, 0, 0
	spritePiece -11, -17, 2, 1, 12, 0, 0, 0, 0
	spritePiece -19, -9, 3, 2, 14, 0, 0, 0, 0
	spritePiece -11, 7, 2, 2, 20, 0, 0, 0, 0
TailsMap_62_End

TailsMap_63: spriteHeader
	spritePiece -31, 3, 3, 2, 0, 0, 0, 0, 0
	spritePiece -11, -16, 2, 1, 6, 0, 0, 0, 0
	spritePiece -19, -8, 3, 2, 8, 0, 0, 0, 0
	spritePiece -11, 8, 2, 2, 14, 0, 0, 0, 0
TailsMap_63_End

TailsMap_64: spriteHeader
	spritePiece -19, 3, 2, 2, 0, 0, 0, 0, 0
	spritePiece -11, -17, 2, 1, 4, 0, 0, 0, 0
	spritePiece -19, -9, 3, 2, 6, 0, 0, 0, 0
	spritePiece -11, 7, 2, 2, 12, 0, 0, 0, 0
TailsMap_64_End

TailsMap_65: spriteHeader
	spritePiece -20, 3, 2, 3, 0, 0, 0, 0, 0
	spritePiece -11, -16, 2, 1, 6, 0, 0, 0, 0
	spritePiece -19, -8, 3, 2, 8, 0, 0, 0, 0
	spritePiece -11, 8, 2, 2, 14, 0, 0, 0, 0
TailsMap_65_End

TailsMap_66: spriteHeader
	spritePiece -20, 6, 4, 2, 0, 0, 0, 0, 0
	spritePiece -20, -16, 3, 2, 8, 0, 0, 0, 0
	spritePiece -20, 0, 4, 1, 14, 0, 0, 0, 0
	spritePiece -4, 8, 2, 1, 18, 0, 0, 0, 0
TailsMap_66_End

TailsMap_67: spriteHeader
	spritePiece -8, 6, 1, 2, 0, 0, 0, 0, 0
	spritePiece -20, -16, 3, 2, 2, 0, 0, 0, 0
	spritePiece -20, 0, 4, 1, 8, 0, 0, 0, 0
	spritePiece -4, 8, 2, 1, 12, 0, 0, 0, 0
TailsMap_67_End

TailsMap_68: spriteHeader
	spritePiece -12, 6, 2, 2, 0, 0, 0, 0, 0
	spritePiece -20, -16, 3, 2, 4, 0, 0, 0, 0
	spritePiece -20, 0, 4, 1, 10, 0, 0, 0, 0
	spritePiece -4, 8, 2, 1, 14, 0, 0, 0, 0
TailsMap_68_End

TailsMap_69: spriteHeader
	spritePiece -20, 6, 4, 2, 0, 0, 0, 0, 0
	spritePiece -20, -16, 3, 2, 8, 0, 0, 0, 0
	spritePiece -20, 0, 4, 1, 14, 0, 0, 0, 0
	spritePiece -4, 8, 2, 1, 18, 0, 0, 0, 0
TailsMap_69_End

TailsMap_6A: spriteHeader
	spritePiece -12, -7, 4, 3, 0, 0, 0, 0, 0
	spritePiece -23, -11, 4, 2, 12, 0, 0, 0, 0
	spritePiece 9, -11, 1, 2, 20, 0, 0, 0, 0
	spritePiece -15, 5, 2, 1, 22, 0, 0, 0, 0
TailsMap_6A_End

TailsMap_6B: spriteHeader
	spritePiece -7, -5, 2, 3, 0, 0, 0, 0, 0
	spritePiece -24, -11, 4, 2, 6, 0, 0, 0, 0
	spritePiece 8, -11, 1, 2, 14, 0, 0, 0, 0
	spritePiece -16, 5, 2, 1, 16, 0, 0, 0, 0
TailsMap_6B_End

TailsMap_6C: spriteHeader
	spritePiece -8, -6, 2, 2, 0, 0, 0, 0, 0
	spritePiece -23, -11, 4, 2, 4, 0, 0, 0, 0
	spritePiece 9, -11, 1, 2, 12, 0, 0, 0, 0
	spritePiece -15, 5, 2, 1, 14, 0, 0, 0, 0
TailsMap_6C_End

TailsMap_6D: spriteHeader
	spritePiece -9, -7, 3, 2, 0, 0, 0, 0, 0
	spritePiece -24, -11, 4, 2, 6, 0, 0, 0, 0
	spritePiece 8, -11, 1, 2, 14, 0, 0, 0, 0
	spritePiece -16, 5, 2, 1, 16, 0, 0, 0, 0
TailsMap_6D_End

TailsMap_6E: spriteHeader
	spritePiece -7, -19, 2, 2, 0, 0, 0, 0, 0
	spritePiece -15, -3, 3, 4, 4, 0, 0, 0, 0
TailsMap_6E_End

TailsMap_6F: spriteHeader
	spritePiece -7, -19, 2, 2, 0, 0, 0, 0, 0
	spritePiece -15, -3, 3, 4, 4, 0, 0, 0, 0
TailsMap_6F_End

TailsMap_70: spriteHeader
	spritePiece -7, -19, 2, 2, 0, 0, 0, 0, 0
	spritePiece -15, -3, 3, 4, 4, 0, 0, 0, 0
TailsMap_70_End

TailsMap_71: spriteHeader
	spritePiece -7, -19, 2, 2, 0, 0, 0, 0, 0
	spritePiece -15, -3, 3, 4, 4, 0, 0, 0, 0
TailsMap_71_End

TailsMap_72: spriteHeader
	spritePiece -7, -19, 2, 2, 0, 0, 0, 0, 0
	spritePiece -15, -3, 3, 4, 4, 0, 0, 0, 0
TailsMap_72_End

TailsMap_73: spriteHeader
	spritePiece -28, 4, 3, 2, 0, 0, 0, 0, 0
	spritePiece -7, -16, 2, 1, 6, 0, 0, 0, 0
	spritePiece -15, -8, 3, 2, 8, 0, 0, 0, 0
	spritePiece -15, 8, 4, 2, 14, 0, 0, 0, 0
TailsMap_73_End

TailsMap_74: spriteHeader
	spritePiece -28, 4, 3, 2, 0, 0, 0, 0, 0
	spritePiece -8, -16, 2, 1, 6, 0, 0, 0, 0
	spritePiece -16, -8, 3, 2, 8, 0, 0, 0, 0
	spritePiece -16, 8, 4, 2, 14, 0, 0, 0, 0
TailsMap_74_End

TailsMap_75: spriteHeader
	spritePiece -13, -15, 3, 1, 0, 0, 0, 0, 0
	spritePiece -21, -7, 4, 3, 3, 0, 0, 0, 0
	spritePiece -25, -16, 4, 1, 15, 0, 0, 0, 0
TailsMap_75_End

TailsMap_76: spriteHeader
	spritePiece -13, -15, 3, 1, 0, 0, 0, 0, 0
	spritePiece -21, -7, 4, 3, 3, 0, 0, 0, 0
	spritePiece -25, -16, 4, 1, 15, 1, 0, 0, 0
TailsMap_76_End

TailsMap_77: spriteHeader
	spritePiece -13, -15, 3, 1, 0, 0, 0, 0, 0
	spritePiece -21, -7, 4, 3, 3, 0, 0, 0, 0
	spritePiece -25, -16, 4, 1, 15, 0, 0, 0, 0
TailsMap_77_End

TailsMap_78: spriteHeader
	spritePiece -13, -15, 3, 1, 0, 0, 0, 0, 0
	spritePiece -21, -7, 4, 3, 3, 0, 0, 0, 0
	spritePiece -25, -16, 4, 1, 15, 1, 0, 0, 0
TailsMap_78_End

TailsMap_79: spriteHeader
	spritePiece -22, -10, 1, 2, 0, 0, 0, 0, 0
	spritePiece -14, -10, 4, 3, 2, 0, 0, 0, 0
	spritePiece -14, 14, 3, 1, 14, 0, 0, 0, 0
TailsMap_79_End

TailsMap_7A: spriteHeader
	spritePiece -12, -10, 4, 3, 0, 0, 0, 0, 0
	spritePiece -20, -10, 1, 2, 12, 0, 0, 0, 0
	spritePiece -12, 14, 3, 1, 14, 0, 0, 0, 0
TailsMap_7A_End

TailsMap_7B: spriteHeader
	spritePiece -18, -10, 4, 4, 0, 0, 0, 0, 0
	spritePiece 14, 6, 1, 1, 16, 0, 0, 0, 0
TailsMap_7B_End

TailsMap_7C: spriteHeader
	spritePiece -14, -10, 4, 2, 0, 0, 0, 0, 0
	spritePiece -22, -10, 1, 1, 8, 0, 0, 0, 0
	spritePiece -22, 6, 4, 2, 9, 0, 0, 0, 0
	spritePiece 10, 6, 1, 1, 17, 0, 0, 0, 0
TailsMap_7C_End

TailsMap_7D: spriteHeader
	spritePiece -19, -10, 4, 4, 0, 0, 0, 0, 0
	spritePiece 13, -10, 1, 2, 16, 0, 0, 0, 0
TailsMap_7D_End

TailsMap_7E: spriteHeader
	spritePiece -13, -15, 3, 1, 0, 0, 0, 0, 0
	spritePiece -21, -7, 4, 3, 3, 0, 0, 0, 0
	spritePiece -25, -16, 4, 1, 15, 0, 0, 0, 0
TailsMap_7E_End

TailsMap_7F: spriteHeader
	spritePiece -13, -15, 3, 1, 0, 0, 0, 0, 0
	spritePiece -21, -7, 4, 3, 3, 0, 0, 0, 0
	spritePiece -25, -16, 4, 1, 15, 1, 0, 0, 0
TailsMap_7F_End

TailsMap_80: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -21, -4, 2, 3, 12, 0, 0, 0, 0
TailsMap_80_End

TailsMap_81: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 12, 0, 0, 0, 0
TailsMap_81_End

TailsMap_82: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 12, 0, 0, 0, 0
TailsMap_82_End

TailsMap_83: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, 4, 3, 2, 12, 0, 0, 0, 0
TailsMap_83_End

TailsMap_84: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 12, 0, 0, 0, 0
TailsMap_84_End

TailsMap_85: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -21, -4, 2, 3, 12, 0, 0, 0, 0
TailsMap_85_End

TailsMap_86: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 12, 0, 0, 0, 0
TailsMap_86_End

TailsMap_87: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 12, 0, 0, 0, 0
TailsMap_87_End

TailsMap_88: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, 4, 3, 2, 12, 0, 0, 0, 0
TailsMap_88_End

TailsMap_89: spriteHeader
	spritePiece -12, -12, 3, 4, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 12, 0, 0, 0, 0
TailsMap_89_End

TailsMap_8A: spriteHeader
	spritePiece -6, -4, 3, 3, 0, 0, 0, 0, 0
	spritePiece -21, -4, 2, 3, 9, 0, 0, 0, 0
TailsMap_8A_End

TailsMap_8B: spriteHeader
	spritePiece -6, -4, 3, 3, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 9, 0, 0, 0, 0
TailsMap_8B_End

TailsMap_8C: spriteHeader
	spritePiece -6, -4, 3, 3, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 9, 0, 0, 0, 0
TailsMap_8C_End

TailsMap_8D: spriteHeader
	spritePiece -6, -4, 3, 3, 0, 0, 0, 0, 0
	spritePiece -28, 4, 3, 2, 9, 0, 0, 0, 0
TailsMap_8D_End

TailsMap_8E: spriteHeader
	spritePiece -6, -4, 3, 3, 0, 0, 0, 0, 0
	spritePiece -28, -4, 3, 3, 9, 0, 0, 0, 0
TailsMap_8E_End

TailsMap_8F: spriteHeader
	spritePiece -14, -12, 3, 1, 0, 0, 0, 0, 0
	spritePiece -22, -4, 4, 2, 3, 0, 0, 0, 0
	spritePiece -14, 12, 2, 1, 11, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_8F_End

TailsMap_90: spriteHeader
	spritePiece -14, -12, 3, 1, 0, 0, 0, 0, 0
	spritePiece -22, -4, 4, 2, 3, 0, 0, 0, 0
	spritePiece -14, 12, 2, 1, 11, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_90_End

TailsMap_91: spriteHeader
	spritePiece -15, -12, 3, 2, 0, 0, 0, 0, 0
	spritePiece -23, 4, 4, 1, 6, 0, 0, 0, 0
	spritePiece -23, 12, 3, 1, 10, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_91_End

TailsMap_92: spriteHeader
	spritePiece -15, -12, 3, 2, 0, 0, 0, 0, 0
	spritePiece -23, 4, 4, 1, 6, 0, 0, 0, 0
	spritePiece -23, 12, 3, 1, 10, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_92_End

TailsMap_93: spriteHeader
	spritePiece -14, -12, 3, 1, 0, 0, 0, 0, 0
	spritePiece -22, -4, 4, 2, 3, 0, 0, 0, 0
	spritePiece -14, 12, 2, 1, 11, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_93_End

TailsMap_94: spriteHeader
	spritePiece -14, -12, 3, 1, 0, 0, 0, 0, 0
	spritePiece -22, -4, 4, 2, 3, 0, 0, 0, 0
	spritePiece -14, 12, 2, 1, 11, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_94_End

TailsMap_95: spriteHeader
	spritePiece -15, -12, 3, 2, 0, 0, 0, 0, 0
	spritePiece -23, 4, 4, 1, 6, 0, 0, 0, 0
	spritePiece -23, 12, 3, 1, 10, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_95_End

TailsMap_96: spriteHeader
	spritePiece -15, -12, 3, 2, 0, 0, 0, 0, 0
	spritePiece -23, 4, 4, 1, 6, 0, 0, 0, 0
	spritePiece -23, 12, 3, 1, 10, 0, 0, 0, 0
	spritePiece -28, -4, 3, 2, 13, 0, 0, 0, 0
TailsMap_96_End

TailsMap_97: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_97_End

TailsMap_98: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_98_End

TailsMap_99: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_99_End

TailsMap_9A: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_9A_End

TailsMap_9B: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_9B_End

TailsMap_9C: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_9C_End

TailsMap_9D: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_9D_End

TailsMap_9E: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_9E_End

TailsMap_9F: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_9F_End

TailsMap_A0: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_A0_End

TailsMap_A1: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_A1_End

TailsMap_A2: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_A2_End

TailsMap_A3: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_A3_End

TailsMap_A4: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_A4_End

TailsMap_A5: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_A5_End

TailsMap_A6: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_A6_End

TailsMap_A7: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_A7_End

TailsMap_A8: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_A8_End

TailsMap_A9: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_A9_End

TailsMap_AA: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_AA_End

TailsMap_AB: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_AB_End

TailsMap_AC: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_AC_End

TailsMap_AD: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_AD_End

TailsMap_AE: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_AE_End

TailsMap_AF: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_AF_End

TailsMap_B0: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_B0_End

TailsMap_B1: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_B1_End

TailsMap_B2: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_B2_End

TailsMap_B3: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_B3_End

TailsMap_B4: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_B4_End

TailsMap_B5: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_B5_End

TailsMap_B6: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_B6_End

TailsMap_B7: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_B7_End

TailsMap_B8: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_B8_End

TailsMap_B9: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_B9_End

TailsMap_BA: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_BA_End

TailsMap_BB: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_BB_End

TailsMap_BC: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_BC_End

TailsMap_BD: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_BD_End

TailsMap_BE: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_BE_End

TailsMap_BF: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_BF_End

TailsMap_C0: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_C0_End

TailsMap_C1: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_C1_End

TailsMap_C2: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_C2_End

TailsMap_C3: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_C3_End

TailsMap_C4: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_C4_End

TailsMap_C5: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_C5_End

TailsMap_C6: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_C6_End

TailsMap_C7: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_C7_End

TailsMap_C8: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_C8_End

TailsMap_C9: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_C9_End

TailsMap_CA: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_CA_End

TailsMap_CB: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_CB_End

TailsMap_CC: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_CC_End

TailsMap_CD: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_CD_End

TailsMap_CE: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_CE_End

TailsMap_CF: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_CF_End

TailsMap_D0: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_D0_End

TailsMap_D1: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_D1_End

TailsMap_D2: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_D2_End

TailsMap_D3: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_D3_End

TailsMap_D4: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_D4_End

TailsMap_D5: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_D5_End

TailsMap_D6: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_D6_End

TailsMap_D7: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_D7_End

TailsMap_D8: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_D8_End

TailsMap_D9: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_D9_End

TailsMap_DA: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -36, -8, 3, 2, 16, 0, 0, 0, 0
TailsMap_DA_End

TailsMap_DB: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_DB_End

TailsMap_DC: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_DC_End

TailsMap_DD: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_DD_End

TailsMap_DE: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -23, -31, 2, 3, 16, 1, 1, 0, 0
TailsMap_DE_End

TailsMap_DF: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_DF_End

TailsMap_E0: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_E0_End

TailsMap_E1: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_E1_End

TailsMap_E2: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, -36, 2, 3, 16, 1, 1, 0, 0
TailsMap_E2_End

TailsMap_E3: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_E3_End

TailsMap_E4: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_E4_End

TailsMap_E5: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_E5_End

TailsMap_E6: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, -23, 3, 2, 16, 1, 1, 0, 0
TailsMap_E6_End

TailsMap_E7: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_E7_End

TailsMap_E8: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_E8_End

TailsMap_E9: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_E9_End

TailsMap_EA: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 12, -8, 3, 2, 16, 1, 1, 0, 0
TailsMap_EA_End

TailsMap_EB: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_EB_End

TailsMap_EC: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_EC_End

TailsMap_ED: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_ED_End

TailsMap_EE: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece 7, 7, 2, 3, 16, 0, 0, 0, 0
TailsMap_EE_End

TailsMap_EF: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_EF_End

TailsMap_F0: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_F0_End

TailsMap_F1: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_F1_End

TailsMap_F2: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -8, 12, 2, 3, 16, 0, 0, 0, 0
TailsMap_F2_End

TailsMap_F3: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_F3_End

TailsMap_F4: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_F4_End

TailsMap_F5: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_F5_End

TailsMap_F6: spriteHeader
	spritePiece -16, -16, 4, 4, 0, 0, 0, 0, 0
	spritePiece -31, 7, 3, 2, 16, 0, 0, 0, 0
TailsMap_F6_End

	even
