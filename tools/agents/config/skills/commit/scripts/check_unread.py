#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Say whether anything in the repo could read the files a commit changes.

The commit skill runs this before step 2. Exit 0 means every path is a Markdown file and no file
outside Markdown names it in a string, names a directory above it in a string, or reads Markdown
files by extension, so the full test suite cannot see the change and may be skipped. Exit 1 means
something might read a path, and the full suite runs as usual. Exit 2 means the check could not
run, which is never a reason to skip anything.

A comment that cites a file by bare name ("per CLAUDE.md") is not a read. A file name in quotes
is, because that is how code opens a file, and so is any pattern that matches every Markdown file.
A name built at run time in some other way is not caught, which is why CI still runs every test.

Usage:
  check_unread.py <path>...      paths as given to `git commit -- <path>...`
"""

import re
import subprocess
import sys
from pathlib import Path

# Lockfiles and other Markdown are never readers. `-I` skips binaries.
EXCLUDE = [
    ":(exclude)*.md",
    ":(exclude)*.lock",
    ":(exclude)package-lock.json",
    ":(exclude)pnpm-lock.yaml",
]

# Patterns that read every Markdown file, whatever its name: globs, extension tests and regexes.
EVERY_MARKDOWN = [r"\*\.md", r"[\"']\.md[\"']", r"[})]\.md[\"']", r"\\\.md", r"\.md\$"]


def git(*args: str, cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)


def grep(root: Path, flag: str, patterns: list[str]) -> list[str]:
    """Lines in tracked files outside Markdown that match any pattern.

    Untracked files are left out: they are not in the commit, and CI never sees them.
    """
    args = ["grep", "-n", "-I", flag]
    for pattern in patterns:
        args += ["-e", pattern]
    result = git(*args, "--", ".", *EXCLUDE, cwd=root)
    if result.returncode == 1:
        return []
    if result.returncode != 0:
        raise RuntimeError(f"git grep failed: {result.stderr.strip()}")
    return result.stdout.splitlines()


def quoted(root: Path, name: str) -> list[str]:
    """Lines that hold `name`, optionally after a path prefix or before a slash, inside quotes."""
    pattern = re.compile(r"""(["'])(?:[^"'\n]*/)?\.?/?""" + re.escape(name) + r"/?\1")
    return [line for line in grep(root, "-F", [name]) if pattern.search(line.split(":", 2)[-1])]


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: check_unread.py <path>...", file=sys.stderr)
        return 2
    top = git("rev-parse", "--show-toplevel", cwd=Path.cwd())
    if top.returncode != 0:
        print(f"not in a git repository: {top.stderr.strip()}", file=sys.stderr)
        return 2
    root = Path(top.stdout.strip())
    paths = [(Path.cwd() / p).resolve().relative_to(root.resolve()).as_posix() for p in argv]

    reasons: list[str] = []
    for path in paths:
        if not path.endswith(".md"):
            reasons.append(f"{path}: not a Markdown file")
    try:
        for path in paths:
            for line in quoted(root, Path(path).name):
                reasons.append(f"{path} is named in a string: {line[:160]}")
            for parent in Path(path).parents:
                if parent.as_posix() != ".":
                    for line in quoted(root, parent.as_posix()):
                        reasons.append(f"{path}'s directory is named in a string: {line[:160]}")
        for line in grep(root, "-E", EVERY_MARKDOWN):
            reasons.append(f"something reads every Markdown file: {line[:160]}")
    except RuntimeError as error:
        print(error, file=sys.stderr)
        return 2

    if reasons:
        print("Run the full test suite. Something might read these paths:")
        print("\n".join(f"- {reason}" for reason in reasons))
        return 1
    print(f"Nothing outside Markdown reads {', '.join(paths)}. The full test suite may be skipped.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
