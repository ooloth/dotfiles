#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/claude/statusline.py, which prints the Claude Code status line.

Run with: uv run tools/claude/tests/test_statusline.py

Most tests pipe the JSON Claude Code sends into the script, with COLUMNS set the way Claude Code
sets it, and a session directory in a throwaway git repo or linked worktree, on a branch or a
detached HEAD, or in no repo at all. Most rate limit tests import the script and call it with a
fixed time, so their colour thresholds are exact. Widths are measured with the colour codes removed,
because those take no screen space.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from datetime import UTC, datetime
from pathlib import Path
from types import ModuleType
from typing import Any
from unittest import mock
from zoneinfo import ZoneInfo

from hypothesis import given, settings
from hypothesis import strategies as st

TOOL = Path(__file__).resolve().parent.parent
SCRIPT = TOOL / "statusline.py"
REPO = TOOL.parent.parent
PAYLOAD = Path(__file__).resolve().parent / "fixtures" / "statusline-payload.json"
SETTINGS = TOOL / "config" / "settings.json"
ANSI_ESCAPE = re.compile(r"\033\[[0-9;]*m")
RIGHT = "Opus 5.5 1M · 10K"
DIM = "\033[2m"
BRANCH_ICON = "\ue725 "  # nf-dev-git_branch, as in tools/tmux/config/gitmux.conf
FOLDER_ICON = "\uf07b  "  # nf-fa-folder, then two spaces because Rex draws it wider than a cell


def load_script() -> ModuleType:
    spec = importlib.util.spec_from_file_location("statusline", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["statusline"] = module  # dataclasses look their module up here
    spec.loader.exec_module(module)
    return module


STATUSLINE = load_script()


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


def status_line(
    directory: Path,
    columns: str | None,
    *,
    used_percentage: float = 1,
    window: int = 1_000_000,
    agent: str | None = None,
) -> str:
    session: dict[str, object] = {
        "model": {"id": "claude-opus-5-5", "display_name": "Opus 5.5"},
        "workspace": {"current_dir": str(directory)},
        "context_window": {"used_percentage": used_percentage, "context_window_size": window},
    }
    if agent is not None:
        session["agent"] = {"name": agent}
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
SUBPATHS = st.lists(st.from_regex(r"[a-z0-9_-]{1,12}", fullmatch=True), max_size=3).map("/".join)


def left_side(line: str) -> str:
    assert line.endswith(" " + RIGHT), line
    return line[: -len(RIGHT)].rstrip(" ")


class LeftSide(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.repo = repo_on_branch(self.tmp, "main")

    def left(self, directory: Path) -> str:
        return left_side(visible(status_line(directory, "120")))

    def worktree(self) -> Path:
        worktree = self.tmp / "wt"
        git(self.repo, "worktree", "add", "-q", "-b", "feat", str(worktree))
        return worktree

    def test_repo_root_shows_repo_name_then_branch(self) -> None:
        self.assertEqual(self.left(self.repo), FOLDER_ICON + "repo · " + BRANCH_ICON + "main")

    def test_subdirectory_shows_path_from_the_repo_root(self) -> None:
        subdirectory = self.repo / "a" / "b"
        subdirectory.mkdir(parents=True)
        self.assertEqual(
            self.left(subdirectory), FOLDER_ICON + "repo/a/b · " + BRANCH_ICON + "main"
        )

    def test_worktree_root_shows_worktree_name_then_its_branch(self) -> None:
        self.assertEqual(self.left(self.worktree()), FOLDER_ICON + "wt · " + BRANCH_ICON + "feat")

    def test_worktree_subdirectory_shows_path_from_the_worktree_root(self) -> None:
        subdirectory = self.worktree() / "x"
        subdirectory.mkdir()
        self.assertEqual(self.left(subdirectory), FOLDER_ICON + "wt/x · " + BRANCH_ICON + "feat")

    def test_detached_head_shows_only_the_location(self) -> None:
        git(self.repo, "checkout", "-q", "--detach")
        self.assertEqual(self.left(self.repo), FOLDER_ICON + "repo")

    def test_directory_outside_a_repo_shows_its_name(self) -> None:
        plain = self.tmp / "plain"
        plain.mkdir()
        self.assertEqual(self.left(plain), FOLDER_ICON + "plain")


def repo_tracking_a_remote(parent: Path) -> Path:
    """A repo on main with one committed file, pushed to a bare remote and tracking it."""
    remote = parent / "remote.git"
    git(parent, "init", "-q", "--bare", "-b", "main", str(remote))
    repo = parent / "repo"
    git(parent, "init", "-q", "-b", "main", str(repo))
    (repo / "file").write_text("a\nb\nc\n")
    git(repo, "add", "file")
    git(repo, "commit", "-q", "-m", "initial")
    git(repo, "remote", "add", "origin", str(remote))
    git(repo, "push", "-q", "-u", "origin", "main")
    return repo


GREEN = "\033[32m"
CYAN = "\033[36m"


class GitStats(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.repo = repo_tracking_a_remote(self.tmp)
        self.file = self.repo / "file"

    def left(self, directory: Path) -> str:
        return left_side(visible(status_line(directory, "120")))

    def fetch_a_commit_from_another_clone(self) -> None:
        other = self.tmp / "other"
        git(self.tmp, "clone", "-q", str(self.tmp / "remote.git"), str(other))
        git(other, "commit", "-q", "--allow-empty", "-m", "theirs")
        git(other, "push", "-q")
        git(self.repo, "fetch", "-q")

    def test_an_unpushed_commit_shows_ahead_by_one(self) -> None:
        git(self.repo, "commit", "-q", "--allow-empty", "-m", "unpushed")
        self.assertEqual(self.left(self.repo), FOLDER_ICON + "repo · " + BRANCH_ICON + "main ↑1")

    def test_ahead_alone_is_followed_by_the_line_counts_after_one_space(self) -> None:
        git(self.repo, "commit", "-q", "--allow-empty", "-m", "unpushed")
        self.file.write_text("a\nb\nc\nd\n")
        self.assertEqual(self.left(self.repo), FOLDER_ICON + "repo · " + BRANCH_ICON + "main ↑1 +1")

    def test_a_fetched_commit_not_yet_merged_shows_behind_by_one(self) -> None:
        self.fetch_a_commit_from_another_clone()
        self.assertEqual(self.left(self.repo), FOLDER_ICON + "repo · " + BRANCH_ICON + "main ↓1")

    def test_staged_and_unstaged_edits_count_together_against_the_last_commit(self) -> None:
        (self.repo / "staged").write_text("new\n")
        git(self.repo, "add", "staged")
        self.file.write_text("a\nX\nc\nd\n")
        self.assertEqual(self.left(self.repo), FOLDER_ICON + "repo · " + BRANCH_ICON + "main +3 -1")

    def test_untracked_files_add_no_lines(self) -> None:
        (self.repo / "untracked").write_text("x\ny\n")
        self.assertEqual(self.left(self.repo), FOLDER_ICON + "repo · " + BRANCH_ICON + "main")

    def test_deletions_alone_show_no_insertions(self) -> None:
        self.file.write_text("a\n")
        self.assertEqual(self.left(self.repo), FOLDER_ICON + "repo · " + BRANCH_ICON + "main -2")

    def test_all_four_counts_appear_in_order(self) -> None:
        self.fetch_a_commit_from_another_clone()
        git(self.repo, "commit", "-q", "--allow-empty", "-m", "ours")
        self.file.write_text("a\nX\nc\nd\n")
        self.assertEqual(
            self.left(self.repo), FOLDER_ICON + "repo · " + BRANCH_ICON + "main ↓1↑1 +2 -1"
        )

    def test_insertions_are_green_and_deletions_red(self) -> None:
        self.file.write_text("a\nX\nc\n")
        line = status_line(self.repo, "120")
        self.assertIn(f"{GREEN}+1", line)
        self.assertIn(f"{RED}-1", line)

    def test_ahead_and_behind_are_cyan(self) -> None:
        self.fetch_a_commit_from_another_clone()
        git(self.repo, "commit", "-q", "--allow-empty", "-m", "ours")
        line = status_line(self.repo, "120")
        self.assertIn(f"{CYAN}↓1↑1\033[0m", line)

    def test_a_linked_worktree_shows_its_own_changes(self) -> None:
        worktree = self.tmp / "wt"
        git(self.repo, "worktree", "add", "-q", "-b", "feat", str(worktree))
        (worktree / "file").write_text("a\nb\nc\nd\n")
        self.file.write_text("a\n")
        self.assertEqual(self.left(worktree), FOLDER_ICON + "wt · " + BRANCH_ICON + "feat +1")

    def test_detached_head_shows_line_counts_after_the_location(self) -> None:
        git(self.repo, "checkout", "-q", "--detach")
        self.file.write_text("a\nb\nc\nd\n")
        self.assertEqual(self.left(self.repo), FOLDER_ICON + "repo · +1")

    def test_a_branch_with_no_commits_shows_the_branch_without_counts_or_errors(self) -> None:
        unborn = self.tmp / "unborn"
        git(self.tmp, "init", "-q", "-b", "main", str(unborn))
        (unborn / "file").write_text("x\n")
        result = subprocess.run(
            [str(SCRIPT)],
            input=json.dumps({"workspace": {"current_dir": str(unborn)}}),
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertTrue(
            visible(result.stdout).startswith(FOLDER_ICON + "unborn · " + BRANCH_ICON + "main "),
            result.stdout,
        )

    def test_reading_the_counts_never_rewrites_the_index(self) -> None:
        # A file whose timestamp no longer matches the index is what makes `git diff` refresh and
        # rewrite the index, taking .git/index.lock from any commit running at the same moment
        later = time.time() + 60
        os.utime(self.file, (later, later))
        index = self.repo / ".git" / "index"
        before = index.stat()
        status_line(self.repo, "120")
        after = index.stat()
        self.assertEqual((after.st_ino, after.st_mtime_ns), (before.st_ino, before.st_mtime_ns))

    @settings(max_examples=25, deadline=None)
    @given(
        insertions=st.integers(min_value=0, max_value=3000),
        deletions=st.integers(min_value=0, max_value=3),
    )
    def test_coloured_line_counts_still_end_at_the_right_edge(
        self, insertions: int, deletions: int
    ) -> None:
        self.file.write_text("a\nb\nc\n"[: 6 - 2 * deletions] + "x\n" * insertions)
        line = status_line(self.repo, "100")
        self.assertEqual(len(visible(line)), 100 - STATUSLINE.EDGE_MARGIN, line)
        self.assertTrue(visible(line).endswith(" " + RIGHT), line)


class GitTimeout(unittest.TestCase):
    def test_a_git_call_past_the_limit_gives_no_counts_and_says_so_on_stderr(self) -> None:
        with tempfile.TemporaryDirectory() as parent:
            slow_git = Path(parent) / "git"
            slow_git.write_text("#!/bin/sh\nexec /bin/sleep 5\n")
            slow_git.chmod(0o755)
            stderr = io.StringIO()
            with (
                mock.patch.dict(os.environ, {"PATH": parent}),
                mock.patch.object(STATUSLINE, "GIT_TIMEOUT_S", 0.1),
                contextlib.redirect_stderr(stderr),
            ):
                checkout = STATUSLINE.read_checkout(parent)
        self.assertEqual(
            checkout,
            STATUSLINE.Checkout(
                location=Path(parent).name,
                branch=None,
                behind=0,
                ahead=0,
                insertions=0,
                deletions=0,
            ),
        )
        lines = stderr.getvalue().splitlines()
        self.assertEqual(len(lines), 4, lines)
        for line in lines:
            self.assertRegex(line, r"^statusline: git .+ timed out after 0\.1s$")


class RightSide(unittest.TestCase):
    def test_agent_name_is_not_shown(self) -> None:
        with tempfile.TemporaryDirectory() as parent:
            line = visible(status_line(Path(parent), "120", agent="security-reviewer"))
        self.assertNotIn("security-reviewer", line)
        self.assertTrue(line.endswith(" " + RIGHT), line)


class Padding(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)

    def test_model_and_context_end_at_the_right_edge_of_a_wide_terminal(self) -> None:
        repo = repo_on_branch(self.tmp, "feature/x")
        line = visible(status_line(repo, "120"))
        self.assertEqual(len(line), 120 - STATUSLINE.EDGE_MARGIN)
        self.assertTrue(line.startswith(f"{FOLDER_ICON}repo · {BRANCH_ICON}feature/x "), line)
        self.assertTrue(line.endswith(" " + RIGHT), line)

    @settings(max_examples=40, deadline=None)
    @given(branch=BRANCHES, subpath=SUBPATHS, columns=st.integers(min_value=1, max_value=140))
    def test_right_side_is_padded_to_the_edge_only_when_it_fits(
        self, branch: str, subpath: str, columns: int
    ) -> None:
        with tempfile.TemporaryDirectory() as parent:
            repo = repo_on_branch(Path(parent), branch)
            directory = repo / subpath
            directory.mkdir(parents=True, exist_ok=True)
            line = visible(status_line(directory, str(columns)))
        left = (
            FOLDER_ICON + "repo" + (f"/{subpath}" if subpath else "") + f" · {BRANCH_ICON}{branch}"
        )
        if len(left) + 1 + len(RIGHT) <= columns - STATUSLINE.EDGE_MARGIN:
            self.assertEqual(len(line), columns - STATUSLINE.EDGE_MARGIN, line)
            self.assertTrue(line.startswith(left + " "), line)
            self.assertTrue(line.endswith(" " + RIGHT), line)
        else:
            self.assertEqual(line, f"{left} {RIGHT}")

    def test_coloured_context_still_ends_at_the_right_edge(self) -> None:
        repo = repo_on_branch(self.tmp, "main")
        for used_percentage in (13, 26):  # 130k is yellow, 260k is red
            line = status_line(repo, "100", used_percentage=used_percentage)
            self.assertIn("\033[", line)
            self.assertEqual(len(visible(line)), 100 - STATUSLINE.EDGE_MARGIN)

    def test_missing_or_non_numeric_columns_gives_one_space_before_the_right_side(self) -> None:
        repo = repo_on_branch(self.tmp, "main")
        for columns in (None, "", "wide"):
            self.assertEqual(
                visible(status_line(repo, columns)),
                f"{FOLDER_ICON}repo · {BRANCH_ICON}main {RIGHT}",
            )


YELLOW = "\033[33m"
RED = "\033[31m"


def context_colour(used_k: int, window_k: int) -> str | None:
    with tempfile.TemporaryDirectory() as parent:
        line = status_line(
            Path(parent), "120", used_percentage=used_k / window_k * 100, window=window_k * 1000
        )
    match = re.search(rf" · (\033\[3[13]m)?{used_k}K", line)
    assert match, line
    return match[1]


class ContextColour(unittest.TestCase):
    def test_a_1m_window_turns_yellow_at_125k(self) -> None:
        self.assertIsNone(context_colour(124, 1000))
        self.assertEqual(context_colour(125, 1000), YELLOW)

    def test_a_1m_window_turns_red_at_250k(self) -> None:
        self.assertEqual(context_colour(249, 1000), YELLOW)
        self.assertEqual(context_colour(250, 1000), RED)

    def test_a_200k_window_turns_yellow_at_half_full(self) -> None:
        self.assertIsNone(context_colour(99, 200))
        self.assertEqual(context_colour(100, 200), YELLOW)

    def test_a_200k_window_turns_red_at_three_quarters_full(self) -> None:
        self.assertEqual(context_colour(149, 200), YELLOW)
        self.assertEqual(context_colour(150, 200), RED)

    def test_the_window_size_is_dim_and_the_model_is_not(self) -> None:
        with tempfile.TemporaryDirectory() as parent:
            line = status_line(Path(parent), "120")
        self.assertIn(f"Opus 5.5{DIM} 1M\033[0m · ", line)


class Payload(unittest.TestCase):
    def run_payload(self, payload: dict[str, object]) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as parent:
            payload["workspace"] = {"current_dir": parent}
            env = {**os.environ, "COLUMNS": "80"}
            return subprocess.run(
                [str(SCRIPT)], input=json.dumps(payload), env=env, capture_output=True, text=True
            )

    def test_a_payload_claude_code_sent_shows_its_model_and_context(self) -> None:
        result = self.run_payload(json.loads(PAYLOAD.read_text()))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn(" Opus 5.5 1M · 110K", visible(result.stdout))

    def test_a_null_used_percentage_shows_no_context_used(self) -> None:
        payload: dict[str, object] = {
            "model": {"id": "claude-opus-5-5"},
            "context_window": {"used_percentage": None, "context_window_size": 1_000_000},
        }
        result = self.run_payload(payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(
            visible(result.stdout).endswith(" claude-opus-5-5 1M · 0K\n"), result.stdout
        )

    def test_the_model_shows_by_its_display_name_then_its_id(self) -> None:
        for model, name in (
            ({"id": "claude-opus-5-5", "display_name": "Opus 5.5"}, "Opus 5.5"),
            ({"id": "claude-opus-5-5"}, "claude-opus-5-5"),
            ({}, "claude"),
        ):
            with self.subTest(name=name):
                session = STATUSLINE.parse_session(json.dumps({"model": model}))
                self.assertEqual(session.model_name, name)

    def test_token_counts_read_in_thousands_then_millions(self) -> None:
        for thousands, text in (
            (0, "0K"),
            (999, "999K"),
            (1000, "1M"),
            (1500, "1.5M"),
            (200, "200K"),
        ):
            with self.subTest(text=text):
                self.assertEqual(STATUSLINE._tokens(thousands), text)


NOW = 1_800_000_000  # Friday 15 January 2027, 08:00 in UTC
ZONE = UTC
HOUR = 3600
FIVE_HOURS = 5 * HOUR
SEVEN_DAYS = 7 * 24 * HOUR
# Nerd Font battery icons by tenths of the battery left: md-battery_outline when empty, md-battery_10
# to md-battery_90, then md-battery when full
BATTERY = {0: "\U000f008e", **{n: chr(0xF0079 + n) for n in range(1, 10)}, 10: "\U000f0079"}
FULL, NINETY, EIGHTY, SEVENTY, SIXTY = BATTERY[10], BATTERY[9], BATTERY[8], BATTERY[7], BATTERY[6]
FORTY, TEN, EMPTY = BATTERY[4], BATTERY[1], BATTERY[0]


def at(day: int, hour: int, minute: int = 0) -> float:
    """Unix seconds for a time in January 2027 in ZONE."""
    return datetime(2027, 1, day, hour, minute, tzinfo=ZONE).timestamp()


def window(used: float, elapsed: float | None, length: int) -> dict[str, object]:
    """A rate limit window as Claude Code sends it, `elapsed` seconds after it started."""
    reported: dict[str, object] = {"used_percentage": used}
    if elapsed is not None:
        reported["resets_at"] = NOW - elapsed + length
    return reported


def usage(rate_limits: dict[str, object] | None, now: float = NOW) -> list[list[Any]]:
    """The segments of each usage window on the right side, for a session with these limits."""
    payload: dict[str, object] = {"model": {"id": "claude-opus-5-5"}}
    if rate_limits is not None:
        payload["rate_limits"] = rate_limits
    session = STATUSLINE.parse_session(json.dumps(payload))
    checkout = STATUSLINE.Checkout(
        location="repo", branch=None, behind=0, ahead=0, insertions=0, deletions=0
    )
    right = STATUSLINE.compose_line(session, checkout, now, ZONE).right
    assert visible(STATUSLINE._render(right[:4])) == "claude-opus-5-5 200K · 0K"
    windows: list[list[Any]] = []
    for segment in right[4:]:
        if segment.text == STATUSLINE.GROUP_SEPARATOR:
            windows.append([])
        else:
            windows[-1].append(segment)
    return windows


def right_side_text(rate_limits: dict[str, object] | None, now: float = NOW) -> str:
    payload: dict[str, object] = {"model": {"id": "claude-opus-5-5"}, "rate_limits": rate_limits}
    session = STATUSLINE.parse_session(json.dumps(payload))
    checkout = STATUSLINE.Checkout(
        location="repo", branch=None, behind=0, ahead=0, insertions=0, deletions=0
    )
    return visible(STATUSLINE._render(STATUSLINE.compose_line(session, checkout, now, ZONE).right))


def shown(rate_limits: dict[str, object] | None, now: float = NOW) -> list[str]:
    return ["".join(segment.text for segment in window) for window in usage(rate_limits, now)]


def five_hour_colour(used: float, elapsed: float | None) -> str | None:
    [segments] = usage({"five_hour": window(used, elapsed, FIVE_HOURS)})
    return segments[0].colour


def seven_day_colour(used: float, elapsed: float) -> str | None:
    [segments] = usage({"seven_day": window(used, elapsed, SEVEN_DAYS)})
    return segments[0].colour


def reset_time(kind: str, resets_at: float) -> str:
    window = STATUSLINE.UsageWindow(STATUSLINE.WindowKind[kind], 50, resets_at)
    return STATUSLINE._reset_time(window, ZONE)


SEVERITY = {None: 0, YELLOW: 1, RED: 2}


class RateLimits(unittest.TestCase):
    def test_the_payload_claude_code_sent_gives_both_windows_in_order(self) -> None:
        session = STATUSLINE.parse_session(PAYLOAD.read_text())
        self.assertEqual(
            [(w.kind.name, w.used_percent, w.resets_at) for w in session.usage],
            [("FIVE_HOUR", 2, 1794124200), ("SEVEN_DAY", 62, 1794229200)],
        )

    def test_each_window_shows_battery_remaining_and_reset_time(self) -> None:
        rate_limits: dict[str, object] = {
            "five_hour": {"used_percentage": 12, "resets_at": at(15, 10, 50)},
            "seven_day": {"used_percentage": 63, "resets_at": at(18, 8)},
        }
        line = right_side_text(rate_limits)
        self.assertEqual(
            line,
            f"claude-opus-5-5 200K · 0K · {NINETY} 88% 10:50am · {FORTY} 37% Mon 8am",
        )

    def test_no_rate_limits_shows_no_usage(self) -> None:
        self.assertEqual(shown(None), [])

    def test_only_the_reported_window_is_shown(self) -> None:
        self.assertEqual(
            shown({"seven_day": {"used_percentage": 62, "resets_at": at(18, 8)}}),
            [f"{FORTY} 38% Mon 8am"],
        )

    def test_a_window_whose_reset_has_passed_is_left_out(self) -> None:
        self.assertEqual(shown({"five_hour": window(40, FIVE_HOURS + 1, FIVE_HOURS)}), [])

    def test_a_window_that_resets_this_second_is_left_out(self) -> None:
        self.assertEqual(shown({"five_hour": {"used_percentage": 40, "resets_at": NOW}}), [])

    def test_a_true_or_false_share_used_leaves_the_window_out(self) -> None:
        for used in (True, False):
            with self.subTest(used=used):
                self.assertEqual(
                    shown({"five_hour": {"used_percentage": used, "resets_at": at(15, 12)}}), []
                )

    def test_a_negative_share_used_shows_the_whole_limit_left(self) -> None:
        self.assertEqual(
            shown({"five_hour": {"used_percentage": -5, "resets_at": at(15, 12)}}),
            [f"{FULL} 100% 12pm"],
        )

    def test_a_reset_time_in_milliseconds_shows_the_window_without_a_time(self) -> None:
        self.assertEqual(
            shown({"five_hour": {"used_percentage": 12, "resets_at": at(15, 12) * 1000}}),
            [f"{NINETY} 88%"],
        )

    def test_a_window_with_no_reset_time_shows_no_time(self) -> None:
        self.assertEqual(shown({"five_hour": {"used_percentage": 12}}), [f"{NINETY} 88%"])

    def test_the_battery_shows_the_remaining_share_to_the_nearest_tenth(self) -> None:
        for remaining, icon in (
            (100, FULL),
            (95, FULL),
            (94, NINETY),
            (5, TEN),
            (4, EMPTY),
            (0, EMPTY),
        ):
            with self.subTest(remaining=remaining):
                self.assertEqual(STATUSLINE._battery(remaining), icon)

    @settings(max_examples=200, deadline=None)
    @given(used=st.floats(min_value=0, max_value=100))
    def test_the_battery_never_differs_from_the_percentage_by_more_than_half_a_tenth(
        self, used: float
    ) -> None:
        [text] = shown({"five_hour": {"used_percentage": used}})
        icon, percent = text.split()
        tenths = STATUSLINE.BATTERY_ICONS.index(icon)
        self.assertLessEqual(abs(tenths * 10 - int(percent.rstrip("%"))), 5, text)

    def test_more_than_the_whole_limit_used_shows_an_empty_battery(self) -> None:
        self.assertEqual(shown({"five_hour": {"used_percentage": 120}}), [f"{EMPTY} 0%"])

    def test_remaining_is_rounded_half_away_from_zero(self) -> None:
        self.assertEqual(shown({"five_hour": {"used_percentage": 23.5}}), [f"{EIGHTY} 77%"])

    def test_five_hour_resets_read_as_a_twelve_hour_clock(self) -> None:
        for hour, minute, text in (
            (2, 50, "2:50am"),
            (8, 0, "8am"),
            (0, 0, "12am"),
            (12, 0, "12pm"),
            (23, 59, "11:59pm"),
        ):
            with self.subTest(text=text):
                self.assertEqual(reset_time("FIVE_HOUR", at(15, hour, minute)), text)

    def test_a_five_hour_reset_tomorrow_shows_no_weekday(self) -> None:
        self.assertEqual(reset_time("FIVE_HOUR", at(16, 1)), "1am")

    def test_a_seven_day_reset_today_still_shows_its_weekday(self) -> None:
        self.assertEqual(reset_time("SEVEN_DAY", at(15, 18)), "Fri 6pm")

    def test_a_reset_time_is_dim_while_its_window_is_coloured(self) -> None:
        [segments] = usage({"five_hour": {"used_percentage": 20, "resets_at": at(15, 12)}})
        self.assertEqual(
            [(s.text, s.colour) for s in segments], [(f"{EIGHTY} 80%", RED), (" 12pm", DIM)]
        )

    def test_a_window_with_no_reset_time_is_coloured_by_use_so_far(self) -> None:
        self.assertIsNone(five_hour_colour(79, None))
        self.assertEqual(five_hour_colour(80, None), YELLOW)
        self.assertEqual(five_hour_colour(100, None), RED)

    def test_a_window_on_pace_to_reach_80_percent_turns_yellow(self) -> None:
        # one hour into five, so use projects to five times what it is
        self.assertIsNone(five_hour_colour(15, HOUR))
        self.assertEqual(five_hour_colour(16, HOUR), YELLOW)

    def test_a_window_on_pace_to_run_out_turns_red(self) -> None:
        self.assertEqual(five_hour_colour(19, HOUR), YELLOW)
        self.assertEqual(five_hour_colour(20, HOUR), RED)

    def test_early_in_a_window_use_projects_as_if_a_tenth_had_passed(self) -> None:
        # ten hours is under a tenth of a week, so use projects to ten times what it is
        self.assertIsNone(seven_day_colour(7.9, 10 * HOUR))
        self.assertEqual(seven_day_colour(8, 10 * HOUR), YELLOW)
        self.assertEqual(seven_day_colour(10, 10 * HOUR), RED)

    @settings(max_examples=300, deadline=None)
    @given(
        used=st.floats(min_value=0, max_value=100),
        more_used=st.floats(min_value=0, max_value=100),
        elapsed=st.integers(min_value=0, max_value=FIVE_HOURS - 1),
        later=st.integers(min_value=0, max_value=FIVE_HOURS - 1),
    )
    def test_more_use_never_lowers_the_colour_and_more_time_never_raises_it(
        self, used: float, more_used: float, elapsed: int, later: int
    ) -> None:
        low, high = sorted((used, more_used))
        early, late = sorted((elapsed, later))
        self.assertLessEqual(
            SEVERITY[five_hour_colour(low, early)], SEVERITY[five_hour_colour(high, early)]
        )
        self.assertGreaterEqual(
            SEVERITY[five_hour_colour(low, early)], SEVERITY[five_hour_colour(low, late)]
        )

    def test_coloured_usage_still_ends_at_the_right_edge(self) -> None:
        now = time.time()
        payload = {
            "model": {"id": "claude-opus-5-5", "display_name": "Opus 5.5"},
            "context_window": {"used_percentage": 1, "context_window_size": 1_000_000},
            # projected to 135% and 90%, far enough from 100% and 80% that the seconds before the
            # script reads the clock cannot change either colour
            "rate_limits": {
                "five_hour": {"used_percentage": 27, "resets_at": now + 4 * HOUR},
                "seven_day": {"used_percentage": 45, "resets_at": now + SEVEN_DAYS / 2},
            },
        }
        with tempfile.TemporaryDirectory() as parent:
            payload["workspace"] = {"current_dir": parent}
            result = subprocess.run(
                [str(SCRIPT)],
                input=json.dumps(payload),
                env={**os.environ, "COLUMNS": "120"},
                capture_output=True,
                text=True,
            )
        line = result.stdout.rstrip("\n")
        self.assertIn(f"{RED}{SEVENTY} 73%\033[0m{DIM} ", line)
        self.assertIn(f"{YELLOW}{SIXTY} 55%\033[0m{DIM} ", line)
        self.assertEqual(len(visible(line)), 120 - STATUSLINE.EDGE_MARGIN, line)
        self.assertRegex(
            visible(line),
            rf" {re.escape(RIGHT)} · {SEVENTY} 73% \d{{1,2}}(:\d\d)?[ap]m · {SIXTY} 55% "
            r"[A-Z][a-z]{2} \d{1,2}(:\d\d)?[ap]m$",
        )

    def test_reset_times_are_shown_in_the_local_time_zone(self) -> None:
        resets_at = (int(time.time()) // 60 + 120) * 60
        tokyo = datetime.fromtimestamp(resets_at, ZoneInfo("Asia/Tokyo"))
        minutes = f":{tokyo.minute:02d}" if tokyo.minute else ""
        clock = f"{tokyo.hour % 12 or 12}{minutes}{'am' if tokyo.hour < 12 else 'pm'}"
        payload = {
            "model": {"id": "claude-opus-5-5"},
            "rate_limits": {"five_hour": {"used_percentage": 1, "resets_at": resets_at}},
        }
        with tempfile.TemporaryDirectory() as parent:
            payload["workspace"] = {"current_dir": parent}
            result = subprocess.run(
                [str(SCRIPT)],
                input=json.dumps(payload),
                env={**os.environ, "TZ": "Asia/Tokyo"},
                capture_output=True,
                text=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(visible(result.stdout).endswith(f" 99% {clock}\n"), result.stdout)


# What a number field in the payload might hold: everything JSON can carry, plus the NaN and
# Infinity that json.dumps writes and json.loads reads back
ODD_NUMBERS = st.one_of(
    st.none(),
    st.booleans(),
    st.integers(min_value=-(10**20), max_value=10**20),
    st.floats(allow_nan=True, allow_infinity=True),
    st.text(max_size=3),
    st.lists(st.integers(), max_size=1),
)


class OddPayloadNumbers(unittest.TestCase):
    @settings(max_examples=500, deadline=None)
    @given(
        five_hour_used=ODD_NUMBERS,
        five_hour_resets_at=ODD_NUMBERS,
        seven_day_used=ODD_NUMBERS,
        seven_day_resets_at=ODD_NUMBERS,
        context_used=ODD_NUMBERS,
        window_size=ODD_NUMBERS,
    )
    def test_any_value_in_a_number_field_still_renders_the_line(
        self,
        five_hour_used: object,
        five_hour_resets_at: object,
        seven_day_used: object,
        seven_day_resets_at: object,
        context_used: object,
        window_size: object,
    ) -> None:
        payload = {
            "model": {"id": "claude-opus-5-5"},
            "context_window": {"used_percentage": context_used, "context_window_size": window_size},
            "rate_limits": {
                "five_hour": {"used_percentage": five_hour_used, "resets_at": five_hour_resets_at},
                "seven_day": {"used_percentage": seven_day_used, "resets_at": seven_day_resets_at},
            },
        }
        session = STATUSLINE.parse_session(json.dumps(payload))
        checkout = STATUSLINE.Checkout(
            location="repo", branch=None, behind=0, ahead=0, insertions=0, deletions=0
        )
        line = STATUSLINE.render(STATUSLINE.compose_line(session, checkout, NOW, ZONE), 120)
        self.assertIn("claude-opus-5-5", visible(line))


class Settings(unittest.TestCase):
    def test_status_line_refreshes_every_five_seconds(self) -> None:
        status_line_settings = json.loads(SETTINGS.read_text())["statusLine"]
        self.assertEqual(status_line_settings["refreshInterval"], 5)

    def test_status_line_runs_the_script_from_the_repo_without_a_link(self) -> None:
        command = json.loads(SETTINGS.read_text())["statusLine"]["command"]
        self.assertEqual(command, "~/Repos/ooloth/dotfiles/tools/claude/statusline.py")
        self.assertTrue(os.access(SCRIPT, os.X_OK), f"{SCRIPT} is not executable")

    def test_no_link_script_links_the_status_line(self) -> None:
        self.assertNotIn("statusline", (REPO / "tools" / "claude" / "link.bash").read_text())


if __name__ == "__main__":
    unittest.main()
