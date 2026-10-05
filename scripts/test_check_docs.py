#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for scripts/check-docs.py.

Run with: uv run scripts/test_check_docs.py

Each test builds a throwaway git repo, writes Markdown into it, and runs check-docs.py against it as
a subprocess, so the checker stays a single file that nothing imports.
"""

from __future__ import annotations

import random
import subprocess
import sys
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

CHECKER = Path(__file__).resolve().parent / "check-docs.py"
LIMIT = 100


@dataclass(frozen=True)
class Run:
    status: int
    stdout: str


def run_checker(files: dict[str, str], *, untracked: dict[str, str] | None = None) -> Run:
    """Commit `files` to a fresh repo, add `untracked` without committing, and run the checker."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        for name, text in files.items():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        for name, text in (untracked or {}).items():
            (root / name).write_text(text, encoding="utf-8")
        result = subprocess.run(
            [sys.executable, str(CHECKER)], cwd=root, capture_output=True, text=True
        )
        return Run(result.returncode, result.stdout + result.stderr)


def line(width: int, filler: str = "a") -> str:
    return filler * width


class Width(unittest.TestCase):
    def test_a_line_of_exactly_the_limit_passes(self) -> None:
        self.assertEqual(run_checker({"a.md": line(LIMIT) + "\n"}).status, 0)

    def test_a_line_one_over_the_limit_fails_naming_file_line_and_width(self) -> None:
        run = run_checker({"docs/a.md": "ok\n" + line(LIMIT + 1) + "\n"})
        self.assertEqual(run.status, 1)
        self.assertIn("docs/a.md:2: 101 columns", run.stdout)

    def test_width_counts_characters_not_bytes(self) -> None:
        self.assertEqual(run_checker({"a.md": line(LIMIT, "é") + "\n"}).status, 0)

    def test_every_overlong_line_is_reported_not_only_the_first(self) -> None:
        run = run_checker({"a.md": line(101) + "\n" + line(102) + "\n"})
        self.assertIn("a.md:1: 101 columns", run.stdout)
        self.assertIn("a.md:2: 102 columns", run.stdout)


class ExemptContent(unittest.TestCase):
    def assert_passes(self, text: str) -> None:
        run = run_checker({"a.md": text})
        self.assertEqual(run.status, 0, run.stdout)

    def test_frontmatter(self) -> None:
        self.assert_passes(f"---\ndescription: {line(150)}\n---\n\nprose\n")

    def test_backtick_fence(self) -> None:
        self.assert_passes(f"```bash\n{line(150)}\n```\n")

    def test_tilde_fence(self) -> None:
        self.assert_passes(f"~~~\n{line(150)}\n~~~\n")

    def test_a_longer_fence_containing_a_shorter_one(self) -> None:
        self.assert_passes(f"````md\n```\n{line(150)}\n```\n{line(150)}\n````\n")

    def test_an_indented_fence_in_a_list(self) -> None:
        self.assert_passes(f"- item\n\n  ```\n  {line(150)}\n  ```\n")

    def test_table_row(self) -> None:
        self.assert_passes(f"| a | b |\n|---|---|\n| {line(150)} | x |\n")

    def test_line_with_a_url(self) -> None:
        self.assert_passes(f"See https://example.com/{line(150)}\n")

    def test_a_fence_closed_by_a_different_character_stays_open(self) -> None:
        run = run_checker({"a.md": f"```\n~~~\n{line(150)}\n```\n{line(101)}\n"})
        self.assertIn("a.md:5: 101 columns", run.stdout)
        self.assertNotIn("a.md:3:", run.stdout)


class NothingSilentlySkipped(unittest.TestCase):
    def test_an_unclosed_fence_is_reported_with_the_line_it_opened_on(self) -> None:
        run = run_checker({"a.md": f"prose\n```\n{line(150)}\n"})
        self.assertEqual(run.status, 1)
        self.assertIn("a.md:2: code fence is never closed", run.stdout)

    def test_unclosed_frontmatter_is_reported(self) -> None:
        run = run_checker({"a.md": f"---\ntitle: x\n{line(150)}\n"})
        self.assertEqual(run.status, 1)
        self.assertIn("a.md:1: frontmatter is never closed", run.stdout)

    def test_a_horizontal_rule_after_line_one_is_not_frontmatter(self) -> None:
        run = run_checker({"a.md": f"prose\n\n---\n{line(101)}\n"})
        self.assertIn("a.md:4: 101 columns", run.stdout)


class WhichFiles(unittest.TestCase):
    def test_an_archive_directory_is_exempt_and_counted(self) -> None:
        run = run_checker({"tools/@archive/a.md": line(150) + "\n", "b.md": "ok\n"})
        self.assertEqual(run.status, 0, run.stdout)
        self.assertIn("checked 1 file (1 exempt)", run.stdout)

    def test_an_archive_directory_at_any_depth_is_exempt(self) -> None:
        run = run_checker({"features/x/@archive/plan/a.md": line(150) + "\n"})
        self.assertEqual(run.status, 0, run.stdout)

    def test_github_markdown_is_exempt(self) -> None:
        run = run_checker({".github/PULL_REQUEST_TEMPLATE.md": line(150) + "\n"})
        self.assertEqual(run.status, 0, run.stdout)

    def test_an_untracked_file_is_not_checked(self) -> None:
        run = run_checker({"a.md": "ok\n"}, untracked={"scratch.md": line(150) + "\n"})
        self.assertEqual(run.status, 0, run.stdout)

    def test_a_new_tracked_file_is_checked_without_configuration(self) -> None:
        run = run_checker({"some/new/place/a.md": line(101) + "\n"})
        self.assertIn("some/new/place/a.md:1: 101 columns", run.stdout)


class GeneratedDocuments(unittest.TestCase):
    """Random documents built from every block kind. The generator knows which lines are prose, so
    the expected report is computed independently of the checker's own classification."""

    def test_reported_lines_are_exactly_the_overlong_prose_lines(self) -> None:
        rng = random.Random(20261004)
        for case in range(150):
            lines: list[str] = []
            expected: set[int] = set()
            if rng.random() < 0.3:
                lines += ["---", f"description: {line(rng.randint(10, 160))}", "---"]
            for _ in range(rng.randint(1, 12)):
                kind = rng.choice(["prose", "prose", "fence", "tilde", "table", "url", "blank"])
                width = rng.randint(LIMIT - 5, LIMIT + 5)
                if kind == "prose":
                    lines.append(line(width, rng.choice("abé")))
                    if width > LIMIT:
                        expected.add(len(lines))
                elif kind in ("fence", "tilde"):
                    mark = "```" if kind == "fence" else "~~~"
                    lines += [mark, line(rng.randint(1, 160)), mark]
                elif kind == "table":
                    lines.append(f"| {line(width)} |")
                elif kind == "url":
                    lines.append(f"https://x.dev/{line(width)}")
                else:
                    lines.append("")
            run = run_checker({"g.md": "\n".join(lines) + "\n"})
            reported = {
                int(part.split(":")[1])
                for part in run.stdout.splitlines()
                if part.startswith("g.md:")
            }
            self.assertEqual(reported, expected, f"case {case}:\n" + "\n".join(lines))
            self.assertEqual(run.status, 1 if expected else 0, f"case {case}")


if __name__ == "__main__":
    unittest.main()
