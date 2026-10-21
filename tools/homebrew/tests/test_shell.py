#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/homebrew/shell.zsh, which stops cask upgrades of self-updating apps on the work laptop.

Run with: uv run tools/homebrew/tests/test_shell.py

Each test sources the file in a bare zsh with `is_work` stubbed, and reads one variable afterwards.
Some tests start with the variable already set, the way tmux hands it to new panes.
"""

from __future__ import annotations

import os
import subprocess
import unittest
from pathlib import Path

SHELL_ZSH = Path(__file__).resolve().parent.parent / "shell.zsh"
GREEDY = "HOMEBREW_UPGRADE_GREEDY"
NO_AUTO_UPDATES = "HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS"


def value_after_sourcing(name: str, *, work: bool, inherited: str | None) -> str | None:
    env = {k: v for k, v in os.environ.items() if k not in (GREEDY, NO_AUTO_UPDATES)}
    if inherited is not None:
        env[name] = inherited
    script = (
        f"is_work() {{ return {0 if work else 1} }}\n"
        f"source '{SHELL_ZSH}'\n"
        f'print -r -- "${{{name}-<unset>}}"\n'
    )
    result = subprocess.run(
        ["zsh", "-f", "-c", script], env=env, capture_output=True, text=True, check=True
    )
    value = result.stdout.strip()
    return None if value == "<unset>" else value


class GreedyUpgradesTest(unittest.TestCase):
    def test_work_laptop_drops_greedy_upgrades_inherited_from_tmux(self) -> None:
        # Apps updated as root can't be replaced without admin rights, which the work account lacks
        self.assertIsNone(value_after_sourcing(GREEDY, work=True, inherited="1"))

    def test_other_machines_upgrade_greedily(self) -> None:
        self.assertEqual(value_after_sourcing(GREEDY, work=False, inherited=None), "1")


class AutoUpdatesCaskUpgradesTest(unittest.TestCase):
    def test_work_laptop_skips_self_updating_casks(self) -> None:
        # Without greedy, brew still upgrades these casks once the app falls behind the tap
        self.assertEqual(value_after_sourcing(NO_AUTO_UPDATES, work=True, inherited=None), "1")

    def test_other_machines_drop_the_skip_inherited_from_tmux(self) -> None:
        self.assertIsNone(value_after_sourcing(NO_AUTO_UPDATES, work=False, inherited="1"))


if __name__ == "__main__":
    unittest.main()
