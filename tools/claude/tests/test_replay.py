#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis", "pydantic>=2,<3"]
# ///
"""Tests for tools/claude/replay.py, which replays unattended planning on a finished ticket.

Run with: uv run tools/claude/tests/test_replay.py

Most tests load the script in-process and call its pure steps directly. The GitHub boundary is
read from a real GraphQL response for ooloth/dotfiles#198, and the transcript and session-result
boundaries from a real sandboxed Claude Code session, trimmed to the lines the audit reads. The
`gh` stand-in and the clone are separate processes and real git, so their tests run them. The
end-to-end test runs `replay plan` as a subprocess with fake `gh` and `claude` commands on PATH, so
no test reaches GitHub or a real Claude Code session.
"""

from __future__ import annotations

import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

from hypothesis import given
from hypothesis import strategies as st

SCRIPT = Path(__file__).resolve().parent.parent / "replay.py"
FIXTURES = Path(__file__).resolve().parent / "fixtures" / "replay"

_spec = importlib.util.spec_from_file_location("replay", SCRIPT)
assert _spec is not None and _spec.loader is not None, f"cannot load {SCRIPT}"
replay = importlib.util.module_from_spec(_spec)
sys.modules["replay"] = replay
_spec.loader.exec_module(replay)

DOTFILES_REF = replay.TicketRef("ooloth", "dotfiles", 198)
OTHER_REF = replay.TicketRef("octo", "widgets", 7)
T0 = datetime(2026, 10, 1, tzinfo=UTC)


def at(minutes: int) -> datetime:
    return T0 + timedelta(minutes=minutes)


def history(
    *,
    body: str = "current body",
    edits: tuple = (),
    approach_at: datetime = T0,
    ref=OTHER_REF,
    title: str = "A title",
    renames: tuple = (),
):
    return replay.TicketHistory(
        ref=ref,
        title=title,
        title_renames=renames,
        body=body,
        body_edits=edits,
        approach=replay.Comment(approach_at, "# Approach\n\nmine"),
        design=replay.Comment(approach_at + timedelta(hours=1), "# Design\n\nmine"),
    )


def git(
    cwd: Path, *args: str, date: datetime | None = None, author_date: datetime | None = None
) -> str:
    env = dict(os.environ)
    if date is not None:
        env["GIT_COMMITTER_DATE"] = env["GIT_AUTHOR_DATE"] = date.isoformat()
    if author_date is not None:
        env["GIT_AUTHOR_DATE"] = author_date.isoformat()
    result = subprocess.run(
        ["git", "-C", str(cwd), *args], check=True, capture_output=True, text=True, env=env
    )
    return result.stdout.strip()


def make_source(root: Path, dates: list[datetime]) -> tuple[Path, list[str]]:
    """A repo on `main` with one commit per date, returning it and the commit hashes."""
    source = root / "source"
    source.mkdir()
    git(source, "init", "-q", "-b", "main")
    git(source, "config", "user.email", "test@example.com")
    git(source, "config", "user.name", "Test")
    shas = []
    for i, date in enumerate(dates):
        (source / f"file{i}.txt").write_text(f"{i}\n")
        git(source, "add", ".")
        git(source, "commit", "-q", "-m", f"commit {i}", date=date)
        shas.append(git(source, "rev-parse", "HEAD"))
    return source, shas


# ── The body the replay sees ───────────────────────────────────────────────────────────────────

edit_minutes = st.lists(st.integers(-500, 500), unique=True, max_size=6)


class CutAtPlanning(unittest.TestCase):
    @given(edit_minutes, st.integers(-500, 500))
    def test_serves_the_newest_body_edited_at_or_before_planning_began(
        self, minutes: list[int], began: int
    ) -> None:
        edits = tuple(replay.BodyEdit(at(m), f"edit at {m}") for m in minutes)
        result = replay.cut_at_planning(history(edits=edits, approach_at=at(began)))
        earlier = [m for m in minutes if m <= began]
        if not minutes:
            assert isinstance(result, replay.PlanningSnapshot)
            assert result.body == "current body"
        elif not earlier:
            assert result == replay.BodyUnknown(at(began))
        else:
            assert isinstance(result, replay.PlanningSnapshot)
            assert result.body == f"edit at {max(earlier)}"

    def test_an_edit_stamped_exactly_when_planning_began_is_served(self) -> None:
        edits = (replay.BodyEdit(at(0), "at planning"), replay.BodyEdit(at(-5), "older"))
        result = replay.cut_at_planning(history(edits=edits, approach_at=at(0)))
        assert isinstance(result, replay.PlanningSnapshot)
        assert result.body == "at planning"

    @given(st.lists(st.integers(-500, 500), unique=True, max_size=5), st.integers(-500, 500))
    def test_serves_the_title_in_force_when_planning_began(
        self, minutes: list[int], began: int
    ) -> None:
        # Title i is in force from the i-th rename on; title 0 from before any.
        times = sorted(minutes)
        renames = tuple(replay.TitleRename(at(m), f"title {i}") for i, m in enumerate(times))
        result = replay.cut_at_planning(
            history(title=f"title {len(times)}", renames=renames, approach_at=at(began))
        )
        assert isinstance(result, replay.PlanningSnapshot)
        assert result.title == f"title {sum(m <= began for m in times)}"

    def test_a_rename_stamped_exactly_when_planning_began_is_in_force(self) -> None:
        renames = (replay.TitleRename(at(0), "before"),)
        result = replay.cut_at_planning(history(title="after", renames=renames, approach_at=at(0)))
        assert isinstance(result, replay.PlanningSnapshot)
        assert result.title == "after"

    def test_planning_began_is_the_approach_comments_time(self) -> None:
        result = replay.cut_at_planning(history(approach_at=at(42)))
        assert isinstance(result, replay.PlanningSnapshot)
        assert result.planning_began == at(42)


# ── Reading GitHub's view of the ticket ────────────────────────────────────────────────────────


class ParseHistory(unittest.TestCase):
    def setUp(self) -> None:
        self.payload = json.loads((FIXTURES / "issue-198.json").read_text())
        self.issue = self.payload["data"]["repository"]["issue"]

    def test_a_real_response_yields_its_approach_design_and_edits(self) -> None:
        result = replay.parse_history(DOTFILES_REF, self.payload)
        assert isinstance(result, replay.TicketHistory)
        assert result.approach.body.startswith("# Approach")
        assert result.design.body.startswith("# Design\n")
        assert len(result.body_edits) == 2

    def test_no_comment_reaches_the_snapshot(self) -> None:
        result = replay.parse_history(DOTFILES_REF, self.payload)
        assert isinstance(result, replay.TicketHistory)
        snapshot = replay.cut_at_planning(result)
        assert isinstance(snapshot, replay.PlanningSnapshot)
        first_comment = self.issue["comments"]["nodes"][0]["body"]
        assert first_comment not in snapshot.body

    def test_a_ticket_without_an_approach_comment_is_refused(self) -> None:
        self.issue["comments"]["nodes"] = [
            c for c in self.issue["comments"]["nodes"] if not c["body"].startswith("# Approach")
        ]
        assert replay.parse_history(DOTFILES_REF, self.payload) == replay.NoApproachComment()

    def test_a_ticket_without_a_design_comment_is_refused(self) -> None:
        self.issue["comments"]["nodes"] = [
            c for c in self.issue["comments"]["nodes"] if not c["body"].startswith("# Design")
        ]
        assert replay.parse_history(DOTFILES_REF, self.payload) == replay.NoDesignComment()

    def test_a_response_with_more_comments_than_one_page_is_refused(self) -> None:
        self.issue["comments"]["pageInfo"]["hasNextPage"] = True
        result = replay.parse_history(DOTFILES_REF, self.payload)
        assert isinstance(result, replay.GitHubUnreadable)

    def test_a_real_rename_is_read_with_its_time_and_previous_title(self) -> None:
        self.issue["timelineItems"]["nodes"] = [
            {"createdAt": "2026-10-26T00:02:51Z", "previousTitle": "The title before"}
        ]
        result = replay.parse_history(DOTFILES_REF, self.payload)
        assert isinstance(result, replay.TicketHistory)
        assert result.title_renames == (
            replay.TitleRename(datetime(2026, 10, 26, 0, 2, 51, tzinfo=UTC), "The title before"),
        )

    def test_a_response_with_more_renames_than_one_page_is_refused(self) -> None:
        self.issue["timelineItems"]["pageInfo"]["hasNextPage"] = True
        result = replay.parse_history(DOTFILES_REF, self.payload)
        assert isinstance(result, replay.GitHubUnreadable)
        assert "rename" in " ".join(result.problems)

    def test_an_edit_without_a_timestamp_is_refused(self) -> None:
        self.issue["userContentEdits"]["nodes"][0]["editedAt"] = None
        result = replay.parse_history(DOTFILES_REF, self.payload)
        assert isinstance(result, replay.GitHubUnreadable)


# ── Tickets that can't be replayed fairly ──────────────────────────────────────────────────────


HUB_REF = replay.TicketRef("ooloth", "hub", 394)


def names(ref, number: int) -> list[str]:
    """Each way a commit message names ticket `number` in `ref`'s repo."""
    forms = [
        f"{ref.owner}/{ref.repo}#{number}",
        f"Fixes {ref.owner}/{ref.repo}#{number}.",
        f"(see https://github.com/{ref.owner}/{ref.repo}/issues/{number})",
        f"{ref.repo}#{number}",
        f"Replays on {ref.repo}#{number}, a milestone",
    ]
    if (ref.owner, ref.repo) == replay.HARNESS_REPO:
        forms += [f"#{number}", f"Fixes #{number}, partly"]
    return forms


def matches(pattern: str, message: str) -> bool:
    return re.search(pattern, message, re.IGNORECASE | re.MULTILINE) is not None


class TicketPattern(unittest.TestCase):
    @given(st.integers(1, 99_999), st.integers(1, 99_999), st.sampled_from([HUB_REF, DOTFILES_REF]))
    def test_a_ticket_is_named_by_its_whole_number_and_never_by_a_near_one(
        self, n: int, m: int, base
    ) -> None:
        ref = replay.TicketRef(base.owner, base.repo, n)
        pattern = replay.ticket_pattern(ref)
        for message in names(ref, n):
            assert matches(pattern, message), message
        near = {m, int(f"{n}0"), int(f"{n}7"), int(f"1{n}")} | ({n // 10} if n >= 10 else set())
        for other in near - {n}:
            for message in names(ref, other):
                assert not matches(pattern, message), message

    def test_the_same_number_in_another_repo_does_not_name_the_ticket(self) -> None:
        assert not matches(replay.ticket_pattern(HUB_REF), "ooloth/other#394")
        assert not matches(replay.ticket_pattern(HUB_REF), "Fixes #394")
        dotfiles = replay.ticket_pattern(replay.TicketRef("ooloth", "dotfiles", 269))
        assert not matches(dotfiles, "ooloth/hub#269")

    def test_the_short_form_counts_only_as_a_whole_repo_name(self) -> None:
        pattern = replay.ticket_pattern(HUB_REF)
        assert matches(pattern, "Fresh-agent replays on hub#394, a dotfiles milestone")
        assert not matches(pattern, "xhub#394")
        assert not matches(pattern, "other/hub#394")


def make_harness_history(root: Path, planning: datetime) -> tuple[Path, dict[str, str]]:
    """A dotfiles-like repo with one commit per case, returning it and each case's hash."""
    repo = root / "dotfiles"
    repo.mkdir()
    git(repo, "init", "-q", "-b", "main")
    git(repo, "config", "user.email", "test@example.com")
    git(repo, "config", "user.name", "Test")
    cases = {
        "named before planning": ("tools/agents/config/skills/a/SKILL.md", "ooloth/hub#394", -60),
        "named after": ("tools/agents/config/skills/b/SKILL.md", "ooloth/hub#394", 30),
        "named after, outside the harness": ("tools/claude/replay.py", "ooloth/hub#394", 40),
        "near number after": ("tools/claude/config/CLAUDE.md", "ooloth/hub#3940", 50),
        "named by URL after": (
            "tools/claude/config/settings.json",
            "https://github.com/ooloth/hub/issues/394",
            60,
        ),
    }
    shas = {}
    for case, (path, name, minutes) in cases.items():
        file = repo / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(case)
        git(repo, "add", ".")
        git(
            repo,
            "commit",
            "-q",
            "-m",
            f"change for {case}\n\n{name}",
            date=planning + timedelta(minutes=minutes),
        )
        shas[case] = git(repo, "rev-parse", "HEAD")
    return repo, shas


class LaterHarnessCommits(unittest.TestCase):
    def test_only_later_harness_commits_that_name_the_ticket_are_found(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo, shas = make_harness_history(Path(tmp), T0)
            found = replay.later_harness_commits(
                repo, replay.ticket_pattern(HUB_REF), T0, replay.HARNESS_PATHS
            )
            assert isinstance(found, tuple), found
            assert set(found) == {shas["named after"], shas["named by URL after"]}
            refused = replay.check_later_harness(
                found, replay.files_changed(repo, found), replay.HARNESS_PATHS
            )
            assert refused == replay.NamedByLaterHarnessCommits(
                tuple(found),
                ("tools/agents/config/skills/b/SKILL.md", "tools/claude/config/settings.json"),
            )

    def test_a_ticket_no_later_harness_commit_names_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo, _ = make_harness_history(Path(tmp), T0)
            found = replay.later_harness_commits(
                repo, replay.ticket_pattern(OTHER_REF), T0, replay.HARNESS_PATHS
            )
            assert found == ()
            assert replay.check_later_harness(found, {}, replay.HARNESS_PATHS) is None

    def test_an_unreadable_history_refuses_the_replay_with_gits_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            found = replay.later_harness_commits(
                Path(tmp), replay.ticket_pattern(HUB_REF), T0, replay.HARNESS_PATHS
            )
            assert isinstance(found, replay.HarnessHistoryUnreadable)
            assert "not a git repository" in found.stderr

    def test_a_later_commit_to_a_live_checkout_folder_the_session_reads_is_found(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo, _ = make_harness_history(Path(tmp), T0)
            (repo / "tools" / "git" / "config").mkdir(parents=True)
            (repo / "tools" / "git" / "config" / "config").write_text("[core]\n")
            git(repo, "add", ".")
            git(repo, "commit", "-q", "-m", "git: for hub#394", date=at(90))
            sha = git(repo, "rev-parse", "HEAD")
            watched = (*replay.HARNESS_PATHS, "tools/git/config/")
            found = replay.later_harness_commits(repo, replay.ticket_pattern(HUB_REF), T0, watched)
            assert isinstance(found, tuple), found
            assert sha in found
            refused = replay.check_later_harness(found, replay.files_changed(repo, found), watched)
            assert refused is not None
            assert "tools/git/config/config" in refused.files

    def test_later_is_judged_by_committer_date_to_the_minute(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo, _ = make_harness_history(Path(tmp), T0)
            shas = {}
            for name, committed, authored in (
                ("just before", at(-1), at(5)),
                ("just after", at(1), at(-120)),
            ):
                path = repo / "tools" / "agents" / "config" / f"{name}.md"
                path.write_text(name)
                git(repo, "add", ".")
                git(
                    repo,
                    "commit",
                    "-q",
                    "-m",
                    f"{name}: ooloth/hub#394",
                    date=committed,
                    author_date=authored,
                )
                shas[name] = git(repo, "rev-parse", "HEAD")
            found = replay.later_harness_commits(
                repo, replay.ticket_pattern(HUB_REF), T0, replay.HARNESS_PATHS
            )
            assert isinstance(found, tuple), found
            assert shas["just after"] in found
            assert shas["just before"] not in found

    def test_live_checkout_folders_the_session_reads_are_watched(self) -> None:
        dotfiles = Path("/repos/dotfiles")
        readable = (
            Path("/home/me/.local/bin"),
            dotfiles / "tools" / "git" / "config",
            dotfiles / "tools" / "codefresh" / "bin",
        )
        assert replay.watched_paths(dotfiles, readable) == (
            *replay.HARNESS_PATHS,
            "tools/git/config/",
            "tools/codefresh/bin/",
        )

    def test_the_refusal_names_each_commit_and_harness_file(self) -> None:
        text = replay.explain(
            replay.NamedByLaterHarnessCommits(("abc1234", "def5678"), ("tools/agents/config/x.md",))
        )
        for name in ("abc1234", "def5678", "tools/agents/config/x.md"):
            assert name in text


# ── The truncated clone ────────────────────────────────────────────────────────────────────────


class Clone(unittest.TestCase):
    def test_the_clone_holds_no_commit_after_planning_began_and_no_remote_url(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, _ = make_source(root, [at(-60), at(-30), at(30), at(60)])
            base = replay.resolve_base(source, "main", at(0))
            assert isinstance(base, str)
            clone = root / "clone"
            replay.make_clone(source, base, clone)
            dates = git(clone, "log", "--all", "--format=%cI").splitlines()
            assert len(dates) == 2
            assert all(datetime.fromisoformat(d) <= at(0) for d in dates)
            urls = subprocess.run(
                ["git", "-C", str(clone), "config", "--get-regexp", r"^remote\..*\.url$"],
                capture_output=True,
                text=True,
                check=False,
            )
            assert urls.stdout == ""
            assert replay.check_clone(clone, at(0)) is None

    def test_a_branch_merged_after_planning_began_does_not_supply_the_base(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source, shas = make_source(Path(tmp), [at(-60)])
            git(source, "switch", "-q", "-c", "feature")
            (source / "feature.txt").write_text("branch work\n")
            git(source, "add", ".")
            git(source, "commit", "-q", "-m", "branch work", date=at(-10))
            git(source, "switch", "-q", "main")
            git(source, "merge", "-q", "--no-ff", "-m", "merge", "feature", date=at(60))
            assert replay.resolve_base(source, "main", at(0)) == shas[0]

    def test_no_commit_before_planning_began_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source, _ = make_source(Path(tmp), [at(30)])
            assert replay.resolve_base(source, "main", at(0)) == replay.BaseNotFound(at(0))


# ── The gh stand-in ────────────────────────────────────────────────────────────────────────────


class StandIn(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        root = Path(self._tmp.name)
        self.capture = root / "capture"
        self.capture.mkdir()
        snapshot = replay.PlanningSnapshot(OTHER_REF, "A title", "The body as planned.", at(0))
        self.gh = replay.write_stand_in(root / "bin", snapshot, self.capture)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def run_gh(self, *args: str, stdin: str = "") -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.gh), *args], capture_output=True, text=True, input=stdin, check=False
        )

    def logged(self) -> list[dict]:
        lines = (self.capture / "gh-calls.log").read_text().splitlines()
        return [json.loads(line) for line in lines]

    def test_issue_view_serves_the_snapshot_with_no_comments_and_no_parent(self) -> None:
        result = self.run_gh(
            "issue", "view", "7", "-R", "octo/widgets", "--json", "title,body,comments,parent"
        )
        assert result.returncode == 0, result.stderr
        assert json.loads(result.stdout) == {
            "title": "A title",
            "body": "The body as planned.",
            "comments": [],
            "parent": None,
        }

    def test_issue_view_serves_no_relationships_in_the_shape_gh_gives_them(self) -> None:
        result = self.run_gh(
            "issue", "view", "7", "-R", "octo/widgets", "--json", "blockedBy,blocking,subIssues"
        )
        assert result.returncode == 0, result.stderr
        none = {"nodes": [], "totalCount": 0}
        assert json.loads(result.stdout) == {"blockedBy": none, "blocking": none, "subIssues": none}

    def test_issue_view_of_another_ticket_is_refused(self) -> None:
        result = self.run_gh("issue", "view", "8", "-R", "octo/widgets", "--json", "body")
        assert result.returncode != 0
        assert "unavailable in replay" in result.stderr

    def test_each_comment_body_is_saved_and_answered_with_a_url(self) -> None:
        body_file = self.capture.parent / "body.md"
        body_file.write_text("# Approach\n\nfrom a file")
        forms = [
            ("--body-file", str(body_file)),
            ("-F", str(body_file)),
            ("--body", "# Design\n\ninline"),
            ("--body-file", "-"),
        ]
        for flag, value in forms:
            result = self.run_gh(
                "issue", "comment", "7", "-R", "octo/widgets", flag, value, stdin="from stdin"
            )
            assert result.returncode == 0, result.stderr
            assert result.stdout.startswith("https://github.com/octo/widgets/issues/7#")
        saved = sorted(self.capture.glob("comment-*.md"))
        assert [p.read_text() for p in saved] == [
            "# Approach\n\nfrom a file",
            "# Approach\n\nfrom a file",
            "# Design\n\ninline",
            "from stdin",
        ]

    def test_a_comment_the_replay_posted_is_served_back_like_gh_does(self) -> None:
        self.run_gh("issue", "comment", "7", "-R", "octo/widgets", "--body", "# Approach\n\nA")
        view = self.run_gh("issue", "view", "7", "-R", "octo/widgets", "--json", "comments")
        assert view.returncode == 0, view.stderr
        [comment] = json.loads(view.stdout)["comments"]
        assert comment["body"] == "# Approach\n\nA"
        assert comment["author"] == {"login": "octo"}
        assert datetime.fromisoformat(comment["createdAt"].replace("Z", "+00:00")) > at(0)

    def test_a_jq_filter_is_applied_as_gh_applies_it(self) -> None:
        result = self.run_gh(
            "issue", "view", "7", "-R", "octo/widgets", "--json", "title,body", "-q", ".title"
        )
        assert result.returncode == 0, result.stderr
        assert result.stdout == "A title\n"

    def test_the_api_lists_the_comments_the_replay_posted(self) -> None:
        self.run_gh("issue", "comment", "7", "-R", "octo/widgets", "--body", "posted")
        listed = self.run_gh(
            "api", "--paginate", "repos/octo/widgets/issues/7/comments", "--jq", ".[].body"
        )
        assert listed.returncode == 0, listed.stderr
        assert listed.stdout == "posted\n"
        issue = self.run_gh("api", "repos/octo/widgets/issues/7", "--jq", ".comments")
        assert issue.stdout == "1\n"

    def test_an_api_call_that_writes_or_names_another_endpoint_is_refused(self) -> None:
        for args in (
            ["api", "-X", "POST", "repos/octo/widgets/issues/7/comments", "-f", "body=x"],
            ["api", "repos/octo/widgets/issues/7/comments", "-f", "body=x"],
            ["api", "repos/octo/widgets/issues/8/comments"],
            ["api", "graphql", "-f", "query={viewer{login}}"],
        ):
            result = self.run_gh(*args)
            assert result.returncode != 0, args
            assert "unavailable in replay" in result.stderr

    def test_edit_last_replaces_the_newest_comment_so_the_grade_reads_the_correction(self) -> None:
        self.run_gh("issue", "comment", "7", "-R", "octo/widgets", "--body", "# Approach\n\nv1")
        result = self.run_gh(
            "issue",
            "comment",
            "7",
            "-R",
            "octo/widgets",
            "--edit-last",
            "--body",
            "# Approach\n\nv2",
        )
        assert result.returncode == 0, result.stderr
        assert [p.read_text() for p in sorted(self.capture.glob("comment-*.md"))] == [
            "# Approach\n\nv2"
        ]
        assert replay.sort_comments(self.capture).approach == "# Approach\n\nv2"

    def test_edit_last_with_nothing_posted_is_refused(self) -> None:
        result = self.run_gh(
            "issue", "comment", "7", "-R", "octo/widgets", "--edit-last", "--body", "x"
        )
        assert result.returncode != 0
        assert "unavailable in replay" in result.stderr
        assert not list(self.capture.glob("comment-*.md"))

    def test_issue_view_with_comments_prints_the_comments_the_replay_posted(self) -> None:
        self.run_gh("issue", "comment", "7", "-R", "octo/widgets", "--body", "# Approach\n\nA")
        result = self.run_gh("issue", "view", "7", "-R", "octo/widgets", "--comments")
        assert result.returncode == 0, result.stderr
        assert "The body as planned." in result.stdout
        assert "# Approach\n\nA" in result.stdout

    def test_calls_the_stand_in_does_not_model_are_refused_and_logged(self) -> None:
        for args in (
            ["issue", "view", "7", "-R", "octo/widgets", "--web"],
            ["api", "repos/octo/widgets/issues/7", "--template", "{{.title}}"],
            ["api", "-XPOST", "repos/octo/widgets/issues/7/comments", "-fbody=x"],
            ["api", "repos/octo/widgets/issues/7/comments", "-Fbody=@x.md"],
        ):
            result = self.run_gh(*args)
            assert result.returncode != 0, args
            assert "unavailable in replay" in result.stderr, args
        assert [call["served"] for call in self.logged()] == [False] * 4

    def test_every_other_command_is_refused_and_logged(self) -> None:
        result = self.run_gh("pr", "list", "-R", "octo/widgets")
        assert result.returncode != 0
        assert "unavailable in replay" in result.stderr
        assert self.logged() == [{"args": ["pr", "list", "-R", "octo/widgets"], "served": False}]


# ── The session's mktemp ───────────────────────────────────────────────────────────────────────


class Mktemp(unittest.TestCase):
    def test_a_folder_with_no_location_of_its_own_lands_in_tmpdir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            mktemp = replay.write_mktemp(root / "bin")
            target = root / "target"
            target.mkdir()
            env = {**os.environ, "TMPDIR": str(target)}
            for args in (["-d"], [], ["-d", "-t", "pre"]):
                made = subprocess.run(
                    [str(mktemp), *args], capture_output=True, text=True, env=env, check=True
                )
                assert Path(made.stdout.strip()).parent == target, (args, made.stdout)

    def test_a_template_or_folder_the_caller_names_is_kept(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            mktemp = replay.write_mktemp(root / "bin")
            elsewhere = root / "elsewhere"
            elsewhere.mkdir()
            env = {**os.environ, "TMPDIR": str(root / "unused")}
            for args in (["-d", f"{elsewhere}/x.XXXX"], ["-d", "-p", str(elsewhere)]):
                made = subprocess.run(
                    [str(mktemp), *args], capture_output=True, text=True, env=env, check=True
                )
                assert Path(made.stdout.strip()).parent == elsewhere, (args, made.stdout)


# ── The sandbox settings ───────────────────────────────────────────────────────────────────────


def fake_paths() -> object:
    return replay.SandboxPaths(
        home=Path("/home/me"),
        tmp_root=Path("/tmp-root"),
        work=Path("/private/tmp/rp-test"),
        clone=Path("/private/tmp/rp-test/clone"),
        capture=Path("/private/tmp/rp-test/capture"),
        scratch=Path("/private/tmp/rp-test/scratch"),
        claude_tmp=Path("/private/tmp/rp-test/t"),
        harness=(Path("/repos/dotfiles/tools/agents/config"),),
        toolchains=(Path("/home/me/.local/bin"),),
    )


class Settings(unittest.TestCase):
    def test_the_built_settings_match_the_expected_file(self) -> None:
        settings = replay.build_settings(fake_paths())
        expected = json.loads((FIXTURES / "settings.json").read_text())
        assert settings == expected

    def test_the_built_settings_pass_their_own_checks(self) -> None:
        replay.check_settings(replay.build_settings(fake_paths()), fake_paths())

    def test_each_condition_broken_on_its_own_fails_the_check_naming_it(self) -> None:
        def set_key(*keys: str, value: object) -> Callable[[dict], None]:
            def apply(settings: dict) -> None:
                target = settings
                for key in keys[:-1]:
                    target = target[key]
                target[keys[-1]] = value

            return apply

        def drop_deny(rule: str) -> Callable[[dict], None]:
            return lambda s: s["permissions"]["deny"].remove(rule)

        breaks = {
            "sandbox.enabled": set_key("sandbox", "enabled", value=False),
            "failIfUnavailable": set_key("sandbox", "failIfUnavailable", value=False),
            "allowUnsandboxedCommands": set_key("sandbox", "allowUnsandboxedCommands", value=True),
            "allowedDomains": lambda s: s["sandbox"]["network"]["allowedDomains"].append(
                "github.com"
            ),
            "denyRead": lambda s: s["sandbox"]["filesystem"]["denyRead"].remove("/home/me"),
            "allowWrite": lambda s: s["sandbox"]["filesystem"]["allowWrite"].append("/home/me"),
            "blockReadsOutsideWorkingDirectories": set_key(
                "permissions", "blockReadsOutsideWorkingDirectories", value=False
            ),
            "Edit(//home/me/**)": drop_deny("Edit(//home/me/**)"),
            "Write(//home/me/**)": drop_deny("Write(//home/me/**)"),
        }
        for name, corrupt in breaks.items():
            settings = replay.build_settings(fake_paths())
            corrupt(settings)
            with self.assertRaises(AssertionError, msg=name) as raised:
                replay.check_settings(settings, fake_paths())
            assert name in str(raised.exception), (name, str(raised.exception))


class SessionCommand(unittest.TestCase):
    def test_the_session_loads_only_the_user_settings_and_the_replays_own(self) -> None:
        command = replay.session_command(Path("/w/settings.json"), (), "/plan-unattended x")
        assert command[command.index("--settings") + 1] == "/w/settings.json"
        assert command[command.index("--setting-sources") + 1] == "user"
        assert "--strict-mcp-config" in command
        assert command[command.index("--disallowedTools") + 1 :][:2] == ["WebFetch", "WebSearch"]
        assert command[-1] == "/plan-unattended x"
        replay.check_command(command)

    def test_a_command_that_loads_project_settings_fails_the_check(self) -> None:
        command = replay.session_command(Path("/w/settings.json"), (), "x")
        command[command.index("--setting-sources") + 1] = "user,project"
        with self.assertRaises(AssertionError) as raised:
            replay.check_command(command)
        assert "--setting-sources" in str(raised.exception)


# ── The sandbox canary ─────────────────────────────────────────────────────────────────────────


def fake_canary() -> Any:
    return replay.Canary(
        secret="s3cr3t-token",
        secret_file=Path("/home/me/.local/state/replays/.canary-n1"),
        write_tool_target=Path("/home/me/.replay-canary-n1-write"),
        bash_target=Path("/home/me/.replay-canary-n1-bash"),
        net_target=Path("/private/tmp/rp-test/scratch/canary-n1-net"),
    )


def attempted_uses(canary: Any) -> list[Any]:
    refused = "Operation not permitted"
    return [
        replay.ToolUse("Bash", {"command": f"cat {canary.secret_file}"}, refused),
        replay.ToolUse("Write", {"file_path": str(canary.write_tool_target)}, "denied"),
        replay.ToolUse("Bash", {"command": f"touch {canary.bash_target}"}, refused),
        replay.ToolUse(
            "Bash",
            {"command": f"curl -sS -m 10 -o {canary.net_target} {replay.CANARY_URL}"},
            "deny network-outbound example.com",
        ),
    ]


NO_EFFECTS = replay.CanaryEffects(write_tool_file=False, bash_file=False, net_bytes=0)


class JudgeCanary(unittest.TestCase):
    def test_a_canary_whose_four_actions_all_had_no_effect_shows_the_sandbox_holds(self) -> None:
        canary = fake_canary()
        verdict = replay.judge_canary(canary, attempted_uses(canary), "DONE", NO_EFFECTS)
        assert verdict == replay.SandboxHolds()

    def test_each_action_that_took_effect_is_named_in_the_breach(self) -> None:
        canary = fake_canary()
        uses = attempted_uses(canary)
        leaked = [
            replay.ToolUse(u.tool, u.input, canary.secret) if i == 0 else u
            for i, u in enumerate(uses)
        ]
        cases = {
            "read": (leaked, NO_EFFECTS),
            "write-tool": (uses, replay.CanaryEffects(True, False, 0)),
            "bash-write": (uses, replay.CanaryEffects(False, True, 0)),
            "network": (uses, replay.CanaryEffects(False, False, 1256)),
        }
        for check, (case_uses, effects) in cases.items():
            verdict = replay.judge_canary(canary, case_uses, "DONE", effects)
            assert isinstance(verdict, replay.SandboxBreached), check
            assert [c for c, _ in verdict.checks] == [check], (check, verdict)

    def test_a_secret_in_the_final_reply_is_a_breach_of_the_read(self) -> None:
        canary = fake_canary()
        verdict = replay.judge_canary(
            canary, attempted_uses(canary), f"it said {canary.secret}", NO_EFFECTS
        )
        assert isinstance(verdict, replay.SandboxBreached)
        assert [c for c, _ in verdict.checks] == ["read"]

    def test_a_canary_that_skipped_an_action_is_inconclusive(self) -> None:
        canary = fake_canary()
        uses = attempted_uses(canary)[:3]
        verdict = replay.judge_canary(canary, uses, "DONE", NO_EFFECTS)
        assert isinstance(verdict, replay.CanaryInconclusive)
        assert "network" in verdict.reason


class SessionEnv(unittest.TestCase):
    def test_npm_keeps_its_cache_in_the_replays_scratch_folder(self) -> None:
        work = Path("/private/tmp/rp-test")
        env = replay.session_env(work / "bin", work / "scratch", work / "t")
        assert env["npm_config_cache"] == str(work / "scratch" / "npm-cache")


# ── What the session left behind ───────────────────────────────────────────────────────────────


class Audit(unittest.TestCase):
    def setUp(self) -> None:
        self.result = replay.parse_session_result(0, (FIXTURES / "result.json").read_text(), "")

    def test_each_kind_of_refusal_in_a_real_transcript_appears(self) -> None:
        assert isinstance(self.result, replay.SessionResult)
        audit = replay.read_audit(
            "session-1", FIXTURES / "transcripts", self.result.permission_denials, []
        )
        assert isinstance(audit, replay.Audit)
        readme = "/Users/michael/Repos/ooloth/dotfiles/README.md"
        assert set(audit.refusals) == {
            replay.FileRefused(
                "head -1 ~/Repos/ooloth/dotfiles/README.md",
                f"head: {readme}: Operation not permitted",
            ),
            replay.ReadRefused(readme),
            replay.NetworkRefused("api.github.com"),
            replay.GhRefused("issue list -R ooloth/dotfiles"),
            replay.FileRefused(
                "echo x > /tmp/outside.txt", "(eval):1: operation not permitted: /tmp/outside.txt"
            ),
        }
        assert audit.transcripts_read == 2
        assert audit.unreadable_lines == 2

    def test_a_refused_connection_in_a_subagent_is_counted(self) -> None:
        assert isinstance(self.result, replay.SessionResult)
        audit = replay.read_audit(
            "session-1", FIXTURES / "transcripts", self.result.permission_denials, []
        )
        assert isinstance(audit, replay.Audit)
        assert audit.refusals.count(replay.NetworkRefused("api.github.com")) == 2

    def test_a_missing_transcript_makes_the_audit_incomplete(self) -> None:
        audit = replay.read_audit("no-such-session", FIXTURES / "transcripts", (), [])
        assert isinstance(audit, replay.AuditIncomplete)
        assert "no-such-session" in audit.reason

    def test_a_refusal_inside_a_command_that_exited_0_appears(self) -> None:
        audit = replay.read_audit("session-2", FIXTURES / "transcripts", (), [])
        assert isinstance(audit, replay.Audit)
        command = "sed -n 1,5p docs/notes.md; ls /home/me/Repos/example/private 2>&1 | head -3"
        assert audit.refusals == (
            replay.FileRefused(
                command, "ls: /home/me/Repos/example/private: Operation not permitted"
            ),
            replay.NetworkRefused("docs.example.com"),
        )

    def test_a_subagents_report_quoting_a_refusal_is_not_counted_again(self) -> None:
        # The subagent's own transcript holds the refusal, so its report repeating it adds none.
        audit = replay.read_audit("session-2", FIXTURES / "transcripts", (), [])
        assert isinstance(audit, replay.Audit)
        assert not [r for r in audit.refusals if "Subagent" in str(r)]

    def test_a_gh_log_line_that_is_not_an_object_is_counted_as_unreadable(self) -> None:
        audit = replay.read_audit("session-2", FIXTURES / "transcripts", (), ["1", "[]"])
        assert isinstance(audit, replay.Audit)
        assert audit.unreadable_lines == 2

    def test_a_gh_call_the_stand_in_refused_is_listed_once(self) -> None:
        assert isinstance(self.result, replay.SessionResult)
        log = ['{"args": ["issue", "list", "-R", "ooloth/dotfiles"], "served": false}']
        audit = replay.read_audit(
            "session-1", FIXTURES / "transcripts", self.result.permission_denials, log
        )
        assert isinstance(audit, replay.Audit)
        assert audit.refusals.count(replay.GhRefused("issue list -R ooloth/dotfiles")) == 1


class SessionResults(unittest.TestCase):
    def test_duration_and_tokens_per_model_come_from_a_real_result(self) -> None:
        result = replay.parse_session_result(0, (FIXTURES / "result.json").read_text(), "")
        assert isinstance(result, replay.SessionResult)
        raw = json.loads((FIXTURES / "result.json").read_text())
        assert result.duration_ms == raw["duration_ms"]
        assert {t.model for t in result.tokens_by_model} == {"claude-haiku-5-5", "claude-opus-5-5"}
        haiku = next(t for t in result.tokens_by_model if t.model == "claude-haiku-5-5")
        assert haiku.output == raw["modelUsage"]["claude-haiku-5-5"]["outputTokens"]

    def test_an_escalated_session_is_recorded_as_escalated(self) -> None:
        raw = json.loads((FIXTURES / "result.json").read_text())
        raw["result"] = "Some words.\n\nESCALATED: the ticket does not say enough."
        result = replay.parse_session_result(0, json.dumps(raw), "")
        assert isinstance(result, replay.SessionResult)
        assert replay.outcome_of(result) == replay.Escalated(
            "ESCALATED: the ticket does not say enough."
        )

    def test_a_planned_session_is_recorded_as_planned(self) -> None:
        raw = json.loads((FIXTURES / "result.json").read_text())
        raw["result"] = "PLANNED: https://github.com/octo/widgets/issues/7#x; implementation not"
        result = replay.parse_session_result(0, json.dumps(raw), "")
        assert isinstance(result, replay.SessionResult)
        assert isinstance(replay.outcome_of(result), replay.Planned)

    def test_a_session_that_exits_non_zero_is_recorded_as_failed(self) -> None:
        result = replay.parse_session_result(1, "", "boom\n")
        assert isinstance(result, replay.SessionFailed)
        assert result.exit == 1
        assert "boom" in result.stderr_tail


class CapturedComments(unittest.TestCase):
    def test_comments_are_sorted_into_approach_design_and_extra(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            capture = Path(tmp)
            (capture / "comment-001.md").write_text("# Approach\n\nA")
            (capture / "comment-002.md").write_text("# Design\n\nD")
            (capture / "comment-003.md").write_text("Something else")
            captured = replay.sort_comments(capture)
            assert captured.approach == "# Approach\n\nA"
            assert captured.design == "# Design\n\nD"
            assert captured.extra == ("Something else",)


# ── Grades ─────────────────────────────────────────────────────────────────────────────────────


class Grades(unittest.TestCase):
    def test_a_filled_in_template_is_graded(self) -> None:
        text = replay.grade_template(OTHER_REF, 1).replace(
            "approach:", "approach: approve-with-edits", 1
        )
        text = text.replace("design:", "design: reject", 1)
        grade = replay.parse_grade(text)
        assert isinstance(grade, replay.Graded)
        assert grade.approach == replay.Verdict.APPROVE_WITH_EDITS
        assert grade.design == replay.Verdict.REJECT

    def test_an_empty_template_is_ungraded(self) -> None:
        assert replay.parse_grade(replay.grade_template(OTHER_REF, 1)) == replay.Ungraded()

    def test_an_escalation_is_graded_on_its_own_verdict(self) -> None:
        text = replay.grade_template(OTHER_REF, 1).replace("escalation:", "escalation: reject", 1)
        assert replay.parse_grade(text) == replay.Graded(None, None, replay.Verdict.REJECT)

    def test_an_escalation_after_an_approach_is_graded_on_both(self) -> None:
        text = replay.grade_template(OTHER_REF, 1).replace(
            "approach:", "approach: approve-as-is", 1
        )
        text = text.replace("escalation:", "escalation: approve-as-is", 1)
        assert replay.parse_grade(text) == replay.Graded(
            replay.Verdict.APPROVE_AS_IS, None, replay.Verdict.APPROVE_AS_IS
        )

    def test_a_plan_graded_without_its_design_is_unreadable(self) -> None:
        text = replay.grade_template(OTHER_REF, 1).replace("approach:", "approach: reject", 1)
        assert isinstance(replay.parse_grade(text), replay.GradeUnreadable)

    def test_a_grade_without_an_escalation_line_is_unreadable(self) -> None:
        text = "approach: reject\ndesign: approve-as-is\n"
        assert isinstance(replay.parse_grade(text), replay.GradeUnreadable)

    def test_an_unknown_verdict_is_unreadable(self) -> None:
        text = replay.grade_template(OTHER_REF, 1).replace("approach:", "approach: maybe", 1)
        text = text.replace("design:", "design: reject", 1)
        assert isinstance(replay.parse_grade(text), replay.GradeUnreadable)

    def test_the_summary_counts_verdicts_and_names_every_ungraded_or_unreadable_grade(self) -> None:
        grades = [
            (Path("a/run-1"), replay.Graded(replay.Verdict.APPROVE_AS_IS, replay.Verdict.REJECT)),
            (Path("a/run-2"), replay.Graded(replay.Verdict.APPROVE_AS_IS, replay.Verdict.REJECT)),
            (Path("d/run-1"), replay.Graded(None, None, replay.Verdict.APPROVE_WITH_EDITS)),
            (Path("b/run-1"), replay.Ungraded()),
            (Path("c/run-1"), replay.GradeUnreadable("approach: 'maybe' is not a verdict")),
        ]
        summary = replay.summarize(grades)
        assert "approach: 2 approve-as-is, 0 approve-with-edits, 0 reject" in summary
        assert "design: 0 approve-as-is, 0 approve-with-edits, 2 reject" in summary
        assert "escalation: 0 approve-as-is, 1 approve-with-edits, 0 reject" in summary
        assert "b/run-1" in summary
        assert "c/run-1" in summary
        assert "'maybe' is not a verdict" in summary

    def test_a_grade_with_a_reason_to_exclude_it_is_excluded_whatever_its_verdicts(self) -> None:
        text = replay.grade_template(OTHER_REF, 1).replace("escalation:", "escalation: reject", 1)
        text = text.replace("excluded:", "excluded: it read the shipped answer", 1)
        assert replay.parse_grade(text) == replay.Excluded("it read the shipped answer")

    def test_an_empty_excluded_line_leaves_the_grade_as_it_is(self) -> None:
        text = replay.grade_template(OTHER_REF, 1).replace("escalation:", "escalation: reject", 1)
        assert replay.parse_grade(text) == replay.Graded(None, None, replay.Verdict.REJECT)

    def test_an_excluded_replay_is_named_with_its_reason_and_left_out_of_the_counts(self) -> None:
        grades = [
            (Path("a/run-1"), replay.Graded(None, None, replay.Verdict.REJECT)),
            (Path("a/run-2"), replay.Excluded("it read the shipped answer")),
        ]
        summary = replay.summarize(grades)
        assert "2 replays: 1 graded, 1 excluded, 0 ungraded, 0 unreadable" in summary
        assert "escalation: 0 approve-as-is, 0 approve-with-edits, 1 reject" in summary
        assert "a/run-2: it read the shipped answer" in summary


# ── End to end, with fake gh and claude ────────────────────────────────────────────────────────

FAKE_OUTER_GH = """#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
if args[:2] == ["api", "graphql"]:
    print(open(os.environ["FAKE_ISSUE"]).read())
else:
    print("fake gh: unexpected " + " ".join(args), file=sys.stderr)
    sys.exit(1)
"""

FAKE_CLAUDE = """#!/usr/bin/env python3
import json, os, re, subprocess, sys
if sys.argv[1:] == ["--version"]:
    print("9.9.9 (Claude Code)")
    sys.exit(0)
prompt = sys.argv[-1]
projects = os.path.join(os.environ["CLAUDE_CONFIG_DIR"], "projects", "x")
os.makedirs(projects, exist_ok=True)
result = json.load(open(os.environ["FAKE_RESULT"]))
result["permission_denials"] = []
if "sandbox check" in prompt:
    # Plays the canary: attempts each action, as a session would, and is refused each time unless
    # FAKE_CANARY names one to let through.
    secret = re.search(r"cat (\\S+)", prompt)[1]
    write = re.search(r"create (\\S+)", prompt)[1]
    touch = re.search(r"touch (\\S+)", prompt)[1]
    net = re.search(r"-o (\\S+)", prompt)[1]
    if os.environ.get("FAKE_CANARY") == "bash-write":
        open(touch, "w").write("")
    uses = [("Bash", {"command": "cat " + secret}), ("Write", {"file_path": write}),
            ("Bash", {"command": "touch " + touch}),
            ("Bash", {"command": "curl -sS -m 10 -o " + net + " https://example.com"})]
    with open(os.path.join(projects, "fake-canary.jsonl"), "w") as f:
        for i, (tool, args) in enumerate(uses):
            f.write(json.dumps({"type": "assistant", "message": {"content": [
                {"type": "tool_use", "id": "u%d" % i, "name": tool, "input": args}]}}) + "\\n")
            f.write(json.dumps({"type": "user", "message": {"content": [
                {"type": "tool_result", "tool_use_id": "u%d" % i, "is_error": True,
                 "content": "Operation not permitted"}]}}) + "\\n")
    result["session_id"] = "fake-canary"
    result["result"] = "DONE"
    print(json.dumps(result))
    sys.exit(0)
view = subprocess.run(["gh", "issue", "view", "7", "-R", "octo/widgets", "--json", "title,body"],
                      capture_output=True, text=True)
assert view.returncode == 0, view.stderr
for body in ["# Approach\\n\\nreplayed", "# Design\\n\\nreplayed"]:
    subprocess.run(["gh", "issue", "comment", "7", "-R", "octo/widgets", "--body", body],
                   check=True, capture_output=True)
open(os.path.join(projects, "fake-session.jsonl"), "w").write("")
result["session_id"] = "fake-session"
result["result"] = "PLANNED: https://github.com/octo/widgets/issues/7#x; implementation not started"
print(json.dumps({**result, "prompt_seen": prompt, "cwd_seen": os.getcwd(),
                  "argv_seen": sys.argv[1:], "gh_token_seen": os.environ.get("GH_TOKEN"),
                  "entrypoint_seen": os.environ.get("CLAUDE_CODE_ENTRYPOINT")}))
"""


class EndToEnd(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._stubs = tempfile.TemporaryDirectory()
        cls.bin_dir = Path(cls._stubs.name) / "bin"
        cls.bin_dir.mkdir()
        for name, text in (("gh", FAKE_OUTER_GH), ("claude", FAKE_CLAUDE)):
            (cls.bin_dir / name).write_text(text)
            (cls.bin_dir / name).chmod(0o755)
        cls.bin_dir.chmod(0o555)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.bin_dir.chmod(0o755)
        cls._stubs.cleanup()

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        bin_dir = self.bin_dir
        issue = json.loads((FIXTURES / "issue-198.json").read_text())
        approach = next(
            c
            for c in issue["data"]["repository"]["issue"]["comments"]["nodes"]
            if c["body"].startswith("# Approach")
        )
        began = datetime.fromisoformat(approach["createdAt"])
        self.began = began
        self.source, _ = make_source(self.root, [began - timedelta(days=1), began + timedelta(1)])
        # A copy of the scripts in a dotfiles-like repo of their own, so the later-harness search
        # reads a history this test controls rather than the live checkout's.
        self.dotfiles = self.root / "dotfiles"
        (self.dotfiles / "tools" / "claude").mkdir(parents=True)
        for script in (SCRIPT, SCRIPT.with_name("replay_gh.py")):
            (self.dotfiles / "tools" / "claude" / script.name).write_text(script.read_text())
        git(self.dotfiles, "init", "-q", "-b", "main")
        git(self.dotfiles, "config", "user.email", "test@example.com")
        git(self.dotfiles, "config", "user.name", "Test")
        git(self.dotfiles, "add", ".")
        git(self.dotfiles, "commit", "-q", "-m", "scripts", date=began - timedelta(days=30))
        (self.root / "issue.json").write_text(json.dumps(issue))
        self.state = self.root / "state"
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}:{os.environ['PATH']}",
            "FAKE_ISSUE": str(self.root / "issue.json"),
            "FAKE_RESULT": str(FIXTURES / "result.json"),
            "CLAUDE_CONFIG_DIR": str(self.root / "claude"),
            "XDG_STATE_HOME": str(self.state),
            "HOME": str(self.root / "home"),
            "GH_TOKEN": "test-token-not-real",
        }
        (self.root / "home").mkdir()

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def plan(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(self.dotfiles / "tools" / "claude" / "replay.py")]
            + ["plan", "octo/widgets#7", "--run", "1"]
            + ["--source", str(self.source)],
            capture_output=True,
            text=True,
            env=self.env,
            check=False,
        )

    def test_one_command_produces_the_full_replay_folder(self) -> None:
        result = self.plan()
        assert result.returncode == 0, result.stderr
        folder = self.state / "replays" / "octo-widgets-7" / "run-1"
        expected = {
            "approach.md",
            "design.md",
            "audit.md",
            "grade.md",
            "gh-calls.log",
            "meta.json",
            "result.json",
            "stderr.log",
            "ticket.md",
            "mine/approach.md",
            "mine/design.md",
        }
        found = {str(p.relative_to(folder)) for p in folder.rglob("*") if p.is_file()}
        assert expected <= found, expected - found
        assert (folder / "approach.md").read_text() == "# Approach\n\nreplayed"
        assert (folder / "mine" / "approach.md").read_text().startswith("# Approach")
        seen = json.loads((folder / "result.json").read_text())
        assert seen["prompt_seen"] == "/plan-unattended octo/widgets#7 plan-only"
        assert seen["entrypoint_seen"] == "factory-replay"
        assert seen["cwd_seen"] != str(self.source)
        meta = json.loads((folder / "meta.json").read_text())
        assert meta["claude_version"] == "9.9.9 (Claude Code)"
        assert meta["canary"] == {"verdict": "SandboxHolds"}
        assert meta["session_command"][1:] == seen["argv_seen"]

    def test_the_session_is_launched_sandboxed_without_project_settings_or_a_github_token(
        self,
    ) -> None:
        assert self.plan().returncode == 0
        folder = self.state / "replays" / "octo-widgets-7" / "run-1"
        argv = json.loads((folder / "result.json").read_text())["argv_seen"]
        settings = Path(argv[argv.index("--settings") + 1])
        assert argv[argv.index("--setting-sources") + 1] == "user"
        assert "--strict-mcp-config" in argv
        assert argv[argv.index("--disallowedTools") + 1 :][:2] == ["WebFetch", "WebSearch"]
        assert settings.name == "settings.json"
        assert json.loads((folder / "result.json").read_text())["gh_token_seen"] is None

    def test_a_canary_whose_bash_write_took_effect_refuses_the_replay_naming_it(self) -> None:
        self.env["FAKE_CANARY"] = "bash-write"
        result = self.plan()
        assert result.returncode != 0
        assert "bash-write" in result.stderr, result.stderr
        assert not (self.state / "replays" / "octo-widgets-7" / "run-1").exists()
        assert not list((self.root / "home").glob(".replay-canary-*"))

    def test_a_ticket_a_later_harness_commit_names_is_refused_before_any_folder(self) -> None:
        skill = self.dotfiles / "tools" / "agents" / "config" / "skills" / "x" / "SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_text("How widgets#7 shipped.")
        git(self.dotfiles, "add", ".")
        git(
            self.dotfiles,
            "commit",
            "-q",
            "-m",
            "skills/x: as octo/widgets#7 shipped",
            date=self.began + timedelta(hours=5),
        )
        sha = git(self.dotfiles, "rev-parse", "--short", "HEAD")
        result = self.plan()
        assert result.returncode == 1, result.stderr
        assert sha in result.stderr, result.stderr
        assert "tools/agents/config/skills/x/SKILL.md" in result.stderr
        assert not (self.state / "replays" / "octo-widgets-7").exists()

    def test_a_later_harness_commit_naming_another_ticket_refuses_nothing(self) -> None:
        skill = self.dotfiles / "tools" / "agents" / "config" / "skills" / "x" / "SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_text("Unrelated.")
        git(self.dotfiles, "add", ".")
        git(
            self.dotfiles,
            "commit",
            "-q",
            "-m",
            "skills/x: for octo/widgets#70",
            date=self.began + timedelta(hours=5),
        )
        result = self.plan()
        assert result.returncode == 0, result.stderr

    def test_a_run_whose_folder_exists_is_refused_and_changes_nothing(self) -> None:
        assert self.plan().returncode == 0
        folder = self.state / "replays" / "octo-widgets-7" / "run-1"
        (folder / "grade.md").write_text("approach: reject\ndesign: reject\n")
        again = self.plan()
        assert again.returncode != 0
        assert "already exists" in again.stderr
        assert (folder / "grade.md").read_text() == "approach: reject\ndesign: reject\n"


if __name__ == "__main__":
    unittest.main()
