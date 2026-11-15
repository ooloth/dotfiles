"""Black-box tests for base_moved.py.

The script runs as a subprocess, never imported, so it stays a single file. A fake `gh` on PATH
answers from a table of canned responses, so no test can reach GitHub. An entry whose value is
{"sequence": [...]} answers each call with the next item, repeating the last one.

Run:
  uv run --with pytest pytest tools/agents/config/skills/review-code/scripts/test_base_moved.py
"""

import json
import os
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import Any

import pytest

SCRIPT = Path(__file__).with_name("base_moved.py")
REPO = "octo/widgets"
BASE_TIP, HEAD, MERGE_BASE = "basetip", "prhead", "forkpoint"
# The base SHA GitHub records on a PR is the base as of the PR's last update, not the branch tip.
STALE_BASE = "stalebase"

FAKE_GH = """#!/usr/bin/env python3
import json, os, sys
table = json.load(open(os.environ["GH_TABLE"]))
key = " ".join(sys.argv[1:])
if key not in table:
    print(f"HTTP 404: Not Found ({key})", file=sys.stderr)
    sys.exit(1)
answer = table[key]
if isinstance(answer, dict) and "sequence" in answer:
    counts_path = os.environ["GH_TABLE"] + ".counts"
    counts = json.load(open(counts_path)) if os.path.exists(counts_path) else {}
    n = counts.get(key, 0)
    counts[key] = n + 1
    json.dump(counts, open(counts_path, "w"))
    answer = answer["sequence"][min(n, len(answer["sequence"]) - 1)]
print(json.dumps(answer))
"""

PR_VIEW = f"api repos/{REPO}/pulls/7"


def pr_files_key(page: int) -> str:
    return f"api repos/{REPO}/pulls/7/files?per_page=100&page={page}"


def commit_key(sha: str, page: int = 1) -> str:
    return f"api repos/{REPO}/commits/{sha}?per_page=100&page={page}"


def file_entry(path: str, previous: str | None = None) -> dict[str, Any]:
    return {"filename": path, **({"previous_filename": previous} if previous else {})}


class Harness:
    def __init__(self, tmp_path: Path) -> None:
        bin_dir = tmp_path / "bin"
        bin_dir.mkdir()
        gh = bin_dir / "gh"
        gh.write_text(FAKE_GH)
        gh.chmod(0o755)
        self.table_path = tmp_path / "table.json"
        self.table: dict[str, Any] = {
            f"api repos/{REPO}/branches/main": {"commit": {"sha": BASE_TIP}},
            f"api repos/{REPO}/compare/{BASE_TIP}...{HEAD}": {
                "merge_base_commit": {"sha": MERGE_BASE}
            },
        }
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            "GH_TABLE": str(self.table_path),
            "BASE_MOVED_RETRY_DELAY": "0",
        }

    def pr(
        self,
        files: Sequence[dict[str, Any]],
        *,
        mergeable: str | list[str] = "MERGEABLE",
        changed_files: int | None = None,
    ) -> None:
        def view(state: str) -> dict[str, Any]:
            return {
                "state": "open",
                "base": {"ref": "main", "sha": STALE_BASE},
                "head": {"sha": HEAD},
                "mergeable": {"MERGEABLE": True, "CONFLICTING": False, "UNKNOWN": None}[state],
                "changed_files": len(files) if changed_files is None else changed_files,
            }

        self.table[PR_VIEW] = (
            {"sequence": [view(s) for s in mergeable]}
            if isinstance(mergeable, list)
            else view(mergeable)
        )
        self.table[pr_files_key(1)] = list(files)
        self.table[pr_files_key(2)] = []

    def base(
        self,
        commits: Sequence[tuple[str, str, Sequence[dict[str, Any]]]],
        *,
        aggregate: Sequence[dict[str, Any]] | None = None,
        total_commits: int | None = None,
    ) -> None:
        """Base commits since the merge base, oldest first, each with the files it touches."""
        if aggregate is None:
            aggregate = [f for _, _, files in commits for f in files]
        self.table[f"api repos/{REPO}/compare/{MERGE_BASE}...{BASE_TIP}"] = {
            "total_commits": len(commits) if total_commits is None else total_commits,
            "commits": [
                {"sha": sha, "commit": {"message": f"{subject}\n\nbody"}}
                for sha, subject, _ in commits
            ],
            "files": list(aggregate),
        }
        for sha, subject, files in commits:
            # GitHub answers a page past the end with an empty file list.
            pages = [list(files[i : i + 100]) for i in range(0, len(files), 100)] + [[]]
            for n, page in enumerate(pages, start=1):
                self.table[commit_key(sha, n)] = {
                    "sha": sha,
                    "commit": {"message": subject},
                    "files": page,
                }

    def run(self) -> subprocess.CompletedProcess[str]:
        self.table_path.write_text(json.dumps(self.table))
        return subprocess.run(
            [sys.executable, str(SCRIPT), "7", "--repo", REPO],
            check=False,
            capture_output=True,
            text=True,
            env=self.env,
        )


@pytest.fixture
def h(tmp_path: Path) -> Harness:
    return Harness(tmp_path)


def test_no_base_commit_touching_the_prs_files_exits_0_and_says_none(h: Harness) -> None:
    h.pr([file_entry("app.py")])
    h.base([("aaaaaaaa1111", "Touch the docs", [file_entry("docs.md")])])
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert "none" in result.stdout.lower()
    assert "aaaaaaaa" not in result.stdout


def test_a_base_commit_editing_a_pr_file_exits_1_with_sha_subject_and_file(h: Harness) -> None:
    h.pr([file_entry("app.py"), file_entry("lib.py")])
    h.base([("bbbbbbbb2222", "Move the guide (#650)", [file_entry("app.py")])])
    result = h.run()
    assert result.returncode == 1, result.stderr
    assert "bbbbbbbb Move the guide (#650)" in result.stdout
    assert "    app.py" in result.stdout
    assert "lib.py" not in result.stdout.split("bbbbbbbb")[1]


def test_a_base_side_rename_of_a_pr_file_is_listed(h: Harness) -> None:
    h.pr([file_entry("old.md")])
    h.base([("cccccccc3333", "Rename the doc", [file_entry("new.md", previous="old.md")])])
    result = h.run()
    assert result.returncode == 1, result.stderr
    assert "cccccccc Rename the doc" in result.stdout
    assert "    old.md" in result.stdout


def test_a_pr_side_rename_still_matches_base_edits_to_the_old_path(h: Harness) -> None:
    h.pr([file_entry("b.py", previous="a.py")])
    h.base([("dddddddd4444", "Edit a.py", [file_entry("a.py")])])
    result = h.run()
    assert result.returncode == 1, result.stderr
    assert "dddddddd Edit a.py" in result.stdout
    assert "    a.py" in result.stdout


def test_commits_are_listed_oldest_first_each_with_only_its_own_files_sorted(h: Harness) -> None:
    h.pr([file_entry("z.py"), file_entry("a.py"), file_entry("m.py")])
    h.base(
        [
            ("11111111aaaa", "First", [file_entry("z.py"), file_entry("a.py")]),
            ("22222222bbbb", "Unrelated", [file_entry("other.py")]),
            ("33333333cccc", "Second", [file_entry("m.py")]),
        ]
    )
    result = h.run()
    assert result.returncode == 1, result.stderr
    out = result.stdout
    assert out.index("11111111 First") < out.index("33333333 Second")
    assert "22222222" not in out
    first = out.split("11111111 First")[1].split("33333333")[0]
    assert first.index("    a.py") < first.index("    z.py")
    assert "m.py" not in first


def test_conflicting_with_no_shared_file_still_exits_1_and_says_so(h: Harness) -> None:
    h.pr([file_entry("app.py")], mergeable="CONFLICTING")
    h.base([])
    result = h.run()
    assert result.returncode == 1, result.stderr
    assert "CONFLICTING" in result.stdout


def test_mergeable_that_stays_unknown_exits_2(h: Harness) -> None:
    h.pr([file_entry("app.py")], mergeable="UNKNOWN")
    h.base([])
    result = h.run()
    assert result.returncode == 2
    assert result.stderr.startswith("base_moved: ")
    assert "UNKNOWN" in result.stderr


def test_mergeable_unknown_then_known_answers_normally(h: Harness) -> None:
    h.pr([file_entry("app.py")], mergeable=["UNKNOWN", "MERGEABLE"])
    h.base([])
    result = h.run()
    assert result.returncode == 0, result.stderr


def test_300_aggregate_files_falls_back_to_per_commit_reads(h: Harness) -> None:
    h.pr([file_entry("app.py")])
    filler = [file_entry(f"f{i}.txt") for i in range(300)]
    h.base(
        [
            ("eeeeeeee5555", "Big sweep", filler),
            ("ffffffff6666", "Edit app", [file_entry("app.py")]),
        ],
        aggregate=filler,
    )
    result = h.run()
    assert result.returncode == 1, result.stderr
    assert "ffffffff Edit app" in result.stdout


def test_a_truncated_commit_list_exits_2(h: Harness) -> None:
    h.pr([file_entry("app.py")])
    h.base([("aaaaaaaa1111", "One", [file_entry("app.py")])], total_commits=251)
    result = h.run()
    assert result.returncode == 2
    assert result.stderr.startswith("base_moved: ")
    assert "251" in result.stderr


def test_a_pr_file_list_shorter_than_github_counts_exits_2(h: Harness) -> None:
    h.pr([file_entry("app.py")], changed_files=2)
    h.base([])
    result = h.run()
    assert result.returncode == 2
    assert result.stderr.startswith("base_moved: ")
    assert "1 files" in result.stderr and "changes 2" in result.stderr


def test_a_shared_file_on_a_base_commits_second_page_is_listed(h: Harness) -> None:
    h.pr([file_entry("late.py")])
    page_one = [file_entry(f"f{i}.txt") for i in range(100)]
    h.base([("99999999aaaa", "Huge commit", page_one)], aggregate=[file_entry("late.py")])
    h.table[commit_key("99999999aaaa", 2)] = {
        "sha": "99999999aaaa",
        "commit": {"message": "Huge commit"},
        "files": [file_entry("late.py")],
    }
    result = h.run()
    assert result.returncode == 1, result.stderr
    assert "99999999 Huge commit" in result.stdout
    assert "    late.py" in result.stdout


def test_a_failed_gh_call_exits_2_naming_the_call(h: Harness) -> None:
    h.pr([file_entry("app.py")])
    result = h.run()  # no compare entry for the base side
    assert result.returncode == 2
    assert result.stderr.startswith("base_moved: ")
    assert f"compare/{MERGE_BASE}...{BASE_TIP}" in result.stderr
