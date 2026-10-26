#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for tools/macos/shell.zsh, which tells zsh which Mac it runs on.

Run with: uv run tools/macos/tests/test_shell.py

Each test sources the real file in a bare zsh and prints the COMPUTER_NAME and COMPUTER it settles
on. `networksetup` is called by absolute path, so the name it detects is whatever this Mac is
called, and the tests compare against that.
"""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path

SHELL_ZSH = Path(__file__).resolve().parent.parent / "shell.zsh"


def sourced(env: dict[str, str]) -> tuple[str, str]:
    result = subprocess.run(
        ["zsh", "-f", "-c", f"source '{SHELL_ZSH}'; print -r -- \"$COMPUTER_NAME|$COMPUTER\""],
        env={"PATH": "/usr/bin:/bin:/usr/sbin:/sbin", **env},
        capture_output=True,
        text=True,
        check=True,
    )
    name, computer = result.stdout.strip().split("|")
    return name, computer


def this_mac() -> str:
    return subprocess.run(
        ["/usr/sbin/networksetup", "-getcomputername"], capture_output=True, text=True, check=True
    ).stdout.strip()


class ComputerName(unittest.TestCase):
    def test_a_new_shell_asks_this_mac_for_its_name(self) -> None:
        self.assertEqual(sourced({})[0], this_mac())

    def test_a_name_inherited_from_the_parent_shell_is_kept(self) -> None:
        # The parent ran on the same Mac, so asking again would only cost a subprocess
        other = "Mini" if this_mac() != "Mini" else "Air"
        self.assertEqual(sourced({"COMPUTER_NAME": other}), (other, other.lower()))

    def test_an_empty_inherited_name_is_asked_for_again(self) -> None:
        self.assertEqual(sourced({"COMPUTER_NAME": ""})[0], this_mac())


if __name__ == "__main__":
    unittest.main()
