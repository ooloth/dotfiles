"""Tests for prepare_feedback_session.py, which readies a worktree and a Rex tab for a pull request.

Run with:
  uv run --with pytest pytest \
    tools/agents/config/skills/monitor-prs/scripts/test_prepare_feedback_session.py

Each test runs the script as a subprocess with real git and the real Rex launcher. HOME is a
temporary folder whose ~/Repos/octo/widgets is a clone of a bare repo holding the head branch
`feat/x`. Only `rex` is faked, because the real one opens tabs: the fake logs every call and
answers from the environment the test sets, so nothing reaches the real Rex. A fake `gh` records
any call and fails, so no test can reach GitHub.
"""

import json
import os
import subprocess
import sys
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path

import pytest

SCRIPT = Path(__file__).with_name("prepare_feedback_session.py")

WORKERS = '{"sessions":[{"session_id":"session:workers","label":"Workers"}]}'
LABEL = "PR 5 (ooloth): review-pr-comments-converge"

# `session list` prints $REX_SESSIONS, or fails when $REX_LIST_FAILS is set. `window ls` prints
# $REX_WINDOWS. `window new` prints the JSON the real one prints, or fails when $REX_NEW_FAILS is
# set, without running the tab's command, so no Claude Code starts.
FAKE_REX = """#!/usr/bin/env python3
import json, os, sys

args = sys.argv[1:]
with open(os.environ["REX_LOG"], "a") as log:
    log.write(json.dumps(args) + "\\n")

match args[:2]:
    case ["session", "list"]:
        if os.environ.get("REX_LIST_FAILS"):
            print("Error: connection refused", file=sys.stderr)
            sys.exit(3)
        print(os.environ["REX_SESSIONS"])
    case ["window", "ls"]:
        print(os.environ.get("REX_WINDOWS", '{"windows":[]}'))
    case ["window", "new"]:
        if os.environ.get("REX_NEW_FAILS"):
            print("Error: request timed out", file=sys.stderr)
            sys.exit(1)
        print('{"window_id":"window:1","block_ids":["block:1"]}')
    case _:
        print("unexpected rex call", file=sys.stderr)
        sys.exit(9)
"""

# Any `gh` call is a failure of the script's promise never to touch GitHub, so the fake records it
# and fails.
FAKE_GH = """#!/usr/bin/env python3
import os, sys

with open(os.environ["GH_LOG"], "a") as log:
    log.write(" ".join(sys.argv[1:]) + "\\n")
sys.exit(1)
"""

# Run by git's ext transport as the remote: it reports the GIT_TERMINAL_PROMPT the fetch was given
# and fails, which needs no network.
PROMPT_REMOTE = """#!/bin/sh
echo "prompt=${GIT_TERMINAL_PROMPT:-unset}" >&2
exit 1
"""


@pytest.fixture(scope="module")
def stubs(tmp_path_factory: pytest.TempPathFactory) -> Iterator[Path]:
    """The fake `rex`, written once and made read-only, so no test can change what another runs."""
    folder = tmp_path_factory.mktemp("stubs")
    rex = folder / "rex"
    rex.write_text(FAKE_REX.replace("#!/usr/bin/env python3", f"#!{sys.executable}"))
    rex.chmod(0o755)
    gh = folder / "gh"
    gh.write_text(FAKE_GH.replace("#!/usr/bin/env python3", f"#!{sys.executable}"))
    gh.chmod(0o755)
    remote = folder / "prompt-remote"
    remote.write_text(PROMPT_REMOTE)
    remote.chmod(0o755)
    folder.chmod(0o555)
    yield folder
    folder.chmod(0o755)


@dataclass
class Machine:
    home: Path
    clone: Path
    remote: Path
    env: dict[str, str]

    def git(self, *args: str, cwd: Path | None = None) -> str:
        result = subprocess.run(
            ["git", *args],
            cwd=cwd or self.clone,
            env=self.env,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()

    def prepare(self, *args: str, **extra: str) -> subprocess.CompletedProcess[str]:
        argv = args or ("octo/widgets", "5", "ooloth", "feat/x")
        return subprocess.run(
            [sys.executable, str(SCRIPT), *argv],
            env={**self.env, **extra},
            capture_output=True,
            text=True,
        )

    def rex_calls(self) -> list[list[str]]:
        log = Path(self.env["REX_LOG"])
        return [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []

    def worktrees(self) -> list[Path]:
        folder = self.clone / ".claude" / "worktrees"
        return sorted(folder.iterdir()) if folder.exists() else []

    def branches(self) -> list[str]:
        return self.git("for-each-ref", "--format=%(refname:short)", "refs/heads").split()

    def stale_worktree(self, name: str) -> Path:
        """An earlier preparation's worktree for PR 5, clean and on the remote head."""
        path = self.clone / ".claude" / "worktrees" / name
        self.git("worktree", "add", "-q", "--track", "-b", name, str(path), "origin/feat/x")
        return path


@pytest.fixture
def machine(tmp_path: Path, stubs: Path) -> Machine:
    home = tmp_path / "home"
    remote = tmp_path / "remotes" / "octo" / "widgets.git"
    clone = home / "Repos" / "octo" / "widgets"
    gitconfig = tmp_path / "gitconfig"
    gitconfig.write_text("")
    env = {
        **os.environ,
        "HOME": str(home),
        "PATH": f"{stubs}{os.pathsep}{os.environ['PATH']}",
        "GIT_CONFIG_GLOBAL": str(gitconfig),
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_AUTHOR_NAME": "t",
        "GIT_AUTHOR_EMAIL": "t@example.com",
        "GIT_COMMITTER_NAME": "t",
        "GIT_COMMITTER_EMAIL": "t@example.com",
        "REX_LOG": str(tmp_path / "rex.log"),
        "GH_LOG": str(tmp_path / "gh.log"),
        "REX_SESSIONS": WORKERS,
        "REX_SESSION": "session:workers",
        "TMUX": "",
    }
    m = Machine(home=home, clone=clone, remote=remote, env=env)
    remote.parent.mkdir(parents=True)
    clone.parent.mkdir(parents=True)
    m.git("init", "-q", "--bare", "-b", "main", str(remote), cwd=tmp_path)
    m.git("clone", "-q", str(remote), str(clone), cwd=tmp_path)
    m.git("commit", "-q", "--allow-empty", "-m", "start")
    m.git("push", "-q", "origin", "HEAD:main", "HEAD:feat/x")
    m.git("fetch", "-q", "origin")
    return m


def output(result: subprocess.CompletedProcess[str]) -> dict:
    """The one JSON line the script prints."""
    [line] = result.stdout.splitlines()
    return json.loads(line)


def test_a_pr_gets_a_worktree_tracking_its_head_and_a_tab(machine: Machine) -> None:
    result = machine.prepare()
    assert result.returncode == 0, result.stderr
    out = output(result)
    [worktree] = machine.worktrees()
    assert out["prepared"] is True
    assert out["worktree"] == str(worktree)
    assert out["pane"] == "block:1"
    assert machine.git("rev-parse", "--abbrev-ref", "@{u}", cwd=worktree) == "origin/feat/x"
    assert worktree.name.startswith("pr-5-")
    assert machine.git("branch", "--show-current", cwd=worktree) == worktree.name
    [new] = [call for call in machine.rex_calls() if call[:2] == ["window", "new"]]
    assert LABEL in new
    assert new[-1] == "/review-pr-comments-converge octo/widgets#5"


def test_the_main_checkout_is_left_on_its_branch(machine: Machine) -> None:
    result = machine.prepare()
    assert result.returncode == 0, result.stderr
    assert machine.git("branch", "--show-current") == "main"


def test_a_clone_of_another_repo_is_refused(machine: Machine) -> None:
    other = machine.remote.parent.parent / "notocto" / "widgets.git"
    machine.git("remote", "set-url", "origin", str(other))
    result = machine.prepare()
    assert result.returncode == 1
    assert output(result)["step"] == "clone"
    assert machine.worktrees() == []
    assert machine.rex_calls() == []


def test_a_missing_clone_names_the_clone_step(machine: Machine) -> None:
    result = machine.prepare("octo/gadgets", "5", "ooloth", "feat/x")
    assert result.returncode == 1
    out = output(result)
    assert out["step"] == "clone"
    assert "gadgets" in out["error"]
    assert "Traceback" not in result.stderr


def test_a_missing_head_branch_names_the_fetch_step(machine: Machine) -> None:
    result = machine.prepare("octo/widgets", "5", "ooloth", "feat/gone")
    assert result.returncode == 1
    out = output(result)
    assert out["step"] == "fetch"
    assert "feat/gone" in out["error"]
    assert machine.worktrees() == []


def test_outside_rex_nothing_is_prepared(machine: Machine) -> None:
    result = machine.prepare(TMUX="tmux-socket,1,0")
    assert result.returncode == 1
    assert output(result)["step"] == "rex"
    assert machine.worktrees() == []


def test_a_failed_launch_with_no_tab_removes_its_worktree_and_branch(machine: Machine) -> None:
    result = machine.prepare(REX_NEW_FAILS="1")
    assert result.returncode == 1
    out = output(result)
    assert out["step"] == "launch"
    assert "request timed out" in out["error"]
    assert out["left"] == "removed"
    assert machine.worktrees() == []
    assert machine.branches() == ["main"]


def test_a_failed_launch_with_its_tab_open_keeps_the_worktree(machine: Machine) -> None:
    windows = json.dumps({"windows": [{"label": LABEL, "focused_block_id": "block:9"}]})
    result = machine.prepare(REX_NEW_FAILS="1", REX_WINDOWS=windows)
    assert result.returncode == 1
    assert output(result)["left"] == "tab open"
    assert len(machine.worktrees()) == 1


def test_a_failed_launch_with_tabs_unreadable_keeps_the_worktree(machine: Machine) -> None:
    result = machine.prepare(REX_NEW_FAILS="1", REX_LIST_FAILS="1")
    assert result.returncode == 1
    assert output(result)["left"] == "tabs unknown"
    assert len(machine.worktrees()) == 1


def test_a_clean_pushed_earlier_worktree_is_removed(machine: Machine) -> None:
    stale = machine.stale_worktree("pr-5-20261101T000000Z")
    result = machine.prepare()
    assert result.returncode == 0, result.stderr
    assert output(result)["removed"] == [str(stale)]
    assert not stale.exists()
    assert "pr-5-20261101T000000Z" not in machine.branches()


@pytest.mark.parametrize("change", ["uncommitted", "untracked", "unpushed"])
def test_an_earlier_worktree_with_work_in_it_is_kept(machine: Machine, change: str) -> None:
    stale = machine.stale_worktree("pr-5-20261101T000000Z")
    match change:
        case "uncommitted":
            (stale / "tracked").write_text("a")
            machine.git("add", "tracked", cwd=stale)
        case "untracked":
            (stale / "notes").write_text("a")
        case "unpushed":
            machine.git("commit", "-q", "--allow-empty", "-m", "local", cwd=stale)
    result = machine.prepare()
    assert result.returncode == 0, result.stderr
    [kept] = output(result)["kept"]
    assert kept["path"] == str(stale)
    assert stale.exists()


def test_another_prs_worktree_is_untouched(machine: Machine) -> None:
    other = machine.clone / ".claude" / "worktrees" / "pr-50-20261101T000000Z"
    machine.git("worktree", "add", "-q", "-b", other.name, str(other), "origin/feat/x")
    result = machine.prepare()
    assert result.returncode == 0, result.stderr
    assert other.exists()
    assert output(result)["removed"] == []


def test_the_fetch_never_waits_on_a_prompt(machine: Machine, stubs: Path) -> None:
    machine.git("config", "protocol.ext.allow", "always")
    url = f"ext::{stubs / 'prompt-remote'} /octo/widgets"
    machine.git("remote", "set-url", "origin", url)
    result = machine.prepare()
    out = output(result)
    assert out["step"] == "fetch"
    assert "prompt=0" in out["error"]


def test_prepared_worktrees_do_not_show_in_the_clones_status(machine: Machine) -> None:
    result = machine.prepare()
    assert result.returncode == 0, result.stderr
    assert machine.git("status", "--porcelain") == ""


def test_nothing_is_pushed_and_gh_is_never_called(machine: Machine) -> None:
    before = machine.git("ls-remote", str(machine.remote))
    result = machine.prepare()
    assert result.returncode == 0, result.stderr
    assert machine.git("ls-remote", str(machine.remote)) == before
    assert not Path(machine.env["GH_LOG"]).exists()


def test_a_non_numeric_pr_number_is_a_usage_error(machine: Machine) -> None:
    result = machine.prepare("octo/widgets", "five", "ooloth", "feat/x")
    assert result.returncode == 2
    assert machine.rex_calls() == []
