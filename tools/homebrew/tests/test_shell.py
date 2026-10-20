#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/homebrew/shell.zsh, which turns greedy cask upgrades off on the work laptop.

Run with: uv run tools/homebrew/tests/test_shell.py

Each test sources the file in a bare zsh with `is_work` stubbed, and reads HOMEBREW_UPGRADE_GREEDY
afterwards. The work test starts with the variable already set, the way tmux hands it to new panes.
"""

from __future__ import annotations

import os
import subprocess
import unittest
from pathlib import Path

SHELL_ZSH = Path(__file__).resolve().parent.parent / "shell.zsh"


def greedy_after_sourcing(*, work: bool, inherited: str | None) -> str | None:
    env = {k: v for k, v in os.environ.items() if k != "HOMEBREW_UPGRADE_GREEDY"}
    if inherited is not None:
        env["HOMEBREW_UPGRADE_GREEDY"] = inherited
    script = (
        f"is_work() {{ return {0 if work else 1} }}\n"
        f"source '{SHELL_ZSH}'\n"
        'print -r -- "${HOMEBREW_UPGRADE_GREEDY-<unset>}"\n'
    )
    result = subprocess.run(
        ["zsh", "-f", "-c", script], env=env, capture_output=True, text=True, check=True
    )
    value = result.stdout.strip()
    return None if value == "<unset>" else value


class GreedyUpgradesTest(unittest.TestCase):
    def test_work_laptop_drops_greedy_upgrades_inherited_from_tmux(self) -> None:
        # Apps updated as root can't be replaced without admin rights, which the work account lacks
        self.assertIsNone(greedy_after_sourcing(work=True, inherited="1"))

    def test_other_machines_upgrade_greedily(self) -> None:
        self.assertEqual(greedy_after_sourcing(work=False, inherited=None), "1")


if __name__ == "__main__":
    unittest.main()
