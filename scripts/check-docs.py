#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Check that Markdown prose in this repo wraps at 100 columns.

Run with: uv run scripts/check-docs.py [--verbose]
Its tests: uv run scripts/test_check_docs.py

Checks every Markdown file git tracks, so a new file is covered without editing this script and a
scratch file nobody committed is not. Width is counted in characters, not bytes.

Not checked, because wrapping them would break them or because they are not prose:
- frontmatter, when the file opens with `---`
- fenced code blocks (``` or ~~~), which close only on the same character, at least as long
- table rows (lines starting with `|`)
- lines containing a URL
- files under any `@archive/` directory, which are frozen
- files under `.github/`, whose text is pasted into GitHub, where a single newline is a line break

A fence or frontmatter block that never closes is reported rather than exempting the rest of the
file, so a typo cannot silently switch the check off.

Deliberately narrow: each result is a fact, never a judgement, so a failure is always worth fixing.

TODO: checks worth porting from ../puzzles/scripts/check-docs.py, each a fact about a file:
- relative Markdown links resolve to files that exist (check_links)
- paths written in backticks resolve to files that exist (check_backticked_paths)
- no link points at a heading anchor, per the documentation standard (check_heading_anchors)
- each docs/questions/*.md has the six sections its README requires, in order
- docs/questions/*.md frontmatter has the keys its README lists
- a `.claude/` directory under docs/ is a harness artifact to delete (check_harness_artifacts)
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

LIMIT = 100
FENCE = re.compile(r"^\s*(`{3,}|~{3,})")
URL = re.compile(r"https?://")


@dataclass(frozen=True)
class Problem:
    path: str
    line: int
    message: str

    def __str__(self) -> str:
        return f"{self.path}:{self.line}: {self.message}"


def is_exempt(path: str) -> bool:
    parts = Path(path).parts
    return "@archive" in parts or parts[0] == ".github"


def tracked_markdown() -> list[str]:
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z", "--", "*.md"], capture_output=True, text=True, check=True
        )
    except (OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(
            f"Could not list tracked files with git ({error}). Run this inside the repo."
        ) from None
    return sorted(name for name in result.stdout.split("\0") if name)


def problems_in(path: str, text: str) -> list[Problem]:
    """Every overlong prose line in one file, plus any fence or frontmatter left open."""
    lines = text.splitlines()
    problems: list[Problem] = []
    start = 0

    if lines and lines[0] == "---":
        close = next((i for i in range(1, len(lines)) if lines[i] in ("---", "...")), None)
        if close is None:
            return [Problem(path, 1, "frontmatter is never closed")]
        start = close + 1

    fence: str | None = None  # the opening run of ` or ~ while inside a code block
    fence_line = 0
    for index in range(start, len(lines)):
        number = index + 1
        current = lines[index]
        opening = FENCE.match(current)
        if fence is None:
            if opening:
                fence, fence_line = opening.group(1), number
                continue
        else:
            closes = (
                opening is not None
                and opening.group(1)[0] == fence[0]
                and len(opening.group(1)) >= len(fence)
                and current.strip() == opening.group(1)
            )
            if closes:
                fence = None
            continue

        if len(current) <= LIMIT or current.lstrip().startswith("|") or URL.search(current):
            continue
        problems.append(Problem(path, number, f"{len(current)} columns"))

    if fence is not None:
        problems.append(Problem(path, fence_line, "code fence is never closed"))
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--verbose", action="store_true", help="also list the exempt files")
    args = parser.parse_args()

    files = tracked_markdown()
    exempt = [path for path in files if is_exempt(path)]
    checked = [path for path in files if not is_exempt(path)]

    problems: list[Problem] = []
    for path in checked:
        try:
            text = Path(path).read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as error:
            raise SystemExit(f"Could not read {path} as UTF-8 text ({error}).") from None
        problems.extend(problems_in(path, text))

    for problem in problems:
        print(problem)
    if args.verbose:
        for path in exempt:
            print(f"exempt: {path}")

    noun = "file" if len(checked) == 1 else "files"
    print(f"checked {len(checked)} {noun} ({len(exempt)} exempt), {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
