#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/claude/cc.bash, which starts Claude Code with a repo's related folders.

Run with: uv run tools/claude/tests/test_cc.py

Each test builds a throwaway HOME holding the repo at ~/Repos/ooloth/dotfiles, where utils.bash
expects it, and runs the script under macOS's own bash from a folder beside its siblings. A `claude`
stub on PATH records its arguments separated by NUL bytes, so no test reaches the real Claude Code. The
shipped map lists no folders, so the tests of the map's handling source the real cc.bash and
replace only its `related_dirs` lookup before calling `main`.
"""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

from hypothesis import given, settings
from hypothesis import strategies as st

REPO = Path(__file__).resolve().parent.parent.parent.parent
SCRIPT = "tools/claude/cc.bash"

CLAUDE_STUB = """#!/bin/bash
for arg in "$@"; do printf '%s\\0' "$arg"; done > "${CLAUDE_LOG}"
"""


@dataclass(frozen=True)
class Run:
    status: int
    output: str
    claude: list[str] | None


class Machine:
    """A temporary HOME and a folder of sibling repos for cc.bash to run in."""

    def __init__(self, root: Path) -> None:
        root = root.resolve()
        self.home = root / "home"
        dotfiles = self.home / "Repos" / "ooloth" / "dotfiles"
        dotfiles.parent.mkdir(parents=True)
        dotfiles.symlink_to(REPO)
        self.repos = root / "repos"
        self.app = self.repos / "app"
        self.app.mkdir(parents=True)
        self.stubs = root / "stubs"
        self.stubs.mkdir()
        claude = self.stubs / "claude"
        claude.write_text(CLAUDE_STUB)
        claude.chmod(0o755)
        self._claude_log = root / "claude.log"

    def sibling(self, name: str) -> None:
        (self.repos / name).mkdir()

    def _env(self, computer: str) -> dict[str, str]:
        return {
            "HOME": str(self.home),
            "PATH": f"{self.stubs}:/usr/bin:/bin:/usr/sbin:/sbin",
            "CLAUDE_LOG": str(self._claude_log),
            "COMPUTER": computer,
        }

    def _run(self, command: list[str], computer: str) -> Run:
        self._claude_log.unlink(missing_ok=True)
        result = subprocess.run(
            command,
            cwd=self.app,
            env=self._env(computer),
            capture_output=True,
            text=True,
            check=False,
        )
        claude = (
            # Bytes, because reading text would turn each \r into \n
            self._claude_log.read_bytes().decode().split("\0")[:-1]
            if self._claude_log.exists()
            else None
        )
        return Run(result.returncode, result.stdout + result.stderr, claude)

    def run(self, *args: str, computer: str = "air") -> Run:
        """Run the shipped cc.bash, as the `cc` alias does."""
        return self._run(["/bin/bash", str(REPO / SCRIPT), *args], computer)

    def run_with_map(self, related: list[str], *args: str, computer: str = "air") -> Run:
        """Run the shipped cc.bash with its lookup replaced by one that lists `related`."""
        lines = "".join(f"printf '%s\\n' {r!r}; " for r in related)
        program = f'source "$1"; related_dirs() {{ {lines}:; }}; shift; main "$@"'
        return self._run(["/bin/bash", "-c", program, "_", str(REPO / SCRIPT), *args], computer)


class UnmappedFolder(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.machine = Machine(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_starts_claude_exactly_as_the_old_alias_did(self) -> None:
        run = self.machine.run("--continue")

        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(run.claude, ["--permission-mode", "bypassPermissions", "--continue"])
        self.assertEqual(run.output, "")

    def test_work_laptop_starts_in_auto_mode(self) -> None:
        run = self.machine.run(computer="work")

        self.assertEqual(run.claude, ["--permission-mode", "auto"], run.output)

    def test_personal_macs_start_with_permissions_bypassed(self) -> None:
        for computer in ("air", "mini"):
            with self.subTest(computer=computer):
                run = self.machine.run(computer=computer)

                self.assertEqual(run.claude, ["--permission-mode", "bypassPermissions"], run.output)


class MappedFolder(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.machine = Machine(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_adds_each_related_folder_in_order_before_the_users_arguments(self) -> None:
        self.machine.sibling("infra")
        self.machine.sibling("docs")

        run = self.machine.run_with_map(["../infra", "../docs"], "--continue")

        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(
            run.claude,
            [
                "--permission-mode",
                "bypassPermissions",
                "--add-dir",
                "../infra",
                "--add-dir",
                "../docs",
                "--continue",
            ],
        )
        self.assertIn("../infra", run.output)
        self.assertIn("../docs", run.output)

    def test_skips_a_related_folder_that_is_not_cloned_and_names_it(self) -> None:
        self.machine.sibling("docs")

        run = self.machine.run_with_map(["../infra", "../docs"])

        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(
            run.claude, ["--permission-mode", "bypassPermissions", "--add-dir", "../docs"]
        )
        self.assertIn("../infra", run.output)


class Arguments(unittest.TestCase):
    @settings(max_examples=50, deadline=None)
    # A process argument can't hold a NUL or an unpaired surrogate, so those are left out
    @given(
        st.lists(
            st.text(
                st.characters(blacklist_categories=("Cs",), blacklist_characters="\x00"),
                max_size=12,
            )
        )
    )
    def test_reach_claude_unchanged(self, args: list[str]) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            run = Machine(Path(tmp)).run(*args)

        self.assertEqual(run.claude, ["--permission-mode", "bypassPermissions", *args], run.output)


if __name__ == "__main__":
    unittest.main()
