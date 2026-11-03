#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Say whether a PR's own diff changed between the head a review read and the PR's head now.

A review describes the PR at one commit. When the head moves, two different things can have
happened: the PR's own changes were edited, or only the code around them moved (the base was
merged in, or the branch was rebased onto a newer base). This compares the PR's diff at each head, file by file, each
against its own base, so the first case is never mistaken for the second.

Usage:
  compare_heads.py <pr-number> --repo OWNER/NAME --old-base SHA --old-head SHA

--old-base and --old-head are the baseRefOid and headRefOid of the head the drafted review
describes, as last saved. The current ones are read from the PR, and the output prints all four in
full so the next comparison can use them.

Exit codes:
  0  the PR's own edits are identical in every file; only code outside them moved
  1  the PR's own edits changed in at least one file, or the PR gained or lost a file
  2  the comparison could not be made; stderr says why. Never read this as 0.

Only the lines the PR adds and removes are compared. Hunk headers and context lines shift
whenever the base changes around an edit, so comparing whole patches would call an untouched
edit changed. A file whose patch GitHub leaves out (binary, or too large) counts as changed,
because its sameness cannot be shown.

Output: the commits between the two heads, then each file in the PR's diff with its verdict, then
the files that changed between the heads outside the PR's diff. Under a changed file the edit
lines that differ are printed, and under a file added to or dropped from the PR, all of its edit
lines. A file whose edits are identical but whose surrounding code changed between the heads is
marked, since a finding that rests on that code may no longer hold.
"""

import argparse
import difflib
import json
import subprocess
import sys
from dataclasses import dataclass
from typing import Any, NoReturn

# GitHub's compare endpoint lists at most this many files and says nothing when it stops.
COMPARE_FILE_LIMIT = 300


def cannot_check(message: str) -> NoReturn:
    print(f"compare_heads: {message}", file=sys.stderr)
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
class FileDiff:
    path: str
    patch: str | None  # None when GitHub leaves the patch out


def edit_lines(patch: str) -> list[str]:
    """The lines a patch adds or removes, without hunk headers or context."""
    return [line for line in patch.splitlines() if line.startswith(("+", "-"))]


def differing_lines(old: list[str], new: list[str]) -> list[str]:
    """The lines that differ between two lists of edit lines, marked - (reviewed) and + (now)."""
    out: list[str] = []
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(a=old, b=new, autojunk=False).get_opcodes():
        if tag != "equal":
            out += [f"-{line}" for line in old[i1:i2]] + [f"+{line}" for line in new[j1:j2]]
    return out


@dataclass(frozen=True)
class Comparison:
    files: dict[str, FileDiff]
    status: str  # GitHub's ahead, behind, diverged or identical
    commits: list[tuple[str, str]]  # (sha, first line of the message)


def compare(repo: str, base: str, head: str) -> Comparison:
    """The diff GitHub shows for base...head (from their merge base)."""
    data = gh_json(["api", f"repos/{repo}/compare/{base}...{head}"])
    files = data.get("files", [])
    if len(files) >= COMPARE_FILE_LIMIT:
        cannot_check(
            f"{base}...{head} lists {len(files)} files, GitHub's limit, so some may be missing."
        )
    return Comparison(
        files={f["filename"]: FileDiff(f["filename"], f.get("patch")) for f in files},
        status=data.get("status", "unknown"),
        commits=[
            (c["sha"], (c["commit"]["message"].splitlines() or [""])[0])
            for c in data.get("commits", [])
        ],
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("pr", type=int)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--old-base", required=True)
    parser.add_argument("--old-head", required=True)
    args = parser.parse_args()

    pr = gh_json(["pr", "view", str(args.pr), "-R", args.repo, "--json", "baseRefOid,headRefOid"])
    new_base, new_head = pr["baseRefOid"], pr["headRefOid"]

    old_diff = compare(args.repo, args.old_base, args.old_head).files
    new_diff = compare(args.repo, new_base, new_head).files
    between = compare(args.repo, args.old_head, new_head)

    print(f"Reviewed: base {args.old_base}  head {args.old_head}")
    print(f"Now:      base {new_base}  head {new_head}")
    print()
    print(f"Commits between the two heads (GitHub says the new head is {between.status}):")
    for sha, subject in between.commits:
        print(f"  {sha[:8]} {subject}")
    if not between.commits:
        print("  none")
    print()
    print("The PR's own diff, file by file:")
    changed = False
    for path in sorted(old_diff.keys() | new_diff.keys()):
        old, new = old_diff.get(path), new_diff.get(path)
        shown: list[str] = []
        if old is None:
            verdict = "added to the PR"
            shown = edit_lines(new.patch) if new and new.patch else []
        elif new is None:
            verdict = "dropped from the PR"
            shown = edit_lines(old.patch) if old.patch else []
        elif old.patch is None or new.patch is None:
            verdict = "changed (GitHub left the patch out, so sameness cannot be shown)"
        elif edit_lines(old.patch) != edit_lines(new.patch):
            verdict = "changed"
            shown = differing_lines(edit_lines(old.patch), edit_lines(new.patch))
        elif path in between.files:
            verdict = "identical edits, but the code around them changed"
        else:
            verdict = "identical"
        changed = changed or not verdict.startswith("identical")
        print(f"  {path}: {verdict}")
        for line in shown:
            print(f"      {line}")

    outside = sorted(set(between.files) - set(new_diff))
    print()
    print(f"Changed between the two heads, outside the PR's diff ({len(outside)}):")
    for path in outside:
        print(f"  {path}")
    if not outside:
        print("  none")

    raise SystemExit(1 if changed else 0)


if __name__ == "__main__":
    main()
