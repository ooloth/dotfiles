#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic>=2"]
# ///
"""Merge a pull request only when every mechanical condition for merging it holds.

merge-and-verify judges what takes judgement (what trunk changed, whether review threads were
answered, the repo's merge-time steps) and then calls this script with the head commit it checked.
The script reads the PR from GitHub and refuses unless all of these hold:

- the head is still the commit the caller checked
- the PR is open and not a draft
- someone approved it, on any commit, and no reviewer's latest review requests changes or was
  dismissed: a push to an approved PR never undoes its approval
- every check on the head passed
- GitHub says it can merge

A check still running is a wait, not a refusal: when the running checks are all that stands
between the PR and merging, the script exits 3 so the caller checks again later.

Then it merges with the repo's allowed method (squash first) and `--match-head-commit`, so a push in
the moment between checking and merging fails at GitHub instead of merging an unchecked head. It is
the only path agents merge through, so `settings.json` can permit this one command without
permitting `gh pr merge`.

Usage:
  merge.py <pr-number> --repo OWNER/NAME --head <40-hex SHA> [--check-only]

Exit codes:
  0  merged (or, with --check-only, ready to merge)
  1  not merged: a condition failed or GitHub refused the merge; every reason is printed
  2  could not run: bad arguments or a GitHub read failed
  3  not merged yet: only checks still running stand in the way; check again later

Requires `gh`, authenticated.
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from typing import Any, Literal, NewType, assert_never

from pydantic import BaseModel, ConfigDict, ValidationError

RepoSlug = NewType("RepoSlug", str)
CommitSha = NewType("CommitSha", str)
MergeMethod = Literal["squash", "merge", "rebase"]

PR_FIELDS = "state,isDraft,headRefOid,mergeStateStatus,reviews,statusCheckRollup"
REPO_FIELDS = "squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed"
PASSING_CONCLUSIONS = {"SUCCESS", "NEUTRAL", "SKIPPED"}
RUNNING_CONTEXT_STATES = {"PENDING", "EXPECTED"}
MERGEABLE_STATES = {"CLEAN", "HAS_HOOKS"}
# What GitHub reports while a check is still running, so it is part of the same wait.
WAITING_MERGE_STATES = {"BLOCKED", "UNSTABLE", "UNKNOWN"}


# GitHub's answers, parsed at the boundary


class _Answer(BaseModel):
    model_config = ConfigDict(extra="ignore", frozen=True)


class _Author(_Answer):
    login: str


class _Commit(_Answer):
    oid: str


class _Review(_Answer):
    author: _Author | None = None
    state: str
    commit: _Commit | None = None
    submittedAt: str | None = None


class _Check(_Answer):
    # A CheckRun has name/status/conclusion; a StatusContext has context/state.
    name: str | None = None
    context: str | None = None
    status: str | None = None
    conclusion: str | None = None
    state: str | None = None


class _PullRequest(_Answer):
    state: str
    isDraft: bool
    headRefOid: str
    mergeStateStatus: str
    reviews: list[_Review]
    statusCheckRollup: list[_Check] | None = None


class _Repo(_Answer):
    squashMergeAllowed: bool
    mergeCommitAllowed: bool
    rebaseMergeAllowed: bool


# Domain types


@dataclass(frozen=True)
class Check:
    name: str
    passed: bool
    running: bool
    shown_state: str

    def __post_init__(self) -> None:
        assert not (self.passed and self.running), f"check {self.name} both passed and running"


@dataclass(frozen=True)
class PullRequestState:
    open: bool
    shown_state: str
    draft: bool
    head: CommitSha
    approved_by: tuple[str, ...]
    changes_requested_by: tuple[str, ...]
    checks: tuple[Check, ...]
    merge_state: str
    allowed_methods: tuple[MergeMethod, ...]


@dataclass(frozen=True)
class HeadMoved:
    checked: CommitSha
    now: CommitSha


@dataclass(frozen=True)
class Closed:
    state: str


@dataclass(frozen=True)
class Draft:
    pass


@dataclass(frozen=True)
class NoApproval:
    pass


@dataclass(frozen=True)
class ChangesRequested:
    by: str


@dataclass(frozen=True)
class CheckFailed:
    name: str
    state: str


@dataclass(frozen=True)
class CheckRunning:
    name: str
    state: str


@dataclass(frozen=True)
class NoChecks:
    pass


@dataclass(frozen=True)
class NotMergeable:
    merge_state: str


@dataclass(frozen=True)
class NoAllowedMethod:
    pass


Refusal = (
    HeadMoved
    | Closed
    | Draft
    | NoApproval
    | ChangesRequested
    | CheckFailed
    | CheckRunning
    | NoChecks
    | NotMergeable
    | NoAllowedMethod
)


@dataclass(frozen=True)
class Ready:
    method: MergeMethod


@dataclass(frozen=True)
class Waiting:
    """Only checks still running, and GitHub's state while they run, stand in the way."""

    waits: tuple[CheckRunning | NotMergeable, ...]


@dataclass(frozen=True)
class NotReady:
    refusals: tuple[Refusal, ...]


Verdict = Ready | Waiting | NotReady


@dataclass(frozen=True)
class Merged:
    merge_commit: str


@dataclass(frozen=True)
class MergeRefused:
    message: str


@dataclass(frozen=True)
class ReadFailed:
    call: str
    message: str


# Parsing


def parse_pull_request(raw: dict[str, Any], repo: dict[str, Any]) -> PullRequestState:
    pr = _PullRequest.model_validate(raw)
    allowed = _Repo.model_validate(repo)
    latest: dict[str, _Review] = {}
    for review in pr.reviews:
        login = review.author.login if review.author else "(unknown)"
        if review.state in {"APPROVED", "CHANGES_REQUESTED", "DISMISSED"}:
            latest[login] = review
    approved = tuple(sorted(login for login, r in latest.items() if r.state == "APPROVED"))
    changes = tuple(sorted(login for login, r in latest.items() if r.state == "CHANGES_REQUESTED"))
    methods: list[MergeMethod] = []
    if allowed.squashMergeAllowed:
        methods.append("squash")
    if allowed.mergeCommitAllowed:
        methods.append("merge")
    if allowed.rebaseMergeAllowed:
        methods.append("rebase")
    return PullRequestState(
        open=pr.state == "OPEN",
        shown_state=pr.state,
        draft=pr.isDraft,
        head=CommitSha(pr.headRefOid),
        approved_by=approved,
        changes_requested_by=changes,
        checks=tuple(_check(c) for c in pr.statusCheckRollup or []),
        merge_state=pr.mergeStateStatus,
        allowed_methods=tuple(methods),
    )


def _check(raw: _Check) -> Check:
    name = raw.name or raw.context or "(unnamed check)"
    if raw.context is not None and raw.name is None:
        state = raw.state or "UNKNOWN"
        return Check(name, state == "SUCCESS", state in RUNNING_CONTEXT_STATES, state)
    if raw.status != "COMPLETED":
        return Check(name, False, True, raw.status or "UNKNOWN")
    conclusion = raw.conclusion or "UNKNOWN"
    return Check(name, conclusion in PASSING_CONCLUSIONS, False, conclusion)


# Judging


def judge(state: PullRequestState, checked_head: CommitSha) -> Verdict:
    refusals: list[Refusal] = []
    if state.head != checked_head:
        refusals.append(HeadMoved(checked_head, state.head))
    if not state.open:
        refusals.append(Closed(state.shown_state))
    if state.draft:
        refusals.append(Draft())
    if not state.approved_by:
        refusals.append(NoApproval())
    refusals.extend(ChangesRequested(by) for by in state.changes_requested_by)
    if not state.checks:
        refusals.append(NoChecks())
    running = [CheckRunning(c.name, c.shown_state) for c in state.checks if c.running]
    refusals.extend(running)
    refusals.extend(
        CheckFailed(c.name, c.shown_state) for c in state.checks if not c.passed and not c.running
    )
    if state.merge_state not in MERGEABLE_STATES:
        refusals.append(NotMergeable(state.merge_state))
    if not state.allowed_methods:
        refusals.append(NoAllowedMethod())
    if not refusals:
        return Ready(state.allowed_methods[0])
    waits = [
        r
        for r in refusals
        if isinstance(r, CheckRunning | NotMergeable) and _is_wait(r, any_running=bool(running))
    ]
    if len(waits) == len(refusals):
        verdict: Verdict = Waiting(tuple(waits))
        assert running, "a wait with no check still running"
        return verdict
    verdict = NotReady(tuple(refusals))
    assert verdict.refusals, "NotReady with no refusal"
    return verdict


def _is_wait(refusal: CheckRunning | NotMergeable, any_running: bool) -> bool:
    match refusal:
        case CheckRunning():
            return True
        case NotMergeable(merge_state):
            return any_running and merge_state in WAITING_MERGE_STATES
        case _:
            assert_never(refusal)


def describe(refusal: Refusal) -> str:
    match refusal:
        case HeadMoved(checked, now):
            return f"the head moved: checked {checked}, now {now}"
        case Closed(state):
            return f"the PR is {state.lower()}, not open"
        case Draft():
            return "the PR is a draft"
        case NoApproval():
            return "nobody has approved the PR"
        case ChangesRequested(by):
            return f"{by}'s latest review requests changes"
        case CheckFailed(name, state):
            return f"check {name!r} has not passed ({state})"
        case CheckRunning(name, state):
            return f"check {name!r} is still running ({state})"
        case NoChecks():
            return "no checks ran on the head"
        case NotMergeable(merge_state):
            return f"GitHub says it can't merge yet ({merge_state})"
        case NoAllowedMethod():
            return "the repo allows no merge method"
        case _:
            assert_never(refusal)


# GitHub calls


def gh(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["gh", *args], capture_output=True, text=True, check=False)


def read(pr: str, repo: RepoSlug) -> PullRequestState | ReadFailed:
    pr_call = gh("pr", "view", pr, "-R", repo, "--json", PR_FIELDS)
    if pr_call.returncode != 0:
        return ReadFailed("gh pr view", pr_call.stderr.strip())
    repo_call = gh("repo", "view", repo, "--json", REPO_FIELDS)
    if repo_call.returncode != 0:
        return ReadFailed("gh repo view", repo_call.stderr.strip())
    try:
        return parse_pull_request(json.loads(pr_call.stdout), json.loads(repo_call.stdout))
    except (json.JSONDecodeError, ValidationError) as error:
        return ReadFailed("parsing GitHub's answer", str(error).splitlines()[0])


def merge(pr: str, repo: RepoSlug, method: MergeMethod, head: CommitSha) -> Merged | MergeRefused:
    args = ("pr", "merge", pr, "-R", repo, f"--{method}", "--match-head-commit", head)
    assert args[-1] == head and args[-2] == "--match-head-commit", "merge without the head pinned"
    call = gh(*args)
    if call.returncode != 0:
        return MergeRefused(call.stderr.strip() or call.stdout.strip())
    after = gh("pr", "view", pr, "-R", repo, "--json", "mergeCommit")
    try:
        commit = json.loads(after.stdout)["mergeCommit"]["oid"]
    except (json.JSONDecodeError, KeyError, TypeError):
        commit = "(merged; GitHub did not return the merge commit)"
    return Merged(commit)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("pr")
    parser.add_argument("--repo", required=True)
    parser.add_argument("--head", required=True)
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args(argv)
    if not re.fullmatch(r"\d+", args.pr):
        print(f"merge.py: {args.pr!r} is not a PR number.", file=sys.stderr)
        return 2
    if not re.fullmatch(r"[\w.-]+/[\w.-]+", args.repo):
        print(f"merge.py: --repo is {args.repo!r}. Give it as OWNER/NAME.", file=sys.stderr)
        return 2
    if not re.fullmatch(r"[0-9a-f]{40}", args.head):
        print(
            f"merge.py: --head is {args.head!r}. Give the full 40-character commit you checked.",
            file=sys.stderr,
        )
        return 2
    repo, head = RepoSlug(args.repo), CommitSha(args.head)

    state = read(args.pr, repo)
    if isinstance(state, ReadFailed):
        print(f"merge.py: {state.call} failed: {state.message}", file=sys.stderr)
        return 2
    verdict = judge(state, head)
    match verdict:
        case NotReady(refusals):
            print(f"Not merged. {len(refusals)} condition(s) failed:")
            for refusal in refusals:
                print(f"- {describe(refusal)}")
            return 1
        case Waiting(waits):
            print("Not merged yet. Waiting on:")
            for wait in waits:
                print(f"- {describe(wait)}")
            return 3
        case Ready(method) if args.check_only:
            print(f"Ready to merge #{args.pr} at {head} with {method}. Nothing was merged.")
            return 0
        case Ready(method):
            pass
        case _:
            assert_never(verdict)
    outcome = merge(args.pr, repo, method, head)
    match outcome:
        case Merged(commit):
            print(f"Merged #{args.pr} at {head} with {method}. Merge commit: {commit}")
            return 0
        case MergeRefused(message):
            print(f"Not merged. GitHub refused the merge: {message}")
            return 1
        case _:
            assert_never(outcome)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
