#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for tools/macos/utils.bash, which tells bash scripts which Mac they run on.

Run with: uv run tools/macos/tests/test_utils.py

Each test sources the real file under macOS's own bash and prints the COMPUTER it settles on. The
machine's own name comes from `networksetup`, which the file calls by absolute path, so the
detected value is whatever this Mac is called and the tests compare against that. An Amp orb is
recognised by AMP_ORB=1, which the tests set themselves.
"""

from __future__ import annotations

import subprocess
import sys
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


def predicates(env: dict[str, str]) -> list[str]:
    """The machine predicates that hold once the file is sourced in `env`."""
    program = 'source "$1"; for p in is_air is_mini is_work is_orb; do "$p" && printf "%s\\n" "$p"; done; :'
    result = subprocess.run(
        ["/bin/bash", "-c", program, "_", str(UTILS)],
        env={"PATH": "/usr/bin:/bin:/usr/sbin:/sbin", **env},
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.split()


def detected() -> str:
    name = subprocess.run(
        ["/usr/sbin/networksetup", "-getcomputername"], capture_output=True, text=True, check=True
    ).stdout.strip()
    return NAMES.get(name, "work")


# Detection compares against this Mac's own name from networksetup, which exists only on macOS. A
# platform check rather than "networksetup is missing", so a Mac that lost it fails instead of skipping.
ON_MACOS = unittest.skipUnless(sys.platform == "darwin", "needs macOS's /usr/sbin/networksetup")


class Computer(unittest.TestCase):
    def test_keeps_the_machine_the_caller_already_named(self) -> None:
        for value in ("air", "mini", "work", "orb"):
            with self.subTest(value=value):
                self.assertEqual(computer({"COMPUTER": value}), value)

    def test_an_amp_orb_is_an_orb_on_any_platform(self) -> None:
        self.assertEqual(computer({"AMP_ORB": "1"}), "orb")
        self.assertEqual(computer({"AMP_ORB": "1", "COMPUTER": ""}), "orb")

    def test_in_an_amp_orb_the_machine_the_caller_named_still_wins(self) -> None:
        for value in ("air", "mini", "work"):
            with self.subTest(value=value):
                self.assertEqual(computer({"AMP_ORB": "1", "COMPUTER": value}), value)

    def test_in_an_amp_orb_only_is_orb_holds(self) -> None:
        self.assertEqual(predicates({"AMP_ORB": "1"}), ["is_orb"])

    @ON_MACOS
    def test_any_other_amp_orb_value_detects_the_mac(self) -> None:
        for value in ("", "0", "true"):
            with self.subTest(value=value):
                self.assertEqual(computer({"AMP_ORB": value}), detected())

    @ON_MACOS
    def test_detects_the_machine_when_the_caller_named_none(self) -> None:
        self.assertEqual(computer({}), detected())

    @ON_MACOS
    def test_detects_the_machine_when_the_callers_value_is_empty(self) -> None:
        self.assertEqual(computer({"COMPUTER": ""}), detected())


if __name__ == "__main__":
    unittest.main()
