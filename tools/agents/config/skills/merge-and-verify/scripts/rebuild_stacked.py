#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Merge trunk into a stacked PR's branch after its base PR squash-merged, keeping only the PR's own change.

A squash merge puts the base PR on trunk as one new commit, so trunk's history holds none of the
base PR's commits the stacked branch carries. Git's merge base is then the trunk commit from
before the base PR, and a plain merge keeps the branch's copies of the base PR's earlier lines
wherever trunk's final version of them doesn't overlap: silently, with no conflict.

This rebuilds the merge from the branch's own diff instead. The own diff runs from the last
base-PR commit the branch contains (the merge base of the branch and the base PR's final head)
to the branch head. Every file that the merge leaves different from trunk, or that conflicts,
starts again from trunk's version, and the own diff is applied to it with --3way. The merge is
left uncommitted for the caller. The script then compares the staged tree, file by file, with
trunk plus the own diff built in a private index, and fails on any difference.

Usage, from the stacked branch's worktree with a clean tree:

    rebuild_stacked.py --base-pr-head <sha> [--trunk origin/trunk]
    rebuild_stacked.py --base-pr-head <sha> --check-only   # after resolving conflicts by hand

Exit 0: the staged tree is trunk plus the own diff, and nothing conflicts. Exit 1: conflicts
remain, or a file's content differs from trunk plus the own diff (both listed); resolve, then
rerun with --check-only. Exit 2: bad input, such as a dirty tree or an unknown commit.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def git(*args: str, check: bool = True, stdin: str | None = None) -> str:
    result = subprocess.run(["git", *args], capture_output=True, text=True, input=stdin)
    if check and result.returncode != 0:
        raise SystemExit(
            f"git {' '.join(args)} failed ({result.returncode}): {result.stderr.strip()}"
        )
    return result.stdout


def lines(text: str) -> set[str]:
    return {line for line in text.splitlines() if line}


def own_diff_base(head: str, base_pr_head: str) -> str:
    """The last base-PR commit the branch contains."""
    return git("merge-base", head, base_pr_head).strip()


def own_files(base: str, head: str) -> set[str]:
    return lines(git("diff", "--name-only", "--no-renames", base, head))


def differing_from(trunk: str) -> set[str]:
    return lines(git("diff", "--cached", "--name-only", "--no-renames", trunk))


def conflicted() -> set[str]:
    return lines(git("diff", "--name-only", "--diff-filter=U"))


def expected_tree(trunk: str, patch: str) -> tuple[str, set[str]]:
    """Trunk with the own diff applied, built in a private index: the tree the merge should stage.

    Returns the tree and the paths the patch could not apply cleanly, whose expected content is
    therefore unknown and has to be checked by hand.
    """
    with tempfile.TemporaryDirectory() as scratch:
        env_index = str(Path(scratch) / "index")
        env = {**os.environ, "GIT_INDEX_FILE": env_index}

        def run(*args: str) -> subprocess.CompletedProcess[str]:
            return subprocess.run(["git", *args], capture_output=True, text=True, env=env)

        run("read-tree", trunk)
        applied = run("apply", "--cached", "--3way", patch)
        unmerged = lines(run("diff", "--cached", "--name-only", "--diff-filter=U").stdout)
        unknown = unmerged | (
            {"<patch did not apply>"} if applied.returncode not in (0, 1) else set()
        )
        for path in unmerged:
            run("update-index", "--force-remove", "--", path)
        tree = run("write-tree").stdout.strip()
        return tree, unknown


def report(trunk: str, own: set[str], base: str, head: str) -> int:
    """Compare the staged tree with trunk plus the own diff, file by file and line by line."""
    stuck = conflicted()
    if stuck:
        print("Conflicts still to resolve:", *sorted(stuck), sep="\n  ")
        return 1
    with tempfile.NamedTemporaryFile("w", suffix=".patch", delete=False) as patch:
        patch.write(git("diff", "--binary", "--no-renames", base, head))
    expected, unknown = expected_tree(trunk, patch.name)
    staged = git("write-tree").strip()
    wrong = lines(git("diff", "--name-only", "--no-renames", expected, staged)) - unknown
    if wrong:
        print(
            "Staged content differs from trunk plus the branch's own diff (stale base-PR lines?):",
            *sorted(wrong),
            sep="\n  ",
        )
    if unknown:
        print(
            "The own diff did not apply cleanly here, so check these by hand:",
            *sorted(unknown),
            sep="\n  ",
        )
    if wrong:
        return 1
    print(f"OK: the staged tree is trunk plus the branch's own diff ({len(own)} files).")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument(
        "--base-pr-head", required=True, help="the base PR's final head commit, as GitHub lists it"
    )
    parser.add_argument("--trunk", default="origin/trunk")
    parser.add_argument(
        "--check-only", action="store_true", help="only compare the staged tree with trunk"
    )
    args = parser.parse_args()

    head = git("rev-parse", "HEAD").strip()
    base = own_diff_base(head, git("rev-parse", args.base_pr_head).strip())
    own = own_files(base, head)
    print(f"Own diff: {base[:8]}..{head[:8]}, {len(own)} files")

    if args.check_only:
        return report(args.trunk, own, base, head)

    if git("status", "--porcelain"):
        print("The working tree has changes; commit or stash them first.", file=sys.stderr)
        return 2

    git("merge", "--no-commit", "--no-ff", args.trunk, check=False)
    # Every file the merge touched differently from trunk starts again from trunk's version.
    rebuild = conflicted() | differing_from(args.trunk) | own
    for path in sorted(rebuild):
        on_trunk = subprocess.run(
            ["git", "cat-file", "-e", f"{args.trunk}:{path}"], capture_output=True
        )
        if on_trunk.returncode == 0:
            git("checkout", args.trunk, "--", path)
        else:
            git("rm", "-q", "--cached", "--ignore-unmatch", "--", path)
            Path(path).unlink(missing_ok=True)

    with tempfile.NamedTemporaryFile("w", suffix=".patch", delete=False) as patch:
        patch.write(git("diff", "--binary", "--no-renames", base, head))
    applied = subprocess.run(
        ["git", "apply", "--3way", "--index", patch.name], capture_output=True, text=True
    )
    if applied.returncode not in (0, 1):
        print(applied.stderr, file=sys.stderr)
        return 2
    return report(args.trunk, own, base, head)


if __name__ == "__main__":
    sys.exit(main())
