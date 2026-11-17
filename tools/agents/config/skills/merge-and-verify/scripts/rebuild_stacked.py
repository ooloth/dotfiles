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

This merges three ways with the base set explicitly instead: `git merge-tree --merge-base` with
the last base-PR commit the branch contains (the merge base of the branch and the base PR's final
head) as the base, trunk on one side and the branch head on the other. Git's own merge carries
renames and splits, so a file the branch split keeps trunk's later edits to it. The result, with
any conflicts as unmerged index entries, replaces the index and working tree of a `git merge
--no-commit` of trunk, and is left uncommitted for the caller.

Two checks then run, each by a method of its own. The staged tree must match that three-way
merge, file by file, which catches a hand-edited or plain merge that kept stale base-PR lines.
And every path the branch's own diff changes must differ from trunk in the staged tree, unless
trunk already holds the branch's version of it, which catches a rebuild that dropped the branch's
change and left trunk's tree: a merge of trunk alone would pass any check that compares the
result with a rebuild made the same way.

Usage, from the stacked branch's worktree with a clean tree:

    rebuild_stacked.py --base-pr-head <sha> [--trunk origin/trunk]
    rebuild_stacked.py --base-pr-head <sha> --check-only   # after resolving conflicts by hand

Exit 0: the staged tree is the three-way merge, carries every path of the own diff, and nothing
conflicts. Exit 1: conflicts remain, or a file differs from the merge, or a path of the own diff
is missing its change (each listed); resolve, then rerun with --check-only. Exit 2: bad input,
such as a dirty tree or an unknown commit.

A path whose change trunk made too, in different words, can still match trunk after the merge
and be listed as missing. Check such a path by hand: the listing names it.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass


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


def conflicted() -> set[str]:
    return lines(git("diff", "--name-only", "--diff-filter=U"))


@dataclass(frozen=True)
class ConflictEntry:
    mode: str
    blob: str
    stage: str
    path: str


@dataclass(frozen=True)
class ThreeWayMerge:
    tree: str
    conflicts: tuple[ConflictEntry, ...]

    @property
    def conflicted_paths(self) -> set[str]:
        return {entry.path for entry in self.conflicts}


def three_way_merge(base: str, trunk: str, head: str) -> ThreeWayMerge:
    """Trunk and the branch head merged with `base` as their base, written to the object store."""
    result = subprocess.run(
        ["git", "merge-tree", "--write-tree", "-z", "--merge-base", base, trunk, head],
        capture_output=True,
        text=True,
    )
    if result.returncode not in (0, 1):
        raise SystemExit(f"git merge-tree failed ({result.returncode}): {result.stderr.strip()}")
    fields = result.stdout.split("\0")
    tree = fields[0]
    assert tree, "git merge-tree printed no tree"
    entries: list[ConflictEntry] = []
    if result.returncode == 1:
        for field in fields[1:]:
            if not field:
                break
            meta, path = field.split("\t", 1)
            mode, blob, stage = meta.split(" ")
            entries.append(ConflictEntry(mode, blob, stage, path))
        assert entries, "git merge-tree reported conflicts but listed no conflicted file"
    return ThreeWayMerge(tree, tuple(entries))


def blobs(tree: str) -> dict[str, str]:
    """Every path in `tree` and the object it holds."""
    found: dict[str, str] = {}
    for record in git("ls-tree", "-r", "-z", tree).split("\0"):
        if not record:
            continue
        meta, path = record.split("\t", 1)
        found[path] = meta.split(" ")[2]
    return found


def stage(merged: ThreeWayMerge) -> None:
    """Replace the index and working tree with the merge, conflicts as unmerged entries."""
    git("read-tree", "--reset", "-u", merged.tree)
    if not merged.conflicts:
        return
    zeros = "0" * len(merged.tree)
    removals = "".join(f"0 {zeros}\t{path}\n" for path in sorted(merged.conflicted_paths))
    stages = "".join(f"{e.mode} {e.blob} {e.stage}\t{e.path}\n" for e in merged.conflicts)
    git("update-index", "--index-info", stdin=removals + stages)


CONFLICT_MARKERS = ("<<<<<<< ", ">>>>>>> ")


def holds_markers(blob: str | None) -> bool:
    if blob is None:
        return False
    text = git("cat-file", "-p", blob)
    return any(line.startswith(CONFLICT_MARKERS) for line in text.splitlines())


def report(trunk: str, own: set[str], base: str, head: str) -> int:
    """Hold the staged tree against the three-way merge and against the branch's own change."""
    stuck = conflicted()
    if stuck:
        print("Conflicts still to resolve:", *sorted(stuck), sep="\n  ")
        return 1
    merged = three_way_merge(base, trunk, head)
    staged = git("write-tree").strip()
    unknown = merged.conflicted_paths
    wrong = lines(git("diff", "--name-only", "--no-renames", merged.tree, staged)) - unknown
    on_staged, on_trunk, on_head = blobs(staged), blobs(trunk), blobs(head)
    missing = {
        path
        for path in own
        if on_staged.get(path) == on_trunk.get(path) and on_head.get(path) != on_trunk.get(path)
    }
    marked = {path for path in unknown if holds_markers(on_staged.get(path))}
    if marked:
        print("These still hold conflict markers:", *sorted(marked), sep="\n  ")
    if wrong:
        print(
            "Staged content differs from trunk merged with the branch's own diff"
            " (stale base-PR lines?):",
            *sorted(wrong),
            sep="\n  ",
        )
    if missing:
        print(
            "The branch's own change is missing from these paths, which match trunk:",
            *sorted(missing),
            sep="\n  ",
        )
    if unknown:
        print(
            "These conflicted in the merge, so check them by hand:",
            *sorted(unknown),
            sep="\n  ",
        )
    if wrong or missing or marked:
        return 1
    print(f"OK: the staged tree is trunk merged with the branch's own diff ({len(own)} files).")
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
    stage(three_way_merge(base, args.trunk, head))
    return report(args.trunk, own, base, head)


if __name__ == "__main__":
    sys.exit(main())
