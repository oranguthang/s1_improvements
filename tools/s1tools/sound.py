"""Sound resources derived from the project's own samples."""

from __future__ import annotations

import argparse
import wave

from s1tools.common import get_root, write_outputs

# Flamedriver plays the SEGA chant from zPlaySEGAPCM, one byte per loop. The
# loop takes 245 Z80 cycles plus about 3.3 wait cycles for reading the byte
# through the 68000 bus window, and the NTSC Z80 runs at 3579545 Hz.
SEGA_LOOP_CYCLES = 245 + 3.3
Z80_CLOCK = 3579545
SEGA_RATE = Z80_CLOCK / SEGA_LOOP_CYCLES


def sega_pcm() -> bytes:
    """Resample Sonic 1's 8-bit SEGA chant to Flamedriver's playback rate."""
    with wave.open(str(get_root() / "sound" / "dac" / "pcm" / "sega.wav")) as source:
        if (source.getnchannels(), source.getsampwidth()) != (1, 1):
            raise ValueError("sega.wav must be 8-bit mono")
        rate = source.getframerate()
        samples = source.readframes(source.getnframes())
    step = rate / SEGA_RATE
    count = int((len(samples) - 1) / step) + 1
    output = bytearray()
    for index in range(count):
        position = index * step
        whole = int(position)
        fraction = position - whole
        following = samples[min(whole + 1, len(samples) - 1)]
        output.append(round(samples[whole] * (1 - fraction) + following * fraction))
    return bytes(output)


def sega_main() -> None:
    parser = argparse.ArgumentParser(description=sega_main.__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    destination = get_root() / "sound" / "flamedriver" / "Sega PCM.bin"
    write_outputs({destination: sega_pcm()}, apply=args.apply)


sega_main.__doc__ = "Write the SEGA chant resampled for Flamedriver."
