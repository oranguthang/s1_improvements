# Settings and SRAM

## Title menu and controls

The title initially shows START GAME and OPTIONS. OPTIONS contains one CHARACTER setting (SONIC, TAILS or KNUCKLES). Left/Right/A/B/C changes the character, and Start returns to the title. Up/Down does nothing on this screen. SRAM remembers the character selection. Sonic Team Presents, the title, attract demos, Continue, credits and credit demos always use Sonic and his palettes; returning to gameplay restores the saved character. The ending uses the selected character, including its run, emerald sequence and jump towards the screen. All three endings currently use normal forms. Tails and Knuckles use their official Sonic 1 mobile ending poses. Special Stage results use Sonic's fixed presentation artwork and HUD. Multiplayer and Competition modes are not supported.

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

Selecting zero required rings switches drain OFF. Enabling drain at zero changes the threshold to 10. DEBUG applies on level/Special Stage entry. B toggles placement; A+B/A+C/B+C while controlling airborne rolling Sonic can transform before placement is entered. Returning from placement restores the current form. Death rescue reverts Super and power-ups; ordinary music keeps its playback position, and shoes only restore normal tempo.

## SRAM record

Odd-byte SRAM is declared at `$200001–$20FFFF`; only the first 16 logical bytes are used. Logical byte N is at `$200001 + 2*N`. The record stores `S1DV`, version 2, payload length 8, menu unlock and five cheats, the selected character and an unused legacy byte, then a big-endian checksum of logical bytes 0–13. The character is 0 for Sonic, 1 for Tails or 2 for Knuckles; the legacy byte is normalized to `$FF` to retain compatibility with older version 2 saves. Valid version 1 records retain their unlock and cheats and default to Sonic. Invalid signatures, lengths, versions or checksums load defaults. Writes invalidate the signature first and restore it last.

The ROM bank is restored after access, and the routines must remain below `$200000`. Keep the emulator `.srm` file when replacing a ROM with the same basename. Save states independently restore RAM and can temporarily restore earlier settings. Earned progress is not a persistent SRAM save system.

## God Mode

God Mode prevents damage, drowning and time-over death. Crossing the lower death boundary bounces Sonic upward; left/right input can move him back to solid ground. Air countdown and drowning music do not start while protection is active.

## Solo Tails

Select TAILS in OPTIONS before starting a game or using Level Select. Jump with A/B/C, then press B or C again in midair to fly; repeated presses supply ascent pulses. Flight lasts up to eight seconds before exhaustion and resets on landing. Underwater the same controls use swimming poses; the normal air supply still applies. A retains Light Dash. Spin Dash and Peel-Out are available; Sonic's Homing Attack is replaced by flight. Debug's standalone B still enters placement mode.

Tails has no Super form, even with all emeralds granted. Giant-ring bonuses still use the effective emerald count. Player art, underwater palettes and the lives icon follow the selected character. Large title illustrations and the small Continue counter illustrations retain Sonic's original artwork. His ending uses the official mobile Tails poses. The rolling body stays aligned with the floor. Its tails follow movement in eight directions and swish independently of the body animation, as in S3K.

## Solo Knuckles

Select KNUCKLES in OPTIONS. Jump with A/B/C, then hold B or C after a second press to glide. Release to fall. Gliding into a vertical terrain wall grabs it; Up/Down climbs, B/C jumps away, and holding away releases the wall. At the top Knuckles climbs onto the ledge. His jump is lower than Sonic's. Gliding can defeat badniks and break monitors and compatible walls. A retains Light Dash; standalone B retains its debug-placement function when debug is enabled.

Knuckles has no Super form. His fur uses protected palette slots 2/4/5, with a separate red/pink ramp and underwater tints; green shoe panels use protected slot 3. Objects retain their three gray shades independently of the selected character. The lives label uses the S3K KTE abbreviation. Large title illustrations and Continue counters remain Sonic artwork. Water tunnels approximate rotation by cycling the ten Sonic 3 & Knuckles glide headings; the original game has no dedicated Knuckles water-spin artwork. Only one playable character is supported.

## Debug display

Coordinates and the sprite count appear separately in the upper-right corner. SCORE and TIME retain their normal meanings. The overlay is hidden during death, results, Game Over and screens that reuse its graphics slots.
