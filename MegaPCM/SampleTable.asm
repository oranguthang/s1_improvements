; ---------------------------------------------------------------
; Mega PCM 2 sample table for Sonic 1 (FeatureMegaPCM)
; From the Mega PCM 2.1 release (megapcm-sample-tables.zip, sonic-1),
; https://github.com/vladikcomper/MegaPCM; samples in sound/dac/megapcm.
; IDs match the SMPS DAC notes $81-$8B; dacSega is the "SEGA" chant.
; ---------------------------------------------------------------
SampleTable:
; name?				type		pointer		Hz		flags?		; sample id
		dcSample	TYPE_DPCM,	Kick,		8000				; $81
		dcSample	TYPE_PCM,	Snare,		24000				; $82
		dcSample	TYPE_DPCM,	Timpani,	7250				; $83
		dcSample	TYPE_NONE							; $84
		dcSample	TYPE_NONE							; $85
		dcSample	TYPE_NONE							; $86
		dcSample	TYPE_NONE							; $87
		dcSample	TYPE_DPCM,	Timpani,	9750				; $88
		dcSample	TYPE_DPCM,	Timpani,	8750				; $89
		dcSample	TYPE_DPCM,	Timpani,	7150				; $8A
		dcSample	TYPE_DPCM,	Timpani,	7000				; $8B
dacSega:	dcSample	TYPE_PCM,	SegaVoice,	16000,		FLAGS_SFX	; $8C (dacSega.id)
		dc.w	-1	; end marker

; ---------------------------------------------------------------
		incdac	Kick, "sound/dac/megapcm/kick.dpcm"
		incdac	Snare, "sound/dac/megapcm/snare.wav"
		incdac	Timpani, "sound/dac/megapcm/timpani.dpcm"
		incdac	SegaVoice, "sound/dac/megapcm/sega.wav"
		even
