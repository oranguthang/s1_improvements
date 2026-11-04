TailsTailSSDPLC_internal: mappingsTable
	mappingsTableEntry.w TailsTailSSPLC_00
	mappingsTableEntry.w TailsTailSSPLC_01
	mappingsTableEntry.w TailsTailSSPLC_02
	mappingsTableEntry.w TailsTailSSPLC_03
	mappingsTableEntry.w TailsTailSSPLC_04
	mappingsTableEntry.w TailsTailSSPLC_05
	mappingsTableEntry.w TailsTailSSPLC_06
	mappingsTableEntry.w TailsTailSSPLC_07
	mappingsTableEntry.w TailsTailSSPLC_08
	mappingsTableEntry.w TailsTailSSPLC_09
	mappingsTableEntry.w TailsTailSSPLC_0A
	mappingsTableEntry.w TailsTailSSPLC_0B
	mappingsTableEntry.w TailsTailSSPLC_0C
	mappingsTableEntry.w TailsTailSSPLC_0D
	mappingsTableEntry.w TailsTailSSPLC_0E
	mappingsTableEntry.w TailsTailSSPLC_0F
	mappingsTableEntry.w TailsTailSSPLC_10
	mappingsTableEntry.w TailsTailSSPLC_11
	mappingsTableEntry.w TailsTailSSPLC_12
	mappingsTableEntry.w TailsTailSSPLC_13
	mappingsTableEntry.w TailsTailSSPLC_14
	mappingsTableEntry.w TailsTailSSPLC_15
	mappingsTableEntry.w TailsTailSSPLC_16

TailsTailSSPLC_00: dplcHeader
TailsTailSSPLC_00_End

TailsTailSSPLC_01: dplcHeader
TailsTailSSPLC_01_End

TailsTailSSPLC_02: dplcHeader
TailsTailSSPLC_02_End

TailsTailSSPLC_03: dplcHeader
TailsTailSSPLC_03_End

TailsTailSSPLC_04: dplcHeader
TailsTailSSPLC_04_End

TailsTailSSPLC_05: dplcHeader
	dplcEntry 13, $0
TailsTailSSPLC_05_End

TailsTailSSPLC_06: dplcHeader
	dplcEntry 13, $D
TailsTailSSPLC_06_End

TailsTailSSPLC_07: dplcHeader
	dplcEntry 12, $1A
TailsTailSSPLC_07_End

TailsTailSSPLC_08: dplcHeader
	dplcEntry 12, $26
TailsTailSSPLC_08_End

TailsTailSSPLC_09: dplcHeader
	dplcEntry 9, $32
TailsTailSSPLC_09_End

TailsTailSSPLC_0A: dplcHeader
	dplcEntry 9, $3B
TailsTailSSPLC_0A_End

TailsTailSSPLC_0B: dplcHeader
	dplcEntry 9, $44
TailsTailSSPLC_0B_End

TailsTailSSPLC_0C: dplcHeader
	dplcEntry 10, $4D
TailsTailSSPLC_0C_End

TailsTailSSPLC_0D: dplcHeader
	dplcEntry 12, $57
TailsTailSSPLC_0D_End

TailsTailSSPLC_0E: dplcHeader
	dplcEntry 13, $63
TailsTailSSPLC_0E_End

TailsTailSSPLC_0F: dplcHeader
	dplcEntry 11, $70
TailsTailSSPLC_0F_End

TailsTailSSPLC_10: dplcHeader
	dplcEntry 10, $7B
TailsTailSSPLC_10_End

TailsTailSSPLC_11: dplcHeader
	dplcEntry 12, $85
TailsTailSSPLC_11_End

TailsTailSSPLC_12: dplcHeader
	dplcEntry 12, $91
TailsTailSSPLC_12_End

TailsTailSSPLC_13: dplcHeader
	dplcEntry 10, $9D
TailsTailSSPLC_13_End

TailsTailSSPLC_14: dplcHeader
	dplcEntry 12, $A7
TailsTailSSPLC_14_End

TailsTailSSPLC_15: dplcHeader
	dplcEntry 16, $B3
TailsTailSSPLC_15_End

TailsTailSSPLC_16: dplcHeader
	dplcEntry 16, $C3
	dplcEntry 1, $D3
TailsTailSSPLC_16_End

	even
