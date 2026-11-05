#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/bash/private-env.bash, which exports this machine's private values from the
ignored private.env, and for tools/bash/utils.bash, which loads them for a script started outside a
configured zsh.

Run with: uv run tools/bash/tests/test_private_env.py

Each test writes a private.env into a temporary directory and calls load_private_env in a bare
shell. .zshrc runs it under zsh and every bash script under /bin/bash, which is bash 3.2 on macOS,
so each test runs in both.
"""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
LOADER = REPO / "tools" / "bash" / "private-env.bash"
SHELLS = {"bash": ["/bin/bash", "--norc", "--noprofile", "-c"], "zsh": ["zsh", "-f", "-c"]}
PATH = "/usr/bin:/bin:/usr/sbin:/sbin"


class Loader(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.file = Path(directory.name) / "private.env"

    def load(self, shell: str, after: str = "") -> subprocess.CompletedProcess[str]:
        """Load the file in SHELL, run AFTER, then list what a child process sees."""
        script = (
            f"source '{LOADER}'\n"
            f"load_private_env '{self.file}'\n"
            f"{after}\n"
            "env | grep -E '^(PRIVATE_|LATER=)' | sort || true\n"
        )
        return subprocess.run(
            [*SHELLS[shell], script],
            env={"HOME": str(self.file.parent), "PATH": PATH},
            capture_output=True,
            text=True,
            check=True,
        )

    def test_quoted_and_unquoted_values_reach_a_child_process_unchanged(self) -> None:
        self.file.write_text(
            "# a comment\n"
            "PRIVATE_PLAIN=plain-value\n"
            'PRIVATE_DOUBLE="two words"\n'
            "PRIVATE_SINGLE='a=b c=d'\n"
            "\n"
            "PRIVATE_LAST=no-trailing-newline"
        )
        for shell in SHELLS:
            with self.subTest(shell=shell):
                loaded = self.load(shell)

                self.assertEqual(
                    loaded.stdout.splitlines(),
                    [
                        "PRIVATE_DOUBLE=two words",
                        "PRIVATE_LAST=no-trailing-newline",
                        "PRIVATE_PLAIN=plain-value",
                        "PRIVATE_SINGLE=a=b c=d",
                    ],
                )
                self.assertEqual(loaded.stderr, "")

    def test_a_variable_assigned_after_loading_is_not_exported(self) -> None:
        self.file.write_text("PRIVATE_KEPT=x\n")
        for shell in SHELLS:
            with self.subTest(shell=shell):
                loaded = self.load(shell, after="LATER=not-exported")

                self.assertEqual(loaded.stdout.splitlines(), ["PRIVATE_KEPT=x"])

    def test_a_missing_file_sets_nothing_and_prints_nothing(self) -> None:
        for shell in SHELLS:
            with self.subTest(shell=shell):
                loaded = self.load(shell)

                self.assertEqual(loaded.stdout, "")
                self.assertEqual(loaded.stderr, "")


class ScriptsStartedOutsideZsh(unittest.TestCase):
    """A script that sources tools/bash/utils.bash, as every bash script here does."""

    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.home = Path(directory.name)
        # The install. utils.bash reads private.env from here, whichever checkout it is sourced from
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
