# Settings and SRAM

## Title menu and controls

Enter Up, Down, Down, Down, Left, Right on the title to unlock START GAME, LEVEL SELECT and SETTINGS. SRAM remembers the unlock. Old title cheat sequences are disabled. With the title menu unlocked, pause and press A to return directly to the title. Debug alone does not unlock this shortcut.

Settings use Up/Down to select, Left/Right/A/B/C to change, and Start to leave.

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

Odd-byte SRAM is declared at `$200001–$20FFFF`; only the first 16 logical bytes are used. Logical byte N is at `$200001 + 2*N`. The record stores `S1DV`, version 1, payload length 6, menu unlock and five settings, two reserved bytes, then a big-endian checksum of logical bytes 0–13. Invalid signatures, lengths, versions or checksums load defaults. Writes invalidate the signature first and restore it last.

The ROM bank is restored after access, and the routines must remain below `$200000`. Keep the emulator `.srm` file when replacing a ROM with the same basename. Save states independently restore RAM and can temporarily restore earlier settings. Earned progress is not a persistent SRAM save system.

## God Mode

God Mode prevents damage, drowning and time-over death. Crossing the lower death boundary bounces Sonic upward; left/right input can move him back to solid ground. Air countdown and drowning music do not start while protection is active.
