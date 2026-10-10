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
- A worktree holds the PR when its branch is named after the head branch or tracks it on the
  remote, as a branch named `pr-531` tracking `origin/feature` does. This checkout wins when it
  holds the PR. Otherwise one other holder is used, and two or more are refused as ambiguous.
- A holder is refused if its branch has diverged from the remote head.
- This checkout holds it and is only behind: fast-forward it and print how to undo that, unless it
  has uncommitted tracked changes, which refuses. Otherwise use it, uncommitted changes included,
  since nothing moves.
- Another worktree holds it: refuse if it is behind or has uncommitted tracked changes, since
  another session may be working there. Otherwise use it.
- No worktree holds it: refuse if this checkout has uncommitted tracked changes, or if a local
  branch named after the head is behind or diverged. Otherwise `git switch` this checkout to it.

Before either move, the fast-forward or the switch, refuse if it would replace an untracked or
gitignored file or directory. Git refuses that on its own for untracked files, but overwrites
gitignored ones without a word. The check runs a moment before the move, so a file created in
between is not caught; nothing short of locking the working tree could close that gap.

Usage:
  resolve_pr_checkout.py <pr-number> [--repo OWNER/NAME]

Exit status: 0 with a path on stdout, 1 refused (the reason is on stderr), 2 usage error.
"""

import argparse
import json
import os
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
    upstream: str | None


@dataclass(frozen=True)
class Holder:
    """A worktree whose branch carries the PR's head, by name or by tracking it."""

    path: Path
    local_branch: str
    upstream: str | None


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
    refs = git_out(
        root,
        "for-each-ref",
        "--format=%(refname:short) %(upstream)",
        "refs/heads",
        failure="Could not read branch upstreams",
    )
    upstreams = {
        name: upstream
        for name, _, upstream in (line.partition(" ") for line in refs.splitlines())
        if upstream
    }
    worktrees: list[Worktree] = []
    for block in listing.split("\n\n"):
        fields = dict(line.split(" ", 1) for line in block.splitlines() if " " in line)
        if "worktree" not in fields:
            continue
        branch = fields.get("branch", "").removeprefix("refs/heads/") or None
        worktrees.append(
            Worktree(
                path=Path(fields["worktree"]).resolve(),
                branch=branch,
                upstream=upstreams.get(branch) if branch else None,
            )
        )
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


def holders(worktrees: list[Worktree], branch: str, remote: str) -> list[Holder]:
    tracked = f"refs/remotes/{remote}/{branch}"
    return [
        Holder(path=w.path, local_branch=w.branch, upstream=w.upstream)
        for w in worktrees
        if w.branch is not None and (w.branch == branch or w.upstream == tracked)
    ]


def holding_reason(holder: Holder, branch: str, remote: str) -> str:
    if holder.local_branch == branch:
        return f"has {branch}"
    return f"is on {holder.local_branch}, which tracks {remote}/{branch}"


def commits_behind(root: Path, local_branch: str, branch: str, remote: str) -> int:
    """How many commits the remote head has that the local branch lacks. Refuses when the local
    branch also has commits of its own, since reconciling them is the author's choice. Ahead alone
    is the author's unpushed work, and is fine to build on."""
    counts = git_out(
        root,
        "rev-list",
        "--left-right",
        "--count",
        f"refs/heads/{local_branch}...refs/remotes/{remote}/{branch}",
        failure=f"Could not compare {local_branch} with {remote}/{branch}",
    )
    ahead, behind = (int(n) for n in counts.split())
    if behind and ahead:
        raise Refused(
            f"Local {local_branch} has diverged from {remote}/{branch} ({ahead} ahead, {behind} "
            "behind). Reconcile them before reviewing, so fixes land on the code the reviewers saw."
        )
    return behind


def behind_refusal(local_branch: str, behind: int, branch: str, remote: str) -> Refused:
    """Behind a remote head in a checkout this script does not move: another worktree, which
    another session may be working in, or a branch it would switch to."""
    return Refused(
        f"Local {local_branch} is {behind} commit(s) behind {remote}/{branch}. "
        "Run `git pull --ff-only` in the checkout that has it, so fixes land on the current head."
    )


def refuse_if_move_would_overwrite(root: Path, target: str, move: str) -> None:
    """Refuse when moving to `target` would replace something on disk that git cannot restore.

    Git overwrites gitignored files without a word when a commit brings a tracked file to the same
    path, and deletes a gitignored directory to make room for one. So every path the target adds is
    checked, and so is every parent of it, since a file or symlink standing where a directory has to
    go is replaced too. A parent that is a tracked file about to become a directory is refused as
    well, although git could restore it: telling the two apart is not worth the risk of a miss.
    """
    added = git_out(
        root,
        "diff",
        "--name-only",
        "--no-renames",
        "--diff-filter=A",
        "-z",
        "HEAD",
        target,
        failure=f"Could not list the files {target} adds",
    )
    at_risk: set[str] = set()
    for path in filter(None, added.split("\0")):
        if os.path.lexists(root / path):
            at_risk.add(path)
        for parent in Path(path).parents:
            on_disk = root / parent
            if parent != Path(".") and (on_disk.is_symlink() or on_disk.is_file()):
                at_risk.add(str(parent))
    if at_risk:
        raise Refused(
            f"{move} would overwrite or delete files git cannot restore: "
            f"{', '.join(sorted(at_risk))}. Move them out of the way, then rerun."
        )


def fast_forward(root: Path, local_branch: str, branch: str, remote: str, behind: int) -> None:
    target = f"refs/remotes/{remote}/{branch}"
    refuse_if_move_would_overwrite(root, target, f"Fast-forwarding {local_branch}")
    old = git_out(root, "rev-parse", "HEAD", failure="Could not read HEAD")
    git_out(
        root,
        "merge",
        "--ff-only",
        "--quiet",
        target,
        failure=f"Could not fast-forward {local_branch} to {remote}/{branch}",
    )

    head = git_out(root, "rev-parse", "HEAD", failure="Could not read HEAD")
    remote_head = git_out(root, "rev-parse", target, failure=f"Could not read {target}")
    assert head == remote_head, f"fast-forwarded to {head}, but {target} is at {remote_head}"
    current = git_out(root, "branch", "--show-current", failure="Could not read the current branch")
    assert current == local_branch, f"fast-forwarded {local_branch} but HEAD is on {current!r}"
    print(
        f"Fast-forwarded {local_branch} by {behind} commit(s) to {remote}/{branch}. "
        f"Undo with: git -C {root} reset --keep {old}",
        file=sys.stderr,
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

    found = holders(list_worktrees(root), branch, remote)
    here = [h for h in found if h.path == root]
    match here, found:
        case [holder], _:
            pass
        case [], [holder]:
            pass
        case [], []:
            holder = None
        case _:
            paths = ", ".join(str(h.path) for h in found)
            raise Refused(
                f"More than one worktree holds {branch}: {paths}. Rerun from the one to work in."
            )
    if holder is not None:
        assert holder.local_branch == branch or holder.upstream == (
            f"refs/remotes/{remote}/{branch}"
        ), f"{holder} neither is nor tracks {branch}"
        reason = holding_reason(holder, branch, remote)
        behind = commits_behind(root, holder.local_branch, branch, remote)
        if behind and holder.path != root:
            raise behind_refusal(holder.local_branch, behind, branch, remote)
        if behind and has_tracked_changes(root):
            raise Refused(
                f"Local {holder.local_branch} is {behind} commit(s) behind {remote}/{branch}, and "
                "this checkout has uncommitted tracked changes. Commit or stash them, then rerun "
                "so the branch can be fast-forwarded."
            )
        if behind:
            fast_forward(root, holder.local_branch, branch, remote, behind)
            print(f"This checkout {reason}.", file=sys.stderr)
            return root
        if holder.path == root:
            note = (
                " It has uncommitted changes; fixes will sit alongside them."
                if has_tracked_changes(root)
                else ""
            )
            print(f"This checkout {reason}.{note}", file=sys.stderr)
            return root
        if has_tracked_changes(holder.path):
            raise Refused(
                f"{branch} is held by {holder.path}, which has uncommitted tracked changes. "
                "Commit or stash them there first, so fixes do not mix with unrelated work."
            )
        print(f"Using the existing worktree at {holder.path}, which {reason}.", file=sys.stderr)
        return holder.path

    if has_tracked_changes(root):
        raise Refused(
            f"No worktree has {branch}, and this checkout has uncommitted tracked changes. "
            f"Commit or stash them, or create a worktree for {branch} yourself, then rerun."
        )
    local_exists = (
        git(root, "rev-parse", "--verify", "--quiet", f"refs/heads/{branch}").returncode == 0
    )
    if local_exists and (behind := commits_behind(root, branch, branch, remote)):
        raise behind_refusal(branch, behind, branch, remote)

    previous = git_out(
        root, "branch", "--show-current", failure="Could not read the current branch"
    )
    if previous:
        undo = f"git -C {root} switch {previous}"
    else:
        sha = git_out(root, "rev-parse", "HEAD", failure="Could not read HEAD")
        undo = f"git -C {root} switch --detach {sha}"
    switch_args = [branch] if local_exists else ["--track", f"{remote}/{branch}"]
    target = f"refs/heads/{branch}" if local_exists else f"refs/remotes/{remote}/{branch}"
    refuse_if_move_would_overwrite(root, target, f"Switching {root} to {branch}")
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
