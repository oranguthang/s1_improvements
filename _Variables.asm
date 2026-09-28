; ===========================================================================
; ---------------------------------------------------------------------------
; RAM Variables
; ---------------------------------------------------------------------------

	include "s1.sounddriver.ram.asm"

; Sign-extends a 32-bit integer to 64-bit
; (All RAM addresses are run through this function to allow them to work in both 16-bit and 32-bit addressing modes.)
ramaddr function x,(-(x&$80000000)<<1)|x

; v = Variables // f = Flags
	phase ramaddr ( $FFFF0000 )
v_ram_start_def:
v_ram_start:		equ	v_ram_start_def&$FFFFFF		; 24-bit addressing

v_256x256_def:		ds.b	chunk_size*$52			; formerly 256x256 chunk mappings (now read from ROM via v_rom_chunks);
								; still scratch RAM for Sega/title/Special Stage and the ending flowers
v_256x256:		equ	v_256x256_def&$FFFFFF		; 24-bit addressing
v_256x256_end:
v_ending_flowers:	equ	v_256x256_def+$4A*chunk_size	; decompressed ending flower art ($1000 bytes, $FF9400-$FFA3FF)
v_ending_flowers_end:	equ	v_256x256_end

v_lvllayout:		ds.b	layout_row*8			; level layouts (FG/BG rows interlaced, 8 rows and $400 total)
v_lvllayout_fg:		equ	v_lvllayout			; start address of foreground's first row
v_lvllayout_bg:		equ	v_lvllayout+layout_row_interlaced ; start address of background's first row
v_lvllayout_end:

v_bgscroll_buffer:	ds.b	$200				; background scroll buffer
v_ngfx_buffer:		ds.b	$200				; Nemesis graphics decompression buffer
v_ngfx_buffer_end:

v_spritequeue:		ds.b	spritelayer_num*spritelayer_size ; sprite display queue, in order of priority (8*$80=$400 bytes)

v_16x16:
Object_Respawn_Table: ds.b $300                ; one state byte per placed object
Object_Respawn_Table_End:
Camera_X_Pos_Last: ds.w 1
Camera_Y_Pos_Last: ds.w 1
Camera_X_Coarse_Back: ds.w 1
Camera_Y_Coarse_Back: ds.w 1
Object_Manager_Size: equ *-v_16x16
v_ringmanager:
v_ringstates: ds.b 512                 ; one state byte per ordinary ring
v_ringstates_pointer: ds.w 1
v_ringwindow_start: ds.l 1
v_ringwindow_end: ds.l 1
v_ringanimqueue_count: ds.w 1
v_ringanimqueue: ds.w $3F
v_draw_rings: ds.b 1
v_ringmanager_size: equ *-v_ringmanager
                    even                        ; Kosinski DMA source must be word aligned
Engine_Managers_Size: equ *-v_16x16
Art_Buffer:         ds.b $1000               ; one decompressed KosM module
Art_Buffer_End:
                    ds.b $1800-Engine_Managers_Size-$1000 ; reserve the rest

VDP_Command_Buffer:	ds.w	7*$12			; 18 queued VDP commands
VDP_Command_Buffer_Slot: ds.l	1			; next free DMA queue slot
colqueue_entries:	equ	96				; one entry per level object slot (checked in ExecuteObjects)
v_colqueue_ptr:		ds.w	1				; next free v_colqueue entry (outside the queue = ReactToItem does a full scan)
f_colqueue_fullscan:	ds.b	1				; flag set to make ReactToItem do a full scan instead of using the queue
			ds.b	1				; unused
v_colqueue:		ds.w	colqueue_entries		; collision response queue: level objects with obColType set, in RAM order
v_colqueue_end:
v_ringart_static:	ds.b	1				; ordinary ring frame queued into ArtTile_Ring, -1 = slot not valid (#42)
v_ringart_lost:		ds.b	1				; lost ring frame queued into ArtTile_Ring_Lost, -1 = slot not valid (#42)
			ds.b	$200-4-colqueue_entries*2-2	; unused after queues
v_tracksonic:		ds.b	$100				; position tracking data for Sonic
v_hscrolltablebuffer:	ds.b	$380				; scrolling table data
v_hscrolltablebuffer_end:
			ds.b	$80				; would be unused, but data from v_hscrolltablebuffer can spill into here
v_hscrolltablebuffer_end_padded:

v_objspace:		ds.b	object_size*$80			; object variable space ($40 bytes per object)

; Title screen objects
v_sonicteam:		equ	v_objspace+object_size*2	; object variable space for the "SONIC TEAM PRESENTS" text ($40 bytes)
v_titlesonic:		equ	v_objspace+object_size*1	; object variable space for Sonic in the title screen ($40 bytes)
v_pressstart:		equ	v_objspace+object_size*2	; object variable space for the "PRESS START BUTTON" text ($40 bytes)
v_titletm:		equ	v_objspace+object_size*3	; object variable space for the trademark symbol ($40 bytes)
v_ttlsonichide:		equ	v_objspace+object_size*4	; object variable space for hiding part of Sonic ($40 bytes)
v_title_emblembuf:	equ	v_objspace+object_size*$40	; title emblem Enigma buffer in unused object slots (cleared after use)
v_title_emblembuf_end:	equ	v_title_emblembuf+40*28*2	; full-screen emblem tilemap ($8C0 bytes, slots $40-$62)

; Level objects
v_player:		equ	v_objspace+object_size*0	; object variable space for Sonic ($40 bytes)
v_hud:			equ	v_objspace+object_size*1	; object variable space for the HUD ($40 bytes)

v_titlecard:		equ	v_objspace+object_size*2	; object variable space for the title card ($100 bytes)
v_ttlcardname:		equ	v_titlecard+object_size*0	; object variable space for the title card zone name text ($40 bytes)
v_ttlcardzone:		equ	v_titlecard+object_size*1	; object variable space for the title card "ZONE" text ($40 bytes)
v_ttlcardact:		equ	v_titlecard+object_size*2	; object variable space for the title card act text ($40 bytes)
v_ttlcardoval:		equ	v_titlecard+object_size*3	; object variable space for the title card oval ($40 bytes)

v_gameovertext1:	equ	v_objspace+object_size*2	; object variable space for the "GAME"/"TIME" in "GAME OVER"/"TIME OVER" text ($40 bytes)
v_gameovertext2:	equ	v_objspace+object_size*3	; object variable space for the "OVER" in "GAME OVER"/"TIME OVER" text ($40 bytes)

v_shieldobj:		equ	v_objspace+object_size*6	; object variable space for the shield ($40 bytes)
v_dustobj:		equ	v_objspace+object_size*7	; Spin Dash dust object
v_starsobj1:		equ	v_objspace+object_size*8	; object variable space for the invincibility stars #1 ($40 bytes)
v_starsobj2:		equ	v_objspace+object_size*9	; object variable space for the invincibility stars #2 ($40 bytes)
v_starsobj3:		equ	v_objspace+object_size*10	; object variable space for the invincibility stars #3 ($40 bytes)
v_starsobj4:		equ	v_objspace+object_size*11	; object variable space for the invincibility stars #4 ($40 bytes)
v_superstars:		equ	v_starsobj1			; Super Sonic speed trail uses the first stars slot

v_splash:		equ	v_objspace+object_size*12	; object variable space for the water splash ($40 bytes)
v_sonicbubbles:		equ	v_objspace+object_size*13	; object variable space for the bubbles that come out of Sonic's mouth/drown countdown ($40 bytes)
v_watersurface1:	equ	v_objspace+object_size*30	; object variable space for the water surface #1 ($40 bytes)
v_watersurface2:	equ	v_objspace+object_size*31	; object variable space for the water surface #1 ($40 bytes)

v_endcard:		equ	v_objspace+object_size*23	; object variable space for the level results card ($1C0 bytes)
v_endcardsonic:		equ	v_endcard+object_size*0		; object variable space for the level results card "SONIC HAS" text ($40 bytes)
v_endcardpassed:	equ	v_endcard+object_size*1		; object variable space for the level results card "PASSED" text ($40 bytes)
v_endcardact:		equ	v_endcard+object_size*2		; object variable space for the level results card act text ($40 bytes)
v_endcardscore:		equ	v_endcard+object_size*3		; object variable space for the level results card score tally ($40 bytes)
v_endcardtime:		equ	v_endcard+object_size*4		; object variable space for the level results card time bonus tally ($40 bytes)
v_endcardring:		equ	v_endcard+object_size*5		; object variable space for the level results card ring bonus tally ($40 bytes)
v_endcardoval:		equ	v_endcard+object_size*6		; object variable space for the level results card oval ($40 bytes)

v_lvlobjspace:		equ	v_objspace+object_size*32	; level object variable space ($1800 bytes)
v_lvlobjend:		equ	v_lvlobjspace+object_size*96
v_objspace_end:		equ	v_lvlobjend

; Special Stage objects
v_ssrescard:		equ	v_objspace+object_size*23	; object variable space for the Special Stage results card ($140 bytes)
v_ssrestext:		equ	v_ssrescard+object_size*0	; object variable space for the Special Stage results card text ($40 bytes)
v_ssresscore:		equ	v_ssrescard+object_size*1	; object variable space for the Special Stage results card score tally ($40 bytes)
v_ssresring:		equ	v_ssrescard+object_size*2	; object variable space for the Special Stage results card ring bonus tally ($40 bytes)
v_ssresoval:		equ	v_ssrescard+object_size*3	; object variable space for the Special Stage results card oval ($40 bytes)
v_ssrescontinue:	equ	v_ssrescard+object_size*4	; object variable space for the Special Stage results card continue icon ($40 bytes)
v_ssresemeralds:	equ	v_objspace+object_size*32	; object variable space for the emeralds in the Special Stage results ($180 bytes)

; Continue screen objects
v_continuetext:		equ	v_objspace+object_size*1	; object variable space for the continue screen text ($40 bytes)
v_continuelight:	equ	v_objspace+object_size*2	; object variable space for the continue screen light spot ($40 bytes)
v_continueicon:		equ	v_objspace+object_size*3	; object variable space for the continue screen icon ($40 bytes)

; Ending objects
v_endemeralds:		equ	v_objspace+object_size*16	; object variable space for the emeralds in the ending ($180 bytes)
v_endemeralds_end:	equ	v_objspace+object_size*32
v_endlogo:		equ	v_objspace+object_size*16	; object variable space for the logo in the ending ($40 bytes)

; Credits objects
v_credits:		equ	v_objspace+object_size*2	; object variable space for the credits text ($40 bytes)
v_endeggman:		equ	v_objspace+object_size*2	; object variable space for Eggman after the credits ($40 bytes)
v_tryagain:		equ	v_objspace+object_size*3	; object variable space for the "TRY AGAIN" text ($40 bytes)
v_eggmanchaos:		equ	v_objspace+object_size*32	; object variable space for the emeralds juggled by Eggman ($180 bytes)

v_snddriver_ram:	SMPS_RAM				; sound driver state
			ds.b	$40				; unused

v_gamemode:		ds.b	1				; game mode (00=Sega; 04=Title; 08=Demo; 0C=Level; 10=SS; 14=Cont; 18=End; 1C=Credit; +8C=PreLevel)
			ds.b	1				; unused
v_jpadhold2:		ds.b	1				; joypad input - held, duplicate
v_jpadpress2:		ds.b	1				; joypad input - pressed, duplicate
v_jpadhold1:		ds.b	1				; joypad input - held
v_jpadpress1:		ds.b	1				; joypad input - pressed
			ds.b	6				; unused
v_vdp_buffer1:		ds.w	1				; VDP instruction buffer of register $81 (used for enabling/disabling display)
			ds.b	6				; unused
v_generictimer:		ds.w	1				; generic timer, decrements to 0 in VBlank (word)
v_scrposy_vdp:		ds.w	1				; screen position y (VDP)
v_bgscrposy_vdp:	ds.w	1				; background screen position y (VDP)
v_scrposx_vdp:		ds.w	1				; screen position x (VDP)
v_bgscrposx_vdp:	ds.w	1				; background screen position x (VDP)
v_bg3scrposy_vdp:	ds.w	1
v_bg3scrposx_vdp:	ds.w	1
			ds.b	2				; unused
v_hblank_hreg:		ds.w	1				; VDP H.interrupt register buffer (8Axx) (previously called v_hbla_hreg)
v_hblank_line:		equ	v_hblank_hreg+1			; screen line where water starts and palette is changed by HBlank (previously called v_hbla_line)
v_pfade_start:		ds.b	1				; palette fading - start position in bytes
v_pfade_size:		ds.b	1				; palette fading - number of colours

v_misc_variables:
v_vblank_0e_counter:	ds.b	1				; tracks how many times vertical interrupts routine 0E occurred (pretty much unused because routine 0E is unused)
v_palmuscounter:	ds.b	1				; keeps music at the correct tempo in PAL regions
v_vblank_routine:	ds.b	1				; VBlank - routine counter (previously called v_vbla_routine)
			ds.b	1				; unused
v_spritecount:		ds.b	1				; number of sprites on-screen
			ds.b	5				; unused
v_pcyc_num:		ds.w	1				; palette cycling - current reference number
v_pcyc_time:		ds.w	1				; palette cycling - time until the next change
v_random:		ds.l	1				; pseudo random number buffer
f_pause:		ds.w	1				; flag set to pause the game
f_title_fast:		ds.b	1				; debug pause exit skips SONIC TEAM PRESENTS once
v_debug_deathmusic:	ds.b	1				; debug rescue: 0=keep song, 1=restore act/boss, 2=normal tempo
			ds.b	2				; unused
v_vdp_buffer2:		ds.w	1				; VDP instruction buffer
			ds.b	2				; unused
f_hblank_pal:		ds.w	1				; flag set to change palette during HBlank (0000 = no; 0001 = change) (previously called f_hbla_pal)
v_waterpos1:		ds.w	1				; water height, actual
v_waterpos2:		ds.w	1				; water height, ignoring sway
v_waterpos3:		ds.w	1				; water height, next target
f_water:		ds.b	1				; flag set for water
v_wtr_routine:		ds.b	1				; water event - routine counter
f_wtr_state:		ds.b	1				; water palette state when water is above/below the screen (00 = partly/all dry; 01 = all underwater)
f_doupdatesinhblank:	ds.b	1				; defers performing various tasks to the Horizontal Interrupt (HBlank)
v_pal_buffer:		ds.b	$30				; palette data buffer (used for palette cycling)
v_misc_variables_end:

plc_slot_size:		equ	4+2				; size of a single PLC slot: 6 bytes = 4 bytes (data address) + 2 bytes (VRAM target address)
v_plc_buffer:		ds.b	plc_slot_size*16		; pattern load cues buffer (maximum $10 PLCs)
v_plc_buffer_dest:	equ	v_plc_buffer+4			; VRAM destination for 1st item in PLC buffer (2 bytes)
v_plc_buffer_only_end:
v_plc_artptr:      ds.l 1                  ; next compressed module, zero before a new cue
v_plc_patternsleft: ds.w 1                 ; decompressed bytes remaining in active cue
                    ds.w 1                  ; pad ClearPLC region to longword boundary
v_plc_buffer_end:                           ; ClearPLC clears up to here
v_plc_peak:        ds.b 1                  ; maximum occupied PLC slots
v_plc_overflow:    ds.b 1                  ; truncated PLC lists, saturating counter
v_plc_dma_pending: ds.b 1                  ; Art_Buffer is still a DMA source
                    ds.b 1                  ; spare
                    ds.b $14                ; keep following level RAM at its original address
v_levelvariables:						; variables that are reset between levels
v_screenposx:		ds.l	1				; screen position x
v_screenposy:		ds.l	1				; screen position y
v_bgscreenposx:		ds.l	1				; background screen position x
v_bgscreenposy:		ds.l	1				; background screen position y
v_bg2screenposx:	ds.l	1
v_bg2screenposy:	ds.l	1
v_bg3screenposx:	ds.l	1
v_bg3screenposy:	ds.l	1
v_limitleft1:		ds.w	1				; left level boundary (unused)
v_limitright1:		ds.w	1				; right level boundary (unused)
v_limittop1:		ds.w	1				; top level boundary (unused)
v_limitbtm1:		ds.w	1				; bottom level boundary
v_limitleft2:		ds.w	1				; left level boundary
v_limitright2:		ds.w	1				; right level boundary
v_limittop2:		ds.w	1				; top level boundary
v_limitbtm2:		ds.w	1				; bottom level boundary
v_unused11:		ds.w	1				; unused
v_limitleft3:		ds.w	1				; left level boundary, at the end of an act
v_shieldartkey:		ds.w	1				; current shield/stars DPLC key
v_squashframe:		ds.w	1				; frame of last squeeze
v_squashobject:		ds.w	1				; object causing the last squeeze
v_scrshiftx:		ds.w	1				; x-screen shift (new - last) * $100
v_scrshifty:		ds.w	1				; y-screen shift (new - last) * $100
v_lookshift:		ds.w	1				; screen shift when Sonic looks up/down
v_unused7:		ds.b	1				; unused
v_unused8:		ds.b	1				; unused
v_dle_routine:		ds.b	1				; dynamic level event - routine counter
			ds.b	1				; unused
f_nobgscroll:		ds.b	1				; flag set to cancel background scrolling
			ds.b	1				; unused
v_unused9:		ds.b	1				; unused
			ds.b	1				; unused
v_unused10:		ds.b	1				; unused
			ds.b	1				; unused
v_fg_xblock:		ds.b	1				; foreground x-block parity (for redraw)
v_fg_yblock:		ds.b	1				; foreground y-block parity (for redraw)
v_bg1_xblock:		ds.b	1				; background x-block parity (for redraw)
v_bg1_yblock:		ds.b	1				; background y-block parity (for redraw)
v_bg2_xblock:		ds.b	1				; secondary background x-block parity (for redraw)
v_bg2_yblock:		ds.b	1				; secondary background y-block parity (unused)
v_bg3_xblock:		ds.b	1				; tertiary background x-block parity (for redraw)
v_bg3_yblock:		ds.b	1				; tertiary background y-block parity (unused)
			ds.b	2				; unused
v_fg_scroll_flags:	ds.w	1				; screen redraw flags for foreground
v_bg1_scroll_flags:	ds.w	1				; screen redraw flags for background 1
v_bg2_scroll_flags:	ds.w	1				; screen redraw flags for background 2
v_bg3_scroll_flags:	ds.w	1				; screen redraw flags for background 3
f_bgscrollvert:		ds.b	1				; flag for vertical background scrolling
			ds.b	3				; unused
v_sonspeedmax:		ds.w	1				; Sonic's maximum speed
v_sonspeedacc:		ds.w	1				; Sonic's acceleration
v_sonspeeddec:		ds.w	1				; Sonic's deceleration
v_sonframenum:		ds.b	1				; frame to display for Sonic
f_sonframechg:		ds.b	1				; flag set to update Sonic's sprite frame
v_anglebuffer:		ds.b	1				; angle of collision block that Sonic or object is standing on
			ds.b	1				; unused
v_anglebuffer2:		ds.b	1				; other angle of collision block that Sonic or object is standing on
			ds.b	1				; unused
v_opl_routine:		ds.b	1				; ObjPosLoad - routine counter
			ds.b	1				; unused
v_opl_screen:		ds.w	1				; ObjPosLoad - screen variable
v_opl_data:		ds.b	$10				; ObjPosLoad - data buffer
v_ssangle:		ds.w	1				; Special Stage angle
v_ssrotate:		ds.w	1				; Special Stage rotation speed
v_ssangleprev:		ds.b	1				; Special Stage wall rotation frame currently queued to VRAM ($FF = none)
			ds.b	$B				; unused
v_btnpushtime1:		ds.w	1				; button push duration - in level
v_btnpushtime2:		ds.w	1				; button push duration - in demo
v_palchgspeed:		ds.w	1				; palette fade/transition speed (0 is fastest)
v_collindex:		ds.l	1				; ROM address for collision index of current level
v_palss_num:		ds.w	1				; palette cycling in Special Stage - reference number
v_palss_time:		ds.w	1				; palette cycling in Special Stage - time until next change
v_palss_index:		ds.w	1				; palette cycling in Special Stage - index into palette cycle 2 (unused?)
v_ssbganim:		ds.w	1				; Special Stage background animation
v_camera_pan:		ds.w	1				; horizontal camera focus (160 +/- 64px)
v_obj31ypos:		ds.w	1				; y-position of object 31 (MZ stomper)
			ds.b	1				; unused
v_bossstatus:		ds.b	1				; status of boss and prison capsule (01 = boss defeated; 02 = prison opened)
v_trackpos:		ds.w	1				; position tracking reference number
v_trackbyte:		equ	v_trackpos+1			; low byte for position tracking
f_lockscreen:		ds.b	1				; flag set to lock screen during bosses
f_bossmusic:		ds.b	1				; boss music phase, independent of the camera lock
v_256loop1:		ds.b	1				; 256x256 level tile which contains a loop (GHZ/SLZ)
v_256loop2:		ds.b	1				; 256x256 level tile which contains a loop (GHZ/SLZ)
v_256roll1:		ds.b	1				; 256x256 level tile which contains a roll tunnel (GHZ)
v_256roll2:		ds.b	1				; 256x256 level tile which contains a roll tunnel (GHZ)
v_lani0_frame:		ds.b	1				; level graphics animation 0 - current frame
v_lani0_time:		ds.b	1				; level graphics animation 0 - time until next frame
v_lani1_frame:		ds.b	1				; level graphics animation 1 - current frame
v_lani1_time:		ds.b	1				; level graphics animation 1 - time until next frame
v_lani2_frame:		ds.b	1				; level graphics animation 2 - current frame
v_lani2_time:		ds.b	1				; level graphics animation 2 - time until next frame
v_lani3_frame:		ds.b	1				; level graphics animation 3 - current frame
v_lani3_time:		ds.b	1				; level graphics animation 3 - time until next frame
v_lani4_frame:		ds.b	1				; level graphics animation 4 - current frame
v_lani4_time:		ds.b	1				; level graphics animation 4 - time until next frame
v_lani5_frame:		ds.b	1				; level graphics animation 5 - current frame
v_lani5_time:		ds.b	1				; level graphics animation 5 - time until next frame
v_gfxexplosionrestore:	ds.b	1				; restore explosion art on the next VBlank
v_gfxringslotstate:	ds.b	1				; bit 0: flash; bit 1: ring; bit 2: flash DMA pending
v_gfxbigring:		ds.w	1				; settings for giant ring graphics loading
f_conveyrev:		ds.b	1				; flag set to reverse conveyor belts in LZ/SBZ
v_obj63:		ds.b	6				; flags set if conveyor group is loaded for LZ (object 63) and SBZ (object 6F)
f_wtunnelmode:		ds.b	1				; LZ water tunnel mode
f_playerctrl:		ds.b	1				; Player control override flags (object interaction, control enable)
f_wtunneldisallow:	ds.b	1				; LZ water tunnels (00 = enabled; 01 = disabled)
f_slidemode:		ds.b	1				; LZ water slide mode
v_obj6B:		ds.b	1				; object 6B (SBZ stomper) variable
f_lockctrl:		ds.b	1				; flag set to lock controls during ending sequence
f_bigring:		ds.b	1				; flag set when Sonic collects the giant ring
f_obj56:		ds.b	1				; object 56 flag
v_squashbuffer:		ds.b	1				; last small squeeze depth, reset each collision-free frame
v_itembonus:		ds.w	1				; item bonus from broken enemies, blocks etc.
v_timebonus:		ds.w	1				; time bonus at the end of an act
v_ringbonus:		ds.w	1				; ring bonus at the end of an act
f_endactbonus:		ds.b	1				; time/ring bonus update flag at the end of an act
v_sonicend:		ds.b	1				; routine counter for Sonic in the ending sequence
v_lz_deform:		ds.w	1				; LZ deformation offset, in units of $80
v_cam_x_delay:		ds.w	1				; horizontal camera delay after a Spin Dash
v_cam_y_delay:		ds.b	1				; look up/down delay
v_spindash_sfx_flag:	ds.b	1			; last sound was Spin Dash rev
v_spindash_sfx_timer:	ds.b	1			; rev pitch timeout
v_spindash_sfx_pitch:	ds.b	1			; rev pitch
f_switch:		ds.b	$10				; flags set when Sonic stands on a switch
v_scroll_block_1_size:	ds.w	1
v_scroll_block_2_size:	ds.w	1				; unused
v_scroll_block_3_size:	ds.w	1				; unused
v_scroll_block_4_size:	ds.w	1				; unused
v_rom_blocks:		ds.l	1				; pointer to the current 16x16 block mappings in ROM
v_rom_chunks:		ds.l	1				; pointer to the current 256x256 chunk mappings in ROM
v_levelvariables_end:

v_spritetablebuffer:	ds.b	spritetable_entrysize*sprites_max ; sprite table (8*80=$280 bytes) (last $80 bytes are overwritten by v_palette_water_fading)
v_spritetablebuffer_end:

v_palette_water_fading:	equ	v_spritetablebuffer_end-$80	; duplicate underwater palette, used for transitions ($80 bytes)

; Main underwater palette
v_palette_water:
v_palette_water_line_1:	ds.b $20
v_palette_water_line_2:	ds.b $20
v_palette_water_line_3:	ds.b $20
v_palette_water_line_4:	ds.b $20
v_palette_water_end:

; Main palette
v_palette:
v_palette_line_1:	ds.b $20
v_palette_line_2:	ds.b $20
v_palette_line_3:	ds.b $20
v_palette_line_4:	ds.b $20
v_palette_end:

; Palette buffer used for fade-in
v_palette_fading:
v_palette_fading_line_1:ds.b $20
v_palette_fading_line_2:ds.b $20
v_palette_fading_line_3:ds.b $20
v_palette_fading_line_4:ds.b $20
v_palette_fading_end:

v_error_workspace:	ds.b	$C0				; former object state list: error data plus $7B spare bytes
v_error_workspace_end:

v_systemstack_end:	ds.b	$140				; system stack end (items get added backwards)
v_systemstack:							; system stack start

; --- RAM beyond this point is only cleared on a cold boot ---

v_crossresetram:
v_midring_act:		ds.w	1				; act whose free giant rings have been used
f_restart:		ds.w	1				; restart level flag
v_framecount:		ds.w	1				; frame counter (adds 1 every frame)
v_framebyte:		equ	v_framecount+1			; low byte for frame counter
v_debugitem:		ds.b	1				; debug item currently selected (NOT the object number of the item)
			ds.b	1				; unused
v_debuguse:		ds.w	1				; debug mode use & routine counter (when Sonic is a ring/item)
v_debugspeedtimer:	ds.b	1				; debug mode - timer before movement starts
v_debugspeed:		ds.b	1				; debug mode - movement speed
v_vblank_count:		ds.l	1				; vertical interrupt counter (adds 1 every VBlank)
v_vblank_word:		equ	v_vblank_count+2 		; low word for vertical interrupt counter (2 bytes)
v_vblank_byte:		equ	v_vblank_word+1			; low byte for vertical interrupt counter
v_zone:			ds.b	1				; current zone number
v_act:			ds.b	1				; current act number
v_zone_act:		equ	v_zone				; when v_zone is read as word
v_lives:		ds.b	1				; number of lives
			ds.b	1				; unused
v_air:			ds.w	1				; air remaining while underwater
v_airbyte:		equ	v_air+1				; low byte for air
v_lastspecial:		ds.b	1				; last special stage number
v_midring_flags:	ds.b	1				; collected free giant rings in current act
v_continues:		ds.b	1				; number of continues
			ds.b	1				; unused
f_timeover:		ds.b	1				; time over flag
v_lifecount:		ds.b	1				; bits 0-6: 100-ring extra lives already awarded; bit 7: Special Stage continue awarded
f_lifecount:		ds.b	1				; lives counter update flag
f_ringcount:		ds.b	1				; ring counter update flag
f_timecount:		ds.b	1				; time counter update flag
f_scorecount:		ds.b	1				; score counter update flag
v_rings:		ds.w	1				; rings
v_ringbyte:		equ	v_rings+1			; low byte for rings
v_time:			ds.l	1				; time
v_timemin:		equ	v_time+1			; time - minutes
v_timesec:		equ	v_time+2			; time - seconds
v_timecent:		equ	v_time+3			; time - centiseconds
v_score:		ds.l	1				; score
			ds.b	2				; unused
v_shield:		ds.b	1				; shield status (00 = no; 01 = yes)
v_invinc:		ds.b	1				; invincibility status (00 = no; 01 = yes)
v_shoes:		ds.b	1				; speed shoes status (00 = no; 01 = yes)
v_unused1:		ds.b	1				; an unused fourth player status (Goggles?)
v_supersonic:		equ v_unused1
v_lastlamp:		ds.b	2				; number of the last lamppost you hit
v_lamp_xpos:		ds.w	1				; x-axis for Sonic to respawn at lamppost
v_lamp_ypos:		ds.w	1				; y-axis for Sonic to respawn at lamppost
v_lamp_rings:		ds.w	1				; rings stored at lamppost
v_lamp_time:		ds.l	1				; time stored at lamppost
v_lamp_dle:		ds.b	1				; dynamic level event routine counter at lamppost
			ds.b	1				; unused
v_lamp_limitbtm:	ds.w	1				; level bottom boundary at lamppost
v_lamp_scrx:		ds.w	1				; x-axis screen at lamppost
v_lamp_scry:		ds.w	1				; y-axis screen at lamppost
v_lamp_bgscrx:		ds.w	1				; x-axis BG screen at lamppost
v_lamp_bgscry:		ds.w	1				; y-axis BG screen at lamppost
v_lamp_bg2scrx:		ds.w	1				; x-axis BG2 screen at lamppost
v_lamp_bg2scry:		ds.w	1				; y-axis BG2 screen at lamppost
v_lamp_bg3scrx:		ds.w	1				; x-axis BG3 screen at lamppost
v_lamp_bg3scry:		ds.w	1				; y-axis BG3 screen at lamppost
v_lamp_wtrpos:		ds.w	1				; water position at lamppost
v_lamp_wtrrout:		ds.b	1				; water routine at lamppost
v_lamp_wtrstat:		ds.b	1				; water state at lamppost
v_lamp_lives:		ds.b	1				; v_lifecount at lamppost (100-ring extra lives already awarded)
			ds.b	2				; unused
v_emeralds:		ds.b	1				; number of chaos emeralds
v_emldlist:		ds.b	6				; special stage where each emerald was obtained
v_oscillate:		ds.w	1				; oscillation bitfield
v_timingandscreenvariables:
v_timingvariables:
			ds.b	$40				; values which oscillate - for swinging platforms, et al
			ds.b	$20				; unused
v_ani0_time:		ds.b	1				; synchronised sprite animation 0 - time until next frame (used for synchronised animations)
v_ani0_frame:		ds.b	1				; synchronised sprite animation 0 - current frame
v_ani1_time:		ds.b	1				; synchronised sprite animation 1 - time until next frame
v_ani1_frame:		ds.b	1				; synchronised sprite animation 1 - current frame
v_ani2_time:		ds.b	1				; synchronised sprite animation 2 - time until next frame
v_ani2_frame:		ds.b	1				; synchronised sprite animation 2 - current frame
v_ani3_time:		ds.b	1				; synchronised sprite animation 3 - time until next frame
v_ani3_frame:		ds.b	1				; synchronised sprite animation 3 - current frame
v_ani3_buf:		ds.w	1				; synchronised sprite animation 3 - info buffer
			ds.b	$26				; unused
v_limittopdb:		ds.w	1				; level upper boundary, buffered for debug mode
v_limitbtmdb:		ds.w	1				; level bottom boundary, buffered for debug mode
			ds.b	$C				; unused
v_timingvariables_end:

	if FixBugs	; With the bug fix introduced in FindNearestTile, this variable will no longer cause any trouble
			ds.w	1				; (truly) unused
	else
v_chunk0collision:	ds.w	1				; very subtly (and perhaps unintentionally) used by FindNearestTile when encountering chunk 0
		if v_chunk0collision<>ramaddr($FFFFFF00)
			error "v_chunk0collision needs to be at address $FFFFFF00 so that FindNearestTile works correctly (currently offset by \{signedToString(v_chunk0collision-ramaddr($FFFFFF00))} bytes) ."
		endif
	endif
			ds.b	$E				; unused
v_screenposx_dup:	ds.l	1				; screen position x (duplicate)
v_screenposy_dup:	ds.l	1				; screen position y (duplicate)
v_bgscreenposx_dup:	ds.l	1				; background screen position x (duplicate)
v_bgscreenposy_dup:	ds.l	1				; background screen position y (duplicate)
v_bg2screenposx_dup:	ds.l	1
v_bg2screenposy_dup:	ds.l	1
v_bg3screenposx_dup:	ds.l	1
v_bg3screenposy_dup:	ds.l	1
v_fg_scroll_flags_dup:	ds.w	1
v_bg1_scroll_flags_dup:	ds.w	1
v_bg2_scroll_flags_dup:	ds.w	1
v_bg3_scroll_flags_dup:	ds.w	1
v_superpal_frame:	ds.w	1				; byte offset in the Super Sonic palette cycle
v_superpal_timer:	ds.b	1				; frames until the next palette step
v_superpal_state:	ds.b	1				; 0=off, 1=transform, 2=revert, 3=transform after landing, $FF=cycle
			ds.b	$44				; unused
v_timingandscreenvariables_end:

v_levseldelay:		ds.w	1				; level select - time until change when up/down is held
v_levselitem:		ds.w	1				; level select - item selected
v_levselsound:		ds.w	1				; level select - sound selected
			ds.b	$3A				; unused
	if Revision=0
v_scorecopy:		ds.l	1				; score, duplicate (REV00 only)
	else
v_scorelife:		ds.l	1				; points required for an extra life (REV01 only)
	endif
			ds.b	$1C				; unused
f_levselcheat:		ds.b	1				; level select cheat flag
f_slomocheat:		ds.b	1				; slow motion & frame advance cheat flag
f_debugcheat:		ds.b	1				; debug mode cheat flag
f_creditscheat:		ds.b	1				; hidden Japanese credits & 9E/9F sound test shortcuts cheat flag
v_title_dcount:		ds.w	1				; number of times the d-pad is pressed on title screen
v_title_ccount:		ds.w	1				; number of times C is pressed on title screen
			ds.b	2				; unused
v_unused2:		ds.w	1				; unused
v_superframe:		equ v_unused2
v_unused3:		ds.b	1				; unused
v_superinputtime:	equ v_unused3
v_unused4:		ds.b	1				; unused
v_superinputmask:	equ v_unused4
v_unused5:		ds.b	1				; unused
v_unused6:		ds.b	1				; unused
f_demo:			ds.w	1				; demo mode flag (0 = no; 1 = yes; $8001 = ending)
v_demonum:		ds.w	1				; demo level number (not the same as the level number)
v_creditsnum:		ds.w	1				; credits index number
			ds.b	2				; unused
v_megadrive:		ds.b	1				; Mega Drive machine type
			ds.b	1				; unused
f_debugmode:		ds.w	1				; debug mode flag
v_init:			ds.l	1				; 'init' text string

v_ram_end:
	if * > 0
		; Don't declare more space than the RAM can contain!
		fatal	"The RAM variable declarations are too large by $\{*} bytes."
	elseif * < 0
		; Likely missing or misaligned RAM declarations!
		warning	"RAM variable declarations are \{signedToString(*)} bytes smaller than expected. Some variables may be missing or not aligned correctly!"
	endif
	dephase


; Special stage
	phase	$FF0000
ss_layout_padding:	equ $20
ss_layout_rowlength:	equ $80
ss_layout_rows:		equ $40
ss_matrixsize:		equ 16

v_sslayout_base:	ds.b	(ss_layout_rowlength*ss_layout_padding)+ss_layout_padding ; SS layout start, with top and left padding ($20 cells each)
v_sslayout_actual:	ds.b	ss_layout_rowlength*ss_layout_rows ; actual SS layout, after padding
v_sslayout_end:							; end of SS layout buffer
			ds.b	$FE0				; unused in SS
v_ss_spritesettings:	ds.b	8*$4F				; sprite mappings/VRAM settings loaded from SS_MapIndex (total $278 bytes)
v_sslayout_decompress:	equ	v_ss_spritesettings		; temporary buffer when decompressing the Enigma-compressed SS layout ($1000 bytes)
			ds.b	$188				; unused in SS
v_ss_animations:	ds.b	8*$20				; animation update queue (8 bytes per entry, $20 entries total)
v_ss_animations_end:						; end of animation update queue
	org	$FFFF8000					; (need 32-bit addressing starting at FFFF8000)
v_ss_rotationmatrix:	ds.b	2*2*ss_matrixsize*ss_matrixsize	; rotated X/Y sprite coordinates (words) per visible cell (2*2*$10*$10 = $400 bytes)
			ds.b	$2600				; unused in SS
v_ss_scroll_bubbles:	ds.b	$28				; buffer to store scroll positions for SS background bubbles
			ds.b	$D8				; unused in SS
v_ss_scroll_clouds:	ds.b	$1C				; buffer to store scroll positions for SS background clouds
	dephase


; Error handler
	phase	v_error_workspace
v_regbuffer:		ds.b	$40				; stores registers d0-a7 during an error event
v_spbuffer:		ds.l	1				; stores most recent sp address
v_errortype:		ds.b	1				; error type
	dephase


	!org 0
