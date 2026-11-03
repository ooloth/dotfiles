"""Black-box tests for compare_heads.py.

The script runs as a subprocess, never imported, so it stays a single file. A fake `gh` on PATH
answers from a table of canned responses, so no test can reach GitHub.

Run:
  uv run --with pytest pytest tools/agents/config/skills/review-code/scripts/test_compare_heads.py
"""

import json
import os
import subprocess
import sys
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Any

import pytest

SCRIPT = Path(__file__).with_name("compare_heads.py")
REPO = "octo/widgets"
OLD_BASE, OLD_HEAD = "oldbase", "oldhead"
NEW_BASE, NEW_HEAD = "newbase", "newhead"

# Answers each `gh` call from GH_TABLE, keyed by its arguments joined with spaces.
FAKE_GH = """#!/usr/bin/env python3
import json, os, sys
table = json.load(open(os.environ["GH_TABLE"]))
key = " ".join(sys.argv[1:])
if key not in table:
    print(f"HTTP 404: Not Found ({key})", file=sys.stderr)
    sys.exit(1)
print(json.dumps(table[key]))
"""

EDIT = "+def greet():\n+    return 'hi'"


def patch(edit: str, *, hunk: str = "@@ -1,2 +1,4 @@", context: str = " import os") -> str:
    return f"{hunk}\n{context}\n{edit}"


def compare_key(base: str, head: str) -> str:
    return f"api repos/{REPO}/compare/{base}...{head}"


class Harness:
    def __init__(self, tmp_path: Path) -> None:
        bin_dir = tmp_path / "bin"
        bin_dir.mkdir()
        gh = bin_dir / "gh"
        gh.write_text(FAKE_GH)
        gh.chmod(0o755)
        self.table_path = tmp_path / "table.json"
        self.table: dict[str, Any] = {
            f"pr view 7 -R {REPO} --json baseRefOid,headRefOid": {
                "baseRefOid": NEW_BASE,
                "headRefOid": NEW_HEAD,
            }
        }
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            "GH_TABLE": str(self.table_path),
        }

    def diffs(
        self,
        reviewed: Mapping[str, str | None],
        now: Mapping[str, str | None],
        between: Mapping[str, str | None] | None = None,
        commits: Sequence[tuple[str, str]] = (),
    ) -> None:
        def files(patches: Mapping[str, str | None]) -> dict[str, Any]:
            return {
                "files": [
                    {"filename": path, **({"patch": p} if p is not None else {})}
                    for path, p in patches.items()
                ]
            }

        self.table[compare_key(OLD_BASE, OLD_HEAD)] = files(reviewed)
        self.table[compare_key(NEW_BASE, NEW_HEAD)] = files(now)
        self.table[compare_key(OLD_HEAD, NEW_HEAD)] = {
            **files(between or {}),
            "status": "ahead",
            "commits": [{"sha": sha, "commit": {"message": message}} for sha, message in commits],
        }

    def run(self) -> subprocess.CompletedProcess[str]:
        self.table_path.write_text(json.dumps(self.table))
        return subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "7",
                "--repo",
                REPO,
                "--old-base",
                OLD_BASE,
                "--old-head",
                OLD_HEAD,
            ],
            check=False,
            capture_output=True,
            text=True,
            env=self.env,
        )


@pytest.fixture
def h(tmp_path: Path) -> Harness:
    return Harness(tmp_path)


def line_for(stdout: str, path: str) -> str:
    return next(line for line in stdout.splitlines() if line.strip().startswith(f"{path}:"))


def test_same_edits_under_moved_context_count_as_identical(h: Harness) -> None:
    moved = patch(EDIT, hunk="@@ -40,2 +40,4 @@", context=" import sys")
    h.diffs({"app.py": patch(EDIT)}, {"app.py": moved}, between={"lib.py": "+x", "app.py": "+y"})
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert "identical" in line_for(result.stdout, "app.py")


def test_files_that_moved_outside_the_pr_are_listed(h: Harness) -> None:
    h.diffs(
        {"app.py": patch(EDIT)}, {"app.py": patch(EDIT)}, between={"lib.py": "+x", "app.py": "+y"}
    )
    result = h.run()
    outside = result.stdout.split("outside the PR's diff")[1]
    assert "lib.py" in outside
    assert "app.py" not in outside


def test_a_changed_edit_line_exits_1_and_shows_both_versions(h: Harness) -> None:
    h.diffs({"app.py": patch(EDIT)}, {"app.py": patch(EDIT.replace("'hi'", "'hello'"))})
    result = h.run()
    assert result.returncode == 1
    assert "changed" in line_for(result.stdout, "app.py")
    assert "-+    return 'hi'" in result.stdout
    assert "++    return 'hello'" in result.stdout


@pytest.mark.parametrize(
    ("reviewed", "now", "verdict"),
    [
        ({}, {"new.py": "+x"}, "added to the PR"),
        ({"old.py": "+x"}, {}, "dropped from the PR"),
    ],
)
def test_a_file_entering_or_leaving_the_pr_exits_1(
    h: Harness, reviewed: dict[str, str | None], now: dict[str, str | None], verdict: str
) -> None:
    h.diffs({"app.py": patch(EDIT), **reviewed}, {"app.py": patch(EDIT), **now})
    result = h.run()
    assert result.returncode == 1
    assert verdict in result.stdout


def test_a_patch_github_left_out_counts_as_changed(h: Harness) -> None:
    h.diffs({"logo.png": None}, {"logo.png": None})
    result = h.run()
    assert result.returncode == 1
    assert "cannot be shown" in line_for(result.stdout, "logo.png")


def test_a_comparison_at_githubs_file_limit_cannot_be_trusted(h: Harness) -> None:
    many = {f"f{i}.py": "+x" for i in range(300)}
    h.diffs(many, many)
    result = h.run()
    assert result.returncode == 2
    assert "300" in result.stderr


def test_a_commit_github_cannot_find_exits_2_with_the_reason(h: Harness) -> None:
    # No compare answers in the table, as when a saved SHA is mistyped or no longer on GitHub.
    result = h.run()
    assert result.returncode == 2
    assert "Not Found" in result.stderr
    assert result.stdout == ""


def test_a_blank_line_in_a_patch_is_not_an_edit_line(h: Harness) -> None:
    h.diffs({"app.py": f"@@ -1,3 +1,4 @@\n import os\n\n{EDIT}"}, {"app.py": patch(EDIT)})
    result = h.run()
    assert result.returncode == 0, result.stdout
    assert line_for(result.stdout, "app.py").endswith("identical")


def test_a_removed_line_that_starts_with_a_dash_is_shown(h: Harness) -> None:
    h.diffs({"notes.md": "@@ -1 +1 @@\n-- old bullet"}, {"notes.md": "@@ -1 +1 @@\n-- new bullet"})
    result = h.run()
    assert result.returncode == 1
    assert "-- old bullet" in result.stdout
    assert "-- new bullet" in result.stdout


def test_a_file_added_to_the_pr_shows_its_lines(h: Harness) -> None:
    h.diffs({}, {"new.py": "@@ -0,0 +1 @@\n+print('new')"})
    result = h.run()
    assert "+print('new')" in result.stdout


def test_identical_edits_in_a_file_that_changed_around_them_are_flagged(h: Harness) -> None:
    h.diffs({"app.py": patch(EDIT)}, {"app.py": patch(EDIT)}, between={"app.py": "+other"})
    result = h.run()
    assert result.returncode == 0
    assert "code around them changed" in line_for(result.stdout, "app.py")


def test_full_shas_and_the_new_commits_are_printed(h: Harness) -> None:
    h.diffs({}, {}, commits=[("abc1234567890", "Merge trunk into feature\n\nbody")])
    result = h.run()
    for sha in (OLD_BASE, OLD_HEAD, NEW_BASE, NEW_HEAD):
        assert sha in result.stdout
    assert "abc12345 Merge trunk into feature" in result.stdout
    assert "body" not in result.stdout
