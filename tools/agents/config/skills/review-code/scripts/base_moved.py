#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""List the base-branch commits since a PR's merge base that touch a file the PR changes.

A PR is reviewed against its merge base, so a commit that reached the base branch after the fork
is invisible in its diff. When such a commit changed one of the PR's files, merging the base can
conflict, or it can merge cleanly while the PR's edit no longer lands where the content now
lives. This lists those commits so a review can check where each edit lands. A rename counts under
both its old and its new path, on either side.

Usage:
  base_moved.py <pr-number> --repo OWNER/NAME

Exit codes:
  0  no base commit since the merge base touches a PR file, and GitHub reports the PR mergeable
  1  at least one does, each listed with the PR files it touches, or GitHub reports CONFLICTING
  2  the check could not be made, or an answer was cut short; stderr says why. Never read this
     as 0.

GitHub computes `mergeable` lazily, so an UNKNOWN answer is asked again a few times before the
check gives up. The compare endpoint lists at most 250 commits and 300 files and says nothing when
it stops: a short commit list is exit 2, and at 300 files each commit's own files are read
instead of the aggregate.
"""

import argparse
import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass
from typing import Any, Literal, NewType, NoReturn

FilePath = NewType("FilePath", str)
Sha = NewType("Sha", str)
Mergeable = Literal["MERGEABLE", "CONFLICTING"]

# GitHub's compare endpoint lists at most this many files and says nothing when it stops.
COMPARE_FILE_LIMIT = 300
MAX_FILE_PAGES = 30  # 100 files a page; GitHub lists at most 3000 files for a PR or commit
MERGEABLE_TRIES = 3
RETRY_DELAY_SECONDS = float(os.environ.get("BASE_MOVED_RETRY_DELAY", "2"))


def cannot_check(message: str) -> NoReturn:
    print(f"base_moved: {message}", file=sys.stderr)
    raise SystemExit(2)


def gh_json(args: list[str]) -> Any:
    try:
        result = subprocess.run(["gh", *args], check=False, capture_output=True, text=True)
    except FileNotFoundError:
        cannot_check("gh is not installed or not on PATH.")
    if result.returncode != 0:
        cannot_check(f"`gh {' '.join(args)}` failed: {result.stderr.strip()}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as e:
        cannot_check(f"`gh {' '.join(args)}` did not return JSON: {e}")


@dataclass(frozen=True)
class PrState:
    base_ref: str
    base_tip: Sha  # the base branch's tip now, not the base SHA GitHub recorded on the PR
    head: Sha
    mergeable: Mergeable
    changed_files: int


@dataclass(frozen=True)
class CommitRef:
    sha: Sha
    subject: str


@dataclass(frozen=True)
class BaseSide:
    merge_base: Sha
    commits: list[CommitRef]  # oldest first
    # Every path the base changed since the merge base, or None when GitHub's list hit its cap.
    touched: frozenset[FilePath] | None


@dataclass(frozen=True)
class BaseMove:
    commit: CommitRef
    shared: frozenset[FilePath]


def paths_of(files: list[Any]) -> set[FilePath]:
    paths: set[FilePath] = set()
    for f in files:
        paths.add(FilePath(f["filename"]))
        if f.get("previous_filename"):
            paths.add(FilePath(f["previous_filename"]))
    return paths


def read_pr(repo: str, number: int) -> PrState:
    """The PR's head, its base branch's tip and its merge state.

    REST's read of the PR also starts GitHub computing the merge state. The PR's own base SHA is
    the base as of the PR's last update, so the tip comes from the branch itself.
    """
    state = "UNKNOWN"
    for attempt in range(MERGEABLE_TRIES):
        pr = gh_json(["api", f"repos/{repo}/pulls/{number}"])
        if pr.get("mergeable") is not None:
            ref = pr["base"]["ref"]
            branch = gh_json(["api", f"repos/{repo}/branches/{ref}"])
            return PrState(
                base_ref=ref,
                base_tip=Sha(branch["commit"]["sha"]),
                head=Sha(pr["head"]["sha"]),
                mergeable="MERGEABLE" if pr["mergeable"] else "CONFLICTING",
                changed_files=pr["changed_files"],
            )
        state = f"UNKNOWN (PR state {pr.get('state')})"
        if attempt < MERGEABLE_TRIES - 1:
            time.sleep(RETRY_DELAY_SECONDS)
    cannot_check(
        f"GitHub still reports #{number} as mergeable={state} after {MERGEABLE_TRIES} reads."
    )


def paged_files(endpoint: str, what: str) -> tuple[set[FilePath], int]:
    """Every path in a paged file list, a rename's old path included, and how many entries."""
    paths: set[FilePath] = set()
    seen = 0
    for page in range(1, MAX_FILE_PAGES + 1):
        answer = gh_json(["api", f"{endpoint}?per_page=100&page={page}"])
        files = answer if isinstance(answer, list) else answer.get("files", [])
        if not isinstance(files, list):
            cannot_check(f"GitHub's file list for {what} was not a list.")
        paths |= paths_of(files)
        seen += len(files)
        if len(files) < 100:
            return paths, seen
    cannot_check(f"{what} has more than {MAX_FILE_PAGES * 100} files to page through.")


def pr_paths(repo: str, number: int, expected: int) -> frozenset[FilePath]:
    paths, seen = paged_files(f"repos/{repo}/pulls/{number}/files", f"#{number}")
    if seen != expected:
        cannot_check(f"GitHub listed {seen} files for #{number} but says it changes {expected}.")
    return frozenset(paths)


def base_side(repo: str, pr: PrState) -> BaseSide:
    fork = gh_json(["api", f"repos/{repo}/compare/{pr.base_tip}...{pr.head}"])
    merge_base = Sha(fork["merge_base_commit"]["sha"])
    data = gh_json(["api", f"repos/{repo}/compare/{merge_base}...{pr.base_tip}"])
    commits = [
        CommitRef(sha=Sha(c["sha"]), subject=c["commit"]["message"].split("\n", 1)[0])
        for c in data.get("commits", [])
    ]
    total = data.get("total_commits", len(commits))
    if len(commits) != total:
        cannot_check(
            f"compare {merge_base}...{pr.base_tip} lists {len(commits)} of {total} commits."
        )
    files = data.get("files", [])
    touched = None if len(files) >= COMPARE_FILE_LIMIT else frozenset(paths_of(files))
    return BaseSide(merge_base=merge_base, commits=commits, touched=touched)


def find_moves(repo: str, prs: frozenset[FilePath], base: BaseSide) -> list[BaseMove]:
    if base.touched is not None and not (base.touched & prs):
        return []
    moves: list[BaseMove] = []
    for commit in base.commits:
        paths, _ = paged_files(f"repos/{repo}/commits/{commit.sha}", f"commit {commit.sha}")
        shared = frozenset(paths) & prs
        if shared:
            moves.append(BaseMove(commit=commit, shared=shared))
    return moves


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("pr", type=int)
    parser.add_argument("--repo", required=True)
    args = parser.parse_args()
    if "/" not in args.repo:
        cannot_check(f"--repo must be OWNER/NAME, not {args.repo!r}.")

    pr = read_pr(args.repo, args.pr)
    prs = pr_paths(args.repo, args.pr, pr.changed_files)
    base = base_side(args.repo, pr)
    moves = find_moves(args.repo, prs, base)
    assert all(m.shared for m in moves), "a listed commit must share a file with the PR"

    print(
        f"PR #{args.pr}: head {pr.head}, {pr.base_ref} tip {pr.base_tip}, merge base {base.merge_base}, "
        f"mergeable={pr.mergeable}. The base has {len(base.commits)} "
        f"{'commit' if len(base.commits) == 1 else 'commits'} since the merge base."
    )
    print()
    if not moves:
        print("None of them touches a file this PR changes.")
    for m in moves:
        print(f"{m.commit.sha[:8]} {m.commit.subject}")
        for path in sorted(m.shared):
            print(f"    {path}")
    if pr.mergeable == "CONFLICTING":
        print()
        print("GitHub reports the PR as CONFLICTING.")
    raise SystemExit(1 if moves or pr.mergeable == "CONFLICTING" else 0)


if __name__ == "__main__":
    main()
