#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for scripts/checks/test-dependencies.py.

Run with: uv run scripts/checks/tests/test_test_dependencies.py

Each test writes test files with script headers into a throwaway folder and runs the script against
them as a subprocess, so it stays a single file that nothing imports.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "test-dependencies.py"


@dataclass(frozen=True)
class Run:
    status: int
    stdout: str
    stderr: str


def run_script(files: dict[str, str]) -> Run:
    with tempfile.TemporaryDirectory() as tmp:
        paths = []
        for name, text in files.items():
            path = Path(tmp) / name
            path.write_text(text, encoding="utf-8")
            paths.append(str(path))
        result = subprocess.run(
            [sys.executable, str(SCRIPT), *paths], capture_output=True, text=True, check=False
        )
        return Run(result.returncode, result.stdout, result.stderr)


def header(*lines: str) -> str:
    body = "".join(f"# {line}\n" if line else "#\n" for line in lines)
    return f"#!/usr/bin/env -S uv run --script\n# /// script\n{body}# ///\nimport sys\n"


class Dependencies(unittest.TestCase):
    def test_each_dependency_is_printed_on_its_own_line(self) -> None:
        run = run_script({"test_a.py": header('dependencies = ["hypothesis", "pydantic==2.14.1"]')})
        self.assertEqual((run.status, run.stdout), (0, "hypothesis\npydantic==2.14.1\n"))

    def test_a_list_spread_over_several_lines_is_read_whole(self) -> None:
        text = header("dependencies = [", '  "beartype",', '  "hypothesis",', "]")
        run = run_script({"test_a.py": text})
        self.assertEqual((run.status, run.stdout), (0, "beartype\nhypothesis\n"))

    def test_files_are_combined_without_repeats_in_sorted_order(self) -> None:
        run = run_script(
            {
                "test_a.py": header('dependencies = ["pyyaml", "hypothesis"]'),
                "test_b.py": header('dependencies = ["hypothesis"]'),
            }
        )
        self.assertEqual((run.status, run.stdout), (0, "hypothesis\npyyaml\n"))

    def test_an_empty_list_or_no_header_adds_nothing(self) -> None:
        run = run_script(
            {
                "test_a.py": header('requires-python = ">=3.11"', "dependencies = []"),
                "test_b.py": "import sys\n",
            }
        )
        self.assertEqual((run.status, run.stdout), (0, ""))

    def test_a_header_that_is_not_valid_toml_fails_naming_the_file(self) -> None:
        run = run_script({"test_a.py": header('dependencies = ["hypothesis"')})
        self.assertEqual(run.status, 1)
        self.assertIn("test_a.py", run.stderr)
        self.assertNotIn("Traceback", run.stderr)

    def test_dependencies_that_are_not_a_list_of_strings_fail_naming_the_file(self) -> None:
        run = run_script({"test_a.py": header('dependencies = "hypothesis"')})
        self.assertEqual(run.status, 1)
        self.assertIn("test_a.py", run.stderr)

    def test_no_files_fails(self) -> None:
        run = run_script({})
        self.assertEqual(run.status, 1)
        self.assertIn("No test files", run.stderr)


if __name__ == "__main__":
    unittest.main()
