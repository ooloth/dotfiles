#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic>=2,<3"]
# ///
"""Replay unattended planning on a ticket I already planned, so its output can be graded against mine.

Run:
  uv run tools/claude/replay.py plan <owner/repo#n> --run <k> [--source PATH] [--branch main]
  uv run tools/claude/replay.py grades

`plan` runs the installed `plan-unattended` skill, unchanged, as a headless Claude Code session
(`claude -p`) in a sandbox that can't post or push, and that sees the ticket's repo only as it stood
when planning began:

- a clone fetched only up to the last commit before the ticket's approach comment
- a `gh` stand-in that serves the ticket's title and body as they stood then, with no parent and
  no comments but the ones the replay posts, which it saves instead of posting
- Claude Code's sandbox with no network except package registries, Bash reads of the home and temp
  folders confined to an allow-list, the Read, Edit and Write tools confined to the working
  directories and the file tools denied in the home folder, and web tools and MCP servers off
- the user's Claude Code settings, the clone's own project instructions, skills and settings, and
  the replay's own settings, which turn every hook off, since hooks run outside the sandbox; a
  clone whose committed project settings hold a key that could widen the sandbox is refused

Before the session starts, a short canary session with the same settings tries to read a secret
beside the replay folders with Bash and with the Read tool, write with the Write tool in the home
folder and outside every working folder, write in the home folder with Bash, and fetch a host off
the registry list. The replay runs only if each was refused with its fence's own message and took
no effect, a Write-tool write in scratch and a `gh` call to the stand-in both worked, a hook the
settings plant never fired, and the clone's `CLAUDE.md`, when it has one, loaded.

One thing is as it is today, not as it was: the agent harness (global instructions, skills,
standards), along with any folder of the dotfiles checkout that the Bash allow-list opens. That is
why a ticket is refused when a commit to one of those paths, made after its planning began, names
it, whether as `owner/repo#n`, `repo#n`, its issue URL, or a bare `#n` for a dotfiles ticket.

It writes one folder per replay under `${XDG_STATE_HOME:-~/.local/state}/replays/`, holding the
replay's approach and design, my own from the ticket, the session's duration and tokens per model,
an audit of the refusals it recognizes in the session's transcripts, and a `grade.md` to fill in.
The folder is created only once the replay is ready to start, and a folder that already exists is
never written to. `grades` summarizes every `grade.md` written so far.

`--source` is a local checkout of the ticket's repo, `~/Repos/<owner>/<repo>` by default, which
the clone is fetched from. The session is labelled `CLAUDE_CODE_ENTRYPOINT=factory-replay`, since
the default label for `claude -p` was measured using more of the 5-hour window
(https://github.com/anthropics/claude-code/issues/97074#issuecomment-6426128541).

Exit codes: 0 when the session planned or escalated, 1 when the ticket can't be replayed or the
session failed, and 128 plus the signal's number when a signal interrupted the session. An
interrupted or failed run keeps what the session posted, and `grades` lists it as unfinished.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import secrets
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import UTC, datetime
from enum import Enum
from pathlib import Path
from typing import Any, NewType, assert_never

from pydantic import BaseModel, ValidationError

Sha = NewType("Sha", str)

DOTFILES = Path(__file__).resolve().parents[2]
# The source of the `gh` stand-in. `write_stand_in` copies it into the session's `bin/gh`, beside
# the ticket it serves.
STAND_IN = Path(__file__).resolve().with_name("replay_gh.py")
HARNESS_REPO = ("ooloth", "dotfiles")
HARNESS_PATHS = ("tools/claude/config/", "tools/agents/config/")
REGISTRIES = (
    "pypi.org",
    "files.pythonhosted.org",
    "crates.io",
    "index.crates.io",
    "static.crates.io",
    "registry.npmjs.org",
)
# Home-relative folders the session's Bash may read: where this Mac's toolchains and git config
# live. A folder missing here shows up in the audit as refused file access.
TOOLCHAINS = (
    ".local/bin",
    ".local/share/uv",
    ".cache/uv",
    ".config/uv",
    ".config/cargo",
    ".config/rustup",
    ".cargo",
    ".rustup",
    ".local/share/fnm",
    ".local/state/fnm_multishells",
    # fnm's own folder: each shell's link above goes through its `aliases` links into `node-versions`,
    # and a link the sandbox can't read fails a PATH lookup that passes through it with EPERM.
    "Library/Application Support/fnm",
    ".config/git",
)
# The session's label in Claude Code's transcripts and usage accounting. "factory" is the epic this
# tool belongs to, ooloth/dotfiles#268.
ENTRYPOINT = "factory-replay"
# Tokens that would let the session reach GitHub, and variables that would send the session to an
# API key, a gateway or a cloud provider instead of the subscription.
UNSET_FOR_SESSION = (
    "GH_TOKEN",
    "GITHUB_TOKEN",
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_AUTH_TOKEN",
    "ANTHROPIC_BASE_URL",
    "CLAUDE_CODE_USE_VERTEX",
    "CLAUDE_CODE_USE_BEDROCK",
)
SESSION_TIMEOUT_SECONDS = 3 * 60 * 60
CANARY_TIMEOUT_SECONDS = 10 * 60
# The host the canary tries to reach. Any host off the registry list would do.
CANARY_URL = "https://example.com"
CALL_TIMEOUT_SECONDS = 120
TAIL_CHARS = 2000

ISSUE_QUERY = """
query($o: String!, $r: String!, $n: Int!) {
  repository(owner: $o, name: $r) {
    issue(number: $n) {
      title
      body
      comments(first: 100) { pageInfo { hasNextPage } nodes { createdAt body } }
      userContentEdits(first: 100) { pageInfo { hasNextPage } nodes { editedAt diff } }
      timelineItems(itemTypes: [RENAMED_TITLE_EVENT], first: 100) {
        pageInfo { hasNextPage }
        nodes { ... on RenamedTitleEvent { createdAt previousTitle } }
      }
    }
  }
}
"""


# ── Domain types ───────────────────────────────────────────────────────────────────────────────


@dataclass(frozen=True)
class TicketRef:
    owner: str
    repo: str
    number: int

    def __str__(self) -> str:
        return f"{self.owner}/{self.repo}#{self.number}"

    @property
    def name_with_owner(self) -> str:
        return f"{self.owner}/{self.repo}"

    @property
    def slug(self) -> str:
        return f"{self.owner}-{self.repo}-{self.number}"


@dataclass(frozen=True)
class Comment:
    created_at: datetime
    body: str


@dataclass(frozen=True)
class BodyEdit:
    """The ticket body as it stood after one edit. GitHub lists the creation as an edit too."""

    edited_at: datetime
    content: str


@dataclass(frozen=True)
class TitleRename:
    """A change of the ticket's title, keeping the title it replaced."""

    renamed_at: datetime
    previous_title: str


@dataclass(frozen=True)
class TicketHistory:
    ref: TicketRef
    title: str
    title_renames: tuple[TitleRename, ...]
    body: str
    body_edits: tuple[BodyEdit, ...]
    approach: Comment
    design: Comment


@dataclass(frozen=True)
class PlanningSnapshot:
    """The ticket as it stood when planning began, with no comments. The stand-in serves this
    plus the comments the replay itself posts."""

    ref: TicketRef
    title: str
    body: str
    planning_began: datetime


@dataclass(frozen=True)
class NoApproachComment:
    pass


@dataclass(frozen=True)
class NoDesignComment:
    pass


@dataclass(frozen=True)
class BodyUnknown:
    planning_began: datetime


@dataclass(frozen=True)
class NamedByLaterHarnessCommits:
    commits: tuple[Sha, ...]
    files: tuple[str, ...]


@dataclass(frozen=True)
class HarnessHistoryUnreadable:
    stderr: str


@dataclass(frozen=True)
class BaseNotFound:
    before: datetime


@dataclass(frozen=True)
class GitHubUnreadable:
    problems: tuple[str, ...]


@dataclass(frozen=True)
class ProjectSettingsWiden:
    """A project settings file in the clone, and its keys that could widen what the session may do."""

    file: str
    keys: tuple[str, ...]


@dataclass(frozen=True)
class ProjectSettingsUnreadable:
    file: str
    problem: str


NotReplayable = (
    NoApproachComment
    | NoDesignComment
    | BodyUnknown
    | NamedByLaterHarnessCommits
    | HarnessHistoryUnreadable
    | BaseNotFound
    | GitHubUnreadable
    | ProjectSettingsWiden
    | ProjectSettingsUnreadable
)


@dataclass(frozen=True)
class SandboxPaths:
    home: Path
    tmp_root: Path
    work: Path
    clone: Path
    capture: Path
    scratch: Path
    claude_tmp: Path
    # Touched by a hook the settings plant and disableAllHooks must silence, so the canary can show
    # no hook runs. It sits outside every folder Bash may write.
    hook_marker: Path
    harness: tuple[Path, ...]
    toolchains: tuple[Path, ...]


@dataclass(frozen=True)
class ReadRefused:
    path: str


@dataclass(frozen=True)
class FileRefused:
    command: str
    detail: str


@dataclass(frozen=True)
class NetworkRefused:
    host: str


@dataclass(frozen=True)
class GhRefused:
    args: str


@dataclass(frozen=True)
class ToolDenied:
    tool: str
    detail: str


Refusal = ReadRefused | FileRefused | NetworkRefused | GhRefused | ToolDenied


@dataclass(frozen=True)
class Audit:
    refusals: tuple[Refusal, ...]
    transcripts_read: int
    unreadable_lines: int


@dataclass(frozen=True)
class AuditIncomplete:
    reason: str


@dataclass(frozen=True)
class ModelTokens:
    model: str
    input: int
    output: int
    cache_read: int
    cache_creation: int


@dataclass(frozen=True)
class PermissionDenial:
    tool: str
    tool_use_id: str
    detail: str


@dataclass(frozen=True)
class SessionResult:
    session_id: str
    duration_ms: int
    tokens_by_model: tuple[ModelTokens, ...]
    permission_denials: tuple[PermissionDenial, ...]
    final_text: str


@dataclass(frozen=True)
class SessionFailed:
    exit: int | None
    reason: str
    stderr_tail: str


@dataclass(frozen=True)
class Planned:
    line: str


@dataclass(frozen=True)
class Escalated:
    line: str


@dataclass(frozen=True)
class Interrupted:
    """The session was stopped by a signal, such as Ctrl-C or a closed terminal."""

    signal: str


SessionOutcome = Planned | Escalated | SessionFailed | Interrupted


@dataclass(frozen=True)
class Canary:
    """Eight actions a short session tries before the replay's own. Six must be refused, each with
    its fence's own message: read a secret beside the replay folders with Bash and with the Read
    tool, write with the Write tool in the home folder and outside every working folder, write in
    the home folder with Bash, and fetch a host off the registry list. Two must work, as planning
    needs them: a Write-tool write in scratch, and a `gh` call to the stand-in."""

    secret: str
    secret_file: Path
    home_write_target: Path
    outside_write_target: Path
    bash_target: Path
    net_target: Path
    allowed_write_target: Path
    gh_command: str
    # The clone's project instructions the session must load, and the file a hook would touch.
    instructions: tuple[Path, ...]
    hook_marker: Path

    def prompt(self) -> str:
        return (
            "This is a sandbox check for a replay: actions 1 to 6 should be refused and 7 and 8 "
            "should work, and the check passes when they do. Run all eight, one tool call each, "
            "in this order, and carry on after a refusal. Don't try another way round a refusal. "
            "Then reply DONE.\n"
            f"1. With Bash, run: cat {self.secret_file}\n"
            f"2. With the Read tool, read {self.secret_file}\n"
            f"3. With the Write tool, create {self.home_write_target} containing the word canary\n"
            f"4. With the Write tool, create {self.outside_write_target} containing the word "
            "canary\n"
            f"5. With Bash, run: touch {self.bash_target}\n"
            f"6. With Bash, run: curl -sS -m 10 -o {self.net_target} {CANARY_URL}\n"
            f"7. With the Write tool, create {self.allowed_write_target} containing the word "
            "canary\n"
            f"8. With Bash, run: {self.gh_command}\n"
        )


@dataclass(frozen=True)
class ToolUse:
    tool: str
    input: Mapping[str, Any]
    result: str


@dataclass(frozen=True)
class CanaryEffects:
    """What the canary's actions left on disk, and whether the stand-in served its `gh` call."""

    home_write_file: bool
    outside_write_file: bool
    bash_file: bool
    net_bytes: int
    hook_ran: bool
    allowed_write_file: bool
    gh_served: bool


@dataclass(frozen=True)
class SandboxHolds:
    pass


@dataclass(frozen=True)
class SandboxBreached:
    """Each action that took effect, with what showed it."""

    checks: tuple[tuple[str, str], ...]


@dataclass(frozen=True)
class ProjectNotLoaded:
    """The clone's own instructions that the canary session did not load."""

    missing: tuple[Path, ...]


@dataclass(frozen=True)
class AllowedActionFailed:
    """Each action planning needs that the canary tried and that didn't work, with what showed it."""

    checks: tuple[tuple[str, str], ...]


@dataclass(frozen=True)
class CanaryInconclusive:
    reason: str


CanaryVerdict = (
    SandboxHolds | SandboxBreached | ProjectNotLoaded | AllowedActionFailed | CanaryInconclusive
)


@dataclass(frozen=True)
class CapturedComments:
    approach: str | None
    design: str | None
    extra: tuple[str, ...]


class Verdict(Enum):
    APPROVE_AS_IS = "approve-as-is"
    APPROVE_WITH_EDITS = "approve-with-edits"
    REJECT = "reject"


@dataclass(frozen=True)
class Graded:
    """A replay that planned has an approach and a design verdict. One that escalated has an
    escalation verdict, and an approach verdict too when it posted an approach first."""

    approach: Verdict | None
    design: Verdict | None
    escalation: Verdict | None = None


@dataclass(frozen=True)
class Ungraded:
    pass


@dataclass(frozen=True)
class GradeUnreadable:
    reason: str


@dataclass(frozen=True)
class Excluded:
    """A replay left out of the tally, such as one that read the shipped answer."""

    reason: str


@dataclass(frozen=True)
class Unfinished:
    """A replay whose session never finished: it failed, was interrupted, or never ended. There is
    nothing to grade, so it is listed apart and left out of the counts."""

    reason: str


Grade = Graded | Ungraded | GradeUnreadable | Excluded | Unfinished


# ── Parsing GitHub's view of the ticket ────────────────────────────────────────────────────────


class _PageInfo(BaseModel):
    hasNextPage: bool


class _CommentNode(BaseModel):
    createdAt: datetime
    body: str


class _EditNode(BaseModel):
    editedAt: datetime | None
    diff: str | None


class _Comments(BaseModel):
    pageInfo: _PageInfo
    nodes: list[_CommentNode]


class _Edits(BaseModel):
    pageInfo: _PageInfo
    nodes: list[_EditNode]


class _RenameNode(BaseModel):
    createdAt: datetime
    previousTitle: str


class _Renames(BaseModel):
    pageInfo: _PageInfo
    nodes: list[_RenameNode]


class _Issue(BaseModel):
    title: str
    body: str
    comments: _Comments
    userContentEdits: _Edits
    timelineItems: _Renames


class _Repository(BaseModel):
    issue: _Issue


class _Data(BaseModel):
    repository: _Repository


class _IssueResponse(BaseModel):
    data: _Data


def parse_ticket_ref(text: str) -> TicketRef | None:
    match = re.fullmatch(r"([\w.-]+)/([\w.-]+)#(\d+)", text)
    if match is None:
        return None
    return TicketRef(match[1], match[2], int(match[3]))


def parse_history(ref: TicketRef, payload: object) -> TicketHistory | NotReplayable:
    """Read GitHub's GraphQL response for the ticket, refusing one that can't be read in full."""
    try:
        issue = _IssueResponse.model_validate(payload).data.repository.issue
    except ValidationError as error:
        return GitHubUnreadable(tuple(str(e["msg"]) + f" at {e['loc']}" for e in error.errors()))
    problems = []
    if issue.comments.pageInfo.hasNextPage:
        problems.append("the ticket has more than 100 comments, and only the first page was read")
    if issue.userContentEdits.pageInfo.hasNextPage:
        problems.append("the body has more than 100 edits, and only the first page was read")
    if issue.timelineItems.pageInfo.hasNextPage:
        problems.append("the title has more than 100 renames, and only the first page was read")
    edits = []
    for node in issue.userContentEdits.nodes:
        if node.editedAt is None or node.diff is None:
            problems.append("a body edit has no timestamp or no content")
            continue
        edits.append(BodyEdit(node.editedAt, node.diff))
    if problems:
        return GitHubUnreadable(tuple(problems))
    approach = next((c for c in issue.comments.nodes if c.body.startswith("# Approach")), None)
    if approach is None:
        return NoApproachComment()
    design = next((c for c in issue.comments.nodes if c.body.startswith("# Design")), None)
    if design is None:
        return NoDesignComment()
    return TicketHistory(
        ref=ref,
        title=issue.title,
        title_renames=tuple(
            TitleRename(n.createdAt, n.previousTitle) for n in issue.timelineItems.nodes
        ),
        body=issue.body,
        body_edits=tuple(edits),
        approach=Comment(approach.createdAt, approach.body),
        design=Comment(design.createdAt, design.body),
    )


def cut_at_planning(history: TicketHistory) -> PlanningSnapshot | BodyUnknown:
    """Keep only what existed when planning began: the title and the body as they stood then."""
    began = history.approach.created_at
    if history.body_edits:
        earlier = [e for e in history.body_edits if e.edited_at <= began]
        if not earlier:
            return BodyUnknown(began)
        served = max(earlier, key=lambda e: e.edited_at)
        assert served.edited_at <= began, "the served body was edited after planning began"
        body = served.content
    else:
        body = history.body
    # The title in force at planning is the one the first later rename replaced, or today's.
    later = [r for r in history.title_renames if r.renamed_at > began]
    if later:
        first = min(later, key=lambda r: r.renamed_at)
        assert first.renamed_at > began, "the served title was set after planning began"
        title = first.previous_title
    else:
        title = history.title
    return PlanningSnapshot(history.ref, title, body, began)


# A POSIX extended regular expression, which `git log -E --grep` reads.
TicketPattern = NewType("TicketPattern", str)


def _ere_literal(text: str) -> str:
    return "".join(f"\\{c}" if c in r".^$*+?()[]{}|\\" else c for c in text)


def ticket_pattern(ref: TicketRef) -> TicketPattern:
    """What names `ref` in a commit message: `owner/repo#n`, `repo#n` or its issue URL, and a bare
    `#n` too for a dotfiles ticket, with the whole number, so `#39` and `#3940` don't name `#394`."""
    owner, repo = _ere_literal(ref.owner), _ere_literal(ref.repo)
    forms = [
        f"(^|[^A-Za-z0-9_.-]){owner}/{repo}#{ref.number}",
        f"github\\.com/{owner}/{repo}/issues/{ref.number}",
        # The short form, as in "replays on hub#327", when no owner or longer name comes before it.
        f"(^|[^A-Za-z0-9_./-]){repo}#{ref.number}",
    ]
    if (ref.owner, ref.repo) == HARNESS_REPO:
        forms.append(f"(^|[^A-Za-z0-9_./-])#{ref.number}")
    return TicketPattern(f"({'|'.join(forms)})([^0-9]|$)")


def watched_paths(dotfiles: Path, readable: Sequence[Path]) -> tuple[str, ...]:
    """The dotfiles paths a replay session reads as they are today: the harness, and each folder of
    the live checkout that the Bash allow-list opens, such as the git config a link points into."""
    live = [
        f"{folder.relative_to(dotfiles)}/" for folder in readable if folder.is_relative_to(dotfiles)
    ]
    return (*HARNESS_PATHS, *live)


def check_later_harness(
    commits: Sequence[Sha], files_of: Mapping[Sha, tuple[str, ...] | None], watched: Sequence[str]
) -> NamedByLaterHarnessCommits | None:
    """Refuse a ticket that a commit to a watched path, made after its planning began, names: every
    session reads those paths as they are today, which may say how the ticket was solved."""
    if not commits:
        return None
    touched: set[str] = set()
    for sha in commits:
        files = files_of.get(sha)
        assert files is not None, f"{sha} came from the same checkout, so its files are readable"
        touched.update(f for f in files if f.startswith(tuple(watched)))
    return NamedByLaterHarnessCommits(tuple(commits), tuple(sorted(touched)))


def explain(reason: NotReplayable) -> str:
    match reason:
        case NoApproachComment():
            return "The ticket has no comment starting with `# Approach`, so there is nothing to grade against."
        case NoDesignComment():
            return "The ticket has no comment starting with `# Design`, so there is nothing to grade against."
        case BodyUnknown(began):
            return f"No version of the ticket body is dated at or before planning began ({began.isoformat()})."
        case NamedByLaterHarnessCommits(commits, files):
            listed = "\n".join(f"  {c}" for c in commits)
            changed = "\n".join(f"  {f}" for f in files)
            return (
                "Commits made after the ticket's planning began name it and change the harness or "
                "another folder every session reads as it is today, so a replay could read how it "
                "was solved:\n"
                f"{listed}\nThey changed:\n{changed}"
            )
        case HarnessHistoryUnreadable(stderr):
            return (
                "git couldn't read the dotfiles history, so whether a later commit to a watched path names "
                f"the ticket is unknown:\n  {stderr}"
            )
        case BaseNotFound(before):
            return f"The default branch has no commit at or before {before.isoformat()}."
        case GitHubUnreadable(problems):
            return "GitHub's answer couldn't be read in full:\n" + "\n".join(
                f"  {p}" for p in problems
            )
        case ProjectSettingsWiden(file, keys):
            return (
                f"The clone's {file} sets {', '.join(keys)}, which could widen what the session may "
                f"read, write or reach, so the replay is not run. It accepts only "
                f"{', '.join(sorted(SAFE_PROJECT_SETTINGS))}."
            )
        case ProjectSettingsUnreadable(file, problem):
            return (
                f"The clone's {file} isn't a JSON object ({problem}), so what it would load can't "
                "be known and the replay is not run."
            )
        case _:
            assert_never(reason)


# ── Git ────────────────────────────────────────────────────────────────────────────────────────


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    # Reads here run alongside other sessions' git work in the dotfiles checkout, so they never
    # refresh the index and take `index.lock`, which would fail a commit made at that moment.
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True,
        text=True,
        check=False,
        timeout=CALL_TIMEOUT_SECONDS,
        env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"},
    )


def files_changed(source: Path, shas: Sequence[Sha]) -> dict[Sha, tuple[str, ...] | None]:
    found: dict[Sha, tuple[str, ...] | None] = {}
    for sha in shas:
        # -z prints each path as it is: without it git quotes non-ASCII paths, which then don't
        # match the watched paths, and splitting on whitespace breaks a path with a space.
        shown = git(
            source,
            "diff-tree",
            "-r",
            "-m",
            "--first-parent",
            "--no-commit-id",
            "--name-only",
            "-z",
            sha,
        )
        found[sha] = (
            tuple(f for f in shown.stdout.split("\0") if f) if shown.returncode == 0 else None
        )
    return found


def later_harness_commits(
    dotfiles: Path, pattern: TicketPattern, since: datetime, watched: Sequence[str]
) -> tuple[Sha, ...] | HarnessHistoryUnreadable:
    """The commits in the dotfiles checkout, committed after `since`, that change a watched path
    and whose message matches `pattern`, newest first."""
    assert since.tzinfo is not None, (
        "planning_began has no time zone, so --since would read it as local"
    )
    listed = git(
        dotfiles,
        "log",
        "-E",
        "--regexp-ignore-case",
        f"--grep={pattern}",
        f"--since={since.isoformat()}",
        "--format=%H",
        "--",
        *watched,
    )
    if listed.returncode != 0:
        return HarnessHistoryUnreadable(listed.stderr.strip())
    return tuple(Sha(line) for line in listed.stdout.split())


def resolve_base(source: Path, branch: str, before: datetime) -> Sha | BaseNotFound:
    """The newest commit on `branch` itself, its first-parent chain, committed at or before
    `before`."""
    # --first-parent keeps to commits that were on `branch` itself, so a branch merged after
    # planning began can't supply the base through a commit dated before it.
    listed = git(
        source, "rev-list", "-n1", "--first-parent", f"--before={before.isoformat()}", branch
    )
    sha = listed.stdout.strip()
    if listed.returncode != 0 or not sha:
        return BaseNotFound(before)
    committed = datetime.fromisoformat(
        git(source, "show", "-s", "--format=%cI", sha).stdout.strip()
    )
    assert committed <= before, f"base {sha} was committed after planning began"
    ancestor = git(source, "merge-base", "--is-ancestor", sha, branch)
    assert ancestor.returncode == 0, f"base {sha} is not on {branch}"
    chain = git(source, "rev-list", "--first-parent", branch).stdout.split()
    assert sha in chain, f"base {sha} is not on {branch}'s first-parent chain"
    return Sha(sha)


def make_clone(source: Path, base: Sha, clone: Path) -> None:
    """A fresh repo holding only `base` and its history, with no remote to push to."""
    clone.mkdir(parents=True)
    for args in (
        ("init", "-q"),
        ("fetch", "-q", "--no-tags", source.resolve().as_uri(), base),
        ("checkout", "-q", "--detach", "FETCH_HEAD"),
    ):
        done = git(clone, *args)
        if done.returncode != 0:
            raise RuntimeError(f"git {' '.join(args)} failed in the clone: {done.stderr.strip()}")


def check_clone(clone: Path, began: datetime) -> None:
    dates = git(clone, "log", "--all", "--format=%cI").stdout.split()
    assert dates, "the clone holds no commits"
    newest = max(datetime.fromisoformat(d) for d in dates)
    assert newest <= began, f"the clone holds a commit from {newest}, after planning began"
    urls = git(clone, "config", "--get-regexp", r"^remote\..*\.url$").stdout.strip()
    assert not urls, f"the clone has a remote URL: {urls}"


# The project settings files the project source loads from the clone.
PROJECT_SETTINGS_FILES = (".claude/settings.json", ".claude/settings.local.json")
# Keys that can't widen the fence: a commit trailer, hooks (all off) and MCP servers (never started
# under --strict-mcp-config). Any other key refuses the replay until someone has looked at it.
SAFE_PROJECT_SETTINGS = frozenset({"attribution", "hooks", "enableAllProjectMcpServers"})


def check_project_settings(clone: Path) -> ProjectSettingsWiden | ProjectSettingsUnreadable | None:
    """Refuse a clone whose committed project settings could widen what the session may read, write
    or reach, since the project source merges them into the session's settings."""
    for name in PROJECT_SETTINGS_FILES:
        path = clone / name
        if not path.exists():
            continue
        try:
            settings = json.loads(path.read_text())
        except (json.JSONDecodeError, UnicodeDecodeError) as error:
            return ProjectSettingsUnreadable(name, str(error))
        if not isinstance(settings, dict):
            return ProjectSettingsUnreadable(name, f"it holds a {type(settings).__name__}")
        widening = tuple(sorted(k for k in settings if k not in SAFE_PROJECT_SETTINGS))
        if widening:
            return ProjectSettingsWiden(name, widening)
    return None


def project_instructions(clone: Path) -> tuple[Path, ...]:
    """The clone's own instructions a session in it must load."""
    claude_md = clone / "CLAUDE.md"
    return (claude_md,) if claude_md.exists() else ()


# ── The gh stand-in ────────────────────────────────────────────────────────────────────────────


# `replay_gh.py` runs inside the sandbox and uses only the standard library, and `jq` from PATH for
# --jq. It serves the ticket as it stood when planning began plus the comments this replay posted,
# since a skill reads back what it posts.
def write_stand_in(bin_dir: Path, snapshot: PlanningSnapshot, capture: Path) -> Path:
    bin_dir.mkdir(parents=True, exist_ok=True)
    config = bin_dir / "gh-snapshot.json"
    config.write_text(
        json.dumps(
            {
                "repo": snapshot.ref.name_with_owner,
                "number": snapshot.ref.number,
                "title": snapshot.title,
                "body": snapshot.body,
                "capture": str(capture),
            }
        )
    )
    # The stand-in runs on the interpreter running this script, which the sandbox can read under
    # uv's folder, rather than whatever `python3` the session's PATH finds first.
    interpreter = Path(sys.executable).resolve()
    gh = bin_dir / "gh"
    gh.write_text(f"#!{interpreter}\n" + STAND_IN.read_text())
    gh.chmod(0o755)
    return gh


# macOS mktemp ignores $TMPDIR and makes plain `mktemp -d` folders in the user's temp folder, which
# the sandbox can't read. Skills call plain `mktemp -d`, so the session's mktemp puts a folder in
# $TMPDIR whenever the caller names no folder of its own.
MKTEMP = r"""#!/bin/sh
prev=""
for a in "$@"; do
  case "$prev" in -t) prev=""; continue ;; esac
  case "$a" in
    -p | --tmpdir | --tmpdir=*) exec /usr/bin/mktemp "$@" ;;
    -t) prev="-t" ;;
    -*) ;;
    *) exec /usr/bin/mktemp "$@" ;;
  esac
done
exec /usr/bin/mktemp -p "$TMPDIR" "$@"
"""


def write_mktemp(bin_dir: Path) -> Path:
    bin_dir.mkdir(parents=True, exist_ok=True)
    mktemp = bin_dir / "mktemp"
    mktemp.write_text(MKTEMP)
    mktemp.chmod(0o755)
    return mktemp


# ── The sandbox settings ───────────────────────────────────────────────────────────────────────


def build_settings(paths: SandboxPaths) -> dict[str, Any]:
    editable = (paths.clone, paths.scratch, paths.claude_tmp)
    return {
        "sandbox": {
            "enabled": True,
            "failIfUnavailable": True,
            "allowUnsandboxedCommands": False,
            "autoAllowBashIfSandboxed": True,
            "network": {"allowedDomains": list(REGISTRIES)},
            "filesystem": {
                "denyRead": [str(paths.home), str(paths.tmp_root), "/private/tmp"],
                "allowRead": [str(p) for p in (paths.work, *paths.harness, *paths.toolchains)],
                # Bash may also write the capture folder, where the gh stand-in saves comments.
                "allowWrite": [
                    str(p) for p in (paths.clone, paths.capture, paths.scratch, paths.claude_tmp)
                ],
            },
        },
        "permissions": {
            "defaultMode": "dontAsk",
            "allow": [
                "Bash",
                "Read",
                "Grep",
                "Glob",
                "Agent",
                "Skill",
                "TodoWrite",
                # Edit rules cover every file tool; Claude Code matches no Write(path) rule.
                *(f"Edit(/{folder}/**)" for folder in editable),
            ],
            # The user settings allow Edit and Write everywhere. The fence below keeps the file
            # tools in the working folders, and the harness folders passed with --add-dir are
            # working folders under home, so home is denied too. A deny wins over any allow.
            "deny": ["WebFetch", "WebSearch", f"Edit(/{paths.home}/**)"],
            "blockReadsOutsideWorkingDirectories": True,
            "blockWritesOutsideWorkingDirectories": True,
        },
        # Hooks run outside the sandbox, and the project source loads the clone's own, so every
        # hook is off. The canary shows it by this one never firing.
        "disableAllHooks": True,
        "hooks": {"SessionStart": [{"hooks": [marker_hook(paths.hook_marker)]}]},
    }


def marker_hook(marker: Path) -> dict[str, str]:
    return {"type": "command", "command": f"touch {shlex.quote(str(marker))}"}


def check_settings(settings: Mapping[str, Any], paths: SandboxPaths) -> None:
    sandbox = settings["sandbox"]
    filesystem = sandbox["filesystem"]
    assert sandbox["enabled"] is True, "sandbox.enabled is not true"
    assert sandbox["failIfUnavailable"] is True, "sandbox.failIfUnavailable is not true"
    assert sandbox["allowUnsandboxedCommands"] is False, (
        "sandbox.allowUnsandboxedCommands is not false"
    )
    assert sandbox["network"]["allowedDomains"] == list(REGISTRIES), (
        "sandbox.network.allowedDomains is not exactly the package registries"
    )
    for denied in (str(paths.home), str(paths.tmp_root), "/private/tmp"):
        assert denied in filesystem["denyRead"], f"sandbox.filesystem.denyRead lacks {denied}"
    writable = [str(p) for p in (paths.clone, paths.capture, paths.scratch, paths.claude_tmp)]
    assert filesystem["allowWrite"] == writable, (
        "sandbox.filesystem.allowWrite is not only the clone, the capture folder, scratch and "
        "Claude Code's temp folder"
    )
    assert settings["permissions"]["blockReadsOutsideWorkingDirectories"] is True, (
        "permissions.blockReadsOutsideWorkingDirectories is not true"
    )
    assert settings["permissions"]["blockWritesOutsideWorkingDirectories"] is True, (
        "permissions.blockWritesOutsideWorkingDirectories is not true"
    )
    home_rule = f"Edit(/{paths.home}/**)"
    assert home_rule in settings["permissions"]["deny"], f"permissions.deny lacks {home_rule}"
    denied = [
        Path(rule.removeprefix("Edit(/").removesuffix("/**)"))
        for rule in settings["permissions"]["deny"]
        if rule.startswith("Edit(/") and rule.endswith("/**)")
    ]
    for folder in (paths.clone, paths.scratch, paths.claude_tmp):
        for root in denied:
            assert not folder.is_relative_to(root), (
                f"the editable folder {folder} sits under the denied {root}"
            )
    assert settings.get("disableAllHooks") is True, "disableAllHooks is not true"
    session_start = settings.get("hooks", {}).get("SessionStart", [])
    assert any(marker_hook(paths.hook_marker) in e.get("hooks", []) for e in session_start), (
        "the settings lack the SessionStart marker hook the canary checks"
    )


def check_command(command: Sequence[str]) -> None:
    """The session loads the user settings, the clone's project instructions, skills and settings,
    and the replay's own file, which turns every hook off."""
    assert "--setting-sources" in command and (
        command[command.index("--setting-sources") + 1] == "user,project"
    ), "the session command doesn't pass --setting-sources user,project"
    assert "--settings" in command, "the session command doesn't pass --settings"


# ── The session's result ───────────────────────────────────────────────────────────────────────


class _Usage(BaseModel):
    inputTokens: int = 0
    outputTokens: int = 0
    cacheReadInputTokens: int = 0
    cacheCreationInputTokens: int = 0


class _Denial(BaseModel):
    tool_name: str
    tool_use_id: str
    tool_input: dict[str, Any] = {}


class _Result(BaseModel):
    session_id: str
    duration_ms: int
    result: str = ""
    is_error: bool = False
    subtype: str = ""
    modelUsage: dict[str, _Usage] = {}
    permission_denials: list[_Denial] = []


def tail(text: str) -> str:
    return text[-TAIL_CHARS:]


def parse_session_result(exit_code: int, stdout: str, stderr: str) -> SessionResult | SessionFailed:
    if exit_code != 0:
        return SessionFailed(exit_code, f"claude exited with {exit_code}", tail(stderr))
    try:
        raw = _Result.model_validate_json(stdout)
    except ValidationError as error:
        return SessionFailed(
            exit_code, f"the session result couldn't be read: {error}", tail(stderr)
        )
    if raw.is_error:
        return SessionFailed(exit_code, f"the session ended with {raw.subtype}", tail(stderr))
    return SessionResult(
        session_id=raw.session_id,
        duration_ms=raw.duration_ms,
        tokens_by_model=tuple(
            ModelTokens(
                model,
                u.inputTokens,
                u.outputTokens,
                u.cacheReadInputTokens,
                u.cacheCreationInputTokens,
            )
            for model, u in sorted(raw.modelUsage.items())
        ),
        permission_denials=tuple(
            PermissionDenial(d.tool_name, d.tool_use_id, json.dumps(d.tool_input))
            for d in raw.permission_denials
        ),
        final_text=raw.result,
    )


def outcome_of(result: SessionResult) -> SessionOutcome:
    """Read the outcome from the skill's own final line."""
    lines = [line.strip() for line in result.final_text.splitlines() if line.strip()]
    last = lines[-1] if lines else ""
    if last.startswith("PLANNED:"):
        return Planned(last)
    if last.startswith("ESCALATED:"):
        return Escalated(last)
    return SessionFailed(
        0, f"the session's last line is neither PLANNED: nor ESCALATED: {last!r}", ""
    )


def sort_comments(capture: Path) -> CapturedComments:
    approach = design = None
    extra: list[str] = []
    for path in sorted(capture.glob("comment-*.md")):
        body = path.read_text()
        if approach is None and body.startswith("# Approach"):
            approach = body
        elif design is None and body.startswith("# Design"):
            design = body
        else:
            extra.append(body)
    return CapturedComments(approach, design, tuple(extra))


# ── The audit ──────────────────────────────────────────────────────────────────────────────────


def result_text(content: object) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(str(part.get("text", "")) for part in content if isinstance(part, dict))
    return ""


def classify(text: str, tool_input: Mapping[str, Any]) -> list[Refusal]:
    command = str(tool_input.get("command", json.dumps(dict(tool_input))))
    found: list[Refusal] = []
    for host in dict.fromkeys(re.findall(r"deny network-outbound ([^\s:]+)", text)):
        found.append(NetworkRefused(host))
    if "blockReadsOutsideWorkingDirectories" in text:
        found.append(
            ReadRefused(str(tool_input.get("file_path") or tool_input.get("path") or text))
        )
    gh = re.search(r"gh: unavailable in replay: (.*)", text)
    if gh is not None:
        found.append(GhRefused(gh[1].strip()))
    for line in text.splitlines():
        if "operation not permitted" in line.lower():
            found.append(FileRefused(command, line.strip()))
    return found


# The tools whose result is a subagent's report rather than what a command printed.
SUBAGENT_TOOLS = ("Agent", "Task")


def read_transcript(path: Path) -> tuple[list[tuple[str, list[Refusal]]], int]:
    """Each refused tool call in one transcript, by its tool-use ID, and how many lines didn't parse."""
    uses: dict[str, tuple[str, Mapping[str, Any]]] = {}
    refused: list[tuple[str, list[Refusal]]] = []
    unreadable = 0
    for line in path.read_text().splitlines():
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            unreadable += 1
            continue
        if not isinstance(record, dict) or record.get("type") not in ("user", "assistant"):
            continue
        content = (record.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use":
                uses[str(block.get("id"))] = (str(block.get("name")), block.get("input") or {})
            elif block.get("type") == "tool_result":
                # Every result, not only errors: a refusal inside a pipeline or a `;` chain exits
                # 0. A subagent's report is skipped, since its own transcript holds the refusal.
                use_id = str(block.get("tool_use_id"))
                tool, tool_input = uses.get(use_id, ("", {}))
                if tool in SUBAGENT_TOOLS:
                    continue
                found = classify(result_text(block.get("content")), tool_input)
                if found:
                    refused.append((use_id, found))
    return refused, unreadable


def read_audit(
    session_id: str,
    projects: Path,
    permission_denials: Sequence[PermissionDenial],
    gh_log: Sequence[str],
) -> Audit | AuditIncomplete:
    mains = sorted(projects.glob(f"*/{session_id}.jsonl"))
    if not mains:
        return AuditIncomplete(f"no transcript was found for session `{session_id}`")
    files = [*mains, *sorted((mains[0].parent / session_id / "subagents").glob("*.jsonl"))]
    refusals: list[Refusal] = []
    classified: set[str] = set()
    unreadable = 0
    for path in files:
        refused, bad = read_transcript(path)
        unreadable += bad
        for use_id, found in refused:
            classified.add(use_id)
            refusals.extend(found)
    for denial in permission_denials:
        if denial.tool_use_id not in classified:
            refusals.append(ToolDenied(denial.tool, denial.detail))
    for line in gh_log:
        try:
            call = json.loads(line)
        except json.JSONDecodeError:
            unreadable += 1
            continue
        if not isinstance(call, dict):
            unreadable += 1
            continue
        if not call.get("served"):
            refused_gh = GhRefused(" ".join(call.get("args", [])))
            if refused_gh not in refusals:
                refusals.append(refused_gh)
    return Audit(tuple(refusals), len(files), unreadable)


def transcript_uses(path: Path) -> list[ToolUse]:
    """Each tool call in one transcript, in order, with the text of its result."""
    calls: dict[str, tuple[str, Mapping[str, Any]]] = {}
    results: dict[str, str] = {}
    for line in path.read_text().splitlines():
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            continue
        content = (record.get("message") or {}).get("content") if isinstance(record, dict) else None
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use":
                calls[str(block.get("id"))] = (str(block.get("name")), block.get("input") or {})
            elif block.get("type") == "tool_result":
                results[str(block.get("tool_use_id"))] = result_text(block.get("content"))
    return [ToolUse(tool, args, results.get(i, "")) for i, (tool, args) in calls.items()]


def loaded_instructions(path: Path) -> frozenset[Path]:
    """The project instruction files a session's transcript says it loaded."""
    loaded: set[Path] = set()
    for line in path.read_text().splitlines():
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            continue
        attachment = record.get("attachment") if isinstance(record, dict) else None
        if not isinstance(attachment, dict) or attachment.get("type") != "instructions":
            continue
        for file in attachment.get("files") or []:
            if isinstance(file, dict) and file.get("type") == "Project" and file.get("path"):
                loaded.add(Path(str(file["path"])))
    return frozenset(loaded)


# The message each forbidden action's fence gives, by the check it stands for. A result without it
# shows the action failed for some other reason, which proves nothing about the fence.
REFUSAL_MESSAGES = {
    "read": "Operation not permitted",
    "read-tool": "blockReadsOutsideWorkingDirectories",
    "write-home": "denied by your permission settings",
    "write-outside": "blockWritesOutsideWorkingDirectories",
    "bash-write": "Operation not permitted",
    "network": "deny network-outbound",
}


def judge_canary(
    canary: Canary,
    uses: Sequence[ToolUse],
    reply: str,
    effects: CanaryEffects,
    loaded: frozenset[Path],
) -> CanaryVerdict:
    """The sandbox holds only when each forbidden action was tried, was refused with its fence's
    message and took no effect, both allowed actions worked, no hook ran, and the clone's own
    instructions loaded. A canary that skipped an action, or whose refusal names no fence, shows
    nothing about it, so the replay is refused then too."""

    def tool_on(tool: str, path: Path) -> list[ToolUse]:
        return [u for u in uses if u.tool == tool and u.input.get("file_path") == str(path)]

    def bash_with(*parts: str) -> list[ToolUse]:
        return [
            u
            for u in uses
            if u.tool == "Bash" and all(p in str(u.input.get("command")) for p in parts)
        ]

    forbidden = {
        "read": bash_with(f"cat {canary.secret_file}"),
        "read-tool": tool_on("Read", canary.secret_file),
        "write-home": tool_on("Write", canary.home_write_target),
        "write-outside": tool_on("Write", canary.outside_write_target),
        "bash-write": bash_with(f"touch {canary.bash_target}"),
        "network": bash_with(str(canary.net_target), CANARY_URL),
    }
    allowed = {
        "allowed-write": tool_on("Write", canary.allowed_write_target),
        "gh": bash_with(canary.gh_command),
    }

    breaches: list[tuple[str, str]] = []
    if canary.secret in reply or any(canary.secret in u.result for u in uses):
        breaches.append(("read", f"the secret in {canary.secret_file} reached the session"))
    for check, took_effect, evidence in (
        (
            "write-home",
            effects.home_write_file,
            f"the Write tool created {canary.home_write_target}",
        ),
        (
            "write-outside",
            effects.outside_write_file,
            f"the Write tool created {canary.outside_write_target}",
        ),
        ("bash-write", effects.bash_file, f"Bash created {canary.bash_target}"),
        ("network", effects.net_bytes > 0, f"{CANARY_URL} returned {effects.net_bytes} bytes"),
        (
            "hooks",
            effects.hook_ran,
            f"a hook ran outside the sandbox and touched {canary.hook_marker}",
        ),
    ):
        if took_effect:
            breaches.append((check, evidence))
    if breaches:
        return SandboxBreached(tuple(breaches))

    missing = tuple(p for p in canary.instructions if p not in loaded)
    if missing:
        return ProjectNotLoaded(missing)

    unshown = [
        f"{check}: not attempted" for check, tried in {**forbidden, **allowed}.items() if not tried
    ]
    unshown += [
        f"{check}: tried, but no result shows the refusal ({REFUSAL_MESSAGES[check]})"
        for check, tried in forbidden.items()
        if tried and not any(REFUSAL_MESSAGES[check] in u.result for u in tried)
    ]
    failed = [
        (check, f"tried, and {target} was not created")
        for check, target, worked in (
            ("allowed-write", canary.allowed_write_target, effects.allowed_write_file),
        )
        if allowed[check] and not worked
    ]
    if allowed["gh"] and not effects.gh_served:
        result = allowed["gh"][-1].result.strip() or "no output"
        failed.append(("gh", f"the stand-in served no call ({tail(result)})"))
    if failed:
        return AllowedActionFailed(tuple(failed))
    if unshown:
        return CanaryInconclusive("; ".join(unshown))
    return SandboxHolds()


def explain_canary(
    verdict: SandboxBreached | ProjectNotLoaded | AllowedActionFailed | CanaryInconclusive,
) -> str:
    match verdict:
        case SandboxBreached(checks):
            found = "; ".join(f"{check}: {evidence}" for check, evidence in checks)
            return f"the sandbox canary was not refused ({found}), so the sandbox is not in force."
        case AllowedActionFailed(checks):
            found = "; ".join(f"{check}: {evidence}" for check, evidence in checks)
            return (
                f"the sandbox canary couldn't do what planning needs ({found}), so the replay "
                "would run handicapped and is not run."
            )
        case ProjectNotLoaded(missing):
            listed = ", ".join(str(p) for p in missing)
            return (
                f"the canary session didn't load the clone's own instructions ({listed}), so the "
                "replay would plan without them and is not run."
            )
        case CanaryInconclusive(reason):
            return f"the sandbox canary showed nothing ({reason}), so the replay is not run."
        case _:
            assert_never(verdict)


def describe(refusal: Refusal) -> str:
    match refusal:
        case ReadRefused(path):
            return f"read refused: `{path}`"
        case FileRefused(command, detail):
            return f"file access refused: `{command}`: {detail}"
        case NetworkRefused(host):
            return f"connection refused: `{host}`"
        case GhRefused(args):
            return f"`gh` call refused: `gh {args}`"
        case ToolDenied(tool, detail):
            return f"tool denied: `{tool}` {detail}"
        case _:
            assert_never(refusal)


def render_audit(audit: Audit | AuditIncomplete) -> str:
    match audit:
        case AuditIncomplete(reason):
            return f"# Audit\n\nIncomplete: {reason}, so what the session was refused is unknown.\n"
        case Audit(refusals, transcripts_read, unreadable_lines):
            counts: dict[str, int] = {}
            for refusal in refusals:
                counts[describe(refusal)] = counts.get(describe(refusal), 0) + 1
            lines = [f"- {text} ({n}×)" if n > 1 else f"- {text}" for text, n in counts.items()]
            body = "\n".join(lines) if lines else "Nothing was refused."
            return (
                f"# Audit\n\nRead {transcripts_read} transcripts; {unreadable_lines} lines couldn't "
                f"be read.\n\n{body}\n"
            )
        case _:
            assert_never(audit)


# ── Grades ─────────────────────────────────────────────────────────────────────────────────────


STAGES = ("approach", "design", "escalation")


def grade_template(ref: TicketRef, run: int) -> str:
    verdicts = ", ".join(v.value for v in Verdict)
    return (
        f"# Grade for {ref}, run {run}\n\n"
        "approach:\n"
        "design:\n"
        "escalation:\n"
        "excluded:\n\n"
        f"Write a verdict after each colon that applies: {verdicts}. A replay that planned gets "
        "`approach` and `design`: compare `approach.md` and `design.md` with `mine/approach.md` "
        "and `mine/design.md`. One that escalated gets `escalation`, for whether escalating was "
        "right and whether its options and recommendation are good, and `approach` too if it posted "
        "one first: the escalation is in `extra/`. Read `audit.md` for anything the replay was "
        "refused. To leave the replay out of the tally, write why after `excluded:`.\n\n"
        "## Missed\n\nWhat the replay missed.\n\n"
        "## Found\n\nAnything it found that I didn't.\n"
    )


def parse_grade(text: str) -> Grade:
    for line in text.splitlines():
        if line.startswith("excluded:") and line.removeprefix("excluded:").strip():
            return Excluded(line.removeprefix("excluded:").strip())
    values: dict[str, str] = {}
    for line in text.splitlines():
        for stage in STAGES:
            if stage not in values and line.startswith(f"{stage}:"):
                values[stage] = line.removeprefix(f"{stage}:").strip()
    if "approach" not in values or "design" not in values:
        return GradeUnreadable("the `approach:` or `design:` line is missing")
    if "escalation" not in values:
        return GradeUnreadable("the `escalation:` line is missing")
    if not any(values.values()):
        return Ungraded()
    known = {v.value: v for v in Verdict}
    problems = [
        f"{stage}: '{value}' is not a verdict"
        for stage, value in values.items()
        if value and value not in known
    ]
    if problems:
        return GradeUnreadable("; ".join(problems))
    filled = tuple(stage for stage in STAGES if values[stage])
    if filled not in (("approach", "design"), ("escalation",), ("approach", "escalation")):
        return GradeUnreadable(
            f"{' and '.join(filled)} graded: a plan needs approach and design, and an escalation "
            "needs escalation, with approach if it posted one"
        )
    return Graded(
        known.get(values["approach"]), known.get(values["design"]), known.get(values["escalation"])
    )


def grade_of_run(meta_text: str | None, grade_text: str | None) -> Grade:
    """A run's grade, read from its `meta.json` first: a run whose session didn't finish has
    nothing to grade, whatever its `grade.md` says."""
    try:
        meta = json.loads(meta_text) if meta_text is not None else None
    except json.JSONDecodeError:
        meta = None
    if not isinstance(meta, dict):
        return Unfinished("meta.json is missing or unreadable")
    if "finished_at" not in meta:
        return Unfinished("the run never finished")
    outcome = meta.get("outcome")
    if outcome not in ("Planned", "Escalated"):
        return Unfinished(f"the session ended as {outcome}")
    if grade_text is None:
        return GradeUnreadable("grade.md is missing")
    return parse_grade(grade_text)


def summarize(grades: Sequence[tuple[Path, Grade]]) -> str:
    graded = [g for _, g in grades if isinstance(g, Graded)]
    excluded = [(p, g) for p, g in grades if isinstance(g, Excluded)]
    unfinished = [(p, g) for p, g in grades if isinstance(g, Unfinished)]
    lines = [
        f"{len(grades)} replays: {len(graded)} graded, {len(excluded)} excluded, "
        f"{len(unfinished)} unfinished, "
        f"{sum(isinstance(g, Ungraded) for _, g in grades)} ungraded, "
        f"{sum(isinstance(g, GradeUnreadable) for _, g in grades)} unreadable"
    ]
    for stage in STAGES:
        counts = [sum(getattr(g, stage) is v for g in graded) for v in Verdict]
        parts = ", ".join(f"{n} {v.value}" for n, v in zip(counts, Verdict, strict=True))
        lines.append(f"{stage}: {parts}")
    if excluded:
        lines += ["Excluded:", *(f"  {p}: {g.reason}" for p, g in excluded)]
    if unfinished:
        lines += ["Unfinished:", *(f"  {p}: {g.reason}" for p, g in unfinished)]
    ungraded = [str(p) for p, g in grades if isinstance(g, Ungraded)]
    if ungraded:
        lines += ["Ungraded:", *(f"  {p}" for p in ungraded)]
    unreadable = [f"  {p}: {g.reason}" for p, g in grades if isinstance(g, GradeUnreadable)]
    if unreadable:
        lines += ["Unreadable:", *unreadable]
    return "\n".join(lines)


# ── I/O edges ──────────────────────────────────────────────────────────────────────────────────


def state_root() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
    return Path(base) / "replays"


def projects_root() -> Path:
    config = os.environ.get("CLAUDE_CONFIG_DIR") or str(Path.home() / ".claude")
    return Path(config) / "projects"


def run_gh(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["gh", *args], capture_output=True, text=True, check=False, timeout=CALL_TIMEOUT_SECONDS
    )


def fetch_ticket(ref: TicketRef) -> object | GitHubUnreadable:
    issue = run_gh(
        "api",
        "graphql",
        "-f",
        f"query={ISSUE_QUERY}",
        "-F",
        f"o={ref.owner}",
        "-F",
        f"r={ref.repo}",
        "-F",
        f"n={ref.number}",
    )
    if issue.returncode != 0:
        return GitHubUnreadable((f"the issue query failed: {issue.stderr.strip()}",))
    try:
        return json.loads(issue.stdout)
    except json.JSONDecodeError as error:
        return GitHubUnreadable((f"the issue query returned no JSON: {error}",))


def readable_dirs(home: Path) -> tuple[Path, ...]:
    found: list[Path] = []
    for relative in TOOLCHAINS:
        path = home / relative
        if not path.exists():
            continue
        found.append(path)
        # A link inside, such as ~/.config/git/config, is read at the folder it points into.
        links = [c for c in path.iterdir() if c.is_symlink()] if path.is_dir() else []
        for target in (link.resolve().parent for link in [path, *links] if link.is_symlink()):
            if target not in found:
                found.append(target)
    return tuple(found)


def harness_dirs(home: Path) -> tuple[Path, ...]:
    dirs = [DOTFILES / "tools" / "agents" / "config", DOTFILES / "tools" / "claude" / "config"]
    # `~/.agents` holds only the skills and standards links, so Bash may read through it. Bash can't
    # read through the links in `~/.claude`, since allowing that folder would expose every
    # transcript in `~/.claude/projects`; the Read tool reaches them as working directories instead.
    links = (".claude/skills", ".claude/standards", ".agents")
    dirs += [home / link for link in links if (home / link).exists()]
    return tuple(dirs)


def harness_version(watched: Sequence[str]) -> dict[str, object]:
    commit = git(DOTFILES, "rev-parse", "HEAD").stdout.strip()
    # Dirty means uncommitted edits in any path the session reads as it is today.
    dirty = git(DOTFILES, "status", "--porcelain", "--", *watched).stdout.strip()
    try:
        version = subprocess.run(
            ["claude", "--version"], capture_output=True, text=True, check=False, timeout=60
        ).stdout.strip()
    except (OSError, subprocess.TimeoutExpired) as error:
        version = f"unknown: {error}"
    return {"dotfiles_commit": commit, "harness_dirty": bool(dirty), "claude_version": version}


def ticket_markdown(snapshot: PlanningSnapshot, base: Sha) -> str:
    return (
        f"# {snapshot.title}\n\n"
        f"What the replay was served for {snapshot.ref}: the title and body as they stood when "
        f"planning began ({snapshot.planning_began.isoformat()}), with no comments but the ones "
        f"the replay posted, on a clone at `{base}`.\n\n"
        f"---\n\n{snapshot.body}\n"
    )


def session_command(
    settings: Path, readable: Sequence[Path], prompt: str, model: str | None = None
) -> list[str]:
    command = ["claude", "-p", "--settings", str(settings), "--setting-sources", "user,project"]
    command += ["--permission-mode", "dontAsk"]
    if model is not None:
        command += ["--model", model]
    for folder in readable:
        command += ["--add-dir", str(folder)]
    command += ["--strict-mcp-config", "--disallowedTools", "WebFetch", "WebSearch"]
    return [*command, "--output-format", "json", prompt]


def session_env(bin_dir: Path, scratch: Path, claude_tmp: Path) -> dict[str, str]:
    env = {k: v for k, v in os.environ.items() if k not in UNSET_FOR_SESSION}
    env["PATH"] = f"{bin_dir}{os.pathsep}{env.get('PATH', '')}"
    env["CLAUDE_CODE_ENTRYPOINT"] = ENTRYPOINT
    env["TMPDIR"] = str(scratch)
    # Claude Code keeps its own temp files, the sandbox's $TMPDIR and the session's scratchpad here,
    # rather than under /tmp/claude-<uid>, which the sandbox can't read. The path is kept short,
    # since the sandbox falls back to /tmp when it is long.
    env["CLAUDE_CODE_TMPDIR"] = str(claude_tmp)
    # npm's own cache, in the home folder, is outside what the sandbox lets Bash write.
    env["npm_config_cache"] = str(scratch / "npm-cache")
    return env


class Signalled(Exception):
    """SIGTERM or SIGHUP arrived. Raised from the handler so the run can record it and clean up,
    as Ctrl-C's KeyboardInterrupt already does."""

    def __init__(self, signum: int) -> None:
        super().__init__(signal.Signals(signum).name)
        self.name = signal.Signals(signum).name


def raise_signalled(signum: int, _frame: object) -> None:
    raise Signalled(signum)


def run_session(
    command: Sequence[str], clone: Path, env: Mapping[str, str]
) -> tuple[SessionResult | SessionFailed | Interrupted, str, str]:
    """Run the session. A signal stops it (subprocess.run kills `claude` on the way out) and is
    returned as Interrupted, so what the session captured is still collected."""
    try:
        done = subprocess.run(
            list(command),
            cwd=clone,
            env=dict(env),
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
            check=False,
            timeout=SESSION_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as error:
        stderr = error.stderr.decode() if isinstance(error.stderr, bytes) else (error.stderr or "")
        hours = SESSION_TIMEOUT_SECONDS // 3600
        return (
            SessionFailed(None, f"the session ran longer than {hours} hours", tail(stderr)),
            "",
            stderr,
        )
    except KeyboardInterrupt:
        return Interrupted("SIGINT"), "", ""
    except Signalled as stopped:
        return Interrupted(stopped.name), "", ""
    return parse_session_result(done.returncode, done.stdout, done.stderr), done.stdout, done.stderr


def run_canary(
    canary: Canary,
    settings: Path,
    readable: Sequence[Path],
    clone: Path,
    env: Mapping[str, str],
    gh_log: Path,
) -> CanaryVerdict:
    """Run the canary as a short session with the replay's own settings and flags, and judge it by
    what it left behind. Its secret, its targets and the stand-in's log of its `gh` call are
    removed afterwards, whatever the verdict, so the session's own log holds only its calls."""
    canary.secret_file.parent.mkdir(parents=True, exist_ok=True)
    canary.secret_file.write_text(canary.secret)
    command = session_command(settings, readable, canary.prompt(), model="haiku")
    check_command(command)
    try:
        try:
            done = subprocess.run(
                command,
                cwd=clone,
                env=dict(env),
                stdin=subprocess.DEVNULL,
                capture_output=True,
                text=True,
                check=False,
                timeout=CANARY_TIMEOUT_SECONDS,
            )
        except subprocess.TimeoutExpired:
            return CanaryInconclusive(f"it ran longer than {CANARY_TIMEOUT_SECONDS} seconds")
        result = parse_session_result(done.returncode, done.stdout, done.stderr)
        if isinstance(result, SessionFailed):
            return CanaryInconclusive(f"{result.reason}: {result.stderr_tail}")
        transcripts = sorted(projects_root().glob(f"*/{result.session_id}.jsonl"))
        if not transcripts:
            return CanaryInconclusive(f"no transcript was found for session {result.session_id}")
        net = canary.net_target
        effects = CanaryEffects(
            home_write_file=canary.home_write_target.exists(),
            outside_write_file=canary.outside_write_target.exists(),
            bash_file=canary.bash_target.exists(),
            net_bytes=net.stat().st_size if net.exists() else 0,
            hook_ran=canary.hook_marker.exists(),
            allowed_write_file=canary.allowed_write_target.exists(),
            gh_served=gh_view_served(gh_log),
        )
        transcript = transcripts[0]
        return judge_canary(
            canary,
            transcript_uses(transcript),
            result.final_text,
            effects,
            loaded_instructions(transcript),
        )
    finally:
        targets = (
            canary.home_write_target,
            canary.outside_write_target,
            canary.bash_target,
            canary.net_target,
            canary.allowed_write_target,
        )
        for path in (canary.secret_file, *targets, gh_log):
            path.unlink(missing_ok=True)


def gh_view_served(gh_log: Path) -> bool:
    """Whether the stand-in logged a served `issue view`, which shows it ran inside the sandbox."""
    if not gh_log.exists():
        return False
    for line in gh_log.read_text().splitlines():
        try:
            call = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(call, dict) and call.get("served") is True:
            args = call.get("args")
            if isinstance(args, list) and args[:2] == ["issue", "view"]:
                return True
    return False


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def plan(ref: TicketRef, run: int, source: Path, branch: str) -> int:
    # Closing the terminal or a `kill` would otherwise end the process without the cleanup below.
    for stop in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(stop, raise_signalled)
    folder = state_root() / ref.slug / f"run-{run}"
    if folder.exists():
        raise SystemExit(
            f"replay: {folder} already exists, and a replay folder is never rewritten."
        )
    if not (source / ".git").exists():
        raise SystemExit(
            f"replay: {source} is not a git checkout. Pass --source with one of {ref.name_with_owner}."
        )

    fetched = fetch_ticket(ref)
    if isinstance(fetched, GitHubUnreadable):
        raise SystemExit(f"replay: {explain(fetched)}")
    history = parse_history(ref, fetched)
    if not isinstance(history, TicketHistory):
        raise SystemExit(f"replay: {explain(history)}")
    snapshot = cut_at_planning(history)
    if isinstance(snapshot, BodyUnknown):
        raise SystemExit(f"replay: {explain(snapshot)}")
    home = Path.home()
    toolchains = readable_dirs(home)
    watched = watched_paths(DOTFILES, toolchains)
    later = later_harness_commits(DOTFILES, ticket_pattern(ref), snapshot.planning_began, watched)
    if isinstance(later, HarnessHistoryUnreadable):
        raise SystemExit(f"replay: {explain(later)}")
    named = check_later_harness(later, files_changed(DOTFILES, later), watched)
    if named is not None:
        raise SystemExit(f"replay: {explain(named)}")
    base = resolve_base(source, branch, snapshot.planning_began)
    if isinstance(base, BaseNotFound):
        raise SystemExit(f"replay: {explain(base)}")

    short_tmp = Path("/private/tmp") if Path("/private/tmp").is_dir() else Path("/tmp")
    work = Path(tempfile.mkdtemp(prefix="rp-", dir=short_tmp)).resolve()
    paths = SandboxPaths(
        home=home,
        tmp_root=Path(tempfile.gettempdir()).resolve(),
        work=work,
        clone=work / "clone",
        capture=work / "capture",
        scratch=work / "scratch",
        claude_tmp=work / "t",
        hook_marker=work / "hook-ran",
        harness=harness_dirs(home),
        toolchains=toolchains,
    )
    try:
        paths.capture.mkdir()
        paths.scratch.mkdir()
        paths.claude_tmp.mkdir()
        settings = build_settings(paths)
        check_settings(settings, paths)
        settings_file = work / "settings.json"
        settings_file.write_text(json.dumps(settings, indent=2))
        write_stand_in(work / "bin", snapshot, paths.capture)
        write_mktemp(work / "bin")
        make_clone(source, base, paths.clone)
        check_clone(paths.clone, snapshot.planning_began)
        widening = check_project_settings(paths.clone)
        if widening is not None:
            raise SystemExit(f"replay: {explain(widening)}")
        readable = (*paths.harness, paths.scratch, paths.claude_tmp)
        env = session_env(work / "bin", paths.scratch, paths.claude_tmp)
        nonce = secrets.token_hex(4)
        canary = Canary(
            secret=secrets.token_hex(16),
            secret_file=state_root() / f".canary-{nonce}",
            home_write_target=home / f".replay-canary-{nonce}-write",
            # Beside the work folder, so outside every folder the session works in.
            outside_write_target=work.parent / f"{work.name}-canary-{nonce}-write",
            bash_target=home / f".replay-canary-{nonce}-bash",
            net_target=paths.scratch / f"canary-{nonce}-net",
            allowed_write_target=paths.scratch / f"canary-{nonce}-allowed",
            gh_command=f"gh issue view {ref.number} -R {ref.owner}/{ref.repo} --json title",
            instructions=project_instructions(paths.clone),
            hook_marker=paths.hook_marker,
        )
        gh_log = paths.capture / "gh-calls.log"
        verdict = run_canary(canary, settings_file, readable, paths.clone, env, gh_log)
        if not isinstance(verdict, SandboxHolds):
            raise SystemExit(f"replay: {explain_canary(verdict)}")
        command = session_command(settings_file, readable, f"/plan-unattended {ref} plan-only")
        check_command(command)
        folder.mkdir(parents=True)

        write(folder / "ticket.md", ticket_markdown(snapshot, base))
        write(folder / "mine" / "approach.md", history.approach.body)
        write(folder / "mine" / "design.md", history.design.body)
        write(folder / "grade.md", grade_template(ref, run))
        meta: dict[str, object] = {
            "ticket": str(ref),
            "run": run,
            "base": base,
            "planning_began": snapshot.planning_began.isoformat(),
            "entrypoint": ENTRYPOINT,
            "started_at": datetime.now(UTC).isoformat(),
            "canary": {"verdict": type(verdict).__name__},
            "session_command": command,
            **harness_version(watched),
        }
        write(folder / "meta.json", json.dumps(meta, indent=2))

        result, stdout, stderr = run_session(command, paths.clone, env)
        write(folder / "result.json", stdout)
        write(folder / "stderr.log", stderr)
        gh_log_path = paths.capture / "gh-calls.log"
        gh_log = gh_log_path.read_text() if gh_log_path.exists() else ""
        write(folder / "gh-calls.log", gh_log)

        captured = sort_comments(paths.capture)
        if captured.approach is not None:
            write(folder / "approach.md", captured.approach)
        if captured.design is not None:
            write(folder / "design.md", captured.design)
        for i, body in enumerate(captured.extra, start=1):
            write(folder / "extra" / f"comment-{i}.md", body)

        match result:
            case SessionResult():
                outcome = outcome_of(result)
                audit = read_audit(
                    result.session_id,
                    projects_root(),
                    result.permission_denials,
                    gh_log.splitlines(),
                )
                meta["session_id"] = result.session_id
                meta["duration_ms"] = result.duration_ms
                meta["tokens_by_model"] = [t.__dict__ for t in result.tokens_by_model]
            case SessionFailed():
                outcome = result
                audit = AuditIncomplete("the session left no result to find its transcript by")
            case Interrupted(name):
                outcome = result
                audit = AuditIncomplete(f"the session was interrupted by {name}")
            case _:
                assert_never(result)
        write(folder / "audit.md", render_audit(audit))
        meta["finished_at"] = datetime.now(UTC).isoformat()
        meta["outcome"] = type(outcome).__name__
        write(folder / "meta.json", json.dumps(meta, indent=2))
    finally:
        shutil.rmtree(work, ignore_errors=True)

    match outcome:
        case Planned(line) | Escalated(line):
            print(f"{line}\nReplay folder: {folder}")
            return 0
        case SessionFailed(exit_code, reason, stderr_tail):
            print(
                f"replay: the session failed ({reason}, exit {exit_code}):\n{stderr_tail}",
                file=sys.stderr,
            )
            print(f"Replay folder: {folder}", file=sys.stderr)
            return 1
        case Interrupted(name):
            print(f"replay: the session was interrupted by {name}.", file=sys.stderr)
            print(f"Replay folder: {folder}", file=sys.stderr)
            return 128 + signal.Signals[name].value
        case _:
            assert_never(outcome)


def grades() -> int:
    found: list[tuple[Path, Grade]] = []
    root = state_root()
    for run_dir in sorted(root.glob("*/run-*")):
        meta_file, grade_file = run_dir / "meta.json", run_dir / "grade.md"
        grade = grade_of_run(
            meta_file.read_text() if meta_file.exists() else None,
            grade_file.read_text() if grade_file.exists() else None,
        )
        found.append((run_dir.relative_to(root), grade))
    print(summarize(found))
    return 0


def main(argv: Sequence[str]) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    commands = parser.add_subparsers(dest="command", required=True)
    plan_parser = commands.add_parser("plan", help="replay planning on a ticket I already planned")
    plan_parser.add_argument("ticket", help="owner/repo#number")
    plan_parser.add_argument("--run", type=int, required=True, help="run number, 1 or more")
    plan_parser.add_argument("--source", type=Path, help="local checkout of the ticket's repo")
    plan_parser.add_argument("--branch", default="main", help="the default branch (main)")
    commands.add_parser("grades", help="summarize every grade so far")
    args = parser.parse_args(argv)

    if args.command == "grades":
        return grades()
    ref = parse_ticket_ref(args.ticket)
    problems = []
    if ref is None:
        problems.append(f"'{args.ticket}' is not a ticket like owner/repo#123")
    if args.run < 1:
        problems.append(f"--run must be 1 or more, not {args.run}")
    if problems or ref is None:
        raise SystemExit("replay: " + "; ".join(problems))
    source = args.source or Path.home() / "Repos" / ref.owner / ref.repo
    branch: str = args.branch
    return plan(ref, args.run, source, branch)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
