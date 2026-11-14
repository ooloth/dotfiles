"""Black-box tests for check_branch.py.

Each test builds a throwaway git repo and runs the script as a subprocess from inside it, so the
script stays a single file and no test touches a real repo.

Run:
  uv run --with pytest pytest tools/agents/config/skills/commit/scripts/test_check_branch.py
"""

import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).with_name("check_branch.py")


def git(repo: Path, *args: str) -> None:
    subprocess.run(
        ["git", "-c", "user.name=t", "-c", "user.email=t@t", *args], cwd=repo, check=True
    )


def make_repo(tmp_path: Path) -> Path:
    repo = tmp_path / "repo"
    repo.mkdir()
    git(repo, "init", "-q", "-b", "main")
    (repo / "a.txt").write_text("a\n")
    git(repo, "add", "a.txt")
    git(repo, "commit", "-q", "-m", "init")
    git(repo, "switch", "-q", "-c", "feature/mine")
    return repo


def run(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-I", str(SCRIPT), *args], cwd=repo, capture_output=True, text=True
    )


def test_the_branch_the_session_is_on_passes(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)

    result = run(repo, "feature/mine")

    assert result.returncode == 0, result.stdout + result.stderr


def test_a_branch_another_session_switched_to_is_refused_and_named(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    git(repo, "switch", "-q", "-c", "someone-else")

    result = run(repo, "feature/mine")

    assert result.returncode == 1
    assert "someone-else" in result.stdout
    assert "feature/mine" in result.stdout
    assert "moving from feature/mine to someone-else" in result.stdout


def test_a_detached_head_is_refused(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    git(repo, "switch", "-q", "--detach", "HEAD")

    result = run(repo, "feature/mine")

    assert result.returncode == 1
    assert "detached" in result.stdout


def test_no_branch_named_is_a_usage_error(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)

    result = run(repo)

    assert result.returncode == 2


def test_outside_a_repository_the_check_cannot_run(tmp_path: Path) -> None:
    result = run(tmp_path, "feature/mine")

    assert result.returncode == 2
