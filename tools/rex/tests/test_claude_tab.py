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
# with --json, or $REX_WINDOW_JSON for `window new` when it is set, then run the tab's command in
# the tab's directory, as the real tab would.
REX_STUB = f"""#!/bin/bash
window_json='{WINDOW_JSON}'
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
  *) json="${{REX_WINDOW_JSON:-${{window_json}}}}" ;;
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
        window_json: str | None = None,
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
        if window_json is not None:
            env["REX_WINDOW_JSON"] = window_json
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
        run = self.machine.run(
            "PR 573 (alice): review-code", "repos/app", "/review", cwd=self.machine.root
        )

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(
            run.rex,
            [
                "window",
                "new",
                "-s",
                "session:workers",
                "PR 573 (alice): review-code",
                "-c",
                str(self.machine.app),
                "--focus=false",
                "--json",
                "--",
                "bash",
                str(REPO / CC),
                "/review",
            ],
        )

    def test_a_tab_opened_with_s_leaves_rex_focus_where_it_was(self) -> None:
        # Rex.app keeps showing its tab when the server's focus moves, and sends key bindings to the
        # server's focused pane, so a new tab that took focus would get every key pressed in the tab
        # still on screen.
        run = self.machine.run("-s", "session:other", "Review", str(self.machine.app))

        self.assertEqual(run.status, 0, run.stderr)
        assert run.rex is not None
        self.assertIn("--focus=false", run.rex)

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


def sessions(*labels: str) -> str:
    """A `session list` answer holding one session per label, with ids session:0, session:1, …"""
    return json.dumps(
        {
            "sessions": [
                {"session_id": f"session:{i}", "label": label} for i, label in enumerate(labels)
            ]
        }
    )


# Each form a remote URL takes, holding the repository name in place of {}.
URL_FORMS = (
    "git@github.com:owner/{}.git",
    "https://github.com/owner/{}",
    "https://github.com/owner/{}.git/",
    "ssh://git@example.com/owner/{}.git",
    "/srv/git/{}.git",
)


class RepositorySession(MachineTest):
    """A tab for a directory in a repository opens in the session named after its origin remote."""

    def git(self, *args: str, cwd: Path) -> None:
        env = {
            "HOME": str(self.machine.home),
            "PATH": "/usr/bin:/bin",
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AUTHOR_NAME": "t",
            "GIT_AUTHOR_EMAIL": "t@example.com",
            "GIT_COMMITTER_NAME": "t",
            "GIT_COMMITTER_EMAIL": "t@example.com",
        }
        subprocess.run(["git", *args], cwd=cwd, env=env, capture_output=True, check=True)

    def repo(self, folder: str, origin: str | None) -> Path:
        """A repository with one commit at repos/<folder>, whose origin is `origin` when given."""
        path = self.machine.repos / folder
        path.mkdir(parents=True)
        self.git("init", "-q", "-b", "main", cwd=path)
        self.git("commit", "-q", "--allow-empty", "-m", "start", cwd=path)
        if origin is not None:
            self.git("remote", "add", "origin", origin, cwd=path)
        return path

    def assert_opened_in(self, run: Run, session: str) -> None:
        self.assertEqual(run.status, 0, run.stderr)
        assert run.rex is not None
        self.assertEqual(run.rex[:4], ["window", "new", "-s", session])

    def assert_created(self, run: Run, label: str) -> None:
        self.assertEqual(run.status, 0, run.stderr)
        assert run.rex is not None
        self.assertEqual(run.rex[:3], ["session", "new", label])

    def test_a_clone_named_differently_from_its_repository_opens_in_the_repositorys_session(
        self,
    ) -> None:
        clone = self.repo("agency-1", "git@github.com:ooloth/agency.git")

        run = self.machine.run(
            "Review", str(clone), sessions=sessions("Workers", "Workers (agency)")
        )

        self.assert_opened_in(run, "session:1")

    def test_a_subdirectory_and_a_linked_worktree_open_in_their_repositorys_session(self) -> None:
        clone = self.repo("app-checkout", "git@github.com:ooloth/web.git")
        subdirectory = clone / "src"
        subdirectory.mkdir()
        worktree = clone / ".claude" / "worktrees" / "pr-5"
        self.git("worktree", "add", "-q", "-b", "pr-5", str(worktree), cwd=clone)

        for directory in (subdirectory, worktree):
            with self.subTest(directory=directory):
                run = self.machine.run(
                    "Review", str(directory), sessions=sessions("Workers", "Workers (web)")
                )

                self.assert_opened_in(run, "session:1")

    def test_a_bare_repositorys_worktree_opens_in_its_repositorys_session(self) -> None:
        # hub keeps a bare clone at ~/.hub/repos/<name> and its worktrees inside it
        source = self.repo("source", None)
        bare = self.machine.repos / "hub"
        self.git("clone", "-q", "--bare", str(source), str(bare), cwd=self.machine.repos)
        self.git("remote", "set-url", "origin", "git@github.com:ooloth/hub.git", cwd=bare)
        main = bare / "main"
        self.git("worktree", "add", "-q", str(main), "main", cwd=bare)

        run = self.machine.run("Review", str(main), sessions=sessions("Workers (hub)"))

        self.assert_opened_in(run, "session:0")

    @settings(max_examples=40, deadline=None)
    @given(
        name=st.text(
            alphabet=st.characters(blacklist_categories=["Cs", "Cc"], blacklist_characters="/:"),
            min_size=1,
            max_size=20,
        ).filter(lambda name: not name.endswith(".git") and name.strip() == name),
        form=st.sampled_from(URL_FORMS),
    )
    def test_every_url_form_names_the_session_after_the_repository(
        self, name: str, form: str
    ) -> None:
        clone = self.machine.repos / "named"
        if not clone.exists():
            self.repo("named", "placeholder")
        self.git("remote", "set-url", "origin", form.format(name), cwd=clone)

        run = self.machine.run("Review", str(clone), sessions='{"sessions":[]}')

        self.assert_created(run, f"Workers ({name})")

    def test_a_missing_repository_session_is_created_holding_the_tab(self) -> None:
        clone = self.repo("web", "https://github.com/ooloth/web.git")

        run = self.machine.run("Review", str(clone), "/review", sessions=sessions("Workers"))

        self.assertEqual(
            run.rex,
            [
                "session",
                "new",
                "Workers (web)",
                "--window",
                "Review",
                "-c",
                str(clone),
                "--json",
                "--",
                "bash",
                str(REPO / CC),
                "/review",
            ],
        )
        self.assertIn("Created Rex session Workers (web)", run.stderr)

    def test_a_repository_without_a_usable_origin_opens_in_workers(self) -> None:
        for folder, origin in (
            ("no-remote", None),
            ("only-segment-missing", "git@github.com:"),
            ("only-slashes", "//"),
        ):
            with self.subTest(origin=origin):
                clone = self.repo(folder, origin)

                run = self.machine.run("Review", str(clone), sessions=sessions("Workers"))

                self.assert_opened_in(run, "session:0")

    def test_a_repository_whose_only_remote_is_not_origin_opens_in_workers(self) -> None:
        clone = self.repo("fork", None)
        self.git("remote", "add", "upstream", "git@github.com:ooloth/fork.git", cwd=clone)

        run = self.machine.run("Review", str(clone), sessions=sessions("Workers", "Workers (fork)"))

        self.assert_opened_in(run, "session:0")

    def test_s_wins_over_the_repositorys_session(self) -> None:
        clone = self.repo("web", "git@github.com:ooloth/web.git")

        run = self.machine.run(
            "-s", "session:other", "Review", str(clone), sessions=sessions("Workers (web)")
        )

        self.assertEqual(len(run.rex_calls), 1, run.rex_calls)
        self.assert_opened_in(run, "session:other")

    def test_only_a_session_with_exactly_the_repositorys_label_matches(self) -> None:
        clone = self.repo("dot", "git@github.com:ooloth/dot.git")
        near_misses = ("Workers (dotfiles)", "Workers", "workers (dot)", "Workers (dot) ")

        run = self.machine.run("Review", str(clone), sessions=sessions(*near_misses))
        self.assert_created(run, "Workers (dot)")

        run = self.machine.run(
            "Review", str(clone), sessions=sessions(*near_misses, "Workers (dot)")
        )
        self.assert_opened_in(run, "session:4")

    def test_the_output_names_the_session_the_tab_opened_in(self) -> None:
        clone = self.repo("web", "git@github.com:ooloth/web.git")

        found = self.machine.run("Review", str(clone), sessions=sessions("Workers (web)"))
        created = self.machine.run("Review", str(clone), sessions='{"sessions":[]}')

        self.assertEqual(json.loads(found.stdout)["session_id"], "session:0", found.stderr)
        self.assertEqual(json.loads(found.stdout)["block_ids"], ["block:1"])
        self.assertEqual(json.loads(created.stdout)["session_id"], "session:new", created.stderr)
        self.assertEqual(json.loads(created.stdout)["block_ids"], ["block:2"])

    def test_s_output_names_the_session_it_was_given(self) -> None:
        run = self.machine.run("-s", "session:other", "Review", str(self.machine.app))

        self.assertEqual(json.loads(run.stdout)["session_id"], "session:other", run.stderr)

    def test_a_new_tab_without_a_pane_is_refused(self) -> None:
        run = self.machine.run(
            "Review", str(self.machine.app), window_json='{"window_id":"window:1","block_ids":[]}'
        )

        self.assertNotEqual(run.status, 0)
        self.assertEqual(run.stdout, "")
        self.assertIn("no pane", run.stderr)


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
