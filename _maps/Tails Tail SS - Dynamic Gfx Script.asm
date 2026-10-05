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
	dplcEntry 11, $0
TailsTailSSPLC_05_End

TailsTailSSPLC_06: dplcHeader
	dplcEntry 11, $B
TailsTailSSPLC_06_End

TailsTailSSPLC_07: dplcHeader
	dplcEntry 10, $16
TailsTailSSPLC_07_End

TailsTailSSPLC_08: dplcHeader
	dplcEntry 10, $20
TailsTailSSPLC_08_End

TailsTailSSPLC_09: dplcHeader
	dplcEntry 8, $2A
TailsTailSSPLC_09_End

TailsTailSSPLC_0A: dplcHeader
	dplcEntry 9, $32
TailsTailSSPLC_0A_End

TailsTailSSPLC_0B: dplcHeader
	dplcEntry 10, $3B
TailsTailSSPLC_0B_End

TailsTailSSPLC_0C: dplcHeader
	dplcEntry 10, $45
TailsTailSSPLC_0C_End

TailsTailSSPLC_0D: dplcHeader
	dplcEntry 12, $4F
TailsTailSSPLC_0D_End

TailsTailSSPLC_0E: dplcHeader
	dplcEntry 12, $5B
TailsTailSSPLC_0E_End

TailsTailSSPLC_0F: dplcHeader
	dplcEntry 10, $67
TailsTailSSPLC_0F_End

TailsTailSSPLC_10: dplcHeader
	dplcEntry 10, $71
TailsTailSSPLC_10_End

TailsTailSSPLC_11: dplcHeader
	dplcEntry 10, $7B
TailsTailSSPLC_11_End

TailsTailSSPLC_12: dplcHeader
	dplcEntry 12, $85
TailsTailSSPLC_12_End

TailsTailSSPLC_13: dplcHeader
	dplcEntry 11, $91
TailsTailSSPLC_13_End

TailsTailSSPLC_14: dplcHeader
	dplcEntry 11, $9C
TailsTailSSPLC_14_End

	even
