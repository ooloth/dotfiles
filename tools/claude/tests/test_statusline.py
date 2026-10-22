#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/claude/config/statusline.sh, which prints the Claude Code status line.

Run with: uv run tools/claude/tests/test_statusline.py

Each test pipes the JSON Claude Code sends into the script, with COLUMNS set the way Claude Code sets
it, and a session directory that is a throwaway git repo on a branch, on a detached HEAD, or no repo
at all. Widths are measured with the colour codes removed, because those take no screen space.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from hypothesis import given, settings
from hypothesis import strategies as st

CONFIG = Path(__file__).resolve().parent.parent / "config"
SCRIPT = CONFIG / "statusline.sh"
SETTINGS = CONFIG / "settings.json"
ANSI_ESCAPE = re.compile(r"\033\[[0-9;]*m")


def edge_margin() -> int:
    match = re.search(r"^edge_margin=(\d+)$", SCRIPT.read_text(), re.MULTILINE)
    assert match, f"{SCRIPT.name} sets no edge_margin"
    return int(match[1])


def git(directory: Path, *args: str) -> None:
    subprocess.run(
        ["git", "-C", str(directory), "-c", "user.name=t", "-c", "user.email=t@t", *args],
        check=True,
        capture_output=True,
    )


def repo_on_branch(parent: Path, branch: str) -> Path:
    repo = parent / "repo"
    git(parent, "init", "-q", "-b", branch, str(repo))
    git(repo, "commit", "-q", "--allow-empty", "-m", "initial")
    return repo


def status_line(directory: Path, columns: str | None, *, used_percentage: float = 1) -> str:
    session = {
        "model": {"id": "claude-opus-5-5"},
        "workspace": {"current_dir": str(directory)},
        "context_window": {"used_percentage": used_percentage, "context_window_size": 1_000_000},
    }
    env = {k: v for k, v in os.environ.items() if k != "COLUMNS"}
    if columns is not None:
        env["COLUMNS"] = columns
    result = subprocess.run(
        [str(SCRIPT)], input=json.dumps(session), env=env, capture_output=True, text=True
    )
    assert result.returncode == 0, result.stderr
    return result.stdout.rstrip("\n")


def visible(line: str) -> str:
    return ANSI_ESCAPE.sub("", line)


# git refuses names with spaces, "..", a leading "-" and similar, so stick to the characters
# branch names usually have
BRANCHES = st.from_regex(r"[a-z][a-z0-9/_-]{0,30}[a-z0-9]", fullmatch=True).filter(
    lambda name: "//" not in name
)


class BranchOnTheRight(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.outside_repo = self.tmp / "plain"
        self.outside_repo.mkdir()

    def test_branch_ends_at_the_right_edge_of_a_wide_terminal(self) -> None:
        repo = repo_on_branch(self.tmp, "feature/x")
        line = visible(status_line(repo, "120"))
        self.assertEqual(len(line), 120 - edge_margin())
        self.assertTrue(line.endswith(" feature/x"), line)

    @settings(max_examples=40, deadline=None)
    @given(branch=BRANCHES, columns=st.integers(min_value=1, max_value=140))
    def test_branch_is_padded_to_the_edge_only_when_it_fits(
        self, branch: str, columns: int
    ) -> None:
        with tempfile.TemporaryDirectory() as parent:
            repo = repo_on_branch(Path(parent), branch)
            left = visible(status_line(self.outside_repo, str(columns)))
            line = visible(status_line(repo, str(columns)))
        if len(left) + 1 + len(branch) <= columns - edge_margin():
            self.assertEqual(len(line), columns - edge_margin(), line)
            self.assertTrue(line.startswith(left + " "), line)
            self.assertTrue(line.endswith(" " + branch), line)
        else:
            self.assertEqual(line, f"{left} {branch}")

    def test_coloured_context_does_not_shift_the_branch(self) -> None:
        repo = repo_on_branch(self.tmp, "main")
        for used_percentage in (6, 12):  # 60k is yellow, 120k is red
            line = status_line(repo, "100", used_percentage=used_percentage)
            self.assertIn("\033[", line)
            self.assertEqual(len(visible(line)), 100 - edge_margin())

    def test_missing_or_non_numeric_columns_gives_one_space_before_the_branch(self) -> None:
        repo = repo_on_branch(self.tmp, "main")
        left = visible(status_line(self.outside_repo, None))
        for columns in (None, "", "wide"):
            self.assertEqual(visible(status_line(repo, columns)), f"{left} main")

    def test_detached_head_shows_no_branch(self) -> None:
        repo = repo_on_branch(self.tmp, "main")
        git(repo, "checkout", "-q", "--detach")
        self.assertEqual(status_line(repo, "120"), status_line(self.outside_repo, "120"))

    def test_directory_outside_a_repo_shows_only_the_left_part(self) -> None:
        line = status_line(self.outside_repo, "120")
        self.assertEqual(visible(line), "claude-opus-5-5 · 10k/1000k")


class Settings(unittest.TestCase):
    def test_status_line_refreshes_every_five_seconds(self) -> None:
        status_line_settings = json.loads(SETTINGS.read_text())["statusLine"]
        self.assertEqual(status_line_settings["refreshInterval"], 5)


if __name__ == "__main__":
    unittest.main()
