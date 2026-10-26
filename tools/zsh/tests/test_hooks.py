#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for activate_venv in tools/zsh/config/hooks.zsh, which activates the nearest Python virtual
environment when zsh starts and on every cd.

Run with: uv run tools/zsh/tests/test_hooks.py

Each test builds folders in a temporary directory, with fake activate scripts that set VIRTUAL_ENV,
then starts a bare zsh in one of them, sources the real file, and prints VIRTUAL_ENV. A few tests
cd somewhere else afterwards, which runs the chpwd hook.
"""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
UTILS = REPO / "tools" / "zsh" / "utils.zsh"
HOOKS = REPO / "tools" / "zsh" / "config" / "hooks.zsh"


class ActivateVenv(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name).resolve()

    def venv(self, path: str) -> Path:
        venv = self.root / path
        (venv / "bin").mkdir(parents=True)
        (venv / "bin" / "activate").write_text(
            f'export VIRTUAL_ENV="{venv}"\ndeactivate() {{ unset -f deactivate; }}\n'
        )
        return venv

    def folder(self, path: str) -> Path:
        folder = self.root / path
        folder.mkdir(parents=True, exist_ok=True)
        return folder

    def virtual_env(self, start: Path, then: Path | None = None) -> str:
        script = f"source '{UTILS}'\nsource '{HOOKS}'\n"
        if then is not None:
            script += f"cd '{then}'\n"
        script += 'print -r -- "${VIRTUAL_ENV-<none>}"\n'
        result = subprocess.run(
            ["zsh", "-f", "-c", script],
            cwd=start,
            env={
                "HOME": os.environ["HOME"],
                "PATH": "/usr/bin:/bin",
                "TERM": "dumb",
                "COMPUTER_NAME": "Air",
            },
            capture_output=True,
            text=True,
            check=True,
            timeout=10,
        )
        return result.stdout.strip()

    def test_a_venv_in_the_starting_folder_is_activated(self) -> None:
        venv = self.venv("project/.venv")
        self.assertEqual(self.virtual_env(self.root / "project"), str(venv))

    def test_the_nearest_venv_above_a_deep_folder_is_activated(self) -> None:
        self.venv("project/.venv")
        nearer = self.venv("project/packages/app/.venv")
        self.assertEqual(
            self.virtual_env(self.folder("project/packages/app/src/module")), str(nearer)
        )

    def test_a_folder_named_venv_counts_when_there_is_no_dot_venv(self) -> None:
        venv = self.venv("project/venv")
        self.assertEqual(self.virtual_env(self.folder("project/src")), str(venv))

    def test_dot_venv_wins_over_venv_in_the_same_folder(self) -> None:
        dot_venv = self.venv("project/.venv")
        self.venv("project/venv")
        self.assertEqual(self.virtual_env(self.root / "project"), str(dot_venv))

    def test_no_venv_anywhere_above_leaves_none_active(self) -> None:
        self.assertEqual(self.virtual_env(self.folder("plain/deep/folder")), "<none>")

    def test_leaving_a_project_deactivates_its_venv(self) -> None:
        self.venv("project/.venv")
        self.assertEqual(
            self.virtual_env(self.root / "project", then=self.folder("elsewhere")), "<none>"
        )

    def test_moving_into_another_project_activates_its_venv(self) -> None:
        self.venv("one/.venv")
        two = self.venv("two/.venv")
        self.assertEqual(self.virtual_env(self.root / "one", then=self.root / "two"), str(two))


if __name__ == "__main__":
    unittest.main()
