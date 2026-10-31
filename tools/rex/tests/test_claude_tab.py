#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/rex/claude-tab.bash, which opens a Rex tab running Claude Code through cc.bash.

Run with: uv run tools/rex/tests/test_claude_tab.py

Each test builds a throwaway HOME holding the repo at ~/Repos/ooloth/dotfiles, where utils.bash
expects it, and runs the launcher under macOS's own bash. A `rex` stub on PATH records the arguments
of every call. It answers `session list` with the sessions the test sets, and for `window new` and
`session new` it does what the real tab would: it runs the command after `--` in the `-c` directory.
A `claude` stub records the arguments cc.bash hands it, so a test sees the permission mode the tab's
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

WINDOW_JSON = '{"window_id":"window:1","block_ids":["block:1"]}'
SESSION_JSON = (
    '{"session_id":"session:new",'
    '"initial_windows":[{"window_id":"window:2","block_ids":["block:2"]}]}'
)
WORKERS = '{"sessions":[{"session_id":"session:workers","label":"Workers"}]}'

# Records each call's arguments in its own numbered file. `session list` prints $REX_SESSIONS, or
# fails when $REX_LIST_FAILS is set. `window new` and `session new` print what the real ones print
# with --json, then run the tab's command in the tab's directory, as the real tab would.
REX_STUB = f"""#!/bin/bash
calls=("${{REX_LOG}}"/*)
[[ -e "${{calls[0]}}" ]] || calls=()
for arg in "$@"; do printf '%s\\0' "$arg"; done > "${{REX_LOG}}/$(printf '%03d' "${{#calls[@]}}")"
case "$1 $2" in
  "session list")
    if [[ -n "${{REX_LIST_FAILS:-}}" ]]; then echo "Error: no server" >&2; exit 3; fi
    printf '%s\\n' "${{REX_SESSIONS}}"
    exit 0
    ;;
  "session new") json='{SESSION_JSON}' ;;
  *) json='{WINDOW_JSON}' ;;
esac
dir=""
while [[ $# -gt 0 && "$1" != "--" ]]; do
  if [[ "$1" == "-c" ]]; then dir="$2"; shift; fi
  shift
done
shift
echo "${{json}}"
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
    rex_calls: list[list[str]]
    claude: list[str] | None

    @property
    def rex(self) -> list[str] | None:
        """The call that opened the tab, which is always the last one."""
        return self.rex_calls[-1] if self.rex_calls else None


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
        self._rex_log = self.root / "rex-calls"
        self._claude_log = self.root / "claude.log"
        self.tab_log = self.root / "tab.log"

    def run(
        self,
        *args: str,
        computer: str = "air",
        session: str | None = "session:here",
        sessions: str = WORKERS,
        list_fails: bool = False,
        script: Path | None = None,
        cwd: Path | None = None,
        related: str = "",
    ) -> Run:
        """Run the launcher, by default the shipped one, as an agent in a Rex pane would, with
        PRIVATE_RELATED_REPOS set to `related`."""
        shutil.rmtree(self._rex_log, ignore_errors=True)
        self._rex_log.mkdir()
        self._claude_log.unlink(missing_ok=True)
        env = {
            "HOME": str(self.home),
            "PATH": f"{self.stubs}:/usr/bin:/bin:/usr/sbin:/sbin",
            "REX_LOG": str(self._rex_log),
            "CLAUDE_LOG": str(self._claude_log),
            "TAB_LOG": str(self.tab_log),
            "COMPUTER": computer,
            "REX_SESSIONS": sessions,
            # Set even when empty, so cc.bash keeps it rather than reading the repo's private.env
            "PRIVATE_RELATED_REPOS": related,
        }
        if list_fails:
            env["REX_LIST_FAILS"] = "1"
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
            [_read_args(call) or [] for call in sorted(self._rex_log.iterdir())],
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


class RelatedRepos(MachineTest):
    def test_tab_gets_the_related_repo_hint_cc_adds(self) -> None:
        app = self.machine.repos / "example-app"
        app.mkdir()
        infra = self.machine.repos / "example-infra"
        infra.mkdir()

        run = self.machine.run(
            "Review", str(app), "/review", computer="work", related="example-app=example-infra"
        )

        assert run.claude is not None, run.stderr
        self.assertEqual(run.claude[:3], ["--permission-mode", "auto", "--append-system-prompt"])
        self.assertIn(f"Related repo: `example-infra` at `{infra}`.", run.claude[3])
        self.assertEqual(run.claude[4:], ["/review"])


class TabRequest(MachineTest):
    def test_opens_the_named_tab_in_the_workers_session_and_directory(self) -> None:
        run = self.machine.run("PR 573: review", "repos/app", "/review", cwd=self.machine.root)

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(
            run.rex,
            [
                "window",
                "new",
                "-s",
                "session:workers",
                "PR 573: review",
                "-c",
                str(self.machine.app),
                "--json",
                "--",
                "bash",
                str(REPO / CC),
                "/review",
            ],
        )

    def test_s_names_another_session_without_looking_up_workers(self) -> None:
        run = self.machine.run("-s", "session:other", "Review", str(self.machine.app))

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(len(run.rex_calls), 1, run.rex_calls)
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


class WorkersSession(MachineTest):
    def test_the_first_of_two_workers_sessions_gets_the_tab(self) -> None:
        sessions = json.dumps(
            {
                "sessions": [
                    {"session_id": "session:goals", "label": "Goals"},
                    {"session_id": "session:first", "label": "Workers"},
                    {"session_id": "session:second", "label": "Workers"},
                ]
            }
        )

        run = self.machine.run("Review", str(self.machine.app), sessions=sessions)

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(
            [call[:2] for call in run.rex_calls], [["session", "list"], ["window", "new"]]
        )
        assert run.rex is not None
        self.assertEqual(run.rex[2:4], ["-s", "session:first"])

    def test_with_no_workers_session_one_is_created_with_the_tab_as_its_first_window(self) -> None:
        for sessions in (
            '{"sessions":[]}',
            '{"sessions":[{"session_id":"session:a","label":"workers"},'
            '{"session_id":"session:b","label":"Workers 2"}]}',
        ):
            with self.subTest(sessions=sessions):
                run = self.machine.run(
                    "Review", str(self.machine.app), "/review", sessions=sessions
                )

                self.assertEqual(run.status, 0, run.stderr)
                self.assertEqual(len(run.rex_calls), 2, run.rex_calls)
                self.assertEqual(
                    run.rex,
                    [
                        "session",
                        "new",
                        "Workers",
                        "--window",
                        "Review",
                        "-c",
                        str(self.machine.app),
                        "--json",
                        "--",
                        "bash",
                        str(REPO / CC),
                        "/review",
                    ],
                )
                self.assertIn("Created Rex session Workers", run.stderr)

    def test_a_created_session_still_prints_the_new_tabs_pane(self) -> None:
        run = self.machine.run("Review", str(self.machine.app), sessions='{"sessions":[]}')

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(json.loads(run.stdout)["block_ids"], ["block:2"])

    def test_the_created_sessions_tab_starts_claude_through_cc(self) -> None:
        run = self.machine.run(
            "Review", str(self.machine.app), "/review", sessions='{"sessions":[]}', computer="work"
        )

        self.assertEqual(run.claude, ["--permission-mode", "auto", "/review"], run.stderr)

    def test_a_failed_session_list_opens_nothing(self) -> None:
        run = self.machine.run("Review", str(self.machine.app), list_fails=True)

        self.assertNotEqual(run.status, 0)
        self.assertEqual([call[:2] for call in run.rex_calls], [["session", "list"]])

    def test_a_session_list_that_is_not_json_opens_nothing(self) -> None:
        run = self.machine.run("Review", str(self.machine.app), sessions="not json")

        self.assertNotEqual(run.status, 0)
        self.assertEqual([call[:2] for call in run.rex_calls], [["session", "list"]])


class UsageErrors(MachineTest):
    def assert_refused(self, run: Run, message: str) -> None:
        self.assertEqual(run.status, 2, run.stderr)
        self.assertIn(message, run.stderr)
        self.assertEqual(run.rex_calls, [], "no Rex call may run")

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
