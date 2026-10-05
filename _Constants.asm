; ===========================================================================
; ---------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------

Size_of_SegaPCM:	  equ $6978
Size_of_DAC_driver_guess: equ $1760

; Clocks
Master_Clock:		equ 53693175
M68000_Clock:		equ Master_Clock/7
Z80_Clock:		equ Master_Clock/15
FM_Sample_Rate:		equ M68000_Clock/(6*6*4)
PSG_Sample_Rate:	equ Z80_Clock/16

; VDP addresses
vdp_data_port:		equ $C00000
vdp_control_port:	equ $C00004
VDP_data_port:		equ vdp_data_port
VDP_control_port:	equ vdp_control_port
vdp_counter:		equ $C00008
psg_input:		equ $C00011
debug_reg:		equ $C0001C

; Z80/YM2612 addresses
z80_ram:		equ $A00000				; start of Z80 RAM
z80_dac3_pitch:		equ $A000EA
z80_dac_status:		equ $A01FFD
z80_dac_sample:		equ $A01FFF
z80_ram_end:		equ $A02000				; end of non-reserved Z80 RAM
ym2612_a0:		equ $A04000
ym2612_d0:		equ $A04001
ym2612_a1:		equ $A04002
ym2612_d1:		equ $A04003
z80_68k_bank:		equ $A06000
psg_input_z80:		equ $A07F11
z80_68k:		equ $A08000
z80_68k_end:		equ $A10000
z80_bus_request:	equ $A11100
z80_reset:		equ $A11200

; I/O addresses
console_version:	equ $A10001
port_1_data_hi:		equ $A10002
port_1_data:		equ $A10003
port_2_data_hi:		equ $A10004
port_2_data:		equ $A10005
port_1_control_hi:	equ $A10008
port_1_control:		equ $A10009
port_2_control_hi:	equ $A1000A
port_2_control:		equ $A1000B
expansion_control_hi:	equ $A1000C
expansion_control:	equ $A1000D
serial_1_tx_hi:		equ $A1000E
serial_1_tx:		equ $A1000F
serial_1_rx_hi:		equ $A10010
serial_1_rx:		equ $A10011
serial_1_control_hi:	equ $A10012
serial_1_control:	equ $A10013
serial_2_tx_hi:		equ $A10014
serial_2_tx:		equ $A10015
serial_2_rx_hi:		equ $A10016
serial_2_rx:		equ $A10017
serial_2_control_hi:	equ $A10018
serial_2_control:	equ $A10019
serial_exp_tx_hi:	equ $A1001A
serial_exp_tx:		equ $A1001B
serial_exp_rx_hi:	equ $A1001C
serial_exp_rx:		equ $A1001D
serial_exp_control_hi:	equ $A1001E
serial_exp_control:	equ $A1001F

; Misc addresses
memory_mode:		equ $A11000
mars_connection:	equ $A130EC
sram_port:		equ $A130F1
mapper_bank_1:		equ $A130F3
mapper_bank_2:		equ $A130F5
mapper_bank_3:		equ $A130F7
mapper_bank_4:		equ $A130F9
mapper_bank_5:		equ $A130FB
mapper_bank_6:		equ $A130FD
mapper_bank_7:		equ $A130FF
security_addr:		equ $A14000
security_flag:		equ $A14101

; SRAM
sram_start:		equ $200000+(AddressSRAM&1)
sram_end:		equ $210000

; VDP registers
vreg_mode1:		equ $8000				; mode 1 options register
vreg_mode2:		equ $8100				; mode 2 options register
vreg_fgvram:		equ $8200				; foreground nametable address
vreg_winvram:		equ $8300				; window nametable address
vreg_bgvram:		equ $8400				; background nametable address
vreg_spritevram:	equ $8500				; sprite table address
vreg_bgcolor:		equ $8700				; background colour palette index
vreg_hintrate:		equ $8A00				; horizontal interrupt rate
vreg_mode3:		equ $8B00				; mode 3 options register
vreg_mode4:		equ $8C00				; mode 4 options register
vreg_hscrollvram:	equ $8D00				; horizontal scroll table address
vreg_autoinc:		equ $8F00				; VDP address auto-increment width
vreg_planesize:		equ $9000				; plane map size
vreg_winxpos:		equ $9100				; window X position
vreg_winypos:		equ $9200				; window Y position
vreg_dmalen:		equ $94009300				; DMA operation length
vreg_dmasrc:		equ $96009500				; DMA operation source address
vreg_dmamode:		equ $9700				; DMA mode + upper byte of source address in 68k -> VDP transfers.

; VRAM data
vram_fg:		equ $C000				; foreground namespace
vram_win:		equ $A000				; window namespace
vram_bg:		equ $E000				; background namespace
vram_sprites:		equ $F800				; sprite table
vram_hscroll:		equ $FC00				; horizontal scroll table

; Sprite data
sprites_max:		equ 80					; maximum number of sprites the Mega Drive can handle
spritelayer_num:	equ 1<<3				; =8 sprite priority layers (must be a power of 2)
spritelayer_size_bits:	equ 7					; layer size must be a power of 2
spritelayer_size:	equ 1<<spritelayer_size_bits		; =$80 (2 bytes entry counter + $7E bytes to store entries)
spritetable_entrysize:	equ 8					; 8 bytes per linked sprite table entry (2 y-pos + 1 size + 1 link + 2 VRAM + 2 x-pos)

; Various sizes
tile_size:		equ 8*8/2				; size of a single 8x8 tile
chunk_size:		equ $200				; size of a single 256x256 chunk
plane_size_64x32:	equ 64*32*2				; size of plane in 512x256 mode

layout_row_interlaced:	equ $40					; size of a single level layout row (FG/BG alternating)
layout_row:		equ layout_row_interlaced*2		; size of a single level layout row (skipping over other plane)

; Levels (zones)
; (Note: id_SS is only used by the level select)
id_GHZ:			equ 0
id_LZ:			equ 1
id_MZ:			equ 2
id_SLZ:			equ 3
id_SYZ:			equ 4
id_SBZ:			equ 5
id_EndZ:		equ 6
id_SS:			equ 7

; Levels (zone/act word combos)
; (Note: act4 is only used for SBZ3/LZ4)
act1:			equ 0
act2:			equ 1
act3:			equ 2
act4:			equ 3

id_GHZ_act1:		equ (id_GHZ<<8)+act1			; $0000
id_GHZ_act2:		equ (id_GHZ<<8)+act2			; $0001
id_GHZ_act3:		equ (id_GHZ<<8)+act3			; $0002

id_LZ_act1:		equ (id_LZ<<8)+act1			; $0100
id_LZ_act2:		equ (id_LZ<<8)+act2			; $0101
id_LZ_act3:		equ (id_LZ<<8)+act3			; $0102

id_MZ_act1:		equ (id_MZ<<8)+act1			; $0200
id_MZ_act2:		equ (id_MZ<<8)+act2			; $0201
id_MZ_act3:		equ (id_MZ<<8)+act3			; $0202

id_SLZ_act1:		equ (id_SLZ<<8)+act1			; $0300
id_SLZ_act2:		equ (id_SLZ<<8)+act2			; $0301
id_SLZ_act3:		equ (id_SLZ<<8)+act3			; $0302

id_SYZ_act1:		equ (id_SYZ<<8)+act1			; $0400
id_SYZ_act2:		equ (id_SYZ<<8)+act2			; $0401
id_SYZ_act3:		equ (id_SYZ<<8)+act3			; $0402

id_SBZ_act1:		equ (id_SBZ<<8)+act1			; $0500
id_SBZ_act2:		equ (id_SBZ<<8)+act2			; $0501
; id_SBZ_act3 is ambiguous, could mean LZ4 or FZ
id_LZ_act4:		equ (id_LZ<<8)+act4			; $0103 (SBZ3)
id_FZ:			equ (id_SBZ<<8)+act3			; $0502 (real SBZ3)

id_EndZ_good:		equ (id_EndZ<<8)+act1			; $0600 (good ending, all emeralds)
id_EndZ_bad:		equ (id_EndZ<<8)+act2			; $0601 (bad ending, not all emeralds)
id_Title_Layout:	equ (id_EndZ<<8)+act4			; $0603 (Level_Index row for the title screen FG/BG layouts only)

; Special Stage
ss_emeralds_num:	equ 6					; total number of Chaos Emeralds and Special Stages
ss_giantring_rings:	equ 50					; number of rings required for giant rings to spawn
ss_continue_rings:	equ 50					; number of rings required to earn an extra continue
ss_rotatespeed:		equ $40					; base special stage rotation speed
ss_timeout:		equ 30					; delay after touching an UP/DOWN or R block
ss_blocksize:		equ 24					; logical size of a single block

; Common colors
cBlack:			equ $000				; color black
cWhite:			equ $EEE				; color white
cBlue:			equ $E00				; color blue
cGreen:			equ $0E0				; color green
cRed:			equ $00E				; color red
cYellow:		equ cGreen+cRed				; color yellow
cAqua:			equ cGreen+cBlue			; color aqua
cMagenta:		equ cBlue+cRed				; color magenta

; Joypad input
bitUp:			equ 0
bitDn:			equ 1
bitL:			equ 2
bitR:			equ 3
bitB:			equ 4
bitC:			equ 5
bitA:			equ 6
bitStart:		equ 7
btnUp:			equ 1<<bitUp				; ($01)
btnDn:			equ 1<<bitDn				; ($02)
btnL:			equ 1<<bitL				; ($04)
btnR:			equ 1<<bitR				; ($08)
btnB:			equ 1<<bitB				; ($10)
btnC:			equ 1<<bitC				; ($20)
btnA:			equ 1<<bitA				; ($40)
btnStart:		equ 1<<bitStart				; ($80)
btnDir:			equ btnUp|btnDn|btnL|btnR		; ($0F)
btnABC:		equ btnA|btnB|btnC
; Separate extra-input bytes; never OR these bits into SACBRLDU.
bitZ: equ 0
bitY: equ 1
bitX: equ 2
bitMode: equ 3
btnZ: equ 1<<bitZ
btnY: equ 1<<bitY
btnX: equ 1<<bitX
btnMode: equ 1<<bitMode
Joypad6_Connected: equ $80

; Flags used by obRender and BuildSprites
sprite_xflip_bit:	equ 0					; flip sprite mappings horizontally (X-axis)
sprite_yflip_bit:	equ 1					; flip sprite mappings vertically (Y-axis)
sprite_cam_field_bit:	equ 2					; position with foreground coordinates (playfield-positioned mode)
sprite_cam_bg_bit:	equ 3					; position with background coordinates (unused, see notes in BuildSpr_Cameras)
sprite_customheight_bit:equ 4					; use obHeight instead of assuming 32px to determine display height
sprite_rawmappings_bit:	equ 5					; obMap points to single, specific sprite piece rather than index of mappings
sprite_looping_bit:	equ 6					; display behind looping chunks (only used by Sonic)
sprite_subsprites_bit:	equ sprite_looping_bit			; same bit: draws sub-sprites only while obSubSprites is also nonzero
sprite_rendered_bit:	equ 7					; set when sprite is in visible screen space and got rendered the previous frame

sprite_xflip:		equ 1<<sprite_xflip_bit
sprite_yflip:		equ 1<<sprite_yflip_bit
sprite_cam_screen:	equ 0					; position with screen-fixed coordinates (implied if bits 2-3 are 0)
sprite_cam_field:	equ 1<<sprite_cam_field_bit
sprite_cam_bg:		equ 1<<sprite_cam_bg_bit
sprite_customheight:	equ 1<<sprite_customheight_bit
sprite_rawmappings:	equ 1<<sprite_rawmappings_bit
sprite_subsprites:	equ 1<<sprite_subsprites_bit
sprite_rendered:	equ 1<<sprite_rendered_bit

; Object variables
obID:			equ 0					; object ID number
obRender:		equ 1					; bitfield for x/y flip, display mode
obGfx:			equ 2					; palette line & VRAM setting (2 bytes)
obMap:			equ 4					; mappings address (4 bytes)
obX:			equ 8					; x-axis position (2-4 bytes)
obSubpixelX:		equ $A					; x-axis subpixel position for playfield items (2 bytes)
obScreenY:		equ obSubpixelX				; y-axis position for screen-fixed items (2 bytes)
obY:			equ $C					; y-axis position (2-4 bytes)
obSubpixelY:		equ $E					; y-axis subpixel position for playfield items (2 bytes)
obVelX:			equ $10					; x-axis velocity (2 bytes)
obVelY:			equ $12					; y-axis velocity (2 bytes)
respawn_index:		equ $14					; address of object state byte (2 bytes)
obInertia:		equ $20					; Sonic ground speed (2 bytes)
obHeight:		equ $16					; height/2
obWidth:		equ $17					; width/2
obPriority:		equ $18					; sprite stack priority -- 0 is front
obActWid:		equ $19					; action width
obFrame:		equ $1A					; current frame displayed
obAniFrame:		equ $1B					; current frame in animation script
obAnim:			equ $1C					; current animation
obPrevAni:		equ $1D					; previous animation
obTimeFrame:		equ $1E					; time to next frame
obDelayAni:		equ $1F					; time to delay animation
obColType:		equ $20					; collision response type
obColProp:		equ $21					; collision extra property
obStatus:		equ $22					; orientation or mode
; SST $23 was obRespawnNo; respawn_index at $14 now stores the state-byte address
obSubSprites:		equ $23					; sub-sprite child count; 0 for every other object
obRoutine:		equ $24					; routine number
ob2ndRout:		equ $25					; secondary routine number
obSolid:		equ ob2ndRout				; solid status flag
obAngle:		equ $26					; angle
obSubtype:		equ $28					; object subtype

; Object variables used by Sonic
flashtime:		equ $30					; time between flashes after getting hit (2 bytes)
invtime:		equ $32					; time left for invincibility (2 bytes)
shoetime:		equ $34					; time left for speed shoes (2 bytes)
angleright:		equ $36					; angle of floor on Sonic's right side
angleleft:		equ $37					; angle of floor on Sonic's left side
sticktoconvex:		equ $38					; flag set while running on an SBZ gear
spindash_flag:		equ $29				; bit 0 Spin Dash, bit 1 Peel-Out charging
spindash_count:		equ $2A				; Spin Dash revs / Peel-Out speed charge (2 bytes)
;unused:		equ $39					; unused by Sonic
restartime:		equ $3A					; time left before level restarts after dying (2 bytes)
jumping:		equ $3C					; flag set while Sonic is jumping
standonobject:		equ $3D					; object index Sonic stands on
locktime:		equ $3E					; temporary D-Pad control lock timer (2 bytes)

; Sonic's collision sizes
sonic_width:		equ 18/2				; Sonic's width
sonic_height:		equ 38/2				; Sonic's height
sonic_roll_width:	equ 14/2				; Sonic's width (rolling)
sonic_roll_height:	equ 28/2				; Sonic's height (rolling)
sonic_solid_width:	equ 22/2				; Sonic's width (solid object collision)
sonic_react_width:	equ 16/2				; Sonic's width (object collision)
sonic_duck_height:	equ 20/2				; Sonic's height (object collision, ducking)
sonic_quick_size:	equ 20/2				; Sonic's size (quick terrain find)

; Miscellaneous object scratch-RAM
objoff_29:		equ $29
objoff_2A:		equ $2A
objoff_2B:		equ $2B
objoff_2C:		equ $2C
objoff_2E:		equ $2E
objoff_2F:		equ $2F
objoff_30:		equ $30
objoff_31:		equ $31
objoff_32:		equ $32
objoff_33:		equ $33
objoff_34:		equ $34
objoff_35:		equ $35
objoff_36:		equ $36
objoff_37:		equ $37
objoff_38:		equ $38
objoff_39:		equ $39
objoff_3A:		equ $3A
objoff_3B:		equ $3B
objoff_3C:		equ $3C
objoff_3D:		equ $3D
objoff_3E:		equ $3E
objoff_3F:		equ $3F

; Object variables used by bosses
obBossHits:		equ obColProp				; number of remaining hit points for boss, defaults to 8
obBossX:		equ objoff_30				; base X boss position (2 bytes)
obBossY:		equ objoff_38				; base Y boss position without swaying effect (2 bytes)
obBossFlash:		equ objoff_3E				; number of remaining flash frames after taking a hit

; Size definition for one object in RAM ($40 bytes)
object_size_bits:	equ 6
object_size:		equ 1<<object_size_bits

; Sub-sprite parents. BuildSprites draws obFrame, then obSubSprites child frames
; from the parent's obMap/obGfx/flip bits, but only when obRender bit 6 is set
; AND obSubSprites is nonzero. Bit 6 alone is still Sonic's loop flag (also
; copied to the Spin Dash dust and debug-placed objects); they keep $23 at 0.
; Children overlay the scratch bytes $29-$3D; $00-$28 keep their usual meaning,
; so respawn_index ($14) and obColType ($20) stay valid. Offsets are signed
; bytes from the parent's drawing position and are not mirrored by the flips.
; A child is skipped when its origin is more than subspr_reach pixels outside
; the screen, so child frames must stay within subspr_reach of their origin.
subspr_data:		equ objoff_29				; first child entry
subspr_x:		equ 0					; X offset, signed byte
subspr_y:		equ 1					; Y offset, signed byte
subspr_frame:		equ 2					; mapping frame
subspr_size:		equ 3
subspr_max:		equ 7					; larger obSubSprites values are clamped
subspr_reach:		equ 64

	if subspr_data+subspr_size*subspr_max>object_size
		fatal "Sub-sprite children end at $\{subspr_data+subspr_size*subspr_max}, past the $\{object_size} byte SST."
	endif

; Animation flags
afEnd:			equ $FF	; return to beginning of animation
afBack:			equ $FE	; go back (specified number) bytes
afChange:		equ $FD	; run specified animation
afRoutine:		equ $FC	; increment routine counter
afReset:		equ $FB	; reset animation and 2nd object routine counter
af2ndRoutine:		equ $FA	; increment 2nd routine counter

aniXFlip:		equ $20 ; horizontally mirrors the current frame
aniYFlip:		equ $40 ; vertically mirrors the current frame

; Sound IDs use the whole byte, as in Sonic 3 & Knuckles: music $01-$7F,
; sound effects $A0-$CF, the special waterfall sound $D0, added sound effects
; $D1-$FA and commands $FB-$FF. $00 stops all sound and $80 marks an empty
; driver slot. The labels keep the original Sonic 1 numbers (ptr_mus81 is $01).
; Background music
bgm__First:		equ $01
bgm_GHZ:		equ ((ptr_mus81-MusicIndex)/4)+bgm__First
bgm_LZ:			equ ((ptr_mus82-MusicIndex)/4)+bgm__First
bgm_MZ:			equ ((ptr_mus83-MusicIndex)/4)+bgm__First
bgm_SLZ:		equ ((ptr_mus84-MusicIndex)/4)+bgm__First
bgm_SYZ:		equ ((ptr_mus85-MusicIndex)/4)+bgm__First
bgm_SBZ:		equ ((ptr_mus86-MusicIndex)/4)+bgm__First
bgm_Invincible:		equ ((ptr_mus87-MusicIndex)/4)+bgm__First
bgm_ExtraLife:		equ ((ptr_mus88-MusicIndex)/4)+bgm__First
bgm_SS:			equ ((ptr_mus89-MusicIndex)/4)+bgm__First
bgm_Title:		equ ((ptr_mus8A-MusicIndex)/4)+bgm__First
bgm_Ending:		equ ((ptr_mus8B-MusicIndex)/4)+bgm__First
bgm_Boss:		equ ((ptr_mus8C-MusicIndex)/4)+bgm__First
bgm_FZ:			equ ((ptr_mus8D-MusicIndex)/4)+bgm__First
bgm_GotThrough:		equ ((ptr_mus8E-MusicIndex)/4)+bgm__First
bgm_GameOver:		equ ((ptr_mus8F-MusicIndex)/4)+bgm__First
bgm_Continue:		equ ((ptr_mus90-MusicIndex)/4)+bgm__First
bgm_Credits:		equ ((ptr_mus91-MusicIndex)/4)+bgm__First
bgm_Drowning:		equ ((ptr_mus92-MusicIndex)/4)+bgm__First
bgm_Emerald:		equ ((ptr_mus93-MusicIndex)/4)+bgm__First
bgm_Super:		equ ((ptr_mus94-MusicIndex)/4)+bgm__First
bgm__Last:		equ ((ptr_musend-MusicIndex-4)/4)+bgm__First

; Sound effects
sfx__First:		equ $A0
sfx_Jump:		equ ((ptr_sndA0-SoundIndex)/4)+sfx__First
sfx_Lamppost:		equ ((ptr_sndA1-SoundIndex)/4)+sfx__First
sfx_SuperTransform:	equ ((ptr_sndA2-SoundIndex)/4)+sfx__First
sfx_Death:		equ ((ptr_sndA3-SoundIndex)/4)+sfx__First
sfx_Skid:		equ ((ptr_sndA4-SoundIndex)/4)+sfx__First
sfx_A5:			equ ((ptr_sndA5-SoundIndex)/4)+sfx__First
sfx_HitSpikes:		equ ((ptr_sndA6-SoundIndex)/4)+sfx__First
sfx_Push:		equ ((ptr_sndA7-SoundIndex)/4)+sfx__First
sfx_SSGoal:		equ ((ptr_sndA8-SoundIndex)/4)+sfx__First
sfx_SSItem:		equ ((ptr_sndA9-SoundIndex)/4)+sfx__First
sfx_Splash:		equ ((ptr_sndAA-SoundIndex)/4)+sfx__First
sfx_AB:			equ ((ptr_sndAB-SoundIndex)/4)+sfx__First
sfx_HitBoss:		equ ((ptr_sndAC-SoundIndex)/4)+sfx__First
sfx_Bubble:		equ ((ptr_sndAD-SoundIndex)/4)+sfx__First
sfx_Fireball:		equ ((ptr_sndAE-SoundIndex)/4)+sfx__First
sfx_Shield:		equ ((ptr_sndAF-SoundIndex)/4)+sfx__First
sfx_Saw:		equ ((ptr_sndB0-SoundIndex)/4)+sfx__First
sfx_Electric:		equ ((ptr_sndB1-SoundIndex)/4)+sfx__First
sfx_Drown:		equ ((ptr_sndB2-SoundIndex)/4)+sfx__First
sfx_Flamethrower:	equ ((ptr_sndB3-SoundIndex)/4)+sfx__First
sfx_Bumper:		equ ((ptr_sndB4-SoundIndex)/4)+sfx__First
sfx_Ring:		equ ((ptr_sndB5-SoundIndex)/4)+sfx__First
sfx_SpikesMove:		equ ((ptr_sndB6-SoundIndex)/4)+sfx__First
sfx_Rumbling:		equ ((ptr_sndB7-SoundIndex)/4)+sfx__First
sfx_B8:			equ ((ptr_sndB8-SoundIndex)/4)+sfx__First
sfx_Collapse:		equ ((ptr_sndB9-SoundIndex)/4)+sfx__First
sfx_SSGlass:		equ ((ptr_sndBA-SoundIndex)/4)+sfx__First
sfx_Door:		equ ((ptr_sndBB-SoundIndex)/4)+sfx__First
sfx_Teleport:		equ ((ptr_sndBC-SoundIndex)/4)+sfx__First
sfx_ChainStomp:		equ ((ptr_sndBD-SoundIndex)/4)+sfx__First
sfx_Roll:		equ ((ptr_sndBE-SoundIndex)/4)+sfx__First
sfx_Continue:		equ ((ptr_sndBF-SoundIndex)/4)+sfx__First
sfx_Basaran:		equ ((ptr_sndC0-SoundIndex)/4)+sfx__First
sfx_BreakItem:		equ ((ptr_sndC1-SoundIndex)/4)+sfx__First
sfx_Warning:		equ ((ptr_sndC2-SoundIndex)/4)+sfx__First
sfx_GiantRing:		equ ((ptr_sndC3-SoundIndex)/4)+sfx__First
sfx_Bomb:		equ ((ptr_sndC4-SoundIndex)/4)+sfx__First
sfx_Cash:		equ ((ptr_sndC5-SoundIndex)/4)+sfx__First
sfx_RingLoss:		equ ((ptr_sndC6-SoundIndex)/4)+sfx__First
sfx_ChainRise:		equ ((ptr_sndC7-SoundIndex)/4)+sfx__First
sfx_Burning:		equ ((ptr_sndC8-SoundIndex)/4)+sfx__First
sfx_Bonus:		equ ((ptr_sndC9-SoundIndex)/4)+sfx__First
sfx_EnterSS:		equ ((ptr_sndCA-SoundIndex)/4)+sfx__First
sfx_WallSmash:		equ ((ptr_sndCB-SoundIndex)/4)+sfx__First
sfx_Spring:		equ ((ptr_sndCC-SoundIndex)/4)+sfx__First
sfx_Switch:		equ ((ptr_sndCD-SoundIndex)/4)+sfx__First
sfx_RingLeft:		equ ((ptr_sndCE-SoundIndex)/4)+sfx__First
sfx_Signpost:		equ ((ptr_sndCF-SoundIndex)/4)+sfx__First
sfx__Last:		equ ((ptr_sndend-SoundIndex-4)/4)+sfx__First

; Special sound effects
spec__First:		equ $D0
sfx_Waterfall:		equ ((ptr_sndD0-SpecSoundIndex)/4)+spec__First
spec__Last:		equ ((ptr_specend-SpecSoundIndex-4)/4)+spec__First

ext__First:		equ $D1
sfx_SpinDash:		equ ((ptr_sndD1-ExtSoundIndex)/4)+ext__First
sfx_PeelCharge: equ ((ptr_sndD2-ExtSoundIndex)/4)+ext__First
sfx_PeelRelease: equ ((ptr_sndD3-ExtSoundIndex)/4)+ext__First
sfx_PeelStop: equ ((ptr_sndD4-ExtSoundIndex)/4)+ext__First
ext__Last:		equ ((ptr_extend-ExtSoundIndex-4)/4)+ext__First

; Sound commands
flg__First:		equ $FB
bgm_Fade:		equ ((ptr_flgE0-Sound_ExIndex)/4)+flg__First
sfx_Sega:		equ ((ptr_flgE1-Sound_ExIndex)/4)+flg__First
bgm_Speedup:		equ ((ptr_flgE2-Sound_ExIndex)/4)+flg__First
bgm_Slowdown:		equ ((ptr_flgE3-Sound_ExIndex)/4)+flg__First
bgm_Stop:		equ ((ptr_flgE4-Sound_ExIndex)/4)+flg__First
flg__Last:		equ ((ptr_flgend-Sound_ExIndex-4)/4)+flg__First
	if MOMPASS>1
	if bgm__Last>=$80
		error "Music IDs must stay below $80, which marks an empty driver slot"
	endif
	if ext__Last>=flg__First
		error "Added sound effects run into the sound commands at $FB"
	endif
	if flg__Last<>$FF
		error "Sound commands must end at $FF"
	endif
	endif
	
; Boss locations
; The main values are based on where the camera boundaries mainly lie
; The end values are where the camera scrolls towards after defeat
boss_ghz_x:		equ $2960				; Green Hill Zone
boss_ghz_y:		equ $300
boss_ghz_end:		equ boss_ghz_x+$160

boss_lz_x:		equ $1DE0				; Labyrinth Zone
boss_lz_y:		equ $C0
boss_lz_end:		equ boss_lz_x+$250

boss_mz_x:		equ $1800				; Marble Zone
boss_mz_y:		equ $210
boss_mz_end:		equ boss_mz_x+$160

boss_slz_x:		equ $2000				; Star Light Zone
boss_slz_y:		equ $210
boss_slz_end:		equ boss_slz_x+$160

boss_syz_x:		equ $2C00				; Spring Yard Zone
boss_syz_y:		equ $4CC
boss_syz_end:		equ boss_syz_x+$140

boss_sbz2_x:		equ $2050				; Scrap Brain Zone act 2 cutscene
boss_sbz2_y:		equ $510

boss_fz_x:		equ $2450				; Final Zone
boss_fz_y:		equ $510
boss_fz_end:		equ boss_fz_x+$2B0

; Tile flags (replaces the old "make_art_tile" function)
Tile_Prio:		equ	1<<15
Tile_Pal1:		equ	0<<13
Tile_Pal2:		equ	1<<13
Tile_Pal3:		equ	2<<13
Tile_Pal4:		equ	3<<13

; VRAM ArtTile definitions
; Multiply by $20 (tile_size) to get the actual location in VRAM

; Shared
ArtTile_GHZ_MZ_Swing:		equ $380
ArtTile_MZ_SYZ_Caterkiller:	equ $4FF
ArtTile_GHZ_SLZ_Smashable_Wall:	equ $50F

; Green Hill Zone
ArtTile_GHZ_Flower_4:		equ ArtTile_Level+$340
ArtTile_GHZ_Edge_Wall:		equ $34C
ArtTile_GHZ_Flower_Stalk:	equ ArtTile_Level+$358
ArtTile_GHZ_Big_Flower_1:	equ ArtTile_Level+$35C
ArtTile_GHZ_Small_Flower:	equ ArtTile_Level+$36C
ArtTile_GHZ_Waterfall:		equ ArtTile_Level+$378
ArtTile_GHZ_Flower_3:		equ ArtTile_Level+$380
ArtTile_GHZ_Bridge:		equ $38E
ArtTile_GHZ_Big_Flower_2:	equ ArtTile_Level+$390
ArtTile_GHZ_Spike_Pole:		equ $398
ArtTile_GHZ_Giant_Ball:		equ $3AA
ArtTile_GHZ_Purple_Rock:	equ $3D0

; Marble Zone
ArtTile_MZ_Block:		equ $2B8
ArtTile_MZ_Animated_Magma:	equ ArtTile_Level+$2D2
ArtTile_MZ_Animated_Lava:	equ ArtTile_Level+$2E2
ArtTile_MZ_Torch:		equ ArtTile_Level+$2F2
ArtTile_MZ_Spike_Stomper:	equ $300
ArtTile_MZ_Fireball:		equ $345
ArtTile_MZ_Glass_Pillar:	equ $38E
ArtTile_MZ_Lava:		equ $3A8

; Spring Yard Zone
ArtTile_SYZ_Bumper:		equ $380
ArtTile_SYZ_Big_Spikeball:	equ $396
ArtTile_SYZ_Spikeball_Chain:	equ $3BA

; Labyrinth Zone
ArtTile_LZ_Block_1:		equ $1E0
ArtTile_LZ_Block_2:		equ $1F0
ArtTile_LZ_Splash:		equ $259
ArtTile_LZ_Gargoyle:		equ $2E9
ArtTile_LZ_Water_Surface:	equ $300
ArtTile_LZ_Spikeball_Chain:	equ $310
ArtTile_LZ_Flapping_Door:	equ $328
ArtTile_LZ_Bubbles:		equ $348
ArtTile_LZ_Moving_Block:	equ $3BC
ArtTile_LZ_Door:		equ $3C4
ArtTile_LZ_Harpoon:		equ $3CC
ArtTile_LZ_Pole:		equ $3DE
ArtTile_LZ_Push_Block:		equ $3DE
ArtTile_LZ_Blocks:		equ $3E6
ArtTile_LZ_Conveyor_Belt:	equ $3F6
ArtTile_LZ_UnusedFace:		equ $440			; Unused
ArtTile_LZ_Rising_Platform:	equ ArtTile_LZ_Blocks+$69
ArtTile_LZ_Orbinaut:		equ $467
ArtTile_LZ_Cork:		equ ArtTile_LZ_Blocks+$11A

; Star Light Zone
ArtTile_SLZ_Seesaw:		equ $374
ArtTile_SLZ_Fan:		equ $3A0
ArtTile_SLZ_Pylon:		equ $3CC
ArtTile_SLZ_Swing:		equ $3DC
ArtTile_SLZ_Orbinaut:		equ $429
ArtTile_SLZ_Fireball:		equ $480
ArtTile_SLZ_Fireball_Launcher:	equ $4D8
ArtTile_SLZ_Collapsing_Floor:	equ $4E0
ArtTile_SLZ_Spikeball:		equ $4F0

; Scrap Brain Zone
ArtTile_SBZ_Caterkiller:	equ $2B0
ArtTile_SBZ_Moving_Block_Short:	equ $2C0
ArtTile_SBZ_Door:		equ $2E8
ArtTile_SBZ_Girder:		equ $2F0
ArtTile_SBZ_Disc:		equ $344
ArtTile_SBZ_Junction:		equ $348
ArtTile_SBZ_Swing:		equ $391
ArtTile_SBZ_Saw:		equ $3B5
ArtTile_SBZ_Flamethrower:	equ $3D9
ArtTile_SBZ_Collapsing_Floor:	equ $3F5
ArtTile_SBZ_Orbinaut:		equ $429
ArtTile_SBZ_Smoke_Puff_1:	equ ArtTile_Level+$448
ArtTile_SBZ_Smoke_Puff_2:	equ ArtTile_Level+$454
ArtTile_SBZ_Moving_Block_Long:	equ $460
ArtTile_SBZ_Horizontal_Door:	equ $46F
ArtTile_SBZ_Electric_Orb:	equ $47E
ArtTile_SBZ_Trap_Door:		equ $492
ArtTile_SBZ_Vanishing_Block:	equ $4C3
ArtTile_SBZ_Spinning_Platform:	equ $4DF

; Final Zone
ArtTile_FZ_Boss:		equ $300
ArtTile_FZ_Eggman_Fleeing:	equ $3A0
ArtTile_FZ_Eggman_No_Vehicle:	equ $470

; General Level Art
ArtTile_Level:			equ $000
ArtTile_Ball_Hog:		equ $302
ArtTile_Bomb:			equ $400
ArtTile_Crabmeat:		equ $400
ArtTile_UnusedExplosion:	equ $41C			; Unused
ArtTile_Buzz_Bomber:		equ $444
ArtTile_Chopper:		equ $47B
ArtTile_Yadrin:			equ $47B
ArtTile_Jaws:			equ $486
ArtTile_Newtron:		equ $49B
ArtTile_Burrobot:		equ $4A6
ArtTile_Basaran:		equ $4B8
ArtTile_Roller:			equ $4B8
ArtTile_Splats:			equ $297			; MZ art ends here; 29 unused tiles before the push block
Splats_Tiles:			equ 29
ArtTile_Moto_Bug:		equ $4F0
ArtTile_Button:			equ $50F
ArtTile_Button_Main:		equ ArtTile_Button+4		; Skips over unused red tiles
ArtTile_Spikes:			equ $51B
ArtTile_Spring_Horizontal:	equ $523
ArtTile_Spring_Vertical:	equ $533
ArtTile_Shield:			equ $541			; 18-tile DPLC slot shared by shield and all stars
Shield_Slot_Tiles:		equ 18
ArtTile_Invincibility:		equ ArtTile_Shield		; never shown with the shield
ArtTile_SuperSonicStars:	equ ArtTile_Shield		; 14 tiles; shield hidden and stars removed while Super
ArtTile_SuperTailsFlickies:	equ ArtTile_Shield		; 14 tiles; Super Tails has no stars
ArtTile_Game_Over:		equ $55E			; $553-$57F no longer hold shield/stars art
ArtTile_Title_Card:		equ $580
ArtTile_Animal_1:		equ $580
ArtTile_Animal_2:		equ $592
ArtTile_Explosion:		equ $5A0
ArtTile_Monitor:		equ $680
ArtTile_HUD:			equ $6CA
ArtTile_HUDScore:		equ ArtTile_HUD+$1A
ArtTile_HUDScore_E:		equ ArtTile_HUDScore-2
ArtTile_HUDTimeMins:		equ ArtTile_HUD+$28
ArtTile_HUDTimeSecs:		equ ArtTile_HUD+$2C
ArtTile_HUDRings:		equ ArtTile_HUD+$30

ArtTile_Sonic:			equ $780
Sonic_Slot_Tiles:		equ 32			; Super frames use up to 31 tiles; ends before spin dust
Tails_Tail_Tiles:		equ 16			; Tails' tails use the second half of the player slot
ArtTile_Tails_Tail:		equ ArtTile_Sonic+Sonic_Slot_Tiles-Tails_Tail_Tiles
ArtTile_Points:			equ ArtTile_Shield+Shield_Slot_Tiles ; $553-$55B, after shield/stars
Points_Tiles:			equ 9
ArtTile_Debug_Stats:		equ ArtTile_Points+Points_Tiles ; SPR label and decimal sprite count
Debug_Stats_Tiles:		equ 5
ArtTile_Lamppost:		equ $D800/$20			; ten tiles just before the HUD
ArtTile_SpinDust:		equ $F400/$20
ArtTile_Ring:			equ $7B2			; current ordinary ring frame, 4 tiles (DMA, #42)
ArtTile_Ring_Lost:		equ ArtTile_Ring+4		; current lost ring frame, 4 tiles (DMA, #42)
ArtTile_Ring_Sparkle:		equ ArtTile_Ring+8		; ring sparkles, 4 tiles (PLC_Main); $7BE-$7BF are free
ArtTile_Lives_Counter:		equ $7D4
ArtTile_Lives_Counter_Num:	equ ArtTile_Lives_Counter+9

; Eggman
ArtTile_Eggman:			equ $400
ArtTile_Eggman_Weapons:		equ $46C
ArtTile_Eggman_Button:		equ $4A4
ArtTile_Eggman_Spikeball:	equ $518
ArtTile_Eggman_Trap_Floor:	equ $518
ArtTile_Eggman_Exhaust:		equ ArtTile_Eggman+$12A

; End of Level
ArtTile_Giant_Ring:		equ ArtTile_Explosion	; shares explosion art while the ring is on screen
ArtTile_Giant_Ring_Flash:	equ ArtTile_Giant_Ring	; flash replaces ring art after collection
ArtTile_Prison_Capsule:		equ $49D
ArtTile_Hidden_Points:		equ $4B6
ArtTile_Warp:			equ $541
ArtTile_Mini_Sonic:		equ $551
ArtTile_Bonuses:		equ $570
; Debug coordinates share tiles with the Game Over art ($55E-$57F) and the
; bonus counters. HudDb_ChkHidden keeps them hidden, and their tiles
; unwritten, while either can be on screen; all 16 are rewritten every
; frame they are shown.
ArtTile_Debug_Coords:		equ $570
Debug_Coords_Tiles:		equ 16
ArtTile_Signpost:		equ $680

; Sega Screen
ArtTile_Sega_Tiles:		equ $000

; Title Screen
; Tile counts of the title graphics; update these when the art changes.
; The title graphics are packed one after another from these counts.
Title_Background_Tiles:		equ $106			; artkosm/8x8 - Title.kosm (at least $106, see below)
Title_Foreground_Tiles:		equ $F0				; artkosm/Title Screen Foreground.kosm (emblem only)
Title_Sonic_Tiles:		equ $20D			; artkosm/Title Screen Sonic.kosm
Title_PSB_Tiles:		equ $12				; artkosm/Title Screen PSB.kosm ("PRESS START BUTTON")
Title_TM_Tiles:			equ 2				; artkosm/Title Screen TM.kosm

ArtTile_Title_Japanese_Text:	equ $000
ArtTile_Title_Foreground:	equ Title_Background_Tiles	; Title Screen.eni (40x28) is relative to this tile
ArtTile_Title_Sonic:		equ ArtTile_Title_Foreground+Title_Foreground_Tiles
ArtTile_Title_PressStart:	equ ArtTile_Title_Sonic+Title_Sonic_Tiles
ArtTile_Title_Trademark:	equ ArtTile_Title_PressStart+Title_PSB_Tiles
ArtTile_Title_Menu: equ $580			; 80 text tiles; $A000 stages submenu tilemaps
Title_Menu_Tiles: equ 4*20
ArtTile_Level_Select_Font:	equ $680
	if ArtTile_Title_Trademark+Title_TM_Tiles>ArtTile_Title_Menu
		error "Title menu overlaps the packed title art"
	endif
	if ArtTile_Title_Menu+Title_Menu_Tiles>vram_fg/tile_size
		error "Title menu overlaps the foreground name table"
	endif
	if ArtTile_Title_Menu<(vram_win+$1000)/tile_size
		error "Title menu overlaps the staged submenu tilemap"
	endif

	; The emblem, big Sonic, "PRESS START" and "TM" load while the "SONIC TEAM
	; PRESENTS" screen still shows its font ($60 tiles at ArtTile_Sonic_Team_Font
	; = $A6, so up to $105); the background art is loaded last, at $0000, once
	; that screen has faded out. The guide's minimum of $105 is one tile short.
	if Title_Background_Tiles<$106
		error "Title_Background_Tiles must be at least $106 to keep the emblem clear of the SONIC TEAM PRESENTS font"
	endif
	if ArtTile_Title_Trademark+Title_TM_Tiles>ArtTile_Level_Select_Font
		error "Title graphics overlap the level select font"
	endif

; Continue Screen
ArtTile_Continue_Sonic:		equ $500
ArtTile_Continue_Number:	equ $6FC

; Ending
ArtTile_Ending_Flowers:		equ $3A0
ArtTile_Ending_Emeralds:	equ $3C5
ArtTile_Ending_Sonic:		equ $3E1
ArtTile_Ending_Eggman:		equ $524
ArtTile_Ending_Rabbit:		equ $553
ArtTile_Ending_Chicken:		equ $565
ArtTile_Ending_Penguin:		equ $573
ArtTile_Ending_Seal:		equ $585
ArtTile_Ending_Pig:		equ $593
ArtTile_Ending_Flicky:		equ $5A5
ArtTile_Ending_Squirrel:	equ $5B3
ArtTile_Ending_STH:		equ $5C5

	; The shared shield/stars slot is written by DMA during play; keep it clear
	; of level-time art that can be on screen at the same time.
	if ArtTile_Shield+Shield_Slot_Tiles>ArtTile_Game_Over
		error "Shield/stars DPLC slot overlaps the Game Over art"
	endif
	if ArtTile_Shield+Shield_Slot_Tiles>ArtTile_Ending_Rabbit
		error "Shield/stars DPLC slot overlaps the ending animals"
	endif
	if ArtTile_Sonic+Sonic_Slot_Tiles>ArtTile_SpinDust
		fatal "Sonic DPLC slot overlaps spin dash dust"
	endif
	if ArtTile_Points+Points_Tiles>ArtTile_Game_Over
		fatal "Points must survive Game Over art loading"
	endif
	if ArtTile_Debug_Stats+Debug_Stats_Tiles>ArtTile_Debug_Coords
		fatal "SPR stats overlap debug coordinate digits"
	endif
	if ArtTile_Shield+Shield_Slot_Tiles>ArtTile_Debug_Coords
		error "Shield/stars DPLC slot overlaps the debug coordinates"
	endif
	if ArtTile_Debug_Coords+Debug_Coords_Tiles>ArtTile_Title_Card
		error "Debug coordinates overlap the title cards"
	endif

; Try Again Screen
ArtTile_Try_Again_Emeralds:	equ $3C5
ArtTile_Try_Again_Eggman:	equ $3E1

; Special Stage
ArtTile_SS_Background_Clouds:	equ $000
ArtTile_SS_Background_Fish:	equ $051
ArtTile_SS_Wall:		equ $142
ArtTile_SS_Plane_1:		equ $200
ArtTile_SS_Bumper:		equ $23B
ArtTile_SS_Goal:		equ $251
ArtTile_SS_Up_Down:		equ $263
ArtTile_SS_R_Block:		equ $2F0
ArtTile_SS_Plane_2:		equ $300
ArtTile_SS_Extra_Life:		equ $370
ArtTile_SS_Emerald_Sparkle:	equ $3F0
ArtTile_SS_Plane_3:		equ $400
ArtTile_SS_Red_White_Block:	equ $470
ArtTile_SS_Ghost_Block:		equ $4F0
ArtTile_SS_Plane_4:		equ $500
ArtTile_SS_W_Block:		equ $570
ArtTile_SS_Glass:		equ $5F0
ArtTile_SS_Plane_5:		equ $600
ArtTile_SS_Plane_6:		equ $700
ArtTile_SS_Emerald:		equ $770
ArtTile_SS_Zone_1:		equ $797
ArtTile_SS_Zone_2:		equ $7A0
ArtTile_SS_Zone_3:		equ $7A9
ArtTile_SS_Zone_4:		equ $797
ArtTile_SS_Zone_5:		equ $7A0
ArtTile_SS_Zone_6:		equ $7A9

; Special Stage Results
ArtTile_SS_Results_Emeralds:	equ $541

; Font
ArtTile_Sonic_Team_Font:	equ $0A6
ArtTile_Credits_Font:		equ $5A0
ArtTile_Credits_Text_Font:	equ $590			; 28 glyphs of 4 tiles, up to the plane A table

; Error Handler
ArtTile_Error_Handler_Font:	equ $7C0

	if ArtTile_Splats<$297
		fatal "Splats must not overwrite the MZ main art."
	endif
	if ArtTile_Splats+Splats_Tiles>ArtTile_MZ_Block
		fatal "Splats must not overwrite the MZ push block."
	endif

; Pattern slots must not intersect any active level-mode VDP table. The
; window is disabled in levels; its reserved address can hold sprite art.
check_game_art_slot: macro first,tiles
	if ((first*tile_size)<(vram_fg+$1000))&&(((first+tiles)*tile_size)>vram_fg)
		fatal "Game art overlaps foreground nametable"
	endif
	if ((first*tile_size)<(vram_bg+$1000))&&(((first+tiles)*tile_size)>vram_bg)
		fatal "Game art overlaps background nametable"
	endif
	if ((first*tile_size)<(vram_sprites+sprites_max*8))&&(((first+tiles)*tile_size)>vram_sprites)
		fatal "Game art overlaps sprite table"
	endif
	if ((first*tile_size)<(vram_hscroll+$400))&&(((first+tiles)*tile_size)>vram_hscroll)
		fatal "Game art overlaps horizontal scroll table"
	endif
	endm

	check_game_art_slot ArtTile_Points,Points_Tiles
	check_game_art_slot ArtTile_Debug_Stats,Debug_Stats_Tiles
	check_game_art_slot ArtTile_Splats,Splats_Tiles
	check_game_art_slot ArtTile_Sonic,Sonic_Slot_Tiles
	check_game_art_slot ArtTile_SpinDust,18
	check_game_art_slot ArtTile_Shield,Shield_Slot_Tiles
	check_game_art_slot ArtTile_Debug_Coords,Debug_Coords_Tiles

; Character resource descriptors (normal and Super are separate records).
Character_Sonic: equ 0
Character_Tails: equ 1
Character_Knuckles: equ 2
Character_Count: equ 3
Character_Off: equ $FF
CharacterAsset_Art: equ 0
CharacterAsset_Map: equ 4
CharacterAsset_DPLC: equ 8
CharacterAsset_Anim: equ 12
CharacterAsset_Palette: equ 16
CharacterAsset_WaterPalette: equ 20
CharacterAsset_SBZ3Palette: equ 24
CharacterAsset_Cycle: equ 28
CharacterAsset_WaterCycle: equ 32
CharacterAsset_SBZ3Cycle: equ 36
CharacterAsset_Run: equ 40
CharacterAsset_Walk: equ 44
CharacterAsset_Roll: equ 48
CharacterAsset_RollFast: equ 52
CharacterAsset_Push: equ 56
CharacterAsset_Figure8: equ 60
CharacterAsset_SharedArt: equ 64
CharacterAsset_SharedFirst: equ 68
CharacterAsset_SharedEnd: equ 69
CharacterAsset_PaletteID: equ 70
CharacterAsset_WaterID: equ 71
CharacterAsset_SBZ3ID: equ 72
CharacterAsset_HUD: equ 73
CharacterAsset_CycleStep: equ 74	; Super cycle frames per steady step, minus one
CharacterAsset_CycleHold: equ 75	; frames on the last steady step, minus one
CharacterAsset_CycleLast: equ 76	; byte offset of the last steady cycle frame
CharacterAsset_WalkFrames: equ 77	; walking frames per floor orientation: 6 (Sonic 1) or 8
CharacterAsset_Size: equ 78

; Read one pointer using a descriptor getter; target must not be a3.
; The lookup preserves all input registers and flags except target and a3;
; this macro additionally preserves a3. MOVEA targets also preserve flags.
character_asset: macro field,target,form
        move.l a3,-(sp)
        jsr (form).l
        move.l field(a3),target
        movea.l (sp)+,a3
        endm
