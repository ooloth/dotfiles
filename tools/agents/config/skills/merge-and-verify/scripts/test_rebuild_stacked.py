"""Tests for rebuild_stacked.py, which merges trunk into a stacked PR after its base squash-merged.

Each test builds the case that a plain merge gets wrong: a base PR that changed again after the
stacked branch last merged it, then squash-merged into trunk. The stacked branch still carries the
base PR's older line, which trunk's final version moved elsewhere in the file, so Git merges the
two without a conflict and keeps both.

Run:
  uv run --with pytest pytest tools/agents/config/skills/merge-and-verify/scripts/test_rebuild_stacked.py
"""

import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

import pytest

SCRIPT = Path(__file__).with_name("rebuild_stacked.py")

LINES = "".join(f"line{n}\n" for n in range(1, 11))


def git(cwd: Path, *args: str) -> str:
    return subprocess.run(
        ["git", *args], cwd=cwd, check=True, capture_output=True, text=True
    ).stdout


def edit(path: Path, old: str, new: str) -> None:
    path.write_text(path.read_text().replace(old, new))


@dataclass(frozen=True)
class Stack:
    work: Path
    base_pr_head: str


@pytest.fixture
def stack(tmp_path: Path) -> Stack:
    origin = tmp_path / "origin"
    origin.mkdir()
    git(origin, "init", "-q", "-b", "trunk")
    git(origin, "config", "user.email", "test@example.com")
    git(origin, "config", "user.name", "test")
    (origin / "a.py").write_text(LINES)
    git(origin, "add", "a.py")
    git(origin, "commit", "-qm", "init")

    # The base PR adds a helper, and the stacked branch is cut from that commit.
    git(origin, "checkout", "-qb", "base")
    (origin / "a.py").write_text("def helper_old(): pass\n" + LINES)
    git(origin, "commit", "-qam", "base: add helper_old")
    git(origin, "checkout", "-qb", "stacked")
    edit(origin / "a.py", "line5\n", "line5  # stacked edit\n")
    (origin / "b.py").write_text("own = 1\n")
    git(origin, "add", "b.py")
    git(origin, "commit", "-qam", "stacked: own change")

    # The base PR then replaces the helper at the other end of the file, and squash-merges.
    git(origin, "checkout", "-q", "base")
    (origin / "a.py").write_text(LINES + "def helper_new(): pass\n")
    git(origin, "commit", "-qam", "base: replace with helper_new")
    base_pr_head = git(origin, "rev-parse", "HEAD").strip()
    git(origin, "checkout", "-q", "trunk")
    git(origin, "merge", "-q", "--squash", "base")
    git(origin, "commit", "-qm", "squash base")

    work = tmp_path / "work"
    git(tmp_path, "clone", "-q", str(origin), str(work))
    git(work, "config", "user.email", "test@example.com")
    git(work, "config", "user.name", "test")
    git(work, "checkout", "-q", "stacked")
    return Stack(work=work, base_pr_head=base_pr_head)


def run(stack: Stack, *extra: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-I", str(SCRIPT), "--base-pr-head", stack.base_pr_head, *extra],
        cwd=stack.work,
        capture_output=True,
        text=True,
    )


def test_a_plain_merge_keeps_the_base_prs_older_line_without_a_conflict(stack: Stack) -> None:
    """The failure this script exists for: without it, the stale helper comes back silently."""
    merged = subprocess.run(
        ["git", "merge", "--no-commit", "--no-ff", "origin/trunk"],
        cwd=stack.work,
        capture_output=True,
        text=True,
    )

    assert merged.returncode == 0
    assert "def helper_old" in (stack.work / "a.py").read_text()


def test_the_rebuild_keeps_trunk_and_only_the_branchs_own_change(stack: Stack) -> None:
    result = run(stack)

    assert result.returncode == 0, result.stdout + result.stderr
    assert (stack.work / "a.py").read_text() == LINES.replace(
        "line5\n", "line5  # stacked edit\n"
    ) + ("def helper_new(): pass\n")
    assert (stack.work / "b.py").read_text() == "own = 1\n"
    assert git(stack.work, "diff", "--cached", "--name-only", "origin/trunk").split() == [
        "a.py",
        "b.py",
    ]


def test_check_only_flags_a_plain_merges_stale_lines(stack: Stack) -> None:
    git(stack.work, "merge", "-q", "--no-commit", "--no-ff", "origin/trunk")

    result = run(stack, "--check-only")

    assert result.returncode == 1
    assert "a.py" in result.stdout


def test_check_only_passes_the_rebuilt_merge(stack: Stack) -> None:
    assert run(stack).returncode == 0

    assert run(stack, "--check-only").returncode == 0


def test_a_dirty_tree_is_refused_before_anything_merges(stack: Stack) -> None:
    (stack.work / "b.py").write_text("uncommitted\n")

    result = run(stack)

    assert result.returncode == 2
    assert not (stack.work / ".git" / "MERGE_HEAD").exists()


# The case that merged a stacked PR as an empty commit: the branch splits one file into others,
# and trunk has edited that file since the branch was cut. A patch of the branch's own diff no
# longer applies to trunk's copy of the file, so the rebuild must not fall back to trunk's tree.
RULES = "".join(f".rule{n} {{ color: red; }}\n" for n in range(1, 31))
SITE_RULES = "".join(f".rule{n} {{ color: red; }}\n" for n in range(1, 4))
INTERNAL_RULES = "".join(f".rule{n} {{ color: red; }}\n" for n in range(4, 31))
TRUNK_RULE = ".badge { color: orange; }\n"


@pytest.fixture
def split_stack(tmp_path: Path) -> Stack:
    origin = tmp_path / "origin"
    origin.mkdir()
    git(origin, "init", "-q", "-b", "trunk")
    git(origin, "config", "user.email", "test@example.com")
    git(origin, "config", "user.name", "test")
    (origin / "style.css").write_text(RULES)
    (origin / "app.py").write_text("app = 1\n")
    git(origin, "add", ".")
    git(origin, "commit", "-qm", "init")

    git(origin, "checkout", "-qb", "base")
    (origin / "app.py").write_text("app = 2\n")
    git(origin, "commit", "-qam", "base: change app")
    base_pr_head = git(origin, "rev-parse", "HEAD").strip()
    git(origin, "checkout", "-qb", "stacked")
    git(origin, "mv", "style.css", "internal.css")
    (origin / "internal.css").write_text(INTERNAL_RULES)
    (origin / "site.css").write_text(SITE_RULES)
    git(origin, "add", "-A")
    git(origin, "commit", "-qm", "stacked: split style.css")

    # Another PR adds a rule to style.css on trunk, then the base PR squash-merges.
    git(origin, "checkout", "-q", "trunk")
    (origin / "style.css").write_text(RULES + TRUNK_RULE)
    git(origin, "commit", "-qam", "another PR: add a badge rule")
    git(origin, "merge", "-q", "--squash", "base")
    git(origin, "commit", "-qm", "squash base")

    work = tmp_path / "work"
    git(tmp_path, "clone", "-q", str(origin), str(work))
    git(work, "config", "user.email", "test@example.com")
    git(work, "config", "user.name", "test")
    git(work, "checkout", "-q", "stacked")
    return Stack(work=work, base_pr_head=base_pr_head)


def test_a_split_file_trunk_edited_keeps_the_split_and_trunks_edit(split_stack: Stack) -> None:
    result = run(split_stack)

    assert result.returncode == 0, result.stdout + result.stderr
    assert not (split_stack.work / "style.css").exists()
    assert (split_stack.work / "site.css").read_text() == SITE_RULES
    assert (split_stack.work / "internal.css").read_text() == INTERNAL_RULES + TRUNK_RULE
    changed = git(
        split_stack.work, "diff", "--cached", "--name-only", "--no-renames", "origin/trunk"
    )
    assert changed.split() == [
        "internal.css",
        "site.css",
        "style.css",
    ]


def test_check_only_refuses_a_staged_tree_that_lost_the_branchs_own_change(
    split_stack: Stack,
) -> None:
    git(split_stack.work, "merge", "-q", "--no-commit", "--no-ff", "origin/trunk")
    git(split_stack.work, "read-tree", "--reset", "-u", "origin/trunk")

    result = run(split_stack, "--check-only")

    assert result.returncode == 1
    assert "site.css" in result.stdout


def test_a_line_both_sides_changed_is_left_as_a_conflict_to_resolve(stack: Stack) -> None:
    origin = stack.work.parent / "origin"
    git(origin, "checkout", "-q", "trunk")
    edit(origin / "a.py", "line5\n", "line5  # trunk edit\n")
    git(origin, "commit", "-qam", "another PR: edit line5")
    git(stack.work, "fetch", "-q")

    result = run(stack)

    assert result.returncode == 1
    assert "Conflicts still to resolve:\n  a.py" in result.stdout
    assert git(stack.work, "diff", "--name-only", "--diff-filter=U").split() == ["a.py"]
    assert "<<<<<<<" in (stack.work / "a.py").read_text()
