#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/bash/private-env.bash, which exports this machine's private values from the
ignored private.env, and for tools/bash/utils.bash, which loads them for a script started outside a
configured zsh.

Run with: uv run tools/bash/tests/test_private_env.py

Each test writes a private.env and a private.env.example into a temporary directory and calls
load_private_env in a bare shell. .zshrc runs it under zsh and every bash script under /bin/bash,
which is bash 3.2 on macOS, so each test runs in both.
"""

from __future__ import annotations

import re
import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
LOADER = REPO / "tools" / "bash" / "private-env.bash"
SHELLS = {"bash": ["/bin/bash", "--norc", "--noprofile", "-c"], "zsh": ["zsh", "-f", "-c"]}

EXAMPLE = """# Private values for this machine.
#
# machines: work
PRIVATE_PROJECT=example-project
# machines: air mini work
PRIVATE_TERMS=example-term
"""


@dataclass(frozen=True)
class Loaded:
    values: dict[str, str]
    stderr: str


class Sandbox:
    """A temporary folder holding private.env and private.env.example."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self.file = root / "private.env"
        self.example = root / "private.env.example"
        self.example.write_text(EXAMPLE)

    def load(
        self, shell: str, *flags: str, computer: str = "work", env: dict[str, str] | None = None
    ) -> Loaded:
        """Run load_private_env in SHELL and read back every PRIVATE_* variable it exported."""
        script = (
            f"source '{LOADER}'\n"
            f"load_private_env {' '.join(flags)} '{self.file}' '{self.example}'\n"
            "env | grep '^PRIVATE_' || true\n"
            'echo "PATH_AFTER=$PATH"\n'
        )
        result = subprocess.run(
            [*SHELLS[shell], script],
            env={
                "HOME": str(self.root),
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
                "COMPUTER": computer,
                **(env or {}),
            },
            capture_output=True,
            text=True,
            check=True,
        )
        values = dict(re.findall(r"^(PRIVATE_\w+|PATH_AFTER)=(.*)$", result.stdout, re.MULTILINE))
        return Loaded(values, result.stderr)


class PrivateEnvTest(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.sandbox = Sandbox(Path(directory.name))

    def each_shell(self):
        for shell in SHELLS:
            with self.subTest(shell=shell):
                yield shell


class Values(PrivateEnvTest):
    def test_each_assignment_is_exported_with_one_pair_of_surrounding_quotes_removed(self) -> None:
        self.sandbox.file.write_text(
            "# a comment\n"
            "\n"
            "PRIVATE_PLAIN=plain-value\n"
            'PRIVATE_DOUBLE="two words"\n'
            "PRIVATE_SINGLE='one'\n"
            "PRIVATE_EQUALS=a=b c=d\n"
            "PRIVATE_LAST=no-trailing-newline"
        )
        for shell in self.each_shell():
            loaded = self.sandbox.load(shell)

            self.assertEqual(
                loaded.values,
                {
                    "PRIVATE_PLAIN": "plain-value",
                    "PRIVATE_DOUBLE": "two words",
                    "PRIVATE_SINGLE": "one",
                    "PRIVATE_EQUALS": "a=b c=d",
                    "PRIVATE_LAST": "no-trailing-newline",
                    "PATH_AFTER": "/usr/bin:/bin:/usr/sbin:/sbin",
                },
            )

    def test_a_value_that_looks_like_a_command_is_kept_as_text_and_runs_nothing(self) -> None:
        marker = self.sandbox.root / "ran"
        self.sandbox.file.write_text(
            f"PRIVATE_SUBSTITUTION=$(touch {marker})\nPRIVATE_BACKTICKS=`touch {marker}`\n"
        )
        for shell in self.each_shell():
            loaded = self.sandbox.load(shell)

            self.assertEqual(loaded.values["PRIVATE_SUBSTITUTION"], f"$(touch {marker})")
            self.assertEqual(loaded.values["PRIVATE_BACKTICKS"], f"`touch {marker}`")
            self.assertFalse(marker.exists())


class SkippedLines(PrivateEnvTest):
    def setUp(self) -> None:
        super().setUp()
        self.sandbox.file.write_text(
            "PRIVATE_KEPT=yes\nnot an assignment\nPATH=/somewhere/else\nprivate_lower=x\n"
        )

    def test_a_line_that_is_not_a_private_assignment_is_not_exported(self) -> None:
        for shell in self.each_shell():
            loaded = self.sandbox.load(shell)

            self.assertEqual(loaded.values["PATH_AFTER"], "/usr/bin:/bin:/usr/sbin:/sbin")
            self.assertEqual(set(loaded.values), {"PRIVATE_KEPT", "PATH_AFTER"})

    def test_with_warnings_each_skipped_line_is_named_by_its_number(self) -> None:
        for shell in self.each_shell():
            loaded = self.sandbox.load(shell, "--warn")

            self.assertEqual(re.findall(r"line (\d+)", loaded.stderr), ["2", "3", "4"])

    def test_without_warnings_nothing_is_printed(self) -> None:
        for shell in self.each_shell():
            self.assertEqual(self.sandbox.load(shell).stderr, "")


class MissingFile(PrivateEnvTest):
    def test_on_a_mac_a_missing_file_is_named(self) -> None:
        for shell in self.each_shell():
            loaded = self.sandbox.load(shell, "--warn")

            self.assertIn(str(self.sandbox.file), loaded.stderr)

    def test_in_an_orb_or_ci_or_without_warnings_a_missing_file_prints_nothing(self) -> None:
        cases = {"orb": ({"AMP_ORB": "1"}, ["--warn"]), "ci": ({"CI": "true"}, ["--warn"])}
        cases["quiet"] = ({}, [])
        for name, (env, flags) in cases.items():
            for shell in self.each_shell():
                with self.subTest(case=name):
                    self.assertEqual(self.sandbox.load(shell, *flags, env=env).stderr, "")


class MissingKeys(PrivateEnvTest):
    def test_a_key_the_example_marks_for_this_machine_is_named_when_unset_or_empty(self) -> None:
        for content in ("PRIVATE_TERMS=x\n", "PRIVATE_TERMS=x\nPRIVATE_PROJECT=\n"):
            self.sandbox.file.write_text(content)
            for shell in self.each_shell():
                with self.subTest(content=content):
                    loaded = self.sandbox.load(shell, "--warn", computer="work")

                    self.assertIn("PRIVATE_PROJECT", loaded.stderr)
                    self.assertNotIn("PRIVATE_TERMS", loaded.stderr)

    def test_a_key_marked_only_for_another_machine_is_not_named(self) -> None:
        self.sandbox.file.write_text("PRIVATE_TERMS=x\n")
        for shell in self.each_shell():
            self.assertEqual(self.sandbox.load(shell, "--warn", computer="air").stderr, "")

    def test_a_machine_with_every_key_it_needs_prints_nothing(self) -> None:
        self.sandbox.file.write_text("PRIVATE_TERMS=x\nPRIVATE_PROJECT=p\n")
        for shell in self.each_shell():
            self.assertEqual(self.sandbox.load(shell, "--warn", computer="work").stderr, "")


class ScriptsStartedOutsideZsh(unittest.TestCase):
    """A script that sources tools/bash/utils.bash, as every bash script here does."""

    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.home = Path(directory.name)
        # utils.bash fixes DOTFILES to this path, so the checkout it reads lives under HOME
        checkout = self.home / "Repos" / "ooloth" / "dotfiles"
        checkout.mkdir(parents=True)
        (checkout / "tools").symlink_to(REPO / "tools")
        (checkout / "private.env").write_text("PRIVATE_FROM_FILE=from-file\n")

    def run_script(self, env: dict[str, str]) -> str:
        script = f'source "{REPO}/tools/bash/utils.bash"; echo "value=${{PRIVATE_FROM_FILE:-}}"'
        result = subprocess.run(
            ["/bin/bash", "--norc", "--noprofile", "-c", script],
            env={
                "HOME": str(self.home),
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
                "COMPUTER": "work",
                **env,
            },
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertEqual(result.stderr, "")
        return result.stdout.strip()

    def test_a_script_with_no_private_values_in_its_environment_reads_them_from_the_file(
        self,
    ) -> None:
        self.assertEqual(self.run_script({}), "value=from-file")

    def test_a_script_that_inherited_private_values_keeps_them(self) -> None:
        self.assertEqual(self.run_script({"PRIVATE_OTHER": "inherited"}), "value=")


if __name__ == "__main__":
    unittest.main()
