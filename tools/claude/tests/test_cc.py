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


def write_stubs(folder: Path) -> Path:
    """Write the `claude` stub into `folder`, then make the folder read-only, so examples that share
    it can't change what the others run."""
    folder.mkdir(parents=True, exist_ok=True)
    claude = folder / "claude"
    claude.write_text(CLAUDE_STUB)
    claude.chmod(0o755)
    folder.chmod(0o555)
    return folder


class Machine:
    """A temporary HOME and a folder of sibling repos for cc.bash to run in.

    `stubs` is a folder from write_stubs to share between Machines. A newly written executable is
    slow to start the first time on a Mac running endpoint security, so a property test that builds
    a Machine per example shares one folder rather than writing the stub again each time.
    """

    def __init__(self, root: Path, stubs: Path | None = None) -> None:
        root = root.resolve()
        self.home = root / "home"
        dotfiles = self.home / "Repos" / "ooloth" / "dotfiles"
        dotfiles.parent.mkdir(parents=True)
        dotfiles.symlink_to(REPO)
        self.repos = root / "repos"
        self.app = self.repos / "app"
        self.app.mkdir(parents=True)
        self.stubs = stubs or write_stubs(root / "stubs")
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

    def _env(self, computer: str, related: str) -> dict[str, str]:
        return {
            "HOME": str(self.home),
            "PATH": f"{self.stubs}:/usr/bin:/bin:/usr/sbin:/sbin",
            "CLAUDE_LOG": str(self._claude_log),
            "COMPUTER": computer,
            # Set even when empty, so cc.bash keeps it rather than reading the repo's private.env
            "PRIVATE_RELATED_REPOS": related,
        }

    def _run(self, command: list[str], computer: str, cwd: Path | None, related: str = "") -> Run:
        self._claude_log.unlink(missing_ok=True)
        result = subprocess.run(
            command,
            cwd=cwd or self.app,
            env=self._env(computer, related),
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

    def run(
        self, *args: str, computer: str = "air", cwd: Path | None = None, related: str = ""
    ) -> Run:
        """Run the shipped cc.bash, as the `cc` alias does, with PRIVATE_RELATED_REPOS set to
        `related`."""
        return self._run(["/bin/bash", str(REPO / SCRIPT), *args], computer, cwd, related)

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


class RelatedReposFromPrivateEnv(unittest.TestCase):
    """PRIVATE_RELATED_REPOS pairs a folder prefix with the repo a session there is told about."""

    PAIRS = "example-app=example-infra example-infra=example-app"

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.machine = Machine(Path(self._tmp.name))
        self.app_repo = self.machine.sibling("example-app")
        self.infra_repo = self.machine.sibling("example-infra")

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_each_checkout_worktree_and_clone_names_its_related_repo(self) -> None:
        cases = {
            "example-app": ("example-infra", self.infra_repo),
            "example-app-ticket-186": ("example-infra", self.infra_repo),
            "example-infra": ("example-app", self.app_repo),
            "example-infra-ticket-295": ("example-app", self.app_repo),
        }
        for folder_name, (name, path) in cases.items():
            for computer, mode in (("work", "auto"), ("air", "bypassPermissions")):
                with self.subTest(folder=folder_name, computer=computer):
                    folder = self.machine.repos / folder_name
                    folder.mkdir(exist_ok=True)

                    run = self.machine.run(computer=computer, cwd=folder, related=self.PAIRS)

                    self.assertEqual(
                        run.claude,
                        ["--permission-mode", mode, "--append-system-prompt", hint(name, path)],
                        run.output,
                    )

    def test_a_folder_no_prefix_matches_names_nothing(self) -> None:
        run = self.machine.run(computer="work", related=self.PAIRS)

        self.assertEqual(run.claude, ["--permission-mode", "auto"], run.output)

    def test_with_no_pairs_a_session_names_nothing(self) -> None:
        run = self.machine.run(computer="work", cwd=self.infra_repo)

        self.assertEqual(run.claude, ["--permission-mode", "auto"], run.output)


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


# Flags cc.bash may pass as a separate argument ahead of the caller's own, each taking exactly one
# value. Any other flag is written as --flag=<value>, so a flag that takes several values can't read
# the caller's arguments as more of its own.
SINGLE_VALUE_FLAGS = {"--append-system-prompt", "--permission-mode"}


def arguments_that_could_take_the_callers(added: list[str]) -> list[str]:
    """The arguments cc.bash added that a flag taking several values could read past."""
    found = []
    rest = iter(added)
    for arg in rest:
        if arg in SINGLE_VALUE_FLAGS:
            next(rest, None)
        elif not (arg.startswith("--") and "=" in arg):
            found.append(arg)
    return found


class AddedArguments(unittest.TestCase):
    def test_leave_the_callers_arguments_to_the_caller(self) -> None:
        cases = {
            "personal mac": ("air", []),
            "work laptop": ("work", []),
            "a cloned related repo": ("work", ["infra"]),
            "a related repo that is not cloned": ("work", ["infra", "missing"]),
        }
        for label, (computer, related) in cases.items():
            with self.subTest(label):
                with tempfile.TemporaryDirectory() as tmp:
                    machine = Machine(Path(tmp))
                    machine.sibling("infra")

                    run = machine.run_with_map(related, "review this", computer=computer)

                assert run.claude is not None, run.output
                self.assertEqual(run.claude[-1], "review this", run.output)
                self.assertEqual(arguments_that_could_take_the_callers(run.claude[:-1]), [])


class Arguments(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._stubs_tmp = tempfile.TemporaryDirectory()
        cls.stubs = write_stubs(Path(cls._stubs_tmp.name) / "stubs")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._stubs_tmp.cleanup()  # resets the read-only folder's permissions first

    def test_a_stub_cannot_write_beside_itself_in_the_shared_folder(self) -> None:
        with self.assertRaises(PermissionError):
            (self.stubs / "written-by-an-example").write_text("x")

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
            run = Machine(Path(tmp), self.stubs).run(*args)

        self.assertEqual(run.claude, ["--permission-mode", "bypassPermissions", *args], run.output)


if __name__ == "__main__":
    unittest.main()
