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
- a `gh` stand-in that serves the ticket body as it stood then, with no comments and no parent, and
  saves the comments the skill tries to post
- Claude Code's sandbox with no network except package registries, Bash reads of the home and temp
  folders confined to an allow-list, the Read tool confined to the working directories, and web
  tools and MCP servers off

Two things are as they are today, not as they were: the agent harness (global instructions, skills,
standards), which is why a dotfiles ticket that changed it is refused, and the hooks in the user's
Claude Code settings, which run outside the sandbox and post nothing.

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
session failed.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
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
HARNESS_REPO = ("ooloth", "dotfiles")
HARNESS_PATHS = ("tools/claude/config/", "tools/agents/config/")
REGISTRIES = (
    "pypi.org",
    "files.pythonhosted.org",
    "crates.io",
    "index.crates.io",
    "static.crates.io",
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
class TicketHistory:
    ref: TicketRef
    title: str
    body: str
    body_edits: tuple[BodyEdit, ...]
    approach: Comment
    design: Comment
    linked_commits: tuple[Sha, ...]


@dataclass(frozen=True)
class PlanningSnapshot:
    """What the replay may see: the ticket as it stood when planning began, with no comments."""

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
class TouchesHarness:
    files: tuple[str, ...]


@dataclass(frozen=True)
class CommitMissing:
    sha: Sha


@dataclass(frozen=True)
class BaseNotFound:
    before: datetime


@dataclass(frozen=True)
class GitHubUnreadable:
    problems: tuple[str, ...]


NotReplayable = (
    NoApproachComment
    | NoDesignComment
    | BodyUnknown
    | TouchesHarness
    | CommitMissing
    | BaseNotFound
    | GitHubUnreadable
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


SessionOutcome = Planned | Escalated | SessionFailed


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


Grade = Graded | Ungraded | GradeUnreadable


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


class _Issue(BaseModel):
    title: str
    body: str
    comments: _Comments
    userContentEdits: _Edits


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


def parse_history(
    ref: TicketRef, payload: object, commit_ids: Sequence[str]
) -> TicketHistory | NotReplayable:
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
        body=issue.body,
        body_edits=tuple(edits),
        approach=Comment(approach.createdAt, approach.body),
        design=Comment(design.createdAt, design.body),
        linked_commits=tuple(Sha(c) for c in commit_ids),
    )


def cut_at_planning(history: TicketHistory) -> PlanningSnapshot | BodyUnknown:
    """Keep only what existed when planning began: the title and the body as it stood then."""
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
    return PlanningSnapshot(history.ref, history.title, body, began)


def check_harness(
    ref: TicketRef, linked: Sequence[Sha], files_of: Mapping[Sha, tuple[str, ...] | None]
) -> TouchesHarness | CommitMissing | None:
    """Refuse a dotfiles ticket whose commits changed the harness: every session loads today's
    harness, which already holds those changes. Only commits the ticket's timeline links are checked."""
    if (ref.owner, ref.repo) != HARNESS_REPO:
        return None
    touched: set[str] = set()
    for sha in linked:
        files = files_of.get(sha)
        if files is None:
            return CommitMissing(sha)
        touched.update(f for f in files if f.startswith(HARNESS_PATHS))
    return TouchesHarness(tuple(sorted(touched))) if touched else None


def explain(reason: NotReplayable) -> str:
    match reason:
        case NoApproachComment():
            return "The ticket has no comment starting with `# Approach`, so there is nothing to grade against."
        case NoDesignComment():
            return "The ticket has no comment starting with `# Design`, so there is nothing to grade against."
        case BodyUnknown(began):
            return f"No version of the ticket body is dated at or before planning began ({began.isoformat()})."
        case TouchesHarness(files):
            listed = "\n".join(f"  {f}" for f in files)
            return (
                "The ticket's commits changed the agent harness, which every session loads as it "
                f"is today, so a replay would see the answer:\n{listed}"
            )
        case CommitMissing(sha):
            return f"Commit {sha}, which the ticket links, is not in the local checkout. Pull it and try again."
        case BaseNotFound(before):
            return f"The default branch has no commit at or before {before.isoformat()}."
        case GitHubUnreadable(problems):
            return "GitHub's answer couldn't be read in full:\n" + "\n".join(
                f"  {p}" for p in problems
            )
        case _:
            assert_never(reason)


# ── Git ────────────────────────────────────────────────────────────────────────────────────────


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True,
        text=True,
        check=False,
        timeout=CALL_TIMEOUT_SECONDS,
    )


def files_changed(source: Path, shas: Sequence[Sha]) -> dict[Sha, tuple[str, ...] | None]:
    found: dict[Sha, tuple[str, ...] | None] = {}
    for sha in shas:
        shown = git(
            source, "diff-tree", "-r", "-m", "--first-parent", "--no-commit-id", "--name-only", sha
        )
        found[sha] = tuple(shown.stdout.split()) if shown.returncode == 0 else None
    return found


def resolve_base(source: Path, branch: str, before: datetime) -> Sha | BaseNotFound:
    """The newest commit on `branch` committed at or before `before`."""
    listed = git(source, "rev-list", "-n1", f"--before={before.isoformat()}", branch)
    sha = listed.stdout.strip()
    if listed.returncode != 0 or not sha:
        return BaseNotFound(before)
    committed = datetime.fromisoformat(
        git(source, "show", "-s", "--format=%cI", sha).stdout.strip()
    )
    assert committed <= before, f"base {sha} was committed after planning began"
    ancestor = git(source, "merge-base", "--is-ancestor", sha, branch)
    assert ancestor.returncode == 0, f"base {sha} is not on {branch}"
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


# ── The gh stand-in ────────────────────────────────────────────────────────────────────────────

# Runs inside the sandbox, under whichever python3 is on PATH, so it uses only the standard
# library and Python 3.9 syntax, and `jq` from PATH for --jq. It serves the ticket as it stood when
# planning began plus the comments this replay posted, since a skill reads back what it posts.
STAND_IN = r'''#!/usr/bin/env python3
"""gh for a replay: serves one ticket as it stood when planning began, plus the comments this
replay posts, and saves those comments instead of posting them."""
import datetime
import glob
import json
import os
import subprocess
import sys

CONFIG = __CONFIG__
cfg = json.load(open(CONFIG))
args = sys.argv[1:]
capture = cfg["capture"]
url = "https://github.com/" + cfg["repo"] + "/issues/" + str(cfg["number"])


def log(served):
    with open(capture + "/gh-calls.log", "a") as f:
        f.write(json.dumps({"args": args, "served": served}) + "\n")


def refuse():
    log(False)
    sys.stderr.write("gh: unavailable in replay: " + " ".join(args) + "\n")
    sys.exit(1)


def option(names):
    for i, a in enumerate(args):
        for n in names:
            if a == n and i + 1 < len(args):
                return args[i + 1]
            if a.startswith(n + "="):
                return a[len(n) + 1:]
    return None


def emit(data):
    """Print as gh does: JSON, or the result of --jq, which gh prints the way `jq -r` does."""
    log(True)
    query = option(["-q", "--jq"])
    if query is None:
        print(json.dumps(data))
        return
    done = subprocess.run(["jq", "-r", query], input=json.dumps(data), text=True)
    sys.exit(done.returncode)


def posted():
    """The comments this replay has posted, oldest first, each with the time it was saved."""
    found = []
    for path in sorted(glob.glob(capture + "/comment-*.md")):
        at = datetime.datetime.fromtimestamp(os.path.getmtime(path), datetime.timezone.utc)
        n = int(path.rsplit("-", 1)[1].split(".")[0])
        found.append(
            {
                "body": open(path).read(),
                "createdAt": at.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "url": url + "#issuecomment-replay-%d" % n,
            }
        )
    return found


def is_this_ticket(target):
    prefix = "https://github.com/"
    if target.startswith(prefix):
        parts = target[len(prefix):].split("/")
        if len(parts) != 4 or parts[2] != "issues":
            return False
        return parts[0] + "/" + parts[1] == cfg["repo"] and parts[3] == str(cfg["number"])
    return target.lstrip("#") == str(cfg["number"]) and option(["-R", "--repo"]) == cfg["repo"]


def view():
    if option(["-t", "--template"]) is not None:
        refuse()
    fields = option(["--json"])
    if fields is None:
        log(True)
        print(cfg["title"] + "\n\n" + cfg["body"])
        return
    owner = {"login": cfg["repo"].split("/")[0]}
    ticket = {
        "number": cfg["number"],
        "title": cfg["title"],
        "body": cfg["body"],
        "comments": [dict(c, author=owner) for c in posted()],
        "parent": None,
        "state": "OPEN",
        "labels": [],
        "url": url,
    }
    wanted = fields.split(",")
    if any(f not in ticket for f in wanted):
        refuse()
    emit({f: ticket[f] for f in wanted})


def comment():
    path = option(["--body-file", "-F"])
    if path == "-":
        body = sys.stdin.read()
    elif path is not None:
        body = open(path).read()
    else:
        body = option(["--body", "-b"])
    if body is None:
        refuse()
    n = len(glob.glob(capture + "/comment-*.md")) + 1
    with open(capture + "/comment-%03d.md" % n, "w") as f:
        f.write(body)
    log(True)
    print(url + "#issuecomment-replay-%d" % n)


def api():
    """The two read-only endpoints a skill uses to check its own comments, for this ticket only."""
    writes = ("-X", "--method", "-f", "-F", "--field", "--raw-field", "--input")
    if any(a in writes or a.startswith(tuple(w + "=" for w in writes)) for a in args[1:]):
        refuse()
    takes_value = ("-q", "--jq", "-H", "--header", "-t", "--template", "--cache")
    endpoints = []
    skip = False
    for a in args[1:]:
        if skip:
            skip = False
        elif a in takes_value:
            skip = True
        elif not a.startswith("-"):
            endpoints.append(a.lstrip("/"))
    base = "repos/" + cfg["repo"] + "/issues/" + str(cfg["number"])
    owner = {"login": cfg["repo"].split("/")[0]}
    comments = [
        {"body": c["body"], "created_at": c["createdAt"], "user": owner, "html_url": c["url"]}
        for c in posted()
    ]
    if endpoints == [base + "/comments"]:
        emit(comments)
    elif endpoints == [base]:
        emit(
            {
                "number": cfg["number"],
                "title": cfg["title"],
                "body": cfg["body"],
                "state": "open",
                "comments": len(comments),
                "html_url": url,
            }
        )
    else:
        refuse()


if args[:2] == ["issue", "view"] and len(args) > 2 and is_this_ticket(args[2]):
    view()
elif args[:2] == ["issue", "comment"] and len(args) > 2 and is_this_ticket(args[2]):
    comment()
elif args[:1] == ["api"]:
    api()
else:
    refuse()
'''


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
    gh = bin_dir / "gh"
    gh.write_text(STAND_IN.replace("__CONFIG__", repr(str(config))))
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
                *(f"{tool}(/{folder}/**)" for folder in editable for tool in ("Edit", "Write")),
            ],
            "deny": ["WebFetch", "WebSearch"],
            "blockReadsOutsideWorkingDirectories": True,
        },
    }


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


def classify(text: str, tool: str, tool_input: Mapping[str, Any]) -> list[Refusal]:
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
            elif block.get("type") == "tool_result" and block.get("is_error"):
                use_id = str(block.get("tool_use_id"))
                tool, tool_input = uses.get(use_id, ("", {}))
                found = classify(result_text(block.get("content")), tool, tool_input)
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
        if not call.get("served"):
            refused_gh = GhRefused(" ".join(call.get("args", [])))
            if refused_gh not in refusals:
                refusals.append(refused_gh)
    return Audit(tuple(refusals), len(files), unreadable)


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
        "escalation:\n\n"
        f"Write a verdict after each colon that applies: {verdicts}. A replay that planned gets "
        "`approach` and `design`: compare `approach.md` and `design.md` with `mine/approach.md` "
        "and `mine/design.md`. One that escalated gets `escalation`, for whether escalating was "
        "right and whether its options and recommendation are good, and `approach` too if it posted "
        "one first: the escalation is in `extra/`. Read `audit.md` for anything the replay was "
        "refused.\n\n"
        "## Missed\n\nWhat the replay missed.\n\n"
        "## Found\n\nAnything it found that I didn't.\n"
    )


def parse_grade(text: str) -> Grade:
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


def summarize(grades: Sequence[tuple[Path, Grade]]) -> str:
    graded = [g for _, g in grades if isinstance(g, Graded)]
    lines = [
        f"{len(grades)} replays: {len(graded)} graded, "
        f"{sum(isinstance(g, Ungraded) for _, g in grades)} ungraded, "
        f"{sum(isinstance(g, GradeUnreadable) for _, g in grades)} unreadable"
    ]
    for stage in STAGES:
        counts = [sum(getattr(g, stage) is v for g in graded) for v in Verdict]
        parts = ", ".join(f"{n} {v.value}" for n, v in zip(counts, Verdict, strict=True))
        lines.append(f"{stage}: {parts}")
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


def fetch_ticket(ref: TicketRef) -> tuple[object, list[str]] | GitHubUnreadable:
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
    timeline = run_gh(
        "api",
        f"repos/{ref.name_with_owner}/issues/{ref.number}/timeline",
        "--paginate",
        "--jq",
        ".[] | select(.commit_id != null) | .commit_id",
    )
    if timeline.returncode != 0:
        return GitHubUnreadable((f"the timeline query failed: {timeline.stderr.strip()}",))
    try:
        payload = json.loads(issue.stdout)
    except json.JSONDecodeError as error:
        return GitHubUnreadable((f"the issue query returned no JSON: {error}",))
    return payload, list(dict.fromkeys(timeline.stdout.split()))


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


def harness_version() -> dict[str, object]:
    commit = git(DOTFILES, "rev-parse", "HEAD").stdout.strip()
    dirty = git(DOTFILES, "status", "--porcelain", "--", *HARNESS_PATHS).stdout.strip()
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
        f"What the replay was served for {snapshot.ref}: the body as it stood when planning began "
        f"({snapshot.planning_began.isoformat()}), with no comments, on a clone at `{base}`.\n\n"
        f"---\n\n{snapshot.body}\n"
    )


def session_command(settings: Path, readable: Sequence[Path], ref: TicketRef) -> list[str]:
    command = ["claude", "-p", "--settings", str(settings), "--permission-mode", "dontAsk"]
    for folder in readable:
        command += ["--add-dir", str(folder)]
    command += ["--strict-mcp-config", "--disallowedTools", "WebFetch", "WebSearch"]
    return [*command, "--output-format", "json", f"/plan-unattended {ref} plan-only"]


def session_env(bin_dir: Path, scratch: Path, claude_tmp: Path) -> dict[str, str]:
    env = {k: v for k, v in os.environ.items() if k not in UNSET_FOR_SESSION}
    env["PATH"] = f"{bin_dir}{os.pathsep}{env.get('PATH', '')}"
    env["CLAUDE_CODE_ENTRYPOINT"] = ENTRYPOINT
    env["TMPDIR"] = str(scratch)
    # Claude Code keeps its own temp files, the sandbox's $TMPDIR and the session's scratchpad here,
    # rather than under /tmp/claude-<uid>, which the sandbox can't read. The path is kept short,
    # since the sandbox falls back to /tmp when it is long.
    env["CLAUDE_CODE_TMPDIR"] = str(claude_tmp)
    return env


def run_session(
    command: Sequence[str], clone: Path, env: Mapping[str, str]
) -> tuple[SessionResult | SessionFailed, str, str]:
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
    return parse_session_result(done.returncode, done.stdout, done.stderr), done.stdout, done.stderr


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def plan(ref: TicketRef, run: int, source: Path, branch: str) -> int:
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
    payload, commit_ids = fetched
    history = parse_history(ref, payload, commit_ids)
    if not isinstance(history, TicketHistory):
        raise SystemExit(f"replay: {explain(history)}")
    snapshot = cut_at_planning(history)
    if isinstance(snapshot, BodyUnknown):
        raise SystemExit(f"replay: {explain(snapshot)}")
    refused = check_harness(
        ref, history.linked_commits, files_changed(source, history.linked_commits)
    )
    if refused is not None:
        raise SystemExit(f"replay: {explain(refused)}")
    base = resolve_base(source, branch, snapshot.planning_began)
    if isinstance(base, BaseNotFound):
        raise SystemExit(f"replay: {explain(base)}")

    home = Path.home()
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
        harness=harness_dirs(home),
        toolchains=readable_dirs(home),
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
            **harness_version(),
        }
        write(folder / "meta.json", json.dumps(meta, indent=2))

        result, stdout, stderr = run_session(
            session_command(settings_file, (*paths.harness, paths.scratch, paths.claude_tmp), ref),
            paths.clone,
            session_env(work / "bin", paths.scratch, paths.claude_tmp),
        )
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
        case _:
            assert_never(outcome)


def grades() -> int:
    found: list[tuple[Path, Grade]] = []
    root = state_root()
    for run_dir in sorted(root.glob("*/run-*")):
        grade_file = run_dir / "grade.md"
        grade: Grade = (
            parse_grade(grade_file.read_text())
            if grade_file.exists()
            else GradeUnreadable("grade.md is missing")
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
