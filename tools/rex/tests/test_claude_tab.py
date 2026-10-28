#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/rex/claude-tab.bash, which opens a Rex tab running Claude Code through cc.bash.

Run with: uv run tools/rex/tests/test_claude_tab.py

Each test builds a throwaway HOME holding the repo at ~/Repos/ooloth/dotfiles, where utils.bash
expects it, and runs the launcher under macOS's own bash. A `rex` stub on PATH records its arguments
and then does what the real tab would: it runs the command after `--` in the `-c` directory. A
`claude` stub records the arguments cc.bash hands it, so a test sees the permission mode the tab's
Claude would really start with, and nothing reaches the real Rex or Claude Code.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

from hypothesis import given, settings
from hypothesis import strategies as st

REPO = Path(__file__).resolve().parent.parent.parent.parent
SCRIPT = Path("tools/rex/claude-tab.bash")
CC = Path("tools/claude/cc.bash")

REX_JSON = '{"window_id":"window:1","block_ids":["block:1"]}'

# Records its arguments, prints what `rex window new --json` prints, then runs the tab's command in
# the tab's directory, as the real tab would
REX_STUB = f"""#!/bin/bash
for arg in "$@"; do printf '%s\\0' "$arg"; done > "${{REX_LOG}}"
dir=""
while [[ $# -gt 0 && "$1" != "--" ]]; do
  if [[ "$1" == "-c" ]]; then dir="$2"; shift; fi
  shift
done
shift
echo '{REX_JSON}'
(cd "${{dir}}" && "$@") > "${{TAB_LOG}}" 2>&1
"""

CLAUDE_STUB = """#!/bin/bash
for arg in "$@"; do printf '%s\\0' "$arg"; done > "${CLAUDE_LOG}"
"""


@dataclass(frozen=True)
class Run:
    status: int
    stdout: str
    stderr: str
    rex: list[str] | None
    claude: list[str] | None


def _read_args(log: Path) -> list[str] | None:
    # Bytes, because reading text would turn each \r into \n
    return log.read_bytes().decode().split("\0")[:-1] if log.exists() else None


class Machine:
    """A temporary HOME, a folder of sibling repos, and stubs for rex and claude."""

    def __init__(self, root: Path) -> None:
        self.root = root.resolve()
        self.home = self.root / "home"
        dotfiles = self.home / "Repos" / "ooloth" / "dotfiles"
        dotfiles.parent.mkdir(parents=True)
        dotfiles.symlink_to(REPO)
        self.repos = self.root / "repos"
        self.app = self.repos / "app"
        self.app.mkdir(parents=True)
        self.stubs = self.root / "stubs"
        self.stubs.mkdir()
        for name, body in (("rex", REX_STUB), ("claude", CLAUDE_STUB)):
            stub = self.stubs / name
            stub.write_text(body)
            stub.chmod(0o755)
        self._rex_log = self.root / "rex.log"
        self._claude_log = self.root / "claude.log"
        self.tab_log = self.root / "tab.log"

    def run(
        self,
        *args: str,
        computer: str = "air",
        session: str | None = "session:here",
        script: Path | None = None,
        cwd: Path | None = None,
    ) -> Run:
        """Run the launcher, by default the shipped one, as an agent in a Rex pane would."""
        self._rex_log.unlink(missing_ok=True)
        self._claude_log.unlink(missing_ok=True)
        env = {
            "HOME": str(self.home),
            "PATH": f"{self.stubs}:/usr/bin:/bin:/usr/sbin:/sbin",
            "REX_LOG": str(self._rex_log),
            "CLAUDE_LOG": str(self._claude_log),
            "TAB_LOG": str(self.tab_log),
            "COMPUTER": computer,
        }
        if session is not None:
            env["REX_SESSION"] = session
        result = subprocess.run(
            ["/bin/bash", str(script or REPO / SCRIPT), *args],
            cwd=cwd or self.root,
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        return Run(
            result.returncode,
            result.stdout,
            result.stderr,
            _read_args(self._rex_log),
            _read_args(self._claude_log),
        )


class MachineTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.machine = Machine(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()


class PermissionMode(MachineTest):
    def test_work_laptop_tab_starts_claude_in_auto_mode(self) -> None:
        run = self.machine.run("Review", str(self.machine.app), "/review", computer="work")

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(run.claude, ["--permission-mode", "auto", "/review"], run.stderr)

    def test_personal_mac_tabs_start_claude_with_permissions_bypassed(self) -> None:
        for computer in ("air", "mini"):
            with self.subTest(computer=computer):
                run = self.machine.run(
                    "Review", str(self.machine.app), "/review", computer=computer
                )

                self.assertEqual(
                    run.claude, ["--permission-mode", "bypassPermissions", "/review"], run.stderr
                )


class RelatedFolders(MachineTest):
    def test_tab_gets_the_plans_folder_cc_adds(self) -> None:
        plans = self.machine.repos / "plans"
        plans.mkdir()

        run = self.machine.run("Review", str(self.machine.app), "/review")

        self.assertEqual(
            run.claude,
            ["--permission-mode", "bypassPermissions", f"--add-dir={plans}", "/review"],
            run.stderr,
        )


class TabRequest(MachineTest):
    def test_opens_the_named_tab_in_the_current_session_and_directory(self) -> None:
        run = self.machine.run("👀 PR 573: review", "repos/app", "/review", cwd=self.machine.root)

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(
            run.rex,
            [
                "window",
                "new",
                "-s",
                "session:here",
                "👀 PR 573: review",
                "-c",
                str(self.machine.app),
                "--json",
                "--",
                "bash",
                str(REPO / CC),
                "/review",
            ],
        )

    def test_s_names_another_session(self) -> None:
        run = self.machine.run("-s", "session:other", "Review", str(self.machine.app))

        self.assertEqual(run.status, 0, run.stderr)
        assert run.rex is not None
        self.assertEqual(run.rex[:4], ["window", "new", "-s", "session:other"])

    def test_s_works_with_no_session_in_the_environment(self) -> None:
        run = self.machine.run("-s", "session:other", "Review", str(self.machine.app), session=None)

        self.assertEqual(run.status, 0, run.stderr)
        assert run.rex is not None
        self.assertEqual(run.rex[2:4], ["-s", "session:other"])

    def test_prints_rex_json_so_the_caller_gets_the_pane_id(self) -> None:
        run = self.machine.run("Review", str(self.machine.app))

        self.assertEqual(json.loads(run.stdout)["block_ids"], ["block:1"])

    def test_with_no_claude_arguments_claude_gets_only_its_mode(self) -> None:
        run = self.machine.run("Review", str(self.machine.app))

        self.assertEqual(run.claude, ["--permission-mode", "bypassPermissions"], run.stderr)

    @settings(max_examples=25, deadline=None)
    @given(
        st.lists(
            st.text(
                alphabet=st.characters(blacklist_categories=["Cs", "Cc"]), min_size=1, max_size=20
            ),
            min_size=1,
            max_size=3,
        )
    )
    def test_claude_arguments_arrive_unchanged(self, args: list[str]) -> None:
        # A first argument starting with - would read as a claude flag, which is the caller's to pass
        run = self.machine.run("Review", str(self.machine.app), *args)

        self.assertEqual(run.status, 0, run.stderr)
        assert run.claude is not None
        self.assertEqual(run.claude[2:], args)


class UsageErrors(MachineTest):
    def assert_refused(self, run: Run, message: str) -> None:
        self.assertEqual(run.status, 2, run.stderr)
        self.assertIn(message, run.stderr)
        self.assertIsNone(run.rex, "no tab may open")

    def test_no_arguments(self) -> None:
        self.assert_refused(self.machine.run(), "Usage:")

    def test_name_without_directory(self) -> None:
        self.assert_refused(self.machine.run("Review"), "Usage:")

    def test_directory_that_does_not_exist(self) -> None:
        missing = self.machine.root / "missing"

        self.assert_refused(
            self.machine.run("Review", str(missing)), f"No such directory: {missing}"
        )

    def test_no_session(self) -> None:
        run = self.machine.run("Review", str(self.machine.app), session=None)

        self.assert_refused(run, "REX_SESSION is not set")

    def test_empty_session(self) -> None:
        run = self.machine.run("Review", str(self.machine.app), session="")

        self.assert_refused(run, "REX_SESSION is not set")

    def test_s_without_a_session(self) -> None:
        self.assert_refused(self.machine.run("-s"), "Usage:")

    def test_no_cc_beside_the_launcher(self) -> None:
        copy = self.machine.root / "checkout" / SCRIPT
        copy.parent.mkdir(parents=True)
        shutil.copy(REPO / SCRIPT, copy)

        run = self.machine.run("Review", str(self.machine.app), script=copy)

        self.assert_refused(run, "No cc.bash at")


class OwnCheckout(MachineTest):
    def test_a_copy_of_the_launcher_runs_its_own_checkouts_cc(self) -> None:
        checkout = self.machine.root / "checkout"
        copy = checkout / SCRIPT
        copy.parent.mkdir(parents=True)
        shutil.copy(REPO / SCRIPT, copy)
        own_cc = checkout / CC
        own_cc.parent.mkdir(parents=True)
        own_cc.write_text('printf "%s\\0" own-cc "$@" > "${CLAUDE_LOG}"\n')

        run = self.machine.run("Review", str(self.machine.app), "/review", script=copy)

        self.assertEqual(run.status, 0, run.stderr)
        assert run.rex is not None
        self.assertEqual(run.rex[-2], str(own_cc))
        self.assertEqual(run.claude, ["own-cc", "/review"])


if __name__ == "__main__":
    unittest.main()
