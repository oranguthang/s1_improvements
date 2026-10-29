# Settings and SRAM

## Title menu and controls

The title initially shows START GAME and OPTIONS. OPTIONS contains one CHARACTER setting (SONIC, TAILS or KNUCKLES). Left/Right/A/B/C changes the character, and Start returns to the title. Up/Down does nothing on this screen. SRAM remembers the character selection. Sonic Team Presents, the title, attract demos, Continue, credits and credit demos always use Sonic and his palettes; returning to gameplay restores the saved character. The ending uses the selected character, including its run, emerald sequence and jump towards the screen. In the good ending every character runs in as Super and reverts when the emeralds glow. Tails and Knuckles use their official Sonic 1 mobile ending poses. Special Stage results use Sonic's fixed presentation artwork and HUD, except the continue icon, which shows the selected character. Multiplayer and Competition modes are not supported.

Enter Up, Down, Down, Down, Left, Right on the title to reveal LEVEL SELECT and CHEATS as two additional choices. SRAM remembers the unlock. Old title cheat sequences are disabled. With the secret menu unlocked, pause and press A to return directly to the title. Debug alone does not unlock this shortcut.

CHEATS uses Up/Down to select, Left/Right/A/B/C to change, and Start to leave.

| Setting | Values | Default |
| --- | --- | --- |
| ALL EMERALDS | OFF / ON | OFF |
| DEBUG | OFF / ON | OFF |
| SUPER RINGS | 0 / 10 / 50 | 50 |
| RING DRAIN | OFF / ON | ON |
| GOD MODE | OFF / ON | OFF |

ALL EMERALDS overlays the six earned emeralds without altering the earned list. Disabling it reveals only earned progress. With six effective emeralds, every uncollected giant ring flashes and awards 50 rings without entering a Special Stage.

Selecting zero required rings switches drain OFF. Enabling drain at zero changes the threshold to 10. DEBUG applies on level/Special Stage entry. B toggles placement; A+B/A+C/B+C while controlling the airborne rolling player can transform before placement is entered. Returning from placement restores the current form. Death rescue reverts Super and power-ups; ordinary music keeps its playback position, and shoes only restore normal tempo.

## SRAM record

Odd-byte SRAM is declared at `$200001–$20FFFF`; only the first 16 logical bytes are used. Logical byte N is at `$200001 + 2*N`. The record stores `S1DV`, version 2, payload length 8, menu unlock and five cheats, the selected character and an unused legacy byte, then a big-endian checksum of logical bytes 0–13. The character is 0 for Sonic, 1 for Tails or 2 for Knuckles; the legacy byte is normalized to `$FF` to retain compatibility with older version 2 saves. Valid version 1 records retain their unlock and cheats and default to Sonic. Invalid signatures, lengths, versions or checksums load defaults. Writes invalidate the signature first and restore it last.

The ROM bank is restored after access, and the routines must remain below `$200000`. Keep the emulator `.srm` file when replacing a ROM with the same basename. Save states independently restore RAM and can temporarily restore earlier settings. Earned progress is not a persistent SRAM save system.

## God Mode

God Mode prevents damage, drowning and time-over death. Crossing the lower death boundary bounces Sonic upward; left/right input can move him back to solid ground. Air countdown and drowning music do not start while protection is active.

## Solo Tails

Select TAILS in OPTIONS before starting a game or using Level Select. Jump with A/B/C, then press A/B/C again in midair to fly; repeated presses supply ascent pulses. Flight lasts up to eight seconds before exhaustion and resets on landing. The propeller sound plays while he flies (a slower one once he is tired), as in s2_improvements; swimming is silent. The flying tail rotor damages badniks and bosses above Tails, as in S3K; side and bottom contacts remain vulnerable. Final Zone's cylinder fight is an exception: flying Tails can also attack Eggman from the side. Underwater the same controls use swimming poses without a tail attack; the normal air supply still applies. Near a chain of rings, A starts Light Dash instead. Spin Dash and Peel-Out are available; Sonic's Homing Attack is replaced by flight. Debug's standalone B still enters placement mode.

With six effective emeralds Tails can become Super Tails, with four Super Flickies (see [Gameplay](gameplay.md#super-tails-and-super-knuckles)). Giant-ring bonuses use the effective emerald count. Player art, underwater palettes and the lives icon follow the selected character. Large title illustrations retain Sonic's original artwork. The Continue screen shows Tails waiting with Sonic 3 & Knuckles' idle animation and Sonic 2's mini Tails as its counters, the same icon as on the Special Stage results, which say TAILS GOT THEM ALL with every emerald. His ending uses the official mobile Tails poses. The rolling body stays aligned with the floor. Its tails follow movement in eight directions and swish independently of the body animation, as in S3K.

## Solo Knuckles

Select KNUCKLES in OPTIONS. Jump with A/B/C, then hold A/B/C after a second press to glide. Release to fall. Gliding into a vertical terrain wall grabs it; Up/Down climbs, A/B/C jumps away, and holding away releases the wall. At the top Knuckles climbs onto the ledge. His jump is lower than Sonic's. Gliding can defeat badniks, damage bosses (including Eggman in Final Zone's cylinders), and break monitors and compatible walls. Near a chain of rings, A starts Light Dash instead; standalone B retains its debug-placement function when debug is enabled.

With six effective emeralds Knuckles can become Super Knuckles. His fur uses protected palette slots 2/4/5, with a separate red/pink ramp and underwater tints; green shoe panels use protected slot 3. Objects retain their three gray shades independently of the selected character. The lives label uses the S3K KTE abbreviation. Large title illustrations remain Sonic artwork. The Continue screen shows Knuckles waiting with Sonic 3 & Knuckles' idle animation and Knuckles in Sonic 2's mini Knuckles as its counters, the same icon as on the Special Stage results. With every emerald the results say KNUCKLES GOT THEM ALL on two lines, as one line would be wider than a sprite frame reaches. Water tunnels approximate rotation by cycling the ten Sonic 3 & Knuckles glide headings; the original game has no dedicated Knuckles water-spin artwork. Only one playable character is supported.

## Debug display

Coordinates and the sprite count appear separately in the upper-right corner. SCORE and TIME retain their normal meanings. The overlay is hidden during death, results, Game Over and screens that reuse its graphics slots.
