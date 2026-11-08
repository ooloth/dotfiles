#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/claude/statusline.py, which prints the Claude Code status line.

Run with: uv run tools/claude/tests/test_statusline.py

Most tests pipe the JSON Claude Code sends into the script, with COLUMNS set the way Claude Code
sets it, and a session directory in a throwaway git repo or linked worktree, on a branch or a
detached HEAD, or in no repo at all. The rate limit tests import the script and call it with a
fixed time, so their colour thresholds are exact. Widths are measured with the colour codes removed, because those take no
screen space.
"""

from __future__ import annotations

import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from types import ModuleType

from hypothesis import given, settings
from hypothesis import strategies as st

CONFIG = Path(__file__).resolve().parent.parent / "config"
SCRIPT = CONFIG.parent / "statusline.py"
REPO = CONFIG.parent.parent.parent
PAYLOAD = Path(__file__).resolve().parent / "fixtures" / "statusline-payload.json"
SETTINGS = CONFIG / "settings.json"
ANSI_ESCAPE = re.compile(r"\033\[[0-9;]*m")
RIGHT = "claude-opus-5-5 · 10k/1000k"
BRANCH_ICON = "\ue725 "  # nf-dev-git_branch, as in tools/tmux/config/gitmux.conf
FOLDER_ICON = "\uf07b  "  # nf-fa-folder, then two spaces because Rex draws it wider than a cell


def edge_margin() -> int:
    match = re.search(r"^EDGE_MARGIN = (\d+)$", SCRIPT.read_text(), re.MULTILINE)
    assert match, f"{SCRIPT.name} sets no EDGE_MARGIN"
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


def status_line(
    directory: Path,
    columns: str | None,
    *,
    used_percentage: float = 1,
    window: int = 1_000_000,
    agent: str | None = None,
) -> str:
    session: dict[str, object] = {
        "model": {"id": "claude-opus-5-5"},
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
        self.assertEqual(len(visible(line)), 100 - edge_margin(), line)
        self.assertTrue(visible(line).endswith(" " + RIGHT), line)


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
        self.assertEqual(len(line), 120 - edge_margin())
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
        if len(left) + 1 + len(RIGHT) <= columns - edge_margin():
            self.assertEqual(len(line), columns - edge_margin(), line)
            self.assertTrue(line.startswith(left + " "), line)
            self.assertTrue(line.endswith(" " + RIGHT), line)
        else:
            self.assertEqual(line, f"{left} {RIGHT}")

    def test_coloured_context_still_ends_at_the_right_edge(self) -> None:
        repo = repo_on_branch(self.tmp, "main")
        for used_percentage in (13, 26):  # 130k is yellow, 260k is red
            line = status_line(repo, "100", used_percentage=used_percentage)
            self.assertIn("\033[", line)
            self.assertEqual(len(visible(line)), 100 - edge_margin())

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
    assert line.endswith(f"{used_k}k/{window_k}k") or line.endswith(
        f"{used_k}k/{window_k}k\033[0m"
    ), line
    for colour in (YELLOW, RED):
        if f"{colour}{used_k}k/" in line:
            return colour
    return None


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
        self.assertIn(" claude-opus-5-5 · 110k/1000k", visible(result.stdout))

    def test_a_null_used_percentage_shows_no_context_used(self) -> None:
        payload: dict[str, object] = {
            "model": {"id": "claude-opus-5-5"},
            "context_window": {"used_percentage": None, "context_window_size": 1_000_000},
        }
        result = self.run_payload(payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.endswith(" claude-opus-5-5 · 0k/1000k\n"), result.stdout)


def load_script() -> ModuleType:
    spec = importlib.util.spec_from_file_location("statusline", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["statusline"] = module  # dataclasses look their module up here
    spec.loader.exec_module(module)
    return module


STATUSLINE = load_script()
NOW = 1_800_000_000
HOUR = 3600
FIVE_HOURS = 5 * HOUR
SEVEN_DAYS = 7 * 24 * HOUR


def window(used: float, elapsed: float | None, length: int) -> dict[str, object]:
    """A rate limit window as Claude Code sends it, `elapsed` seconds after it started."""
    reported: dict[str, object] = {"used_percentage": used}
    if elapsed is not None:
        reported["resets_at"] = NOW - elapsed + length
    return reported


def right_side(rate_limits: dict[str, object] | None, now: float = NOW) -> str:
    """The right side of the line, with colour codes, for a session with these rate limits."""
    payload: dict[str, object] = {"model": {"id": "claude-opus-5-5"}}
    if rate_limits is not None:
        payload["rate_limits"] = rate_limits
    session = STATUSLINE.parse_session(json.dumps(payload))
    checkout = STATUSLINE.Checkout(
        location="repo", branch=None, behind=0, ahead=0, insertions=0, deletions=0
    )
    line = STATUSLINE.compose_line(session, checkout, now)
    return STATUSLINE._render(line.right)


def five_hour_colour(used: float, elapsed: float | None) -> str | None:
    line = right_side({"five_hour": window(used, elapsed, FIVE_HOURS)})
    shown = f"5h {STATUSLINE._round(used)}%"
    assert shown in visible(line), line
    for colour in (YELLOW, RED):
        if f"{colour}{shown}" in line:
            return colour
    return None


def seven_day_colour(used: float, elapsed: float) -> str | None:
    line = right_side({"seven_day": window(used, elapsed, SEVEN_DAYS)})
    for colour in (YELLOW, RED):
        if f"{colour}7d " in line:
            return colour
    return None


SEVERITY = {None: 0, YELLOW: 1, RED: 2}


class RateLimits(unittest.TestCase):
    def test_the_payload_claude_code_sent_gives_both_windows_in_order(self) -> None:
        session = STATUSLINE.parse_session(PAYLOAD.read_text())
        self.assertEqual(
            [(w.label, w.used_percent, w.resets_at) for w in session.usage],
            [("5h", 2, 1794124200), ("7d", 62, 1794229200)],
        )

    def test_both_windows_follow_the_context(self) -> None:
        line = right_side(
            {
                "five_hour": window(23, HOUR, FIVE_HOURS),
                "seven_day": window(41, 3 * 24 * HOUR, SEVEN_DAYS),
            }
        )
        self.assertEqual(visible(line), "claude-opus-5-5 · 0k/200k · 5h 23% · 7d 41%")

    def test_no_rate_limits_shows_no_usage(self) -> None:
        self.assertEqual(visible(right_side(None)), "claude-opus-5-5 · 0k/200k")

    def test_only_the_reported_window_is_shown(self) -> None:
        line = visible(right_side({"seven_day": window(62, 3 * 24 * HOUR, SEVEN_DAYS)}))
        self.assertEqual(line, "claude-opus-5-5 · 0k/200k · 7d 62%")

    def test_a_window_whose_reset_has_passed_is_left_out(self) -> None:
        line = right_side({"five_hour": window(40, FIVE_HOURS + 1, FIVE_HOURS)})
        self.assertEqual(visible(line), "claude-opus-5-5 · 0k/200k")

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

    def test_usage_is_rounded_half_away_from_zero(self) -> None:
        line = visible(right_side({"five_hour": window(23.5, 4 * HOUR, FIVE_HOURS)}))
        self.assertTrue(line.endswith("5h 24%"), line)

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
            "model": {"id": "claude-opus-5-5"},
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
        self.assertIn(f"{RED}5h 27%", line)
        self.assertIn(f"{YELLOW}7d 45%", line)
        self.assertEqual(len(visible(line)), 120 - edge_margin(), line)
        self.assertTrue(visible(line).endswith(f" {RIGHT} · 5h 27% · 7d 45%"), line)


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
