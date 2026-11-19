#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for the provider switch in tools/claude/config/settings.json.

Run with: uv run tools/claude/tests/test_settings.py

`CLAUDE_CODE_USE_VERTEX` in the settings file's `env` block moves every running session between the
subscription and Vertex AI. On the work laptop it is "1" while sessions use Vertex AI, and ""
otherwise. Every machine reads the committed file, so a commit made while it is "1" would start
personal Macs, which have no Vertex AI project, on Vertex AI.
"""

from __future__ import annotations

import json
import subprocess
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent.parent
SETTINGS = "tools/claude/config/settings.json"
SWITCH = "CLAUDE_CODE_USE_VERTEX"


class ProviderSwitch(unittest.TestCase):
    def test_the_settings_file_holds_the_switch(self) -> None:
        # A running session moves back to the subscription only when the value is set to "", since
        # removing a variable from the file does not unset it there
        env = json.loads((REPO / SETTINGS).read_text())["env"]
        self.assertIn(env.get(SWITCH), ("", "1"))

    def test_the_committed_settings_file_has_the_switch_off(self) -> None:
        # Reads the last commit, not the working copy, which is "1" while the work laptop is on
        # Vertex AI
        committed = subprocess.run(
            ["git", "-C", str(REPO), "show", f"HEAD:{SETTINGS}"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout
        self.assertNotEqual(json.loads(committed)["env"].get(SWITCH), "1")


if __name__ == "__main__":
    unittest.main()
