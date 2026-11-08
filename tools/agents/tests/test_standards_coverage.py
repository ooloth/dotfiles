#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests that every standards file can be reached by the skill that scans for it.

Run with: uv run tools/agents/tests/test_standards_coverage.py

scan-standards takes one theme per standards file in its argument-hint. A file added to
tools/agents/config/standards/ without a theme there is one a scan can never be asked for, and
nothing else would notice.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

CONFIG = Path(__file__).resolve().parent.parent / "config"
STANDARDS = CONFIG / "standards"
SCAN_STANDARDS = CONFIG / "skills" / "scan-standards" / "SKILL.md"


def argument_hint_themes() -> set[str]:
    match = re.search(r"^argument-hint: '\[([^\]]*)\]", SCAN_STANDARDS.read_text(), re.MULTILINE)
    assert match, f"{SCAN_STANDARDS} has no argument-hint listing themes"
    return {theme.strip() for theme in match[1].split("|")}


class ScanStandardsThemes(unittest.TestCase):
    def test_every_standards_file_is_a_theme_scan_standards_accepts(self) -> None:
        files = {path.stem for path in STANDARDS.glob("*.md") if path.name != "README.md"}
        self.assertTrue(files, f"no standards files found in {STANDARDS}")
        self.assertEqual(sorted(files - argument_hint_themes()), [])

    def test_every_theme_scan_standards_accepts_has_a_standards_file(self) -> None:
        files = {path.stem for path in STANDARDS.glob("*.md")}
        self.assertEqual(sorted(argument_hint_themes() - files), [])


if __name__ == "__main__":
    unittest.main()
