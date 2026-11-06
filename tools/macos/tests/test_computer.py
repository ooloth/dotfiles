#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for tools/macos/computer.rb, which tells Brewfiles which Mac they are evaluated on.

Run with: uv run tools/macos/tests/test_computer.py

The helper has to agree with tools/macos/utils.bash, because the shell decides which tools run and
the Brewfiles decide which get installed. The Ruby tests run macOS's own /usr/bin/ruby, which is
older than the Ruby Homebrew evaluates Brewfiles with, so syntax that passes here passes there.
"""

from __future__ import annotations

import re
import subprocess
import sys
import unittest
from pathlib import Path

MACOS = Path(__file__).resolve().parent.parent
TOOLS = MACOS.parent
HELPER = MACOS / "computer.rb"
UTILS = MACOS / "utils.bash"
REQUIRE = 'require_relative "../macos/computer"'

ON_MACOS = unittest.skipUnless(sys.platform == "darwin", "needs macOS's /usr/bin/ruby")


def ruby(expression: str, *args: str) -> str:
    script = f"require {str(HELPER)!r}; print({expression})"
    result = subprocess.run(
        ["/usr/bin/ruby", "-e", script, *args], capture_output=True, text=True, check=True
    )
    return result.stdout


def brewfiles() -> list[Path]:
    return sorted(path for path in TOOLS.glob("*/Brewfile") if path.parent.name != "@archive")


@ON_MACOS
class ComputerFor(unittest.TestCase):
    def test_names_the_two_personal_macs_and_calls_every_other_name_work(self) -> None:
        cases = {
            "Air": "air",
            "Mini": "mini",
            "": "work",
            "work": "work",
            "air": "work",
            "MacBook Pro": "work",
        }
        for name, expected in cases.items():
            with self.subTest(name=name):
                self.assertEqual(ruby("computer_for(ARGV[0])", name), expected)

    def test_agrees_with_the_shell_on_this_mac(self) -> None:
        shell = subprocess.run(
            ["/bin/bash", "-c", 'source "$1"; printf "%s" "$COMPUTER"', "_", str(UTILS)],
            env={"PATH": "/usr/bin:/bin:/usr/sbin:/sbin"},
            capture_output=True,
            text=True,
            check=True,
        ).stdout
        self.assertEqual(ruby("computer"), shell)

    def test_exactly_one_predicate_holds_on_this_mac(self) -> None:
        answers = ruby("[air?, mini?, work?].count(true)")
        self.assertEqual(answers, "1")


class Brewfiles(unittest.TestCase):
    def test_no_brewfile_works_out_the_machine_itself(self) -> None:
        for path in brewfiles():
            with self.subTest(brewfile=str(path.relative_to(TOOLS))):
                self.assertNotRegex(path.read_text(), r"networksetup|computer_name")

    def test_every_brewfile_that_asks_which_mac_loads_the_helper(self) -> None:
        for path in brewfiles():
            text = path.read_text()
            code = "\n".join(
                line for line in text.splitlines() if not line.lstrip().startswith("#")
            )
            if re.search(r"\b(air|mini|work)\?|\bcomputer\b", code):
                with self.subTest(brewfile=str(path.relative_to(TOOLS))):
                    self.assertIn(REQUIRE, text)


if __name__ == "__main__":
    unittest.main()
