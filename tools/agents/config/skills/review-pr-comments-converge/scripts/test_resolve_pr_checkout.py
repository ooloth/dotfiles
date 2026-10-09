"""Black-box tests for resolve_pr_checkout.py.

The script runs as a subprocess, never imported, so it stays a single file. Git is real: each test
builds a bare remote and a clone under tmp_path, with global and system git config switched off so
the developer's hooks and signing settings cannot leak in. A fake `gh` on PATH answers the PR
lookup, so no test can reach GitHub.

Run:
  uv run --with pytest pytest \
    tools/agents/config/skills/review-pr-comments-converge/scripts/test_resolve_pr_checkout.py
"""

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).with_name("resolve_pr_checkout.py")
REPO = "octo/widgets"
HEAD = "feature"

FAKE_GH = """#!/bin/sh
if [ -n "$GH_FAIL" ]; then echo "HTTP 404: Not Found" >&2; exit 1; fi
case "$1" in
  pr) printf '%s\\n' "$GH_PR_JSON" ;;
  repo) printf '{"nameWithOwner": "%s"}\\n' "$GH_REPO_NAME" ;;
esac
"""


class Harness:
    def __init__(self, tmp_path: Path) -> None:
        self.tmp_path = tmp_path
        bin_dir = tmp_path / "bin"
        bin_dir.mkdir()
        gh = bin_dir / "gh"
        gh.write_text(FAKE_GH)
        gh.chmod(0o755)
        empty_config = tmp_path / "gitconfig"
        empty_config.write_text("")
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            "GIT_CONFIG_GLOBAL": str(empty_config),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AUTHOR_NAME": "Test",
            "GIT_AUTHOR_EMAIL": "test@example.com",
            "GIT_COMMITTER_NAME": "Test",
            "GIT_COMMITTER_EMAIL": "test@example.com",
            "GH_REPO_NAME": REPO,
        }
        self.env.pop("GH_REPO", None)
        self.pr(state="OPEN")

        self.remote = tmp_path / "remotes" / "octo" / "widgets.git"
        self.remote.parent.mkdir(parents=True)
        self.git(tmp_path, "init", "-q", "--bare", "-b", "trunk", str(self.remote))
        self.main = tmp_path / "main"
        self.git(tmp_path, "clone", "-q", str(self.remote), str(self.main))
        self.git(self.main, "switch", "-q", "-c", "trunk")
        self.commit(self.main, "README.md", "hello\n")
        self.git(self.main, "push", "-q", "-u", "origin", "trunk")
        self.git(self.main, "switch", "-q", "-c", HEAD)
        self.commit(self.main, "feature.txt", "one\n")
        self.git(self.main, "push", "-q", "-u", "origin", HEAD)
        self.git(self.main, "switch", "-q", "trunk")
        self.git(self.main, "branch", "-q", "-D", HEAD)

    def pr(self, state: str = "OPEN", cross_repo: bool = False) -> None:
        self.env["GH_PR_JSON"] = json.dumps(
            {"state": state, "headRefName": HEAD, "isCrossRepository": cross_repo}
        )

    def git(self, cwd: Path, *args: str) -> str:
        result = subprocess.run(
            ["git", *args], cwd=cwd, env=self.env, check=True, capture_output=True, text=True
        )
        return result.stdout.strip()

    def commit(self, cwd: Path, name: str, text: str) -> None:
        (cwd / name).write_text(text)
        self.git(cwd, "add", name)
        self.git(cwd, "commit", "-q", "-m", f"change {name}")

    def push_from_elsewhere(self) -> None:
        """Move the remote's head branch forward without touching any test checkout."""
        other = self.tmp_path / "other"
        self.git(self.tmp_path, "clone", "-q", "-b", HEAD, str(self.remote), str(other))
        self.commit(other, "feature.txt", "two\n")
        self.git(other, "push", "-q", "origin", HEAD)

    def sibling_worktree(self) -> Path:
        edge = self.tmp_path / "edge"
        self.git(self.main, "worktree", "add", "-q", str(edge), HEAD)
        return edge

    def snapshot(self) -> list[tuple[str, str, str, str]]:
        """Every worktree's path, branch, HEAD and full status, untracked files included."""
        listing = self.git(self.main, "worktree", "list", "--porcelain")
        paths = [
            line.split(" ", 1)[1] for line in listing.splitlines() if line.startswith("worktree ")
        ]
        return [
            (
                path,
                self.git(Path(path), "branch", "--show-current"),
                self.git(Path(path), "rev-parse", "HEAD"),
                self.git(Path(path), "status", "--porcelain", "--untracked-files=all"),
            )
            for path in paths
        ]

    def run(
        self, *args: str, cwd: Path | None = None, fail_gh: bool = False
    ) -> subprocess.CompletedProcess[str]:
        env = {**self.env, **({"GH_FAIL": "1"} if fail_gh else {})}
        return subprocess.run(
            [sys.executable, str(SCRIPT), "233", *args],
            cwd=cwd or self.main,
            check=False,
            capture_output=True,
            text=True,
            env=env,
        )

    def assert_refused(
        self,
        result: subprocess.CompletedProcess[str],
        before: list[tuple[str, str, str, str]],
        *words: str,
    ) -> None:
        assert result.returncode == 1, result.stderr
        assert result.stdout == ""
        assert "Traceback" not in result.stderr
        for word in words:
            assert word in result.stderr
        assert self.snapshot() == before


@pytest.fixture
def h(tmp_path: Path) -> Harness:
    return Harness(tmp_path)


def resolved(path: Path) -> str:
    return str(path.resolve())


@pytest.mark.parametrize("state", ["CLOSED", "MERGED"])
def test_a_pr_that_is_not_open_is_refused(h: Harness, state: str) -> None:
    h.pr(state=state)
    before = h.snapshot()
    h.assert_refused(h.run(), before, state)


def test_a_pr_whose_head_is_on_a_fork_is_refused(h: Harness) -> None:
    h.pr(cross_repo=True)
    before = h.snapshot()
    h.assert_refused(h.run(), before, "fork")


def test_a_clean_in_sync_sibling_worktree_is_used_and_nothing_moves(h: Harness) -> None:
    edge = h.sibling_worktree()
    before = h.snapshot()
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == resolved(edge)
    assert "existing worktree" in result.stderr
    assert h.snapshot() == before


def test_a_sibling_worktree_ahead_of_the_remote_is_used(h: Harness) -> None:
    edge = h.sibling_worktree()
    h.commit(edge, "local.txt", "unpushed\n")
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == resolved(edge)


def test_a_sibling_worktree_with_uncommitted_tracked_changes_is_refused(h: Harness) -> None:
    edge = h.sibling_worktree()
    (edge / "feature.txt").write_text("edited\n")
    before = h.snapshot()
    h.assert_refused(h.run(), before, str(edge.resolve()), "uncommitted")


def test_a_sibling_worktree_behind_the_remote_is_refused(h: Harness) -> None:
    h.sibling_worktree()
    h.push_from_elsewhere()
    before = h.snapshot()
    h.assert_refused(h.run(), before, "behind")


def test_a_sibling_worktree_diverged_from_the_remote_is_refused(h: Harness) -> None:
    edge = h.sibling_worktree()
    h.push_from_elsewhere()
    h.commit(edge, "local.txt", "unpushed\n")
    before = h.snapshot()
    h.assert_refused(h.run(), before, "diverged")


def test_a_clean_checkout_switches_to_the_head_branch_and_says_how_to_undo(h: Harness) -> None:
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == resolved(h.main)
    assert h.git(h.main, "branch", "--show-current") == HEAD
    assert "switch trunk" in result.stderr


def test_untracked_files_survive_the_switch(h: Harness) -> None:
    (h.main / "notes.md").write_text("mine\n")
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert h.git(h.main, "branch", "--show-current") == HEAD
    assert (h.main / "notes.md").read_text() == "mine\n"


def test_a_checkout_with_uncommitted_tracked_changes_is_not_switched(h: Harness) -> None:
    (h.main / "README.md").write_text("edited\n")
    before = h.snapshot()
    h.assert_refused(h.run(), before, "uncommitted")


def test_a_local_head_branch_behind_the_remote_is_not_switched_to(h: Harness) -> None:
    h.git(h.main, "branch", HEAD, f"origin/{HEAD}")
    h.push_from_elsewhere()
    before = h.snapshot()
    h.assert_refused(h.run(), before, "behind")


def test_a_checkout_already_on_the_head_branch_is_used_even_with_uncommitted_changes(
    h: Harness,
) -> None:
    h.git(h.main, "switch", "-q", HEAD)
    (h.main / "feature.txt").write_text("in progress\n")
    before = h.snapshot()
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == resolved(h.main)
    assert "uncommitted" in result.stderr
    assert h.snapshot() == before


def test_a_checkout_already_on_the_head_branch_but_behind_is_refused(h: Harness) -> None:
    h.git(h.main, "switch", "-q", HEAD)
    h.push_from_elsewhere()
    before = h.snapshot()
    h.assert_refused(h.run(), before, "behind")


def test_a_checkout_tracking_the_head_branch_is_used_despite_a_stale_branch_of_that_name(
    h: Harness,
) -> None:
    h.git(h.main, "branch", HEAD, f"origin/{HEAD}")
    h.push_from_elsewhere()
    h.git(h.main, "fetch", "-q", "origin")
    h.git(h.main, "switch", "-q", "-c", "pr-233", "--track", f"origin/{HEAD}")
    before = h.snapshot()
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == resolved(h.main)
    assert f"pr-233, which tracks origin/{HEAD}" in result.stderr
    assert h.snapshot() == before


def test_a_sibling_worktree_tracking_the_head_branch_is_used(h: Harness) -> None:
    edge = h.tmp_path / "edge"
    h.git(h.main, "worktree", "add", "-q", "--track", "-b", "pr-233", str(edge), f"origin/{HEAD}")
    before = h.snapshot()
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == resolved(edge)
    assert f"pr-233, which tracks origin/{HEAD}" in result.stderr
    assert h.snapshot() == before


def test_a_checkout_tracking_the_head_branch_but_behind_is_refused(h: Harness) -> None:
    h.git(h.main, "switch", "-q", "-c", "pr-233", "--track", f"origin/{HEAD}")
    h.push_from_elsewhere()
    before = h.snapshot()
    h.assert_refused(h.run(), before, "pr-233", "behind")


def test_a_checkout_tracking_the_head_branch_is_used_even_with_uncommitted_changes(
    h: Harness,
) -> None:
    h.git(h.main, "switch", "-q", "-c", "pr-233", "--track", f"origin/{HEAD}")
    (h.main / "feature.txt").write_text("in progress\n")
    before = h.snapshot()
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == resolved(h.main)
    assert "uncommitted" in result.stderr
    assert h.snapshot() == before


def test_two_other_worktrees_holding_the_head_branch_are_refused(h: Harness) -> None:
    edge = h.sibling_worktree()
    other = h.tmp_path / "other-edge"
    h.git(h.main, "worktree", "add", "-q", "--track", "-b", "pr-233", str(other), f"origin/{HEAD}")
    before = h.snapshot()
    h.assert_refused(h.run(), before, str(edge.resolve()), str(other.resolve()))


def test_a_checkout_of_a_different_repo_is_refused(h: Harness) -> None:
    before = h.snapshot()
    h.assert_refused(h.run("--repo", "octo/gadgets"), before, "octo/gadgets")


def test_a_failed_pr_lookup_is_refused_with_a_sentence(h: Harness) -> None:
    before = h.snapshot()
    h.assert_refused(h.run("--repo", REPO, fail_gh=True), before, "gh pr view")


def test_a_failed_fetch_is_refused_with_a_sentence(h: Harness) -> None:
    h.git(
        h.main,
        "remote",
        "set-url",
        "origin",
        str(h.tmp_path / "remotes" / "octo" / "widgets-missing.git"),
    )
    h.git(h.main, "remote", "add", "github", str(h.tmp_path / "nowhere" / "octo" / "widgets.git"))
    h.git(h.main, "remote", "remove", "origin")
    before = h.snapshot()
    h.assert_refused(h.run(), before, "fetch")


def test_running_outside_a_git_checkout_is_refused(h: Harness) -> None:
    outside = h.tmp_path / "plain"
    outside.mkdir()
    result = h.run("--repo", REPO, cwd=outside)
    assert result.returncode == 1
    assert "git checkout" in result.stderr
    assert "Traceback" not in result.stderr
