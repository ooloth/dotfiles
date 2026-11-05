#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests that a script acts on the checkout it lives in, and that only the install links $HOME.

Run with: uv run tools/bash/tests/test_dotfiles_location.py

tools/bash/utils.bash sets DOTFILES from its own location, spelled as the install path
(~/Repos/ooloth/dotfiles under HOME) when the checkout is the install. Each test runs under macOS's
own bash 3.2 with a temporary HOME, and sets COMPUTER so tools/macos/utils.bash does not ask
networksetup which Mac this is.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
PATH = "/usr/bin:/bin:/usr/sbin:/sbin"
SOURCE_UTILS = 'source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"'
HELPERS = ("tools/bash", "tools/macos")
# A file every checkout in a test holds, so a write to the wrong checkout changes content that
# already exists there, the way a script regenerating a tracked file such as Brewfile.generated would
SHARED_FILE = "probe-target"


def copy_checkout(to: Path, *parts: str) -> Path:
    """Copy the helpers every script sources, plus each named folder, into a new checkout."""
    for part in (*HELPERS, *parts):
        shutil.copytree(
            REPO / part, to / part, ignore=shutil.ignore_patterns("tests", "__pycache__")
        )
    (to / SHARED_FILE).write_text("original\n")
    return to


def write_script(path: Path, *lines: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(["#!/usr/bin/env bash", "set -euo pipefail", SOURCE_UTILS, *lines]))
    return path


def contents(checkout: Path) -> dict[Path, bytes | None]:
    return {
        path.relative_to(checkout): path.read_bytes() if path.is_file() else None
        for path in checkout.rglob("*")
    }


def run_bash(
    script: str, *, home: Path, env: dict[str, str] | None = None
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["/bin/bash", "--norc", "--noprofile", "-c", script],
        env={"HOME": str(home), "PATH": PATH, "COMPUTER": "test", **(env or {})},
        capture_output=True,
        text=True,
        check=False,
    )


class ScriptInACopy(unittest.TestCase):
    """A copy with two decoys: one the caller's DOTFILES names, one at the HOME install path."""

    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        self.home = root / "home"
        self.copy = copy_checkout(root / "copy", "tools/claude", "tools/git", "features/check")
        self.exported = copy_checkout(root / "exported")
        self.install = copy_checkout(self.home / "Repos/ooloth/dotfiles", "tools/claude")
        self.decoys = (self.exported, self.install)
        self.snapshots = {decoy: contents(decoy) for decoy in self.decoys}

    def run_in_copy(self, script: Path) -> subprocess.CompletedProcess[str]:
        return run_bash(f'bash "{script}"', home=self.home, env={"DOTFILES": str(self.exported)})

    def assert_decoys_untouched(self) -> None:
        for decoy in self.decoys:
            self.assertEqual(contents(decoy), self.snapshots[decoy], decoy)

    def assert_home_untouched(self) -> None:
        self.assertEqual([p.name for p in self.home.iterdir()], ["Repos"])

    def test_its_helpers_and_writes_come_from_the_copy(self) -> None:
        probe = write_script(
            self.copy / "tools/probe/probe.bash",
            "shopt -s extdebug",
            "declare -F symlink is_work load_private_env",
            f"printf 'written\\n' > \"${{DOTFILES}}/{SHARED_FILE}\"",
        )
        run = self.run_in_copy(probe)
        self.assertEqual(run.returncode, 0, run.stderr)
        defined_in = {
            line.split()[0]: Path(line.split()[2]).resolve() for line in run.stdout.splitlines()
        }
        self.assertEqual(
            defined_in,
            {
                "symlink": (self.copy / "tools/bash/utils.bash").resolve(),
                "is_work": (self.copy / "tools/macos/utils.bash").resolve(),
                "load_private_env": (self.copy / "tools/bash/private-env.bash").resolve(),
            },
        )
        self.assertEqual((self.copy / SHARED_FILE).read_text(), "written\n")
        self.assert_decoys_untouched()

    def test_its_link_step_leaves_home_empty(self) -> None:
        run = self.run_in_copy(self.copy / "tools/claude/link.bash")
        self.assertNotEqual(run.returncode, 0, run.stdout)
        self.assertIn(str(self.copy), run.stderr)
        self.assert_home_untouched()
        self.assert_decoys_untouched()

    def test_its_update_skips_the_link_step_says_so_and_carries_on(self) -> None:
        update = write_script(
            self.copy / "tools/probe/update.bash",
            'run_link_step "${DOTFILES}/tools/claude/link.bash"',
            'echo "after the link step"',
        )
        run = self.run_in_copy(update)
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertIn("after the link step", run.stdout)
        self.assertIn("tools/claude/link.bash", run.stderr)
        self.assertIn(str(self.install), run.stderr)
        self.assert_home_untouched()
        self.assert_decoys_untouched()

    def test_its_link_check_refuses_once(self) -> None:
        run = self.run_in_copy(self.copy / "features/check/dotfiles.bash")
        self.assertNotEqual(run.returncode, 0, run.stdout)
        self.assertEqual(run.stderr.count(str(self.install)), 1, run.stderr)
        self.assertNotIn("CLAUDE.md", run.stdout)
        self.assert_home_untouched()


class UpdateFromTheInstall(unittest.TestCase):
    def test_an_update_runs_its_link_step(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        home = root / "home"
        checkout = copy_checkout(root / "checkout", "tools/claude")
        install = home / "Repos/ooloth/dotfiles"
        install.parent.mkdir(parents=True)
        install.symlink_to(checkout)
        write_script(
            checkout / "tools/probe/update.bash",
            'run_link_step "${DOTFILES}/tools/claude/link.bash"',
        )
        run = run_bash(f'bash "{install}/tools/probe/update.bash"', home=home)
        self.assertEqual(run.returncode, 0, run.stderr)
        link = home / ".claude/CLAUDE.md"
        self.assertEqual(link.readlink(), install / "tools/claude/config/CLAUDE.md")


class HowDotfilesIsSpelled(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.home = Path(tmp.name)
        self.install = self.home / "Repos/ooloth/dotfiles"

    def dotfiles_after_sourcing(self, utils: Path) -> str:
        run = run_bash(
            f'source "{utils}"; printf "%s" "$DOTFILES"',
            home=self.home,
            env={"DOTFILES": "/somewhere/else"},
        )
        self.assertEqual(run.returncode, 0, run.stderr)
        return run.stdout

    def test_the_install_is_spelled_as_the_install_path_however_it_was_reached(self) -> None:
        # An Amp orb links ~/Repos/ooloth/dotfiles to the checkout it works in
        self.install.parent.mkdir(parents=True)
        self.install.symlink_to(REPO)
        for reached_through in (self.install, REPO):
            with self.subTest(reached_through=str(reached_through)):
                utils = reached_through / "tools/bash/utils.bash"
                self.assertEqual(self.dotfiles_after_sourcing(utils), str(self.install))

    def test_the_install_is_recognised_whatever_case_its_path_is_typed_in(self) -> None:
        self.install.parent.mkdir(parents=True)
        self.install.symlink_to(REPO)
        swapped = Path(str(REPO).swapcase())
        if not swapped.exists():
            self.skipTest("this filesystem is case-sensitive")
        utils = swapped / "tools/bash/utils.bash"
        self.assertEqual(self.dotfiles_after_sourcing(utils), str(self.install))

    def test_a_copy_is_spelled_as_its_own_path(self) -> None:
        self.assertEqual(self.dotfiles_after_sourcing(REPO / "tools/bash/utils.bash"), str(REPO))


ASSIGNS_DOTFILES = re.compile(
    r"(?:^|[;&|(]|\s)(?:(?:export|readonly|local|typeset|declare(?:\s+-\w+)*)\s+)?DOTFILES="
)
RUNS_LINK_SCRIPT = re.compile(r"^\s*bash\s+\S*link\.bash")
NAMES_INSTALL = "Repos/ooloth/dotfiles"
# Sets up the install itself, before anything in it can be sourced
MAY_NAME_INSTALL = {"tools/amp/workspace-resume.bash"}


def location_problems(name: str, text: str) -> list[str]:
    """What breaks the rule that a script finds its checkout from its own location, if anything."""
    code = [
        line for line in text.splitlines() if line.strip() and not line.lstrip().startswith("#")
    ]
    problems = []
    for line in code:
        if ASSIGNS_DOTFILES.search(line):
            problems.append(f"assigns DOTFILES: {line.strip()}")
        if NAMES_INSTALL in line and name not in MAY_NAME_INSTALL:
            problems.append(f"names the install path: {line.strip()}")
        if Path(name).name in ("update.bash", "install.bash") and RUNS_LINK_SCRIPT.search(line):
            problems.append(f"runs its link step without run_link_step: {line.strip()}")
    if any("DOTFILES" in line or "utils.bash" in line for line in code):
        if SOURCE_UTILS not in code:
            problems.append("does not source utils.bash by a path relative to itself")
        else:
            # Sourced at the top, before anything but `set`, so no branch can skip it
            before = code[: code.index(SOURCE_UTILS)]
            problems.extend(
                f"runs before sourcing utils.bash: {line.strip()}"
                for line in before
                if not line.startswith("set ")
            )
    return problems


def scripts() -> list[Path]:
    """Every bash script directly in a tools/<tool>/ or features/<feature>/ folder, apart from the
    files utils.bash itself sources."""
    sourced_by_utils = {REPO / "tools/macos/utils.bash"}
    found = sorted(
        path
        for pattern in ("tools/*/*.bash", "features/*/*.bash")
        for path in REPO.glob(pattern)
        if path.parent.name != "@archive"
        and path.parent != REPO / "tools/bash"
        and path not in sourced_by_utils
    )
    if not found:
        raise AssertionError(f"no scripts found under {REPO}")
    return found


class EveryScript(unittest.TestCase):
    def test_every_script_finds_its_checkout_from_its_own_location(self) -> None:
        for script in scripts():
            name = str(script.relative_to(REPO))
            with self.subTest(script=name):
                self.assertEqual(location_problems(name, script.read_text()), [])


class TheLocationCheck(unittest.TestCase):
    def script(self, *lines: str) -> str:
        return "\n".join(["#!/usr/bin/env bash", "set -euo pipefail", *lines])

    def test_accepts_a_script_that_sources_utils_first(self) -> None:
        text = self.script(SOURCE_UTILS, 'echo "${DOTFILES}"')
        self.assertEqual(location_problems("tools/x/update.bash", text), [])

    def test_rejects_a_script_that_sources_the_install_by_a_fixed_path(self) -> None:
        text = self.script('source "${HOME}/Repos/ooloth/dotfiles/tools/bash/utils.bash"')
        self.assertNotEqual(location_problems("tools/x/update.bash", text), [])

    def test_rejects_every_spelling_of_assigning_dotfiles(self) -> None:
        for assignment in (
            "DOTFILES=/x",
            "export DOTFILES=/x",
            "declare -x DOTFILES=/x",
            "readonly DOTFILES=/x",
            "local DOTFILES=/x",
            "cd /; DOTFILES=/x",
        ):
            with self.subTest(assignment=assignment):
                text = self.script(SOURCE_UTILS, assignment)
                self.assertNotEqual(location_problems("tools/x/update.bash", text), [])

    def test_rejects_an_update_or_install_that_runs_its_link_step_directly(self) -> None:
        for name in ("tools/x/update.bash", "tools/x/install.bash"):
            with self.subTest(script=name):
                text = self.script(SOURCE_UTILS, 'bash "${DOTFILES}/tools/x/link.bash"')
                self.assertNotEqual(location_problems(name, text), [])

    def test_rejects_anything_before_the_source_line(self) -> None:
        text = self.script('echo "${DOTFILES}"', SOURCE_UTILS)
        self.assertNotEqual(location_problems("tools/x/update.bash", text), [])


if __name__ == "__main__":
    unittest.main()
