; ===========================================================================
; ---------------------------------------------------------------------------
; Flamedriver (FeatureSoundDriver = SoundDriver_S3K)
; ---------------------------------------------------------------------------
; Flamewing's Sonic 3 & Knuckles Z80 driver plays all music and sound
; effects. The game keeps its Sonic 1 interface: QueueSound1-3 fill
; v_snddriver_ram.v_soundqueue0-2, PauseGame sets f_pausemusic and the speed
; shoes set f_speedup. UpdateMusic, called every VBlank, passes these on to
; the driver. The rest of the SMPS_RAM block stays unused.
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to load the sound driver
; ---------------------------------------------------------------------------

DACDriverLoad:
		nop
		stopZ80
		deassertZ80Reset
		waitZ80
		lea	(Snd_Driver).l,a0
		lea	(z80_ram).l,a1
		jsr	(KosDec).l				; decompress the driver into Z80 RAM
		lea	(z80_ram+z80_stack).l,a1
		move.w	#zTracksStart-z80_stack-1,d0
	.clearVariables:
		clr.b	(a1)+					; clear the driver's variables
		dbf	d0,.clearVariables
		btst	#6,(v_megadrive).w			; is this a PAL console?
		beq.s	.notPAL
		move.b	#1,(z80_ram+zPalFlag).l			; then update the music five times every six frames
	.notPAL:
		assertZ80Reset
		nop
		nop
		nop
		nop
		deassertZ80Reset
		startZ80
		rts
; End of function DACDriverLoad

; ---------------------------------------------------------------------------
; Subroutine to pass the sound queue, pause and tempo requests to the driver
; ---------------------------------------------------------------------------

UpdateMusic:
		lea	(v_snddriver_ram).w,a6
		tst.b	SMPS_RAM.f_push_playing(a6)		; count down the push sound
		beq.s	.pushDone
		subq.b	#1,SMPS_RAM.f_push_playing(a6)
	.pushDone:
		moveq	#0,d2					; no song or command sent this frame
		lea	SMPS_RAM.v_soundqueue0(a6),a1
		moveq	#SMPS_RAM.v_soundqueue_end-SMPS_RAM.v_soundqueue0-1,d3
	.nextQueued:
		moveq	#0,d1
		move.b	(a1),d1
		beq.s	.slotDone
		bsr.s	SoundS3K_Dispatch
	.slotDone:
		addq.w	#1,a1
		dbf	d3,.nextQueued

		; Pause: PauseGame writes 1 to pause and $80 to resume; 2 marks a
		; pause that has already reached the driver.
		move.b	SMPS_RAM.f_pausemusic(a6),d1
		beq.s	.tempo
		bmi.s	.resume
		cmpi.b	#1,d1
		bne.s	.tempo
		move.b	#2,SMPS_RAM.f_pausemusic(a6)
		bra.s	.sendPause
	.resume:
		clr.b	SMPS_RAM.f_pausemusic(a6)
	.sendPause:
		stopZ80
		waitZ80
		move.b	d1,(z80_ram+zPauseFlag).l
		startZ80

	.tempo:
		; Speed shoes: f_speedup is $80 while they last. The driver keeps its
		; tempo across songs, so only changes are sent; v_speeduptempo holds
		; the value the driver has.
		moveq	#0,d1
		tst.b	SMPS_RAM.f_speedup(a6)
		beq.s	.compareTempo
		moveq	#8,d1					; Sonic 3 & Knuckles speed shoes tempo
	.compareTempo:
		cmp.b	SMPS_RAM.v_speeduptempo(a6),d1
		beq.s	.done
		move.b	d1,SMPS_RAM.v_speeduptempo(a6)
		stopZ80
		waitZ80
		move.b	d1,(z80_ram+zTempoSpeedup).l
		startZ80
	.done:
		rts
; End of function UpdateMusic

; ---------------------------------------------------------------------------
; Send one queued ID. The driver reads one song or command per frame, so a
; second one stays queued until the next frame.
;
; input:
;	d1.w = queued ID
;	d2.b = nonzero once a song or command was sent this frame
;	a1 = queue slot, cleared once the ID is handled
;	a6 = v_snddriver_ram
; ---------------------------------------------------------------------------

SoundS3K_PushFrames = 7+2+6+$10			; length of sfx_Push ("SndA7 - Push Block.asm")

SoundS3K_Dispatch:
		cmpi.b	#bgm__Last,d1
		bls.s	.music
		cmpi.b	#sfx__First,d1
		blo.s	.handled				; unused IDs do nothing
		cmpi.b	#sfx__Last,d1
		bls.s	.soundEffect
		cmpi.b	#flg__First,d1
		blo.s	.handled
		subi.b	#flg__First,d1
		add.w	d1,d1
		move.w	.commands(pc,d1.w),d1
		jmp	.commands(pc,d1.w)
; ---------------------------------------------------------------------------
.commands:
		dc.w	.fade-.commands				; bgm_Fade
		dc.w	.sega-.commands				; sfx_Sega
		dc.w	.speedUp-.commands			; bgm_Speedup
		dc.w	.slowDown-.commands			; bgm_Slowdown
		dc.w	.stop-.commands				; bgm_Stop
; ---------------------------------------------------------------------------
.music:
		tst.b	d2
		bne.s	.deferred
		cmpi.b	#bgm_ExtraLife,d1			; the driver resumes the song under a 1-up itself
		bne.s	.notExtraLife
		; The driver saves the song over its sound effect tracks. A sound
		; effect it starts in the same update would overwrite the saved song,
		; so the ones still waiting are dropped, and so are later ones this
		; frame (d2 = -1).
		moveq	#-1,d2
		stopZ80
		waitZ80
		clr.b	(z80_ram+zSFXNumber0).l
		clr.b	(z80_ram+zSFXNumber1).l
		bra.s	.writeMusic
	.notExtraLife:
		move.b	d1,SMPS_RAM.v_current_music(a6)
	.sendMusic:
		moveq	#1,d2
		stopZ80
		waitZ80
	.writeMusic:
		move.b	d1,(z80_ram+zMusicNumber).l
		startZ80
	.handled:
		clr.b	(a1)
	.deferred:
		rts
; ---------------------------------------------------------------------------
.soundEffect:
		tst.b	d2					; a 1-up sent this frame?
		bmi.s	.handled				; then the sound effect is dropped
		cmpi.b	#sfx_Push,d1				; the pushable block asks every frame
		bne.s	.notPush
		tst.b	SMPS_RAM.f_push_playing(a6)		; still playing?
		bne.s	.handled				; then let it finish, as Sonic 1's driver does
		move.b	#SoundS3K_PushFrames,SMPS_RAM.f_push_playing(a6)
	.notPush:
		subi.b	#sfx__First-zsfx__First,d1
		stopZ80
		waitZ80
		cmp.b	(z80_ram+zSFXNumber0).l,d1		; already requested this frame?
		beq.s	.soundQueued
		tst.b	(z80_ram+zSFXNumber0).l
		bne.s	.secondSlot
		move.b	d1,(z80_ram+zSFXNumber0).l
		bra.s	.soundQueued
	.secondSlot:
		move.b	d1,(z80_ram+zSFXNumber1).l
	.soundQueued:
		startZ80
		clr.b	(a1)
		rts
; ---------------------------------------------------------------------------
.fade:
		tst.b	d2
		bne.s	.deferred
		clr.b	SMPS_RAM.v_current_music(a6)
		move.b	#zcmd_FadeOut,d1
		bra.w	.sendMusic
.stop:
		tst.b	d2
		bne.s	.deferred
		clr.b	SMPS_RAM.v_current_music(a6)
		move.b	#zcmd_Stop,d1
		bra.w	.sendMusic
.sega:
		tst.b	d2
		bne.s	.deferred
		move.b	#zcmd_SegaSound,d1
		bra.w	.sendMusic
.speedUp:
		move.b	#$80,SMPS_RAM.f_speedup(a6)
		clr.b	(a1)
		rts
.slowDown:
		clr.b	SMPS_RAM.f_speedup(a6)
		clr.b	(a1)
		rts
; End of function SoundS3K_Dispatch

; ---------------------------------------------------------------------------
; Subroutine to stop the SEGA chant early. The driver plays it with its
; interrupts off and checks for this command after every byte.
; ---------------------------------------------------------------------------

StopSegaPCM:
		stopZ80
		waitZ80
		move.b	#zcmd_StopSega,(z80_ram+zMusicNumber).l
		startZ80
		rts
; End of function StopSegaPCM

; ===========================================================================
FixMusicAndSFXDataBugs = FixBugs		; song and SFX fixes in the SMPS2ASM sources
z80_ptr function x,k68z80Pointer(x)		; SMPS2ASM's pointer into the driver's bank window

; The driver, compressed by the build (see Size_of_Snd_driver_guess)
Snd_Driver:
	include	"sound/flamedriver/Z80Driver.a80"
Snd_Driver_End:

; DAC samples, sound effects with the SEGA chant, and music, each in
; 32 KiB banks the Z80 can see through its ROM window.
	include	"sound/flamedriver/DACBanks.asm"
	include	"sound/S3K SFX Bank.asm"
	include	"sound/S3K Music Bank.asm"
		even
