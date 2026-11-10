"""Black-box tests for overlapping_prs.py.

The script runs as a subprocess, never imported, so it stays a single file. A fake `gh` on PATH
answers from a table of canned responses, so no test can reach GitHub. A GraphQL call is keyed by
its variables, leaving out the query text; any other call by its arguments joined with spaces.

Run:
  uv run --with pytest pytest tools/agents/config/skills/review-code/scripts/test_overlapping_prs.py
"""

import json
import os
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import Any

import pytest

SCRIPT = Path(__file__).with_name("overlapping_prs.py")
OWNER, NAME = "octo", "widgets"
REPO = f"{OWNER}/{NAME}"
TARGET = 7

FAKE_GH = """#!/usr/bin/env python3
import json, os, sys
table = json.load(open(os.environ["GH_TABLE"]))
args = sys.argv[1:]
if args[:2] == ["api", "graphql"]:
    pairs, i = [], 2
    while i < len(args):
        if args[i] in ("-f", "-F"):
            if not args[i + 1].startswith("query="):
                pairs.append(args[i + 1])
            i += 2
        else:
            i += 1
    key = "graphql " + " ".join(sorted(pairs))
else:
    key = " ".join(args)
if key not in table:
    print(f"HTTP 404: Not Found ({key})", file=sys.stderr)
    sys.exit(1)
print(json.dumps(table[key]))
"""

# A file is a path, or an (old path, new path) pair for a rename.
File = str | tuple[str, str]


def rest_file(f: File) -> dict[str, Any]:
    if isinstance(f, tuple):
        return {"filename": f[1], "previous_filename": f[0], "status": "renamed"}
    return {"filename": f, "status": "modified"}


def gql_file(f: File) -> dict[str, Any]:
    if isinstance(f, tuple):
        return {"path": f[1], "changeType": "RENAMED"}
    return {"path": f, "changeType": "MODIFIED"}


def files_page(files: Sequence[File], *, total: int, cursor: str | None = None) -> dict[str, Any]:
    return {
        "totalCount": total,
        "pageInfo": {"hasNextPage": cursor is not None, "endCursor": cursor},
        "nodes": [gql_file(f) for f in files],
    }


@pytest.fixture(scope="module")
def fake_gh_dir(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """The fake `gh`, written once for the module into a folder then made read-only, so no test
    can change what the others run."""
    folder = tmp_path_factory.mktemp("bin")
    gh = folder / "gh"
    gh.write_text(FAKE_GH)
    gh.chmod(0o755)
    folder.chmod(0o555)
    return folder


class Harness:
    def __init__(self, tmp_path: Path, bin_dir: Path) -> None:
        self.table_path = tmp_path / "table.json"
        self.table: dict[str, Any] = {}
        self.pr_pages: list[list[dict[str, Any]]] = [[]]
        self.pr_total: int | None = None  # what GitHub reports; the number listed when None
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            "GH_TABLE": str(self.table_path),
        }

    def target(self, files: Sequence[File], *, changed_files: int | None = None) -> None:
        self.table[f"api repos/{REPO}/pulls/{TARGET}"] = {
            "number": TARGET,
            "base": {"ref": "trunk"},
            "changed_files": len(files) if changed_files is None else changed_files,
        }
        self.table[f"api repos/{REPO}/pulls/{TARGET}/files?per_page=100&page=1"] = [
            rest_file(f) for f in files
        ]

    def open_pr(
        self,
        number: int,
        files: Sequence[File],
        *,
        draft: bool = False,
        page: int = 0,
        more_files: Sequence[File] = (),
        total: int | None = None,
        serve_more: bool = True,
    ) -> None:
        """Add an open PR to the listing. `more_files` arrive on a second page of its files."""
        everything = [*files, *more_files]
        count = len(everything) if total is None else total
        node = {
            "number": number,
            "title": f"Change {number}",
            "isDraft": draft,
            "baseRefName": "trunk",
            "author": {"login": "alice"},
            "files": files_page(files, total=count, cursor="f2" if more_files else None),
        }
        while len(self.pr_pages) <= page:
            self.pr_pages.append([])
        self.pr_pages[page].append(node)
        if more_files and serve_more:
            key = f"graphql cursor=f2 name={NAME} number={number} owner={OWNER}"
            self.table[key] = {
                "data": {
                    "repository": {"pullRequest": {"files": files_page(more_files, total=count)}}
                }
            }
        if any(isinstance(f, tuple) for f in everything):
            self.table[f"api repos/{REPO}/pulls/{number}/files?per_page=100&page=1"] = [
                rest_file(f) for f in everything
            ]

    def run(self, *, drop: Sequence[str] = ()) -> subprocess.CompletedProcess[str]:
        """Run the script. `drop` names table keys to leave out, so the call they answer fails."""
        listed = sum(len(nodes) for nodes in self.pr_pages)
        for i, nodes in enumerate(self.pr_pages):
            cursor = f" cursor=p{i}" if i else ""
            last = i == len(self.pr_pages) - 1
            self.table[f"graphql{cursor} name={NAME} owner={OWNER}"] = {
                "data": {
                    "repository": {
                        "pullRequests": {
                            "totalCount": listed if self.pr_total is None else self.pr_total,
                            "pageInfo": {
                                "hasNextPage": not last,
                                "endCursor": None if last else f"p{i + 1}",
                            },
                            "nodes": nodes,
                        }
                    }
                }
            }
        table = {k: v for k, v in self.table.items() if k not in drop}
        self.table_path.write_text(json.dumps(table))
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(TARGET), "--repo", REPO],
            check=False,
            capture_output=True,
            text=True,
            env=self.env,
        )


@pytest.fixture
def h(tmp_path: Path, fake_gh_dir: Path) -> Harness:
    return Harness(tmp_path, fake_gh_dir)


def listed(stdout: str) -> set[int]:
    return {int(line.split()[0][1:]) for line in stdout.splitlines() if line.startswith("#")}


def test_no_shared_file_exits_0_and_says_how_many_prs_were_checked(h: Harness) -> None:
    h.target(["app.py"])
    h.open_pr(8, ["lib.py"])
    h.open_pr(9, ["docs.md"])
    result = h.run()
    assert result.returncode == 0, result.stderr
    assert "Checked 2 other open PRs" in result.stdout
    assert listed(result.stdout) == set()


def test_a_pr_sharing_one_file_exits_1_and_names_it(h: Harness) -> None:
    h.target(["app.py", "lib.py"])
    h.open_pr(8, ["lib.py", "other.py"])
    result = h.run()
    assert result.returncode == 1, result.stderr
    assert "#8 Change 8 (alice, base trunk)" in result.stdout
    assert "    lib.py" in result.stdout
    assert "other.py" not in result.stdout


def test_only_prs_that_share_a_file_are_listed_with_every_shared_file(h: Harness) -> None:
    h.target(["a.py", "b.py", "c.py"])
    h.open_pr(8, ["a.py", "b.py"])
    h.open_pr(9, ["z.py"])
    result = h.run()
    assert listed(result.stdout) == {8}
    assert "    a.py" in result.stdout and "    b.py" in result.stdout


def test_an_overlapping_draft_is_listed_and_marked_draft(h: Harness) -> None:
    h.target(["app.py"])
    h.open_pr(8, ["app.py"], draft=True)
    result = h.run()
    assert "#8 Change 8 (alice, draft, base trunk)" in result.stdout


def test_the_target_pr_is_not_listed_as_its_own_overlap(h: Harness) -> None:
    h.target(["app.py"])
    h.open_pr(TARGET, ["app.py"])
    h.open_pr(8, ["lib.py"])
    result = h.run()
    assert result.returncode == 0, result.stdout
    assert "Checked 1 other open PR" in result.stdout


def test_a_pr_editing_the_old_path_of_a_file_the_target_renames_is_listed(h: Harness) -> None:
    h.target([("old.py", "new.py")])
    h.open_pr(8, ["old.py"])
    result = h.run()
    assert listed(result.stdout) == {8}
    assert "    old.py" in result.stdout


def test_a_pr_renaming_a_file_the_target_edits_is_listed(h: Harness) -> None:
    h.target(["old.py"])
    h.open_pr(8, [("old.py", "new.py")])
    result = h.run()
    assert listed(result.stdout) == {8}


def test_an_overlapping_pr_on_the_second_page_of_open_prs_is_listed(h: Harness) -> None:
    h.target(["app.py"])
    h.open_pr(8, ["lib.py"])
    h.open_pr(9, ["app.py"], page=1)
    result = h.run()
    assert listed(result.stdout) == {9}
    assert "Checked 2 other open PRs" in result.stdout


def test_a_shared_file_on_the_second_page_of_a_prs_files_is_found(h: Harness) -> None:
    h.target(["app.py"])
    h.open_pr(8, ["lib.py"], more_files=["app.py"])
    result = h.run()
    assert listed(result.stdout) == {8}


def test_a_file_list_shorter_than_its_count_exits_2_naming_the_pr(h: Harness) -> None:
    h.target(["app.py"])
    h.open_pr(8, ["lib.py"], total=5)
    result = h.run()
    assert result.returncode == 2
    assert "listed 1 files for #8 but says it changes 5" in result.stderr


def test_a_target_file_list_shorter_than_changed_files_exits_2(h: Harness) -> None:
    h.target(["app.py"], changed_files=3001)
    h.open_pr(8, ["lib.py"])
    result = h.run()
    assert result.returncode == 2
    assert f"#{TARGET}" in result.stderr


def test_a_failing_gh_call_exits_2_quoting_the_error(h: Harness) -> None:
    h.target(["app.py"])
    h.open_pr(8, ["app.py"])
    result = h.run(drop=[f"graphql name={NAME} owner={OWNER}"])
    assert result.returncode == 2
    assert "HTTP 404" in result.stderr


def test_a_target_pr_that_does_not_exist_exits_2(h: Harness) -> None:
    h.open_pr(8, ["app.py"])
    result = h.run()
    assert result.returncode == 2
    assert result.stdout == ""


def test_an_open_pr_listing_shorter_than_its_count_exits_2(h: Harness) -> None:
    h.target(["app.py"])
    h.open_pr(8, ["lib.py"])
    h.pr_total = 3
    result = h.run()
    assert result.returncode == 2
    assert "listed 1 open PRs but says there are 3" in result.stderr


def test_a_target_with_exactly_100_files_is_read_from_one_page(h: Harness) -> None:
    h.target([f"f{i}.py" for i in range(100)])
    h.open_pr(8, ["f42.py"])
    result = h.run()
    assert result.returncode == 1, result.stderr
    assert listed(result.stdout) == {8}


def test_the_target_is_not_paged_through_in_the_open_pr_listing(h: Harness) -> None:
    h.target(["app.py"])
    h.open_pr(TARGET, ["app.py"], more_files=["x.py"], serve_more=False)
    h.open_pr(8, ["app.py"])
    result = h.run()
    assert result.returncode == 1, result.stderr
    assert listed(result.stdout) == {8}
