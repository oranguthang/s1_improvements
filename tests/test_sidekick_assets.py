"""Reproducible companion resources and DMA-bank boundaries."""

from s1tools.common import write_outputs
from s1tools.sidekick import generate


def test_checked_in_companion_resources():
    outputs = generate()
    assert len(outputs) > 90
    write_outputs(outputs, apply=False)
