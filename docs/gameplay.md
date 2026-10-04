# Gameplay and controls

## Special Stages

Special Stage rotation and jump calculations use matching angular precision. Bumpers and jumps preserve the stage collision rules.

## Lost rings

Scattered rings use underwater gravity and flashing near expiry. Their lifetime handles timer wrapping.

## Momentum

Movement can preserve speed above the normal running cap. Input acceleration and braking still apply.

## Rolling jumps

Directional steering remains available after jumping from a roll.

## Score tally

Press an action button during act or Special Stage results to finish counting the remaining bonus immediately.

## Checkpoints

Lampposts save the ring count for a checkpoint restart.

## Extended camera

The horizontal camera looks farther ahead as Sonic runs. Demo exits preserve the final camera position through the fade.

## Air Roll

Press an action button while airborne to curl into a ball when no higher-priority move consumes that input.

## Jump Dash and Homing Attack

An airborne action can dash toward a valid forward target. Homing targets the upper part of the object so low targets do not pull Sonic into the floor.

## Startup

Start can skip the SEGA screen while its sound is playing.

## Spin Dash

Hold Down on the ground and press an action button to charge. Release Down to launch. Charging retains its animation against solid objects; a rolling launch can break compatible walls and monitors.

## Super Sonic

With all six Chaos Emeralds and enough rings, press A+B, A+C or B+C while airborne and rolling to toggle Super. The default threshold is 50 rings and the drain is one ring per second. Speed shoes do not stack with Super movement. Drowning music has priority over form changes; recovery selects the appropriate active music.

## Underwater Super Sonic

Labyrinth uses a subdued blue-grey cycle. Scrap Brain Act 3 uses a related pink-grey cycle. Both use ten steady-cycle entries, with a restrained pulse in the darker fur shades. Water crossings and reversion restore the correct zone palette.

## Super Tails and Super Knuckles

Solo Tails and Knuckles use the same emerald, ring and drain rules. Press two jump buttons together (A+B, A+C or B+C, within six frames) while airborne and rolling; unlike Sonic, holding one button and pressing another does not count, because B/C held after a jump already starts flight or gliding. The combo is checked before flight and gliding, so it never also starts them.

As in Sonic 3 & Knuckles, both keep their normal sprites and change only fur colours: Tails cycles through a yellow ramp, Knuckles through a pink ramp, each with its S3K timing. Each plays the S3K transformation pose. Labyrinth and Scrap Brain Act 3 use underwater versions of both cycles. Super movement uses the S3K values for these characters: top speed $800, acceleration $18 and deceleration $C0, halved underwater. Super Knuckles glides and climbs faster.

Super Tails summons four Super Flickies instead of stars. They circle him, pick a visible badnik or boss and fly into it. Badniks are destroyed and score as if Tails had hit them; a boss loses one hit. Two birds never chase the same target, and a bird waits two seconds after a hit before searching again. When Tails reverts or dies they fly off towards the top left. The Flickies use the stars' VRAM slot; shields remain hidden while Super, as for Sonic.

## Act entry

Title cards begin moving after the level fade. Control resumes as they move away, with level and animal graphics loaded through the entry sequence.

## Giant rings

Free rings can enter a Special Stage from within an act. Act-end rings require 50 rings. Entry freezes Sonic while the flash plays. A return uses the ring centre for X and searches downward for supporting terrain; without a suitable surface the entry height is kept. Separate free-ring subtypes track independent rewards.

## Extra lives

Every 100 rings awards an extra life, including 200, 300 and later thresholds. Losing the rings resets those thresholds: collecting another 100 awards another life. The HUD counters remain bounded.

## Special Stage selection

Level Select can choose Special Stage 1–6 directly. Replaying an already earned emerald does not duplicate it.

## Controllers

Three-button and six-button pads are supported. X, Y, Z and Mode are read but have no assigned gameplay actions.

## Peel-Out

Hold Up on the ground and press A/B/C to charge. Release Up to launch an upright run. Normal Sonic uses figure-eight running; Super Sonic keeps his flying run at every speed. Release feedback uses the Spin Dash release sound.

## Spring poses

Spring launches can use twirling and falling poses. The falling pose is limited to a spring launch and ends on landing.

## Light Dash

Press A in the air facing a chain of at least three ordinary placed rings. Both forms follow curved chains and can continue across ground contact. Grounded A still jumps. Initial range is 64 pixels, maximum inter-ring gap 72 pixels. Speed is 12 pixels/frame, or 6 underwater. Exit momentum follows the final two distinct rings at dash speed. Sonic attacks badniks during the dash; ordinary Sonic is vulnerable after it ends unless curled again. An unreachable target cancels the dash after three stationary frames.

## Good ending

With six effective emeralds, the selected character approaches as Super using the original cutscene timing and Ending music; Tails and Knuckles keep their normal sprites with the Super fur cycle. When the emeralds glow, the regular reversion cycle fades back to the normal colours. Animals, logo and enlarged ending sprites then use their normal palette.
