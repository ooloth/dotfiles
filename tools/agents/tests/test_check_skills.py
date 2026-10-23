#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for tools/agents/check-skills.py.

Run with: uv run tools/agents/tests/test_check_skills.py

Each test writes skills into a throwaway git repo and runs check-skills.py against it as a
subprocess, so the checker stays a single file that nothing imports. The repo is needed because the
checker takes its file list from git.
"""

from __future__ import annotations

import os
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


def run_checker(
    files: dict[str, str | bytes], *, gitignore: str = "", tracked: tuple[str, ...] = ()
) -> Run:
    """Write `files` into a skills directory inside a fresh git repo and run the checker on it.

    `gitignore` becomes the repo's root .gitignore, as in the dotfiles repo, and each path in
    `tracked` is force-added to the index, so it is tracked even where `gitignore` ignores it.
    """
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        skills = repo / "skills"
        skills.mkdir()
        subprocess.run(["git", "init", "--quiet", str(repo)], check=True)
        (repo / ".gitignore").write_text(gitignore, encoding="utf-8")
        for name, content in files.items():
            path = skills / name
            path.parent.mkdir(parents=True, exist_ok=True)
            if isinstance(content, bytes):
                path.write_bytes(content)
            else:
                path.write_text(content, encoding="utf-8")
        if tracked:
            subprocess.run(["git", "-C", str(skills), "add", "--force", *tracked], check=True)
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


class WhichFilesAreChecked(unittest.TestCase):
    """Git decides, so a gitignored skill, such as a synced third-party one, is never checked."""

    def test_a_gitignored_file_naming_a_fixed_tmp_path_is_not_reported(self) -> None:
        files = skill("Fine.\n") | {"synced/theirs/run.py": 'OUT = "/tmp/out.json"\n'}
        run = run_checker(files, gitignore="skills/synced/\n")
        self.assertEqual(run.status, 0, run.stdout)
        self.assertNotIn("synced/", run.stdout)

    def test_a_gitignored_skill_with_broken_frontmatter_is_not_reported(self) -> None:
        files = skill("Fine.\n") | {"theirs/SKILL.md": "No frontmatter here.\n"}
        run = run_checker(files, gitignore="skills/theirs/\n")
        self.assertEqual(run.status, 0, run.stdout)
        self.assertNotIn("theirs/", run.stdout)

    def test_an_untracked_file_that_is_not_ignored_is_still_reported(self) -> None:
        files = skill("Fine.\n") | {"new/SKILL.md": FRONTMATTER + "`/tmp/new`\n"}
        run = run_checker(files, gitignore="skills/synced/\n")
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("new/SKILL.md:6: names /tmp/new", run.stdout)

    def test_a_tracked_file_inside_an_ignored_folder_is_still_reported(self) -> None:
        files = skill("Fine.\n") | {"synced/kept.md": "`/tmp/kept`\n"}
        run = run_checker(files, gitignore="skills/synced/\n", tracked=("synced/kept.md",))
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("synced/kept.md:1: names /tmp/kept", run.stdout)


class WhatCannotBeChecked(unittest.TestCase):
    def test_a_directory_with_no_skills_fails(self) -> None:
        run = run_checker({})
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("No SKILL.md files found", run.stdout)

    def test_a_file_that_is_not_utf8_text_fails_by_name(self) -> None:
        run = run_checker(skill("Fine.\n") | {"example/logo.bin": b"\xff\xfe\x00"})
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("example/logo.bin: not UTF-8 text", run.stdout)

    def test_a_skills_directory_outside_a_git_repo_fails_with_a_sentence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(
                ["uv", "run", "--quiet", "--script", str(CHECKER), tmp],
                capture_output=True,
                text=True,
                env={**os.environ, "GIT_CEILING_DIRECTORIES": str(Path(tmp).parent)},
            )
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("Can't list the files", result.stderr)
        self.assertNotIn("Traceback", result.stderr)


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
