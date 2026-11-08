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
from datetime import UTC, datetime, timedelta
from pathlib import Path

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
    linked: tuple = (),
):
    return replay.TicketHistory(
        ref=ref,
        title="A title",
        body=body,
        body_edits=edits,
        approach=replay.Comment(approach_at, "# Approach\n\nmine"),
        design=replay.Comment(approach_at + timedelta(hours=1), "# Design\n\nmine"),
        linked_commits=linked,
    )


def git(cwd: Path, *args: str, date: datetime | None = None) -> str:
    env = dict(os.environ)
    if date is not None:
        env["GIT_COMMITTER_DATE"] = env["GIT_AUTHOR_DATE"] = date.isoformat()
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
        result = replay.parse_history(DOTFILES_REF, self.payload, ["abc123"])
        assert isinstance(result, replay.TicketHistory)
        assert result.approach.body.startswith("# Approach")
        assert result.design.body.startswith("# Design\n")
        assert len(result.body_edits) == 2
        assert result.linked_commits == ("abc123",)

    def test_no_comment_reaches_the_snapshot(self) -> None:
        result = replay.parse_history(DOTFILES_REF, self.payload, [])
        assert isinstance(result, replay.TicketHistory)
        snapshot = replay.cut_at_planning(result)
        assert isinstance(snapshot, replay.PlanningSnapshot)
        first_comment = self.issue["comments"]["nodes"][0]["body"]
        assert first_comment not in snapshot.body

    def test_a_ticket_without_an_approach_comment_is_refused(self) -> None:
        self.issue["comments"]["nodes"] = [
            c for c in self.issue["comments"]["nodes"] if not c["body"].startswith("# Approach")
        ]
        assert replay.parse_history(DOTFILES_REF, self.payload, []) == replay.NoApproachComment()

    def test_a_ticket_without_a_design_comment_is_refused(self) -> None:
        self.issue["comments"]["nodes"] = [
            c for c in self.issue["comments"]["nodes"] if not c["body"].startswith("# Design")
        ]
        assert replay.parse_history(DOTFILES_REF, self.payload, []) == replay.NoDesignComment()

    def test_a_response_with_more_comments_than_one_page_is_refused(self) -> None:
        self.issue["comments"]["pageInfo"]["hasNextPage"] = True
        result = replay.parse_history(DOTFILES_REF, self.payload, [])
        assert isinstance(result, replay.GitHubUnreadable)

    def test_an_edit_without_a_timestamp_is_refused(self) -> None:
        self.issue["userContentEdits"]["nodes"][0]["editedAt"] = None
        result = replay.parse_history(DOTFILES_REF, self.payload, [])
        assert isinstance(result, replay.GitHubUnreadable)


# ── Tickets that can't be replayed fairly ──────────────────────────────────────────────────────


class CheckHarness(unittest.TestCase):
    def test_a_dotfiles_ticket_that_touched_the_harness_is_refused_naming_the_files(self) -> None:
        files = {
            "a1": ("features/x.py", "tools/claude/config/settings.json"),
            "b2": ("tools/agents/config/skills/x/SKILL.md",),
        }
        result = replay.check_harness(DOTFILES_REF, ("a1", "b2"), files)
        assert result == replay.TouchesHarness(
            ("tools/agents/config/skills/x/SKILL.md", "tools/claude/config/settings.json")
        )

    def test_a_dotfiles_ticket_that_left_the_harness_alone_passes(self) -> None:
        files = {"a1": ("tools/bash/utils.bash", "tools/claude/cc.bash")}
        assert replay.check_harness(DOTFILES_REF, ("a1",), files) is None

    def test_a_ticket_from_another_repo_is_not_checked_against_the_harness_paths(self) -> None:
        files = {"a1": ("tools/claude/config/settings.json",)}
        assert replay.check_harness(OTHER_REF, ("a1",), files) is None

    def test_a_linked_commit_missing_locally_refuses_the_ticket(self) -> None:
        files = {"a1": ("features/x.py",), "b2": None}
        result = replay.check_harness(DOTFILES_REF, ("a1", "b2"), files)
        assert result == replay.CommitMissing("b2")


HUB_REF = replay.TicketRef("ooloth", "hub", 394)


def names(ref, number: int) -> list[str]:
    """Each way a commit message names ticket `number` in `ref`'s repo."""
    forms = [
        f"{ref.owner}/{ref.repo}#{number}",
        f"Fixes {ref.owner}/{ref.repo}#{number}.",
        f"(see https://github.com/{ref.owner}/{ref.repo}/issues/{number})",
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
            found = replay.later_harness_commits(repo, replay.ticket_pattern(HUB_REF), T0)
            assert isinstance(found, tuple), found
            assert set(found) == {shas["named after"], shas["named by URL after"]}
            refused = replay.check_later_harness(found, replay.files_changed(repo, found))
            assert refused == replay.NamedByLaterHarnessCommits(
                tuple(found),
                ("tools/agents/config/skills/b/SKILL.md", "tools/claude/config/settings.json"),
            )

    def test_a_ticket_no_later_harness_commit_names_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo, _ = make_harness_history(Path(tmp), T0)
            found = replay.later_harness_commits(repo, replay.ticket_pattern(OTHER_REF), T0)
            assert found == ()
            assert replay.check_later_harness(found, {}) is None

    def test_an_unreadable_history_refuses_the_replay_with_gits_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            found = replay.later_harness_commits(Path(tmp), replay.ticket_pattern(HUB_REF), T0)
            assert isinstance(found, replay.HarnessHistoryUnreadable)
            assert "not a git repository" in found.stderr

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

    def test_settings_that_allow_unsandboxed_commands_fail_the_check(self) -> None:
        settings = replay.build_settings(fake_paths())
        settings["sandbox"]["allowUnsandboxedCommands"] = True
        with self.assertRaises(AssertionError) as raised:
            replay.check_settings(settings, fake_paths())
        assert "allowUnsandboxedCommands" in str(raised.exception)


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
elif args[:1] == ["api"] and "timeline" in args[1]:
    print("")
else:
    print("fake gh: unexpected " + " ".join(args), file=sys.stderr)
    sys.exit(1)
"""

FAKE_CLAUDE = """#!/usr/bin/env python3
import json, os, subprocess, sys
if sys.argv[1:] == ["--version"]:
    print("9.9.9 (Claude Code)")
    sys.exit(0)
prompt = sys.argv[-1]
view = subprocess.run(["gh", "issue", "view", "7", "-R", "octo/widgets", "--json", "title,body"],
                      capture_output=True, text=True)
assert view.returncode == 0, view.stderr
for body in ["# Approach\\n\\nreplayed", "# Design\\n\\nreplayed"]:
    subprocess.run(["gh", "issue", "comment", "7", "-R", "octo/widgets", "--body", body],
                   check=True, capture_output=True)
projects = os.path.join(os.environ["CLAUDE_CONFIG_DIR"], "projects", "x")
os.makedirs(projects, exist_ok=True)
open(os.path.join(projects, "fake-session.jsonl"), "w").write("")
result = json.load(open(os.environ["FAKE_RESULT"]))
result["session_id"] = "fake-session"
result["permission_denials"] = []
result["result"] = "PLANNED: https://github.com/octo/widgets/issues/7#x; implementation not started"
print(json.dumps({**result, "prompt_seen": prompt, "cwd_seen": os.getcwd(),
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
        self.source, _ = make_source(self.root, [began - timedelta(days=1), began + timedelta(1)])
        (self.root / "issue.json").write_text(json.dumps(issue))
        self.state = self.root / "state"
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}:{os.environ['PATH']}",
            "FAKE_ISSUE": str(self.root / "issue.json"),
            "FAKE_RESULT": str(FIXTURES / "result.json"),
            "CLAUDE_CONFIG_DIR": str(self.root / "claude"),
            "XDG_STATE_HOME": str(self.state),
        }

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def plan(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), "plan", "octo/widgets#7", "--run", "1"]
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
