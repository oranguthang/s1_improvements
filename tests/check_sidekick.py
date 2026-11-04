"""Companion regressions on the default ROM; requires unicorn==2.1.4.
Build first, then run python tests/check_sidekick.py from the repository.
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

if __name__ == "__main__":
    import check_sidekick_modes  # noqa: F401 - selection/SRAM table checks
    from check_sidekick_behavior import run as behavior
    from check_sidekick_carry_water import carry, water
    from check_sidekick_collision import run as collisions
    from check_sidekick_dust import run as dust
    from check_sidekick_effects import run as effects
    from check_sidekick_fixes import run as fixes
    from check_sidekick_gimmicks import run as gimmicks
    from check_sidekick_lifecycle import run as lifecycle
    from check_sidekick_palette import context, palettes

    fixes()
    behavior()
    lifecycle()
    collisions()
    carry()
    water()
    effects()
    dust()
    context()
    palettes()
    gimmicks()
    print("S1 companion checks passed")
