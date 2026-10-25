#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for tools/macos/utils.bash, which tells bash scripts which Mac they run on.

Run with: uv run tools/macos/tests/test_utils.py

Each test sources the real file under macOS's own bash and prints the COMPUTER it settles on. The
machine's own name comes from `networksetup`, which the file calls by absolute path, so the
detected value is whatever this Mac is called and the tests compare against that.
"""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path

UTILS = Path(__file__).resolve().parent.parent / "utils.bash"
NAMES = {"Air": "air", "Mini": "mini"}


def computer(env: dict[str, str]) -> str:
    result = subprocess.run(
        ["/bin/bash", "-c", 'source "$1"; printf "%s" "$COMPUTER"', "_", str(UTILS)],
        env={"PATH": "/usr/bin:/bin:/usr/sbin:/sbin", **env},
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout


def detected() -> str:
    name = subprocess.run(
        ["/usr/sbin/networksetup", "-getcomputername"], capture_output=True, text=True, check=True
    ).stdout.strip()
    return NAMES.get(name, "work")


class Computer(unittest.TestCase):
    def test_keeps_the_machine_the_caller_already_named(self) -> None:
        for value in ("air", "mini", "work"):
            with self.subTest(value=value):
                self.assertEqual(computer({"COMPUTER": value}), value)

    def test_detects_the_machine_when_the_caller_named_none(self) -> None:
        self.assertEqual(computer({}), detected())

    def test_detects_the_machine_when_the_callers_value_is_empty(self) -> None:
        self.assertEqual(computer({"COMPUTER": ""}), detected())


if __name__ == "__main__":
    unittest.main()
