; Music bank for Flamedriver: the music pointer table, the universal voice
; bank and every song, in Gen_Music_Table order (sound/flamedriver/Tables.asm).
; All Sonic 1 songs fit in one 32 KiB bank; a new bank must repeat
; Music_Master_Table and the UniBank include at its start.
MusBank1:	startBank
	Music_Master_Table
z80_UniVoiceBank:	include "sound/flamedriver/UniBank.asm"
Mus_GHZ:	include "sound/music/Mus81 - GHZ.asm"
Mus_LZ:	include "sound/music/Mus82 - LZ.asm"
Mus_MZ:	include "sound/music/Mus83 - MZ.asm"
Mus_SLZ:	include "sound/music/Mus84 - SLZ.asm"
Mus_SYZ:	include "sound/music/Mus85 - SYZ.asm"
Mus_SBZ:	include "sound/music/Mus86 - SBZ.asm"
Mus_Invincible:	include "sound/music/Mus87 - Invincibility.asm"
Mus_ExtraLife:	include "sound/music/Mus88 - Extra Life.asm"
Mus_SS:	include "sound/music/Mus89 - Special Stage.asm"
Mus_Title:	include "sound/music/Mus8A - Title Screen.asm"
Mus_Ending:	include "sound/music/Mus8B - Ending.asm"
Mus_Boss:	include "sound/music/Mus8C - Boss.asm"
Mus_FZ:	include "sound/music/Mus8D - FZ.asm"
Mus_GotThrough:	include "sound/music/Mus8E - Sonic Got Through.asm"
Mus_GameOver:	include "sound/music/Mus8F - Game Over.asm"
Mus_Continue:	include "sound/music/Mus90 - Continue Screen.asm"
Mus_Credits:	include "sound/music/Mus91 - Credits.asm"
Mus_Drowning:	include "sound/music/Mus92 - Drowning.asm"
Mus_Emerald:	include "sound/music/Mus93 - Get Emerald.asm"
Mus_Super:	include "sound/music/Mus94 - Super Sonic.asm"
	finishBank
