#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for tools/agents/check-skills.py.

Run with: uv run tools/agents/tests/test_check_skills.py

Each test writes skills into a throwaway directory and runs check-skills.py against it as a
subprocess, so the checker stays a single file that nothing imports.
"""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

CHECKER = Path(__file__).resolve().parent.parent / "check-skills.py"
FRONTMATTER = "---\nname: example\ndescription: An example skill.\n---\n\n"


@dataclass(frozen=True)
class Run:
    status: int
    stdout: str


def run_checker(files: dict[str, str | bytes]) -> Run:
    """Write `files` into a fresh skills directory and run the checker against it."""
    with tempfile.TemporaryDirectory() as tmp:
        skills = Path(tmp)
        for name, content in files.items():
            path = skills / name
            path.parent.mkdir(parents=True, exist_ok=True)
            if isinstance(content, bytes):
                path.write_bytes(content)
            else:
                path.write_text(content, encoding="utf-8")
        result = subprocess.run(
            ["uv", "run", "--quiet", "--script", str(CHECKER), str(skills)],
            capture_output=True,
            text=True,
        )
        return Run(result.returncode, result.stdout + result.stderr)


def skill(body: str) -> dict[str, str | bytes]:
    return {"example/SKILL.md": FRONTMATTER + body}


class FixedTmpPaths(unittest.TestCase):
    def test_a_skill_naming_a_fixed_tmp_path_fails_naming_file_line_and_path(self) -> None:
        run = run_checker(skill("Steps:\n\n1. `git diff > /tmp/changes.patch`\n"))
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("example/SKILL.md:8: names /tmp/changes.patch", run.stdout)

    def test_a_script_inside_a_skill_naming_a_fixed_tmp_path_fails(self) -> None:
        files = skill("Fine.\n") | {"example/scripts/run.py": 'OUT = "/tmp/out.json"\n'}
        run = run_checker(files)
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("example/scripts/run.py:1: names /tmp/out.json", run.stdout)

    def test_every_fixed_tmp_path_is_reported_not_only_the_first(self) -> None:
        run = run_checker(skill("`/tmp/a`\n`/tmp/b`\n"))
        self.assertIn("names /tmp/a", run.stdout)
        self.assertIn("names /tmp/b", run.stdout)

    def test_other_shared_temp_directories_fail(self) -> None:
        for path in ("/private/tmp/x", "/var/tmp/x"):
            with self.subTest(path=path):
                run = run_checker(skill(f"Write to `{path}`.\n"))
                self.assertEqual(run.status, 1, run.stdout)
                self.assertIn(f"names {path}", run.stdout)

    def test_paths_that_are_not_fixed_tmp_paths_pass(self) -> None:
        for text in (
            'p="$(mktemp -d)/changes.patch"',
            "${TMPDIR:-/tmp}/cache",
            "./build/tmp/x",
            "~/tmp/x",
            "Scratch work never goes in bare `/tmp`.",
        ):
            with self.subTest(text=text):
                run = run_checker(skill(text + "\n"))
                self.assertEqual(run.status, 0, run.stdout)

    def test_compiled_python_caches_are_not_checked(self) -> None:
        files = skill("Fine.\n") | {"example/__pycache__/run.cpython-314.pyc": b"\xff/tmp/x"}
        run = run_checker(files)
        self.assertEqual(run.status, 0, run.stdout)


class WhatCannotBeChecked(unittest.TestCase):
    def test_a_directory_with_no_skills_fails(self) -> None:
        run = run_checker({})
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("No SKILL.md files found", run.stdout)

    def test_a_file_that_is_not_utf8_text_fails_by_name(self) -> None:
        run = run_checker(skill("Fine.\n") | {"example/logo.bin": b"\xff\xfe\x00"})
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("example/logo.bin: not UTF-8 text", run.stdout)


class Frontmatter(unittest.TestCase):
    def test_a_valid_skill_passes(self) -> None:
        run = run_checker(skill("Fine.\n"))
        self.assertEqual(run.status, 0, run.stdout)
        self.assertIn("✅ All skill frontmatter parses", run.stdout)

    def test_broken_frontmatter_still_fails_with_the_same_message(self) -> None:
        run = run_checker({"example/SKILL.md": "No frontmatter here.\n"})
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("example/SKILL.md: no YAML frontmatter block", run.stdout)
        self.assertIn("skill(s) have frontmatter a strict loader will reject", run.stdout)


if __name__ == "__main__":
    unittest.main()
