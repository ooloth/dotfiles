#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for how `symlinks` finds link scripts and sweeps broken links, in tools/bash/utils.bash and
features/update/symlinks.bash.

Run with: uv run scripts/test_symlinks.py

Each test builds a throwaway HOME holding the repo at ~/Repos/ooloth/dotfiles, where utils.bash
expects it, and runs the code under macOS's own bash with no terminal, the way CI does. A `trash`
stub on PATH records what it was asked to remove and removes it, so a run leaves nothing in the real
Trash.
"""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

TRASH_STUB = """#!/bin/bash
printf '%s\\n' "$@" >> "${TRASH_LOG}"
rm "$@"
"""


@dataclass(frozen=True)
class Run:
    status: int
    output: str
    trashed: list[str]


class FakeHome:
    """A temporary HOME with the repo where utils.bash sources it from."""

    def __init__(self, root: Path) -> None:
        self.path = root / "home"
        self.dotfiles = self.path / "Repos" / "ooloth" / "dotfiles"
        self.dotfiles.parent.mkdir(parents=True)
        self.dotfiles.symlink_to(REPO)
        self._bin = root / "bin"
        self._bin.mkdir()
        trash = self._bin / "trash"
        trash.write_text(TRASH_STUB)
        trash.chmod(0o755)
        self._trash_log = root / "trash.log"

    def link(self, at: str, to: Path | str) -> Path:
        """Create a symlink at HOME-relative `at` pointing to `to`."""
        path = self.path / at
        path.parent.mkdir(parents=True, exist_ok=True)
        path.symlink_to(to)
        return path

    def run(self, script: str, *, dotfiles: str | None = None) -> Run:
        """Source utils.bash in this HOME, optionally override DOTFILES, then run `script`."""
        override = "" if dotfiles is None else f'DOTFILES="{dotfiles}"\n'
        body = f'source "$HOME/Repos/ooloth/dotfiles/tools/bash/utils.bash"\n{override}{script}\n'
        env = {
            "HOME": str(self.path),
            "PATH": f"{self._bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "TRASH_LOG": str(self._trash_log),
        }
        result = subprocess.run(
            ["/bin/bash", "-c", body], env=env, capture_output=True, text=True, check=False
        )
        log = self._trash_log.read_text().splitlines() if self._trash_log.exists() else []
        return Run(result.returncode, result.stdout + result.stderr, log)


class LinkScriptsTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.home = FakeHome(Path(self._tmp.name))
        self.repo = Path(self._tmp.name) / "repo"

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def _script(self, path: str) -> Path:
        script = self.repo / "tools" / path
        script.parent.mkdir(parents=True, exist_ok=True)
        script.write_text("")
        return script

    def test_only_scripts_at_a_tools_root_are_listed(self) -> None:
        a = self._script("a/link.bash")
        b = self._script("b/link.bash")
        self._script("a/wip/link.bash")
        self._script("@new/link.bash")
        self._script("@archive/old/link.bash")
        run = self.home.run("link_scripts", dotfiles=str(self.repo))
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(run.output.splitlines(), [str(a), str(b)])

    def test_every_link_script_in_the_repo_is_listed(self) -> None:
        expected = sorted(
            str(self.home.dotfiles / p.relative_to(REPO))
            for p in REPO.glob("tools/*/link.bash")
            if not p.parent.name.startswith("@")
        )
        run = self.home.run("link_scripts")
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(sorted(run.output.splitlines()), expected)

    def test_no_link_scripts_is_an_error_naming_where_it_looked(self) -> None:
        (self.repo / "tools").mkdir(parents=True)
        run = self.home.run("link_scripts", dotfiles=str(self.repo))
        self.assertNotEqual(run.status, 0, run.output)
        self.assertIn(str(self.repo), run.output)


class SweepTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.home = FakeHome(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_broken_link_into_the_repo_is_trashed(self) -> None:
        link = self.home.link(".claude/hooks", self.home.dotfiles / "tools/claude/config/hooks")
        run = self.home.run('remove_broken_repo_symlinks "$HOME/.claude"')
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(run.trashed, [str(link)])
        self.assertFalse(link.is_symlink())

    def test_broken_link_outside_the_repo_is_kept(self) -> None:
        link = self.home.link(".local/bin/other-tool", "/nonexistent/other-tool")
        run = self.home.run('remove_broken_repo_symlinks "$HOME/.local/bin"')
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(run.trashed, [])
        self.assertTrue(link.is_symlink())

    def test_working_link_into_the_repo_is_kept(self) -> None:
        link = self.home.link(
            ".claude/CLAUDE.md", self.home.dotfiles / "tools/claude/config/CLAUDE.md"
        )
        run = self.home.run('remove_broken_repo_symlinks "$HOME/.claude"')
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(run.trashed, [])
        self.assertTrue(link.is_symlink())

    def test_empty_dotfiles_stops_the_sweep_before_it_removes_anything(self) -> None:
        link = self.home.link(".claude/hooks", self.home.dotfiles / "tools/claude/config/hooks")
        run = self.home.run('remove_broken_repo_symlinks "$HOME/.claude"', dotfiles="")
        self.assertNotEqual(run.status, 0, run.output)
        self.assertEqual(run.trashed, [])
        self.assertTrue(link.is_symlink())

    def test_missing_directory_is_skipped(self) -> None:
        run = self.home.run('remove_broken_repo_symlinks "$HOME/.codex"')
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(run.trashed, [])

    def test_home_sweep_still_removes_any_broken_link(self) -> None:
        link = self.home.link(".old-tool-rc", "/nonexistent/old-tool-rc")
        run = self.home.run('remove_broken_symlinks "$HOME"')
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(run.trashed, [str(link)])

    def test_symlinks_removes_a_link_whose_repo_source_was_deleted(self) -> None:
        link = self.home.link(".claude/hooks", self.home.dotfiles / "tools/claude/config/hooks")
        run = self.home.run('bash "$DOTFILES/features/update/symlinks.bash" claude')
        self.assertEqual(run.status, 0, run.output)
        self.assertIn(str(link), run.trashed)


if __name__ == "__main__":
    unittest.main()
