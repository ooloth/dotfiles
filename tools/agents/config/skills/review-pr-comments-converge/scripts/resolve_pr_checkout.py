#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Find or make a checkout of a PR's head branch to work in, or refuse with the reason.

Prints the directory to work in on stdout, and nothing else. Everything meant for a human goes to
stderr: the target, which path was taken, and how to undo a switch.

Run it from a checkout of the target repo. It decides in this order:

- The PR is not open, or its head branch lives on a fork: refuse.
- A worktree already has the head branch: refuse if that branch is behind or diverged from the
  remote. Use it if it is this checkout, uncommitted changes included, since nothing moves. Use it
  if it is another worktree with no uncommitted tracked changes; refuse otherwise.
- No worktree has it: refuse if this checkout has uncommitted tracked changes, or if a local branch
  of that name is behind or diverged. Otherwise `git switch` this checkout to it.

Untracked files never block anything: git refuses a switch on its own if one would be overwritten.

Usage:
  resolve_pr_checkout.py <pr-number> [--repo OWNER/NAME]

Exit status: 0 with a path on stdout, 1 refused (the reason is on stderr), 2 usage error.
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


class Refused(Exception):
    """An expected reason to stop. main() prints it and exits 1, never a traceback."""


@dataclass(frozen=True)
class PullRequest:
    number: int
    repo: str
    state: str
    head_branch: str
    cross_repo: bool


@dataclass(frozen=True)
class Worktree:
    path: Path
    branch: str | None


def git(cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, check=False)


def git_out(cwd: Path, *args: str, failure: str) -> str:
    result = git(cwd, *args)
    if result.returncode != 0:
        raise Refused(f"{failure}: {result.stderr.strip()}")
    return result.stdout.strip()


def gh_json(*args: str, failure: str) -> dict[str, object]:
    result = subprocess.run(["gh", *args], capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise Refused(f"{failure}: {result.stderr.strip()}")
    return json.loads(result.stdout)


def checkout_root() -> Path:
    result = git(Path.cwd(), "rev-parse", "--show-toplevel")
    if result.returncode != 0:
        raise Refused("Not inside a git checkout. Run this from a checkout of the PR's repo.")
    return Path(result.stdout.strip()).resolve()


def target_repo(explicit: str | None) -> str:
    if explicit:
        return explicit
    data = gh_json("repo", "view", "--json", "nameWithOwner", failure="`gh repo view` failed")
    return str(data["nameWithOwner"])


def read_pr(number: int, repo: str) -> PullRequest:
    data = gh_json(
        "pr",
        "view",
        str(number),
        "--repo",
        repo,
        "--json",
        "state,headRefName,isCrossRepository",
        failure=f"`gh pr view {number} --repo {repo}` failed",
    )
    return PullRequest(
        number=number,
        repo=repo,
        state=str(data["state"]),
        head_branch=str(data["headRefName"]),
        cross_repo=bool(data["isCrossRepository"]),
    )


def find_remote(root: Path, repo: str) -> str:
    """The remote whose URL ends in OWNER/NAME, for SSH, HTTPS and local-path URLs alike."""
    pattern = re.compile(rf"[:/]{re.escape(repo)}(\.git)?/?$", re.IGNORECASE)
    listing = git_out(root, "remote", "-v", failure="Could not list remotes")
    for line in listing.splitlines():
        name, url, *_ = line.split()
        if pattern.search(url):
            return name
    raise Refused(
        f"No remote of {root} points at {repo}. This is a checkout of a different repo: run "
        f"from a checkout of {repo}, or pass the right --repo."
    )


def list_worktrees(root: Path) -> list[Worktree]:
    listing = git_out(root, "worktree", "list", "--porcelain", failure="Could not list worktrees")
    worktrees: list[Worktree] = []
    for block in listing.split("\n\n"):
        fields = dict(line.split(" ", 1) for line in block.splitlines() if " " in line)
        if "worktree" not in fields:
            continue
        branch = fields.get("branch", "").removeprefix("refs/heads/") or None
        worktrees.append(Worktree(path=Path(fields["worktree"]).resolve(), branch=branch))
    return worktrees


def has_tracked_changes(path: Path) -> bool:
    return bool(
        git_out(
            path,
            "status",
            "--porcelain",
            "--untracked-files=no",
            failure=f"Could not read the status of {path}",
        )
    )


def refuse_if_behind(root: Path, branch: str, remote: str) -> None:
    """Refuse when the local branch lacks commits the remote has. Ahead alone is the author's
    unpushed work, and is fine to build on."""
    counts = git_out(
        root,
        "rev-list",
        "--left-right",
        "--count",
        f"refs/heads/{branch}...refs/remotes/{remote}/{branch}",
        failure=f"Could not compare {branch} with {remote}/{branch}",
    )
    ahead, behind = (int(n) for n in counts.split())
    if behind and ahead:
        raise Refused(
            f"Local {branch} has diverged from {remote}/{branch} ({ahead} ahead, {behind} behind). "
            "Reconcile them before reviewing, so fixes land on the code the reviewers saw."
        )
    if behind:
        raise Refused(
            f"Local {branch} is {behind} commit(s) behind {remote}/{branch}. "
            "Run `git pull --ff-only` in the checkout that has it, so fixes land on the current "
            "head."
        )


def resolve(pr: PullRequest, root: Path) -> Path:
    if pr.state != "OPEN":
        raise Refused(
            f"PR #{pr.number} is {pr.state}, so there is no open PR for fixes to land on."
        )
    if pr.cross_repo:
        raise Refused(
            f"PR #{pr.number}'s head branch {pr.head_branch} is on a fork, which this checkout "
            "cannot push to."
        )

    remote = find_remote(root, pr.repo)
    branch = pr.head_branch
    git_out(
        root,
        "fetch",
        "--quiet",
        remote,
        f"+refs/heads/{branch}:refs/remotes/{remote}/{branch}",
        failure=f"Could not fetch {branch} from {remote}",
    )

    holder = next((w for w in list_worktrees(root) if w.branch == branch), None)
    if holder is not None:
        refuse_if_behind(root, branch, remote)
        if holder.path == root:
            note = (
                " It has uncommitted changes; fixes will sit alongside them."
                if has_tracked_changes(root)
                else ""
            )
            print(f"This checkout is already on {branch}.{note}", file=sys.stderr)
            return root
        if has_tracked_changes(holder.path):
            raise Refused(
                f"{branch} is checked out at {holder.path}, which has uncommitted tracked changes. "
                "Commit or stash them there first, so fixes do not mix with unrelated work."
            )
        print(f"Using the existing worktree at {holder.path}, which has {branch}.", file=sys.stderr)
        return holder.path

    if has_tracked_changes(root):
        raise Refused(
            f"No worktree has {branch}, and this checkout has uncommitted tracked changes. "
            f"Commit or stash them, or create a worktree for {branch} yourself, then rerun."
        )
    local_exists = (
        git(root, "rev-parse", "--verify", "--quiet", f"refs/heads/{branch}").returncode == 0
    )
    if local_exists:
        refuse_if_behind(root, branch, remote)

    previous = git_out(
        root, "branch", "--show-current", failure="Could not read the current branch"
    )
    if previous:
        undo = f"git -C {root} switch {previous}"
    else:
        sha = git_out(root, "rev-parse", "HEAD", failure="Could not read HEAD")
        undo = f"git -C {root} switch --detach {sha}"
    switch_args = [branch] if local_exists else ["--track", f"{remote}/{branch}"]
    git_out(root, "switch", "--quiet", *switch_args, failure=f"Could not switch {root} to {branch}")

    current = git_out(root, "branch", "--show-current", failure="Could not read the current branch")
    assert current == branch, f"switched to {branch} but HEAD is on {current!r}"
    print(f"Switched {root} to {branch}. Undo with: {undo}", file=sys.stderr)
    return root


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("pr", type=int, help="PR number")
    parser.add_argument(
        "--repo", help="Target repository as OWNER/NAME. Defaults to the one gh infers from here."
    )
    args = parser.parse_args()

    try:
        root = checkout_root()
        repo = target_repo(args.repo)
        pr = read_pr(args.pr, repo)
        print(f"Target: {repo}#{pr.number}, head branch {pr.head_branch}", file=sys.stderr)
        path = resolve(pr, root)
    except Refused as reason:
        print(f"Refused: {reason}", file=sys.stderr)
        sys.exit(1)

    assert git(path, "rev-parse", "--show-toplevel").stdout.strip() == str(path), (
        f"{path} is not a checkout root"
    )
    print(path)


if __name__ == "__main__":
    main()
