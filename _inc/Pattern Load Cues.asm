; ===========================================================================
; ---------------------------------------------------------------------------
; Pattern load cues
; ---------------------------------------------------------------------------

; Macro to define PLC pointer entry
plcptr:		macro plc,{INTLABEL}
__LABEL__:	label	(*-ArtLoadCues)/2
		dc.w	plc-ArtLoadCues
		endm

; Macro for the header of a PLC list
plcheader:	macro {INTLABEL}
__LABEL__:	label	*
		dc.w ((__LABEL___end-__LABEL__-2)/6)-1
		endm

; Macro for single pattern load cue entry
plcm:		macro gfx,vram
		dc.l gfx
		dc.w (vram)*tile_size
		endm

; ---------------------------------------------------------------------------

; Index and ID definitions
ArtLoadCues:

plcid_Main:		plcptr	PLC_Main
plcid_Main2:		plcptr	PLC_Main2
plcid_Explode:		plcptr	PLC_Explode
plcid_GameOver:		plcptr	PLC_GameOver

	PLC_Levels:
plcid_GHZ:		plcptr	PLC_GHZ
plcid_GHZ2:		plcptr	PLC_GHZ2
plcid_LZ:		plcptr	PLC_LZ
plcid_LZ2:		plcptr	PLC_LZ2
plcid_MZ:		plcptr	PLC_MZ
plcid_MZ2:		plcptr	PLC_MZ2
plcid_SLZ:		plcptr	PLC_SLZ
plcid_SLZ2:		plcptr	PLC_SLZ2
plcid_SYZ:		plcptr	PLC_SYZ
plcid_SYZ2:		plcptr	PLC_SYZ2
plcid_SBZ:		plcptr	PLC_SBZ
plcid_SBZ2:		plcptr	PLC_SBZ2
	zonewarning PLC_Levels,4

plcid_TitleCard:	plcptr	PLC_TitleCard
plcid_Boss:		plcptr	PLC_Boss
plcid_Signpost:		plcptr	PLC_Signpost
plcid_Warp:		plcptr	PLC_Warp
plcid_SpecialStage:	plcptr	PLC_SpecialStage

	PLC_Animals:
plcid_GHZAnimals:	plcptr	PLC_GHZAnimals
plcid_LZAnimals:	plcptr	PLC_LZAnimals
plcid_MZAnimals:	plcptr	PLC_MZAnimals
plcid_SLZAnimals:	plcptr	PLC_SLZAnimals
plcid_SYZAnimals:	plcptr	PLC_SYZAnimals
plcid_SBZAnimals:	plcptr	PLC_SBZAnimals
	zonewarning PLC_Animals,2

plcid_SSResult:		plcptr	PLC_SSResult
plcid_Ending:		plcptr	PLC_Ending
plcid_TryAgain:		plcptr	PLC_TryAgain
plcid_EggmanSBZ2:	plcptr	PLC_EggmanSBZ2
plcid_FZBoss:		plcptr	PLC_FZBoss

	; Lists loaded immediately with QuickPLC (formerly direct NemDec calls)
plcid_Sega:		plcptr	PLC_Sega
plcid_TitleSonicTeam:	plcptr	PLC_TitleSonicTeam
plcid_TitleForeground:	plcptr	PLC_TitleForeground
plcid_TitleBackground:	plcptr	PLC_TitleBackground
plcid_Continue:		plcptr	PLC_Continue
plcid_Credits:		plcptr	PLC_Credits
plcid_Points:		plcptr	PLC_Points
plcid_PlayerHUD:		plcptr	PLC_PlayerHUD
plcid_TailsHUD: plcptr PLC_TailsHUD
plcid_KnucklesHUD: plcptr PLC_KnucklesHUD
plcid_TailsSignpost: plcptr PLC_TailsSignpost
plcid_KnucklesSignpost: plcptr PLC_KnucklesSignpost
plcid_TailsMonitors: plcptr PLC_TailsMonitors
plcid_KnucklesMonitors: plcptr PLC_KnucklesMonitors
plcid_SonicEnding: plcptr PLC_SonicEnding
plcid_TailsEnding: plcptr PLC_TailsEnding
plcid_KnucklesEnding: plcptr PLC_KnucklesEnding
	if FeatureTextCredits
plcid_CreditsText:	plcptr	PLC_CreditsText
	endif

; ---------------------------------------------------------------------------
; Pattern load cues - standard block 1
; ---------------------------------------------------------------------------
PLC_Main:	plcheader
		plcm	KosM_Lamp,	ArtTile_Lamppost		; lamppost
		plcm	KosM_Hud,	ArtTile_HUD			; HUD
		plcm	KosM_RingSparkles,	ArtTile_Ring_Sparkle	; ring sparkles (ring frames are DMA'd, #42)
PLC_Main_end:

; ---------------------------------------------------------------------------
; Pattern load cues - standard block 2
; ---------------------------------------------------------------------------
PLC_Main2:	plcheader
		plcm	KosM_Monitors,	ArtTile_Monitor			; monitors
		; shield and invincibility stars are DMA-loaded by ShieldStars_LoadGfx
PLC_Main2_end:

; Only the four 1UP portrait tiles differ between solo characters.
PLC_TailsMonitors: plcheader
        plcm KosM_Monitors,ArtTile_Monitor
        plcm KosM_TailsMonitor,ArtTile_Monitor+$1C
PLC_TailsMonitors_end:
PLC_KnucklesMonitors: plcheader
        plcm KosM_Monitors,ArtTile_Monitor
        plcm KosM_KnucklesMonitor,ArtTile_Monitor+$1C
PLC_KnucklesMonitors_end:

; ---------------------------------------------------------------------------
; Pattern load cues - explosion
; ---------------------------------------------------------------------------
PLC_Explode:	plcheader
		plcm	KosM_Explode,	ArtTile_Explosion		; explosion
PLC_Explode_end:

; ---------------------------------------------------------------------------
; Pattern load cues - game/time over
; ---------------------------------------------------------------------------
PLC_GameOver:	plcheader
		plcm	KosM_GameOver,	ArtTile_Game_Over		; game/time over
PLC_GameOver_end:

; ---------------------------------------------------------------------------
; Pattern load cues - Green Hill
; ---------------------------------------------------------------------------
PLC_GHZ:	plcheader
		plcm	KosM_GHZ_1st,	ArtTile_Level			; GHZ main patterns
		plcm	KosM_GHZ_2nd,	ArtTile_Level+$1CD		; GHZ secondary patterns
		plcm	KosM_Stalk,	ArtTile_GHZ_Flower_Stalk	; flower stalk
		plcm	KosM_PplRock,	ArtTile_GHZ_Purple_Rock		; purple rock
		plcm	KosM_Crabmeat,	ArtTile_Crabmeat		; crabmeat enemy
		plcm	KosM_Buzz,	ArtTile_Buzz_Bomber		; buzz bomber enemy
		plcm	KosM_Chopper,	ArtTile_Chopper			; chopper enemy
		plcm	KosM_Newtron,	ArtTile_Newtron			; newtron enemy
		plcm	KosM_Motobug,	ArtTile_Moto_Bug		; motobug enemy
		plcm	KosM_Spikes,	ArtTile_Spikes			; spikes
		plcm	KosM_HSpring,	ArtTile_Spring_Horizontal	; horizontal spring
		plcm	KosM_VSpring,	ArtTile_Spring_Vertical		; vertical spring
PLC_GHZ_end:

PLC_GHZ2:	plcheader
		plcm	KosM_Swing,	ArtTile_GHZ_MZ_Swing		; swinging platform
		plcm	KosM_Bridge,	ArtTile_GHZ_Bridge		; bridge
		plcm	KosM_SpikePole,	ArtTile_GHZ_Spike_Pole		; spiked pole
		plcm	KosM_Ball,	ArtTile_GHZ_Giant_Ball		; giant ball
		plcm	KosM_GhzWall1,	ArtTile_GHZ_SLZ_Smashable_Wall	; breakable wall
		plcm	KosM_GhzWall2,	ArtTile_GHZ_Edge_Wall		; normal wall
PLC_GHZ2_end:

; ---------------------------------------------------------------------------
; Pattern load cues - Labyrinth
; ---------------------------------------------------------------------------
PLC_LZ:		plcheader
		plcm	KosM_LZ,		ArtTile_Level			; LZ main patterns
		plcm	KosM_LzBlock1,	ArtTile_LZ_Block_1		; block
		plcm	KosM_LzBlock2,	ArtTile_LZ_Block_2		; blocks
		plcm	KosM_Splash,	ArtTile_LZ_Splash		; waterfalls and splash
	if WaterSurfaceSprites
		plcm	KosM_Water,	ArtTile_LZ_Water_Surface	; water surface
	endif
		plcm	KosM_LzSpikeBall, ArtTile_LZ_Spikeball_Chain	; spiked ball
		plcm	KosM_FlapDoor,	ArtTile_LZ_Flapping_Door	; flapping door
		plcm	KosM_Bubbles,	ArtTile_LZ_Bubbles		; bubbles and numbers
		plcm	KosM_LzBlock3,	ArtTile_LZ_Moving_Block		; block
		plcm	KosM_LzDoor1,	ArtTile_LZ_Door			; vertical door
		plcm	KosM_Harpoon,	ArtTile_LZ_Harpoon		; harpoon
		plcm	KosM_Burrobot,	ArtTile_Burrobot		; burrobot enemy
PLC_LZ_end:

PLC_LZ2:	plcheader
		plcm	KosM_LzPole,	ArtTile_LZ_Pole			; pole that breaks
		plcm	KosM_LzDoor2,	ArtTile_LZ_Blocks		; large horizontal door
		plcm	KosM_LzWheel,	ArtTile_LZ_Conveyor_Belt	; wheel
		plcm	KosM_Gargoyle,	ArtTile_LZ_Gargoyle		; gargoyle head
	if Revision=0
		plcm	KosM_LzSonic,	ArtTile_LZ_UnusedFace		; unused face of Sonic holding his breath
	endif
		plcm	KosM_LzPlatfm,	ArtTile_LZ_Rising_Platform	; rising platform
		plcm	KosM_Orbinaut,	ArtTile_LZ_Orbinaut		; orbinaut enemy
		plcm	KosM_Jaws,	ArtTile_Jaws			; jaws enemy
		plcm	KosM_LzSwitch,	ArtTile_Button		; grey LZ switch body and pedestal
		plcm	KosM_Cork,	ArtTile_LZ_Cork			; cork block
		plcm	KosM_Spikes,	ArtTile_Spikes			; spikes
		plcm	KosM_HSpring,	ArtTile_Spring_Horizontal	; horizontal spring
		plcm	KosM_VSpring,	ArtTile_Spring_Vertical		; vertical spring
PLC_LZ2_end:

; ---------------------------------------------------------------------------
; Pattern load cues - Marble
; ---------------------------------------------------------------------------
PLC_MZ:		plcheader
		plcm	KosM_MZ,	ArtTile_Level				; MZ main patterns
		plcm	KosM_MzMetal,	ArtTile_MZ_Spike_Stomper	; metal blocks
		plcm	KosM_MzFire,	ArtTile_MZ_Fireball		; fireballs
		plcm	KosM_Swing,	ArtTile_GHZ_MZ_Swing		; swinging platform
		plcm	KosM_MzGlass,	ArtTile_MZ_Glass_Pillar		; green glassy block
		plcm	KosM_Lava,	ArtTile_MZ_Lava			; lava
		plcm	KosM_Buzz,	ArtTile_Buzz_Bomber		; buzz bomber enemy
		plcm	KosM_Yadrin,	ArtTile_Yadrin			; yadrin enemy
		plcm	KosM_Basaran,	ArtTile_Basaran			; basaran enemy
		plcm	KosM_Splats,	ArtTile_Splats			; splats enemy
		plcm	KosM_Cater,	ArtTile_MZ_SYZ_Caterkiller	; caterkiller enemy
PLC_MZ_end:

PLC_MZ2:	plcheader
		plcm	KosM_MzSwitch,	ArtTile_Button_Main		; switch
		plcm	KosM_Spikes,	ArtTile_Spikes			; spikes
		plcm	KosM_HSpring,	ArtTile_Spring_Horizontal	; horizontal spring
		plcm	KosM_VSpring,	ArtTile_Spring_Vertical		; vertical spring
		plcm	KosM_MzBlock,	ArtTile_MZ_Block		; green stone block
PLC_MZ2_end:

; ---------------------------------------------------------------------------
; Pattern load cues - Star Light
; ---------------------------------------------------------------------------
PLC_SLZ:	plcheader
		plcm	KosM_SLZ,	ArtTile_Level			; SLZ main patterns
		plcm	KosM_Bomb,	ArtTile_Bomb			; bomb enemy
		plcm	KosM_Orbinaut,	ArtTile_SLZ_Orbinaut		; orbinaut enemy
		plcm	KosM_MzFire,	ArtTile_SLZ_Fireball		; fireballs
		plcm	KosM_SlzBlock,	ArtTile_SLZ_Collapsing_Floor	; block
		plcm	KosM_SlzWall,	ArtTile_GHZ_SLZ_Smashable_Wall+4 ; breakable wall
		plcm	KosM_Spikes,	ArtTile_Spikes			; spikes
		plcm	KosM_HSpring,	ArtTile_Spring_Horizontal	; horizontal spring
		plcm	KosM_VSpring,	ArtTile_Spring_Vertical		; vertical spring
PLC_SLZ_end:

PLC_SLZ2:	plcheader
		plcm	KosM_Seesaw,	ArtTile_SLZ_Seesaw		; seesaw
		plcm	KosM_Fan,	ArtTile_SLZ_Fan			; fan
		plcm	KosM_Pylon,	ArtTile_SLZ_Pylon		; foreground pylon
		plcm	KosM_SlzSwing,	ArtTile_SLZ_Swing		; swinging platform
		plcm	KosM_SlzCannon,	ArtTile_SLZ_Fireball_Launcher	; fireball launcher
		plcm	KosM_SlzSpike,	ArtTile_SLZ_Spikeball		; spikeball
PLC_SLZ2_end:

; ---------------------------------------------------------------------------
; Pattern load cues - Spring Yard
; ---------------------------------------------------------------------------
PLC_SYZ:	plcheader
		plcm	KosM_SYZ,	ArtTile_Level			; SYZ main patterns
		plcm	KosM_Crabmeat,	ArtTile_Crabmeat		; crabmeat enemy
		plcm	KosM_Buzz,	ArtTile_Buzz_Bomber		; buzz bomber enemy
		plcm	KosM_Yadrin,	ArtTile_Yadrin			; yadrin enemy
		plcm	KosM_Roller,	ArtTile_Roller			; roller enemy
PLC_SYZ_end:

PLC_SYZ2:	plcheader
		plcm	KosM_Bumper,	ArtTile_SYZ_Bumper		; bumper
		plcm	KosM_SyzSpike1,	ArtTile_SYZ_Big_Spikeball	; large spikeball
		plcm	KosM_SyzSpike2,	ArtTile_SYZ_Spikeball_Chain	; small spikeball
	if FixBugs=0
		; Despite being unused, this corrupts the Roller's graphics
		plcm	KosM_Cater,	ArtTile_MZ_SYZ_Caterkiller	; caterkiller enemy
	endif
		plcm	KosM_LzSwitch,	ArtTile_Button			; switch
		plcm	KosM_Spikes,	ArtTile_Spikes			; spikes
		plcm	KosM_HSpring,	ArtTile_Spring_Horizontal	; horizontal spring
		plcm	KosM_VSpring,	ArtTile_Spring_Vertical		; vertical spring
PLC_SYZ2_end:

; ---------------------------------------------------------------------------
; Pattern load cues - Scrap Brain
; ---------------------------------------------------------------------------
PLC_SBZ:	plcheader
		plcm	KosM_SBZ,	ArtTile_Level			; SBZ main patterns
		plcm	KosM_Stomper,	ArtTile_SBZ_Moving_Block_Short	; moving platform and stomper
		plcm	KosM_SbzDoor1,	ArtTile_SBZ_Door		; door
		plcm	KosM_Girder,	ArtTile_SBZ_Girder		; girder
		plcm	KosM_BallHog,	ArtTile_Ball_Hog		; ball hog enemy
		plcm	KosM_SbzWheel1,	ArtTile_SBZ_Disc		; spot on large wheel
		plcm	KosM_SbzWheel2,	ArtTile_SBZ_Junction		; wheel that grabs Sonic
		plcm	KosM_SyzSpike1,	ArtTile_SBZ_Swing		; large spikeball
		plcm	KosM_Cutter,	ArtTile_SBZ_Saw			; pizza cutter
		plcm	KosM_FlamePipe,	ArtTile_SBZ_Flamethrower	; flaming pipe
		plcm	KosM_SbzFloor,	ArtTile_SBZ_Collapsing_Floor	; collapsing floor
		plcm	KosM_SbzBlock,	ArtTile_SBZ_Vanishing_Block	; vanishing block
PLC_SBZ_end:

PLC_SBZ2:	plcheader
		plcm	KosM_Cater,	ArtTile_SBZ_Caterkiller		; caterkiller enemy
		plcm	KosM_Bomb,	ArtTile_Bomb			; bomb enemy
		plcm	KosM_Orbinaut,	ArtTile_SBZ_Orbinaut		; orbinaut enemy
		plcm	KosM_SlideFloor,	ArtTile_SBZ_Moving_Block_Long	; floor that slides away
		plcm	KosM_SbzDoor2,	ArtTile_SBZ_Horizontal_Door	; horizontal door
		plcm	KosM_Electric,	ArtTile_SBZ_Electric_Orb	; electric orb
		plcm	KosM_TrapDoor,	ArtTile_SBZ_Trap_Door		; trapdoor
		plcm	KosM_SbzFloor,	ArtTile_SBZ_Collapsing_Floor+4	; collapsing floor
		plcm	KosM_SpinPform,	ArtTile_SBZ_Spinning_Platform	; small spinning platform
		plcm	KosM_LzSwitch,	ArtTile_Button		; grey SBZ switch body and pedestal
		plcm	KosM_Spikes,	ArtTile_Spikes			; spikes
		plcm	KosM_HSpring,	ArtTile_Spring_Horizontal	; horizontal spring
		plcm	KosM_VSpring,	ArtTile_Spring_Vertical		; vertical spring
PLC_SBZ2_end:

; ---------------------------------------------------------------------------
; Pattern load cues - title card
; ---------------------------------------------------------------------------
PLC_TitleCard:	plcheader
		plcm	KosM_TitleCard,	ArtTile_Title_Card
PLC_TitleCard_end:

; ---------------------------------------------------------------------------
; Pattern load cues - act 3 boss
; ---------------------------------------------------------------------------
PLC_Boss:	plcheader
		plcm	KosM_Eggman,	ArtTile_Eggman			; Eggman main patterns
		plcm	KosM_Weapons,	ArtTile_Eggman_Weapons		; Eggman's weapons
		plcm	KosM_Prison,	ArtTile_Prison_Capsule		; prison capsule
		plcm	KosM_Bomb,	ArtTile_Eggman_Spikeball	; bomb enemy (gets overwritten)
		plcm	KosM_SlzSpike,	ArtTile_Eggman_Spikeball	; spikeball (SLZ boss)
		plcm	KosM_Exhaust,	ArtTile_Eggman_Exhaust		; exhaust flame
PLC_Boss_end:

; ---------------------------------------------------------------------------
; Pattern load cues - act 1/2 signpost
; ---------------------------------------------------------------------------
PLC_Signpost:	plcheader
		plcm	KosM_SignPost,	ArtTile_Signpost		; signpost
		plcm	KosM_Bonus,	ArtTile_Hidden_Points		; hidden bonus points
PLC_Signpost_end:

; Keep the original sign and pole, replacing only the 24-tile player face.
PLC_TailsSignpost: plcheader
        plcm KosM_SignPost,ArtTile_Signpost
        plcm KosM_Bonus,ArtTile_Hidden_Points
        plcm KosM_TailsSignpost,ArtTile_Signpost+$20
PLC_TailsSignpost_end:
PLC_KnucklesSignpost: plcheader
        plcm KosM_SignPost,ArtTile_Signpost
        plcm KosM_Bonus,ArtTile_Hidden_Points
        plcm KosM_KnucklesSignpost,ArtTile_Signpost+$20
PLC_KnucklesSignpost_end:

; ---------------------------------------------------------------------------
; Pattern load cues - beta special stage warp effect
; ---------------------------------------------------------------------------
PLC_Warp:
	if Revision=0
PLC_WarpRev0:	plcheader
		plcm	KosM_Warp,	ArtTile_Warp
PLC_WarpRev0_end:
	endif

; ---------------------------------------------------------------------------
; Pattern load cues - special stage
; ---------------------------------------------------------------------------
PLC_SpecialStage:	plcheader
		plcm	KosM_SSBgCloud,	ArtTile_SS_Background_Clouds	; bubble and cloud background
		plcm	KosM_SSBgFish,	ArtTile_SS_Background_Fish	; bird and fish background
		plcm	KosM_Bumper,	ArtTile_SS_Bumper		; bumper
		plcm	KosM_SSGOAL,	ArtTile_SS_Goal			; GOAL block
		plcm	KosM_SSUpDown,	ArtTile_SS_Up_Down		; UP and DOWN blocks
		plcm	KosM_SSRBlock,	ArtTile_SS_R_Block		; R block
		plcm	KosM_SS1UpBlock,	ArtTile_SS_Extra_Life		; 1UP block
		plcm	KosM_SSEmStars,	ArtTile_SS_Emerald_Sparkle	; emerald collection stars
		plcm	KosM_SSRedWhite,	ArtTile_SS_Red_White_Block	; red and white block
		plcm	KosM_SSGhost,	ArtTile_SS_Ghost_Block		; ghost block
		plcm	KosM_SSWBlock,	ArtTile_SS_W_Block		; W block
		plcm	KosM_SSGlass,	ArtTile_SS_Glass		; glass block
		plcm	KosM_SSEmerald,	ArtTile_SS_Emerald		; emeralds
		plcm	KosM_SSZone1,	ArtTile_SS_Zone_1		; ZONE 1 block
		plcm	KosM_SSZone2,	ArtTile_SS_Zone_2		; ZONE 2 block
		plcm	KosM_SSZone3,	ArtTile_SS_Zone_3		; ZONE 3 block
PLC_SpecialStage_end:

		; Unused
		plcm	KosM_SSZone4,	ArtTile_SS_Zone_4		; ZONE 4 block
		plcm	KosM_SSZone5,	ArtTile_SS_Zone_5		; ZONE 5 block
		plcm	KosM_SSZone6,	ArtTile_SS_Zone_6		; ZONE 6 block

; ---------------------------------------------------------------------------
; Pattern load cues - GHZ animals
; ---------------------------------------------------------------------------
PLC_GHZAnimals:	plcheader
		plcm	KosM_Rabbit,	ArtTile_Animal_1		; rabbit
		plcm	KosM_Flicky,	ArtTile_Animal_2		; flicky
PLC_GHZAnimals_end:

; ---------------------------------------------------------------------------
; Pattern load cues - LZ animals
; ---------------------------------------------------------------------------
PLC_LZAnimals:	plcheader
		plcm	KosM_Penguin,	ArtTile_Animal_1		; penguin
		plcm	KosM_Seal,	ArtTile_Animal_2		; seal
PLC_LZAnimals_end:

; ---------------------------------------------------------------------------
; Pattern load cues - MZ animals
; ---------------------------------------------------------------------------
PLC_MZAnimals:	plcheader
		plcm	KosM_Squirrel,	ArtTile_Animal_1		; squirrel
		plcm	KosM_Seal,	ArtTile_Animal_2		; seal
PLC_MZAnimals_end:

; ---------------------------------------------------------------------------
; Pattern load cues - SLZ animals
; ---------------------------------------------------------------------------
PLC_SLZAnimals:	plcheader
		plcm	KosM_Pig,	ArtTile_Animal_1		; pig
		plcm	KosM_Flicky,	ArtTile_Animal_2		; flicky
PLC_SLZAnimals_end:

; ---------------------------------------------------------------------------
; Pattern load cues - SYZ animals
; ---------------------------------------------------------------------------
PLC_SYZAnimals:	plcheader
		plcm	KosM_Pig,	ArtTile_Animal_1		; pig
		plcm	KosM_Chicken,	ArtTile_Animal_2		; chicken
PLC_SYZAnimals_end:

; ---------------------------------------------------------------------------
; Pattern load cues - SBZ animals
; ---------------------------------------------------------------------------
PLC_SBZAnimals:	plcheader
		plcm	KosM_Rabbit,	ArtTile_Animal_1		; rabbit
		plcm	KosM_Chicken,	ArtTile_Animal_2		; chicken
PLC_SBZAnimals_end:

; ---------------------------------------------------------------------------
; Pattern load cues - special stage results screen
; ---------------------------------------------------------------------------
PLC_SSResult:	plcheader
		plcm	KosM_ResultEm,	ArtTile_SS_Results_Emeralds	; emeralds
		plcm	KosM_MiniSonic,	ArtTile_Mini_Sonic		; mini Sonic
PLC_SSResult_end:

; ---------------------------------------------------------------------------
; Pattern load cues - ending sequence
; ---------------------------------------------------------------------------
PLC_Ending:	plcheader
		plcm	KosM_GHZ_1st,	ArtTile_Level			; GHZ main patterns
		plcm	KosM_GHZ_2nd,	ArtTile_Level+$1CD		; GHZ secondary patterns
		plcm	KosM_Stalk,	ArtTile_GHZ_Flower_Stalk	; flower stalk
		plcm	KosM_EndFlower,	ArtTile_Ending_Flowers		; flowers
		plcm	KosM_EndSharedEm,	ArtTile_Ending_Emeralds		; emeralds
	if Revision=0
		plcm	KosM_EndEggman,	ArtTile_Ending_Eggman		; Eggman's death (unused)
	endif
		plcm	KosM_Rabbit,	ArtTile_Ending_Rabbit		; rabbit
		plcm	KosM_Chicken,	ArtTile_Ending_Chicken		; chicken
		plcm	KosM_Penguin,	ArtTile_Ending_Penguin		; penguin
		plcm	KosM_Seal,	ArtTile_Ending_Seal		; seal
		plcm	KosM_Pig,	ArtTile_Ending_Pig		; pig
		plcm	KosM_Flicky,	ArtTile_Ending_Flicky		; flicky
		plcm	KosM_Squirrel,	ArtTile_Ending_Squirrel		; squirrel
		plcm	KosM_EndStH,	ArtTile_Ending_STH		; "SONIC THE HEDGEHOG"
PLC_Ending_end:

PLC_SonicEnding: plcheader
        plcm KosM_Lives,ArtTile_Lives_Counter
        plcm KosM_EndSonic,ArtTile_Ending_Sonic
PLC_SonicEnding_end:
PLC_TailsEnding: plcheader
        plcm KosM_TailsLives,ArtTile_Lives_Counter
        plcm KosM_EndTails,ArtTile_Ending_Sonic
        plcm KosM_EndSharedLogo,ArtTile_Ending_STH
PLC_TailsEnding_end:
PLC_KnucklesEnding: plcheader
        plcm KosM_KnucklesLives,ArtTile_Lives_Counter
        plcm KosM_EndKnuckles,ArtTile_Ending_Sonic
        plcm KosM_EndSharedLogo,ArtTile_Ending_STH
PLC_KnucklesEnding_end:

	if FeatureTextCredits
PLC_CreditsText:	plcheader
		plcm	KosM_CreditsTextFont,	ArtTile_Credits_Text_Font	; 16x16 credits font
PLC_CreditsText_end:
	endif

; ---------------------------------------------------------------------------
; Pattern load cues - "TRY AGAIN" and "END" screens
; ---------------------------------------------------------------------------
PLC_TryAgain:	plcheader
		plcm	KosM_EndEm,	ArtTile_Try_Again_Emeralds	; emeralds
		plcm	KosM_TryAgain,	ArtTile_Try_Again_Eggman	; Eggman
		plcm	KosM_CreditText,	ArtTile_Credits_Font		; credits alphabet
PLC_TryAgain_end:

; ---------------------------------------------------------------------------
; Pattern load cues - Eggman on SBZ 2
; ---------------------------------------------------------------------------
PLC_EggmanSBZ2:	plcheader
		plcm	KosM_SbzBlock,	ArtTile_Eggman_Trap_Floor	; block
		plcm	KosM_Sbz2Eggman,	ArtTile_Eggman			; Eggman
		plcm	KosM_LzSwitch,	ArtTile_Eggman_Button-4		; switch
PLC_EggmanSBZ2_end:

; ---------------------------------------------------------------------------
; Pattern load cues - final boss
; ---------------------------------------------------------------------------
PLC_FZBoss:	plcheader
		plcm	KosM_FzEggman,	ArtTile_FZ_Eggman_Fleeing	; Eggman after boss
		plcm	KosM_FzBoss,	ArtTile_FZ_Boss			; FZ boss
		plcm	KosM_Eggman,	ArtTile_Eggman			; Eggman main patterns
		plcm	KosM_Sbz2Eggman,	ArtTile_FZ_Eggman_No_Vehicle	; Eggman without ship
		plcm	KosM_Exhaust,	ArtTile_Eggman_Exhaust		; exhaust flame
PLC_FZBoss_end:

; ---------------------------------------------------------------------------
; Pattern load cues - Sega screen
; ---------------------------------------------------------------------------
PLC_Sega:	plcheader
		plcm	KosM_SegaLogo,	ArtTile_Sega_Tiles		; Sega logo
PLC_Sega_end:

; ---------------------------------------------------------------------------
; Pattern load cues - "SONIC TEAM PRESENTS" before the title screen
; ---------------------------------------------------------------------------
PLC_TitleSonicTeam:	plcheader
		plcm	KosM_JapNames,	ArtTile_Title_Japanese_Text	; hidden Japanese credits
		plcm	KosM_CreditText,	ArtTile_Sonic_Team_Font		; STP font (same as the credits font)
PLC_TitleSonicTeam_end:

; ---------------------------------------------------------------------------
; Pattern load cues - title screen foreground (while STP is displayed)
; ---------------------------------------------------------------------------
PLC_TitleForeground:	plcheader
		plcm	KosM_TitleFg,	ArtTile_Title_Foreground	; emblem
		plcm	KosM_TitleSonic,	ArtTile_Title_Sonic		; big Sonic
		plcm	KosM_TitleTM,	ArtTile_Title_Trademark		; "TM"
		plcm	KosM_TitlePSB,	ArtTile_Title_PressStart	; "PRESS START BUTTON"
PLC_TitleForeground_end:

; ---------------------------------------------------------------------------
; Pattern load cues - title screen background (after STP has faded out)
; ---------------------------------------------------------------------------
PLC_TitleBackground:	plcheader
		plcm	KosM_Title,	ArtTile_Level			; title background (separate from GHZ)
PLC_TitleBackground_end:

; ---------------------------------------------------------------------------
; Pattern load cues - continue screen
; ---------------------------------------------------------------------------
PLC_Continue:	plcheader
		plcm	KosM_TitleCard,	ArtTile_Title_Card		; title card font
		plcm	KosM_ContSonic,	ArtTile_Continue_Sonic		; Sonic
		plcm	KosM_MiniSonic,	ArtTile_Mini_Sonic		; mini Sonic icons
PLC_Continue_end:

; ---------------------------------------------------------------------------
; Pattern load cues - credits
; ---------------------------------------------------------------------------
PLC_Credits:	plcheader
		plcm	KosM_CreditText,	ArtTile_Credits_Font		; credits font
PLC_Credits_end:


; Reload before any act objects: SS results/Continue/ending reuse this range.
PLC_Points:	plcheader
		plcm	KosM_Points,	ArtTile_Points
PLC_Points_end:

PLC_PlayerHUD: plcheader
		plcm	KosM_Lives,	ArtTile_Lives_Counter		; lives counter
PLC_PlayerHUD_end:

PLC_TailsHUD: plcheader
        plcm KosM_TailsLives,ArtTile_Lives_Counter
PLC_TailsHUD_end:
PLC_KnucklesHUD: plcheader
        plcm KosM_KnucklesLives,ArtTile_Lives_Counter
PLC_KnucklesHUD_end:
