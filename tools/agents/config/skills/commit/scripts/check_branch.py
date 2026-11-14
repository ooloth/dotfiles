#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Say whether the checkout is still on the branch this session is working on.

The commit skill runs this before it commits. Another session sharing the checkout can switch its
branch at any moment, and a path-limited commit then lands on that session's branch without any
error. Exit 0 means HEAD is on the named branch. Exit 1 means it is on another branch or detached,
and the output names both branches and the reflog's latest checkout, so the caller can tell the
user what happened. Exit 2 means the check could not run, which is never a reason to commit.

Usage:
  check_branch.py <branch>      the branch this session created or switched to
"""

import subprocess
import sys


def git(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], capture_output=True, text=True)


def latest_checkout() -> str:
    """The reflog's most recent checkout line, or a note that there is none."""
    reflog = git("reflog", "-n", "50", "--date=iso", "--format=%gd %gs")
    for line in reflog.stdout.splitlines():
        if "checkout: moving from" in line:
            return line
    return "(no checkout in the last 50 reflog entries)"


def main(argv: list[str]) -> int:
    if len(argv) != 1 or not argv[0].strip():
        print(__doc__, file=sys.stderr)
        return 2
    expected = argv[0].strip()

    inside = git("rev-parse", "--is-inside-work-tree")
    if inside.returncode != 0 or inside.stdout.strip() != "true":
        print("Not inside a git work tree, so the branch could not be checked.", file=sys.stderr)
        return 2

    head = git("symbolic-ref", "--quiet", "--short", "HEAD")
    current = head.stdout.strip() if head.returncode == 0 else None
    if current == expected:
        return 0

    found = f"on branch {current}" if current else "on a detached HEAD"
    print(
        f"Expected to be on {expected}, but the checkout is {found}.\n"
        f"Latest checkout in the reflog: {latest_checkout()}\n"
        "Another session may have switched this checkout. Commit nothing; tell the user."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
