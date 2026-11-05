#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests that a script acts on the checkout it lives in, and that only the install links $HOME.

Run with: uv run tools/bash/tests/test_dotfiles_location.py

tools/bash/utils.bash sets DOTFILES from its own location, spelled as the install path
(~/Repos/ooloth/dotfiles under HOME) when the checkout resolves to the install. Each test runs under
macOS's own bash 3.2 with a temporary HOME, and sets COMPUTER so tools/macos/utils.bash does not ask
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


def copy_checkout(to: Path, *tools: str) -> Path:
    """Copy the helpers every script sources, plus each named tool folder, into a new checkout."""
    for part in (*HELPERS, *tools):
        shutil.copytree(
            REPO / part, to / part, ignore=shutil.ignore_patterns("tests", "__pycache__")
        )
    return to


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
        self.copy = copy_checkout(root / "copy", "tools/claude")
        self.exported = copy_checkout(root / "exported")
        self.install = copy_checkout(self.home / "Repos/ooloth/dotfiles", "tools/claude")
        self.decoys = (self.exported, self.install)
        self.snapshots = {decoy: sorted(decoy.rglob("*")) for decoy in self.decoys}

    def assert_decoys_untouched(self) -> None:
        for decoy in self.decoys:
            self.assertEqual(sorted(decoy.rglob("*")), self.snapshots[decoy], decoy)

    def test_its_helpers_and_writes_come_from_the_copy(self) -> None:
        probe = self.copy / "tools/probe/probe.bash"
        probe.parent.mkdir(parents=True)
        probe.write_text(
            "#!/usr/bin/env bash\n"
            "set -euo pipefail\n"
            f"{SOURCE_UTILS}\n"
            "shopt -s extdebug\n"
            "declare -F symlink is_work load_private_env\n"
            'touch "${DOTFILES}/written"\n'
        )
        run = run_bash(f'bash "{probe}"', home=self.home, env={"DOTFILES": str(self.exported)})
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
        self.assertTrue((self.copy / "written").exists())
        self.assert_decoys_untouched()

    def test_its_link_step_leaves_home_empty(self) -> None:
        link = self.copy / "tools/claude/link.bash"
        run = run_bash(f'bash "{link}"', home=self.home, env={"DOTFILES": str(self.exported)})
        self.assertNotEqual(run.returncode, 0, run.stdout)
        self.assertIn(str(self.copy), run.stderr)
        self.assertEqual([p.name for p in self.home.iterdir()], ["Repos"])
        self.assert_decoys_untouched()


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

    def test_a_copy_is_spelled_as_its_own_path(self) -> None:
        self.assertEqual(self.dotfiles_after_sourcing(REPO / "tools/bash/utils.bash"), str(REPO))


def scripts() -> list[Path]:
    """Every script under tools/ and features/, apart from utils.bash and the files it sources."""
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
    def test_no_script_reads_dotfiles_before_finding_utils_from_its_own_location(self) -> None:
        assigns = re.compile(r"^\s*(export\s+)?DOTFILES=")
        for script in scripts():
            with self.subTest(script=str(script.relative_to(REPO))):
                code = [
                    line
                    for line in script.read_text().splitlines()
                    if line.strip() and not line.lstrip().startswith("#")
                ]
                self.assertFalse([line for line in code if assigns.search(line)])
                if not any("DOTFILES" in line for line in code):
                    continue
                # Sourced at the top, before anything but `set`, so no branch can skip it
                self.assertIn(SOURCE_UTILS, code)
                before = code[: code.index(SOURCE_UTILS)]
                self.assertEqual([line for line in before if not line.startswith("set ")], [])


if __name__ == "__main__":
    unittest.main()
