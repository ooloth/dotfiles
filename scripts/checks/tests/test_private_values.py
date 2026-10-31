#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for scripts/checks/private_values.py.

Run with: uv run scripts/checks/tests/test_private_values.py

Each test builds a throwaway git repo holding a private.env.example, writes files into it, and runs
the check against it as a subprocess with only the PRIVATE_* values the test chooses, so the check
stays a single file that nothing imports.
"""

from __future__ import annotations

import string
import subprocess
import sys
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st

CHECK = Path(__file__).resolve().parent.parent / "private_values.py"

EXAMPLE = """# Private values for this machine.

# machines: air mini work
# read by: the leak check
PRIVATE_TERMS="made-up-term"

# machines: work
# read by: example.bash
PRIVATE_PROJECT=example-project
"""


@dataclass(frozen=True)
class Run:
    status: int
    output: str


class Repo:
    """A git repo with private.env.example committed, ready for files a test adds."""

    def __init__(self, root: Path) -> None:
        self.root = root
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        self.write("private.env.example", EXAMPLE)
        self.write(".gitignore", "ignored/\n")
        self.add()

    def write(self, name: str, text: str) -> None:
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def add(self) -> None:
        subprocess.run(["git", "add", "-A"], cwd=self.root, check=True)

    def check(self, private: dict[str, str] | None = None, **env: str) -> Run:
        """Run the check with only these PRIVATE_* values and environment variables set."""
        result = subprocess.run(
            [sys.executable, str(CHECK)],
            cwd=self.root,
            env={"PATH": "/usr/bin:/bin", "HOME": str(self.root), **(private or {}), **env},
            capture_output=True,
            text=True,
        )
        return Run(result.returncode, result.stdout + result.stderr)


TERMS = {"PRIVATE_TERMS": "secret-host.internal another-name"}


class CheckTest(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.repo = Repo(Path(directory.name))


class Mentions(CheckTest):
    def test_a_repo_that_names_no_term_passes(self) -> None:
        self.repo.write("notes.md", "nothing to see\n")
        self.repo.add()
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 0, run.output)

    def test_a_term_in_a_tracked_file_fails_naming_path_line_and_term(self) -> None:
        self.repo.write("docs/notes.md", "first line\nsee secret-host.internal for details\n")
        self.repo.add()
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("docs/notes.md:2: secret-host.internal", run.output)

    def test_a_term_in_a_file_path_fails(self) -> None:
        self.repo.write("tools/another-name/config.yaml", "key: value\n")
        self.repo.add()
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("tools/another-name/config.yaml: another-name (in the path)", run.output)

    def test_a_term_in_an_untracked_file_git_does_not_ignore_fails(self) -> None:
        self.repo.write("new.md", "another-name\n")
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("new.md:1: another-name", run.output)

    def test_a_term_in_an_ignored_file_passes(self) -> None:
        self.repo.write("ignored/another-name.md", "another-name\n")
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 0, run.output)

    def test_every_line_and_term_in_a_file_is_reported(self) -> None:
        self.repo.write("a.md", "another-name\nok\nsecret-host.internal and another-name\n")
        self.repo.add()
        run = self.repo.check(TERMS)
        self.assertIn("a.md:1: another-name", run.output)
        self.assertIn("a.md:3: another-name", run.output)
        self.assertIn("a.md:3: secret-host.internal", run.output)

    @settings(max_examples=25, deadline=None, suppress_health_check=[HealthCheck.too_slow])
    @given(
        term=st.text(string.ascii_lowercase + string.digits + ".-", min_size=4, max_size=12),
        before=st.text(string.ascii_letters + "_/", max_size=6),
        after=st.text(string.ascii_letters + "_/", max_size=6),
        upper=st.lists(st.booleans(), min_size=12, max_size=12),
    )
    def test_a_term_in_any_letter_case_inside_a_longer_name_is_found(
        self, term: str, before: str, after: str, upper: list[bool]
    ) -> None:
        cased = "".join(c.upper() if up else c for c, up in zip(term, upper, strict=False))
        self.repo.write("found.txt", f"x = {before}{cased}{after}\n")
        self.repo.add()
        run = self.repo.check({"PRIVATE_TERMS": term})
        self.assertEqual(run.status, 1, run.output)
        self.assertIn(f"found.txt:1: {term}", run.output)


class Terms(CheckTest):
    @settings(max_examples=25, deadline=None, suppress_health_check=[HealthCheck.too_slow])
    @given(
        values=st.dictionaries(
            st.text(string.ascii_uppercase + string.digits + "_", min_size=1, max_size=8),
            st.lists(
                st.text(string.ascii_lowercase + string.digits + ".-:/", min_size=4, max_size=10),
                min_size=1,
                max_size=4,
            ),
            min_size=1,
            max_size=3,
        ),
        separator=st.sampled_from([" ", "  ", "\t", "="]),
        pick=st.integers(min_value=0),
    )
    def test_every_word_of_every_private_value_is_a_term(
        self, values: dict[str, list[str]], separator: str, pick: int
    ) -> None:
        private = {f"PRIVATE_{key}": separator.join(words) for key, words in values.items()}
        every_word = [word for words in values.values() for word in words]
        word = every_word[pick % len(every_word)]
        self.repo.write("leak.txt", f"{word}\n")
        self.repo.add()
        run = self.repo.check(private)
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("leak.txt:1:", run.output)

    def test_a_variable_outside_private_is_not_a_term(self) -> None:
        self.repo.write("a.md", "bin usr\n")
        self.repo.add()
        run = self.repo.check(TERMS, OTHER="bin usr")
        self.assertEqual(run.status, 0, run.output)


class NoTerms(CheckTest):
    def test_on_a_mac_with_no_private_values_the_check_fails_naming_private_env(self) -> None:
        for private in ({}, {"PRIVATE_TERMS": ""}, {"PRIVATE_TERMS": "  "}):
            with self.subTest(private=private):
                run = self.repo.check(private)
                self.assertEqual(run.status, 1, run.output)
                self.assertIn("private.env", run.output)

    def test_in_ci_or_an_orb_the_check_passes_and_says_it_skipped(self) -> None:
        for env in ({"CI": "true"}, {"AMP_ORB": "1"}):
            with self.subTest(env=env):
                run = self.repo.check({}, **env)
                self.assertEqual(run.status, 0, run.output)
                self.assertIn("skipped", run.output)


class DocumentedKeys(CheckTest):
    def test_a_key_used_in_tracked_code_that_the_example_lists_passes(self) -> None:
        self.repo.write("tools/x/shell.zsh", 'echo "${PRIVATE_PROJECT:?}"\n')
        self.repo.add()
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 0, run.output)

    def test_a_key_the_example_lacks_fails_naming_where_it_is_used(self) -> None:
        self.repo.write("tools/x/shell.zsh", "\n" + 'echo "${PRIVATE_MISSING}"\n')
        self.repo.add()
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("tools/x/shell.zsh:2: PRIVATE_MISSING", run.output)

    def test_a_key_the_example_lacks_fails_in_ci_too(self) -> None:
        self.repo.write("tools/x/shell.zsh", 'echo "${PRIVATE_MISSING}"\n')
        self.repo.add()
        run = self.repo.check({}, CI="true")
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("PRIVATE_MISSING", run.output)

    def test_a_longer_name_ending_in_private_is_not_a_key(self) -> None:
        self.repo.write("tools/ssh/utils.bash", 'chmod 600 "$SSH_PRIVATE_KEY"\n')
        self.repo.add()
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 0, run.output)

    def test_a_made_up_key_in_a_tests_folder_passes(self) -> None:
        self.repo.write("tools/x/tests/test_x.py", 'ENV = {"PRIVATE_MADE_UP": "x"}\n')
        self.repo.add()
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 0, run.output)


class ExampleFormat(CheckTest):
    def check_example(self, example: str) -> Run:
        self.repo.write("private.env.example", example)
        self.repo.add()
        return self.repo.check(TERMS)

    def test_a_key_with_no_machines_line_fails_naming_its_line(self) -> None:
        run = self.check_example("# read by: x\nPRIVATE_TERMS=a\n")
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("private.env.example:2: PRIVATE_TERMS has no `# machines:` line", run.output)

    def test_one_machines_line_covers_only_the_next_key(self) -> None:
        run = self.check_example("# machines: air\nPRIVATE_TERMS=a\nPRIVATE_PROJECT=b\n")
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("private.env.example:3: PRIVATE_PROJECT", run.output)

    def test_an_unknown_machine_fails_naming_it(self) -> None:
        run = self.check_example("# machines: air laptop\nPRIVATE_TERMS=a\n")
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("private.env.example:1: unknown machine laptop", run.output)

    def test_a_machines_line_naming_no_machine_fails(self) -> None:
        run = self.check_example("# machines:\nPRIVATE_TERMS=a\n")
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("private.env.example:1: names no machine", run.output)

    def test_a_line_that_is_not_a_comment_or_a_private_assignment_fails(self) -> None:
        run = self.check_example("# machines: air\nPRIVATE_TERMS=a\nPATH=/bin\n")
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("private.env.example:3: not a comment or a PRIVATE_<NAME>=", run.output)

    def test_a_missing_example_fails(self) -> None:
        (self.repo.root / "private.env.example").unlink()
        self.repo.add()
        run = self.repo.check(TERMS)
        self.assertEqual(run.status, 1, run.output)
        self.assertIn("private.env.example", run.output)


if __name__ == "__main__":
    unittest.main()
