#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Ready a worktree and a Rex tab where review-pr-comments-converge answers a pull request's feedback.

monitor-prs runs this for each of my pull requests it prepares, after deciding the pull request
needs it and that no tab for it is open. Working in my clone at ~/Repos/<owner>/<name>, it:

1. Refuses outside Rex (TMUX set, or REX_SESSION empty).
2. Finds the clone's remote whose URL points at the pull request's repo.
3. Fetches the head branch, without ever waiting on a credential prompt, giving up after 60 s.
4. Removes this pull request's earlier worktrees under .claude/worktrees/pr-<number>-*, with their
   branches, when they are clean and their tip is on the remote head. Any other is kept and named.
5. Adds a worktree on a new branch pr-<number>-<UTC time> tracking the head, and makes sure
   .claude/worktrees/ is ignored in the clone.
6. Opens the tab `PR <number> (<author>): review-pr-comments-converge` with the Rex launcher.
   When the launch fails, it removes the new worktree and branch unless a tab with that label is
   open, or the tabs cannot be listed.

It never calls gh and never pushes. It prints one JSON line: {"prepared": true, ...} with the tab's
pane, or {"prepared": false, "step": ..., "error": ...} naming the step that failed.

Exit status: 0 prepared, 1 not prepared, 2 usage error.

Usage:
  prepare_feedback_session.py <owner>/<name> <number> <author> <head-branch>
"""

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path

LAUNCHER = Path(__file__).resolve().parents[6] / "tools" / "rex" / "claude-tab.bash"
FETCH_TIMEOUT_SECONDS = 60


@dataclass(frozen=True)
class PrTarget:
    repo: str
    number: int
    author: str
    head: str

    @property
    def label(self) -> str:
        return f"PR {self.number} ({self.author}): review-pr-comments-converge"

    @property
    def prompt(self) -> str:
        return f"/review-pr-comments-converge {self.repo}#{self.number}"


@dataclass(frozen=True)
class Clone:
    path: Path
    remote: str


@dataclass(frozen=True)
class Kept:
    path: Path
    reason: str


@dataclass(frozen=True)
class Pruned:
    removed: list[Path] = field(default_factory=list)
    kept: list[Kept] = field(default_factory=list)


@dataclass(frozen=True)
class Worktree:
    path: Path
    branch: str


class NotPrepared(Exception):
    """An expected reason the pull request was not prepared. main() reports it as JSON and exits 1."""

    def __init__(self, step: str, error: str, left: str | None = None) -> None:
        super().__init__(error)
        self.step = step
        self.error = error
        self.left = left


def git(cwd: Path, *args: str, timeout: float | None = None) -> subprocess.CompletedProcess[str]:
    env = {**os.environ, "GIT_TERMINAL_PROMPT": "0"}
    return subprocess.run(
        ["git", *args], cwd=cwd, env=env, capture_output=True, text=True, timeout=timeout
    )


def failure(result: subprocess.CompletedProcess[str]) -> str:
    return (result.stderr or result.stdout).strip()


def check_rex() -> None:
    if os.environ.get("TMUX"):
        raise NotPrepared("rex", "TMUX is set: sessions are prepared only in Rex")
    if not os.environ.get("REX_SESSION"):
        raise NotPrepared("rex", "REX_SESSION is empty: sessions are prepared only in Rex")


def find_clone(target: PrTarget) -> Clone:
    path = Path.home() / "Repos" / target.repo
    if not path.is_dir():
        raise NotPrepared("clone", f"No clone of {target.repo} at {path}")
    # Read from config rather than `git remote -v`, whose lines split wrongly when a URL has spaces.
    listing = git(path, "config", "--get-regexp", r"^remote\..*\.url$")
    if listing.returncode not in (0, 1):
        raise NotPrepared("clone", f"Could not list the remotes of {path}: {failure(listing)}")
    pattern = re.compile(rf"[:/]{re.escape(target.repo)}(\.git)?/?$", re.IGNORECASE)
    for line in listing.stdout.splitlines():
        key, url = line.split(" ", 1)
        if pattern.search(url):
            return Clone(path=path, remote=key.removeprefix("remote.").removesuffix(".url"))
    raise NotPrepared("clone", f"No remote of {path} points at {target.repo}")


def fetch_head(clone: Clone, target: PrTarget) -> None:
    try:
        result = git(clone.path, "fetch", clone.remote, target.head, timeout=FETCH_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        raise NotPrepared(
            "fetch", f"git fetch {clone.remote} {target.head} took over {FETCH_TIMEOUT_SECONDS}s"
        ) from None
    if result.returncode != 0:
        raise NotPrepared("fetch", f"git fetch {clone.remote} {target.head}: {failure(result)}")


def worktrees_of(clone: Clone, target: PrTarget) -> list[Worktree]:
    """This pull request's worktrees from earlier preparations, by folder and branch name."""
    folder = clone.path / ".claude" / "worktrees"
    prefix = f"pr-{target.number}-"
    listing = git(clone.path, "worktree", "list", "--porcelain")
    found: list[Worktree] = []
    path: Path | None = None
    for line in listing.stdout.splitlines():
        if line.startswith("worktree "):
            path = Path(line.removeprefix("worktree "))
        elif line.startswith("branch refs/heads/") and path is not None:
            branch = line.removeprefix("branch refs/heads/")
            if path.parent == folder and path.name.startswith(prefix) and branch == path.name:
                found.append(Worktree(path=path, branch=branch))
    return found


def why_kept(worktree: Worktree) -> str | None:
    """Why removing this worktree could lose something, or None when nothing would be lost."""
    status = git(worktree.path, "status", "--porcelain")
    if status.returncode != 0:
        return f"could not read its status: {failure(status)}"
    if status.stdout.strip():
        return "it has uncommitted or untracked files"
    upstream = git(worktree.path, "rev-parse", "--abbrev-ref", "@{u}")
    if upstream.returncode != 0:
        return "its branch tracks nothing"
    if git(worktree.path, "merge-base", "--is-ancestor", "HEAD", "@{u}").returncode != 0:
        return f"it has commits {upstream.stdout.strip()} lacks"
    return None


def prune_stale(clone: Clone, target: PrTarget) -> Pruned:
    pruned = Pruned()
    for worktree in worktrees_of(clone, target):
        reason = why_kept(worktree)
        if reason is not None:
            pruned.kept.append(Kept(worktree.path, reason))
            continue
        # Only a bug in the selection above could reach here with anything else, and a wrong
        # removal is the one act here that cannot be undone.
        assert worktree.path.parent == clone.path / ".claude" / "worktrees", worktree
        assert worktree.path.name.startswith(f"pr-{target.number}-"), worktree
        removed = git(clone.path, "worktree", "remove", str(worktree.path))
        if removed.returncode != 0:
            pruned.kept.append(Kept(worktree.path, f"git worktree remove: {failure(removed)}"))
            continue
        git(clone.path, "branch", "-D", worktree.branch)
        pruned.removed.append(worktree.path)
    return pruned


def ignore_worktrees(clone: Clone) -> None:
    """List .claude/worktrees/ in the clone's info/exclude, unless something already ignores it."""
    if git(clone.path, "check-ignore", "-q", ".claude/worktrees/x").returncode == 0:
        return
    exclude = git(clone.path, "rev-parse", "--git-path", "info/exclude").stdout.strip()
    path = clone.path / exclude
    path.parent.mkdir(parents=True, exist_ok=True)
    existing = path.read_text() if path.exists() else ""
    separator = "" if not existing or existing.endswith("\n") else "\n"
    path.write_text(f"{existing}{separator}/.claude/worktrees/\n")


def add_worktree(clone: Clone, target: PrTarget) -> Worktree:
    time = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
    branch = f"pr-{target.number}-{time}"
    path = clone.path / ".claude" / "worktrees" / branch
    ignore_worktrees(clone)
    result = git(
        clone.path,
        "worktree",
        "add",
        "--track",
        "-b",
        branch,
        str(path),
        f"{clone.remote}/{target.head}",
    )
    if result.returncode != 0:
        raise NotPrepared("worktree", f"git worktree add {path}: {failure(result)}")
    return Worktree(path=path, branch=branch)


def open_labels() -> list[str] | None:
    """Every open tab's label in every Rex session, or None when Rex cannot list them."""
    sessions = subprocess.run(["rex", "session", "list", "--json"], capture_output=True, text=True)
    if sessions.returncode != 0:
        return None
    labels: list[str] = []
    try:
        for session in json.loads(sessions.stdout)["sessions"]:
            windows = subprocess.run(
                ["rex", "window", "ls", "-s", session["session_id"], "--json"],
                capture_output=True,
                text=True,
            )
            if windows.returncode != 0:
                return None
            labels += [window["label"] for window in json.loads(windows.stdout)["windows"]]
    except (json.JSONDecodeError, KeyError, TypeError):
        return None
    return labels


def launch(clone: Clone, target: PrTarget, worktree: Worktree) -> str:
    """Open the tab and return its pane, or clean up after a failed launch and raise."""
    result = subprocess.run(
        # --unattended is cc.bash's: auto mode on every machine, since nobody watches this session
        ["bash", str(LAUNCHER), target.label, str(worktree.path), "--unattended", target.prompt],
        capture_output=True,
        text=True,
    )
    pane = None
    if result.returncode == 0:
        try:
            tab = json.loads(result.stdout)
            if tab.get("window_id") and tab.get("block_ids"):
                pane = tab["block_ids"][0]
        except (json.JSONDecodeError, AttributeError, TypeError):
            pane = None
    if pane:
        return pane

    error = failure(result) or f"the launcher printed no tab: {result.stdout.strip()!r}"
    labels = open_labels()
    if labels is None:
        raise NotPrepared("launch", error, left="tabs unknown")
    if target.label in labels:
        raise NotPrepared("launch", error, left="tab open")
    git(clone.path, "worktree", "remove", "--force", str(worktree.path))
    git(clone.path, "branch", "-D", worktree.branch)
    raise NotPrepared("launch", error, left="removed")


def parse_args() -> PrTarget:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("repo", help="the pull request's repo, as OWNER/NAME")
    parser.add_argument("number", type=int, help="the pull request's number")
    parser.add_argument("author", help="the pull request author's login")
    parser.add_argument("head", help="the pull request's head branch")
    args = parser.parse_args()
    if not re.fullmatch(r"[\w.-]+/[\w.-]+", args.repo):
        parser.error("repo must be OWNER/NAME")
    if args.number < 1:
        parser.error("number must be positive")
    return PrTarget(repo=args.repo, number=args.number, author=args.author, head=args.head)


def prepare(target: PrTarget) -> dict[str, object]:
    check_rex()
    clone = find_clone(target)
    fetch_head(clone, target)
    pruned = prune_stale(clone, target)
    worktree = add_worktree(clone, target)
    pane = launch(clone, target, worktree)
    return {
        "prepared": True,
        "tab": target.label,
        "pane": pane,
        "worktree": str(worktree.path),
        "branch": worktree.branch,
        "removed": [str(path) for path in pruned.removed],
        "kept": [{"path": str(k.path), "reason": k.reason} for k in pruned.kept],
    }


def main() -> None:
    target = parse_args()
    try:
        out = prepare(target)
    except NotPrepared as e:
        out = {"prepared": False, "step": e.step, "error": e.error}
        if e.left is not None:
            out["left"] = e.left
        print(json.dumps({"repo": target.repo, "number": target.number, **out}))
        sys.exit(1)
    print(json.dumps({"repo": target.repo, "number": target.number, **out}))


if __name__ == "__main__":
    main()
