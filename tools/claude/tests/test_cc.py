#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/claude/cc.bash, which starts Claude Code told where a repo's related repos are.

Run with: uv run tools/claude/tests/test_cc.py

Each test builds a throwaway HOME holding the repo at ~/Repos/ooloth/dotfiles, where utils.bash
expects it, and runs the script under macOS's own bash from a folder beside its siblings. A `claude`
stub on PATH records its arguments separated by NUL bytes, so no test reaches the real Claude Code.
The tests of the map's handling in general source the real cc.bash and replace only its
`related_repos` lookup before calling `main`; the shipped entries are tested as shipped.
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

    def sibling(self, name: str) -> Path:
        folder = self.repos / name
        folder.mkdir()
        return folder

    def make_git_repo(self, folder: Path) -> None:
        """Turn `folder` into a git repo with one commit, so a worktree can be added to it."""
        git = [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.com",
            "-C",
            str(folder),
        ]
        subprocess.run([*git, "init", "-q"], check=True)
        subprocess.run([*git, "commit", "-q", "--allow-empty", "-m", "init"], check=True)

    def add_worktree(self, repo: Path, folder: Path) -> None:
        folder.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            ["git", "-C", str(repo), "worktree", "add", "-q", "-b", folder.name, str(folder)],
            check=True,
        )

    def _env(self, computer: str) -> dict[str, str]:
        return {
            "HOME": str(self.home),
            "PATH": f"{self.stubs}:/usr/bin:/bin:/usr/sbin:/sbin",
            "CLAUDE_LOG": str(self._claude_log),
            "COMPUTER": computer,
        }

    def _run(self, command: list[str], computer: str, cwd: Path | None) -> Run:
        self._claude_log.unlink(missing_ok=True)
        result = subprocess.run(
            command,
            cwd=cwd or self.app,
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

    def run(self, *args: str, computer: str = "air", cwd: Path | None = None) -> Run:
        """Run the shipped cc.bash, as the `cc` alias does."""
        return self._run(["/bin/bash", str(REPO / SCRIPT), *args], computer, cwd)

    def run_with_map(
        self, related: list[str], *args: str, computer: str = "air", cwd: Path | None = None
    ) -> Run:
        """Run the shipped cc.bash with its lookup replaced by one that lists `related`."""
        lines = "".join(f"printf '%s\\n' {r!r}; " for r in related)
        program = f'source "$1"; related_repos() {{ {lines}:; }}; shift; main "$@"'
        command = ["/bin/bash", "-c", program, "_", str(REPO / SCRIPT), *args]
        return self._run(command, computer, cwd)


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

    def test_names_each_related_repo_in_order_before_the_users_arguments(self) -> None:
        infra = self.machine.sibling("infra")
        docs = self.machine.sibling("docs")

        run = self.machine.run_with_map(["infra", "docs"], "--continue")

        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(
            run.claude,
            [
                "--permission-mode",
                "bypassPermissions",
                "--append-system-prompt",
                f"{hint('infra', infra)}\n{hint('docs', docs)}",
                "--continue",
            ],
        )

    def test_says_a_related_repo_is_not_cloned_where_it_was_looked_for(self) -> None:
        docs = self.machine.sibling("docs")

        run = self.machine.run_with_map(["infra", "docs"])

        self.assertEqual(run.status, 0, run.output)
        infra = self.machine.repos / "infra"
        self.assertEqual(
            run.claude,
            [
                "--permission-mode",
                "bypassPermissions",
                "--append-system-prompt",
                f"Related repo: `infra` is not cloned at `{infra}`.\n{hint('docs', docs)}",
            ],
        )

    def test_a_worktree_finds_related_repos_beside_its_main_checkout(self) -> None:
        infra = self.machine.sibling("infra")
        self.machine.make_git_repo(self.machine.app)
        worktree = self.machine.repos / "app-worktrees" / "feature"
        self.machine.add_worktree(self.machine.app, worktree)

        run = self.machine.run_with_map(["infra"], cwd=worktree)

        self.assertEqual(
            run.claude,
            [
                "--permission-mode",
                "bypassPermissions",
                "--append-system-prompt",
                hint("infra", infra),
            ],
            run.output,
        )


def hint(name: str, path: Path) -> str:
    """The system prompt line that tells a session about one related repo."""
    return (
        f"Related repo: `{name}` at `{path}`. It is a working checkout that may be on a feature"
        " branch or behind origin. To read origin's current default branch, run"
        " `git -C <path> fetch origin` and then `git -C <path> show origin/HEAD:<file>`. Don't"
        " change its branch or files; to change that repo, add a worktree beside it."
    )


class SiteOutreachRepos(unittest.TestCase):
    """react-clinops-siteoutreach and bc-eng-clinical each tell a session about the other."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.machine = Machine(Path(self._tmp.name))
        self.app_repo = self.machine.sibling("react-clinops-siteoutreach")
        self.infra_repo = self.machine.sibling("bc-eng-clinical")

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_each_checkout_worktree_and_clone_names_the_other_repo_on_the_work_laptop(
        self,
    ) -> None:
        cases = {
            "react-clinops-siteoutreach": ("bc-eng-clinical", self.infra_repo),
            "react-clinops-siteoutreach-ceng-186": ("bc-eng-clinical", self.infra_repo),
            "bc-eng-clinical": ("react-clinops-siteoutreach", self.app_repo),
            "bc-eng-clinical-ceng-295": ("react-clinops-siteoutreach", self.app_repo),
            "bc-eng-clinical-valid": ("react-clinops-siteoutreach", self.app_repo),
        }
        for folder_name, (name, path) in cases.items():
            with self.subTest(folder=folder_name):
                folder = self.machine.repos / folder_name
                folder.mkdir(exist_ok=True)

                run = self.machine.run(computer="work", cwd=folder)

                self.assertEqual(
                    run.claude,
                    ["--permission-mode", "auto", "--append-system-prompt", hint(name, path)],
                    run.output,
                )

    def test_personal_macs_name_nothing(self) -> None:
        run = self.machine.run(cwd=self.infra_repo)

        self.assertEqual(run.claude, ["--permission-mode", "bypassPermissions"], run.output)


class PlansFolder(unittest.TestCase):
    """Plans moved to the content vault, which the next-step skill finds by its own path."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.machine = Machine(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_a_plans_folder_beside_the_repo_is_not_added(self) -> None:
        self.machine.sibling("plans")
        self.machine.make_git_repo(self.machine.app)

        run = self.machine.run("--continue")

        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(run.claude, ["--permission-mode", "bypassPermissions", "--continue"])


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
