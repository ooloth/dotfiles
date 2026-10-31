"""Tests for merge.py, the gate merge-and-verify merges through.

Pure judging is tested in-process, loaded from the script's path so it stays a single file. The
command line is tested as a subprocess with a fake `gh` on PATH that answers from files and records
every call, so no test reaches GitHub.

Run:
  uv run --with pytest --with hypothesis --with pydantic pytest \
    tools/agents/config/skills/merge-and-verify/scripts/test_merge.py
"""

import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path
from types import ModuleType
from typing import Any

import pytest
from hypothesis import given
from hypothesis import strategies as st

SCRIPT = Path(__file__).with_name("merge.py")
REPO = "octo/widgets"
PR = "305"
HEAD = "a332bdad17df579716f3d0aaf32a935d86d3acd7"
OLD = "0123456789abcdef0123456789abcdef01234567"
MERGED = "1e0d2d079ed3b07aef234cf0f5a4615c1a0d7181"


def _load_script() -> ModuleType:
    spec = importlib.util.spec_from_file_location("merge", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    # dataclasses resolve their annotations through sys.modules, so register before running
    sys.modules["merge"] = module
    spec.loader.exec_module(module)
    return module


mg = _load_script()


def check_run(name: str, conclusion: str = "SUCCESS", status: str = "COMPLETED") -> dict[str, Any]:
    return {"__typename": "CheckRun", "name": name, "status": status, "conclusion": conclusion}


def status_context(context: str, state: str = "SUCCESS") -> dict[str, Any]:
    return {"__typename": "StatusContext", "context": context, "state": state}


def review(state: str = "APPROVED", commit: str = HEAD, login: str = "ooloth") -> dict[str, Any]:
    return {
        "author": {"login": login},
        "state": state,
        "commit": {"oid": commit},
        "submittedAt": "2026-10-28T18:29:25Z",
    }


def pull_request(**overrides: Any) -> dict[str, Any]:
    """A PR shaped like `gh pr view --json` answered for example-app#305."""
    return {
        "state": "OPEN",
        "isDraft": False,
        "headRefOid": HEAD,
        "mergeStateStatus": "CLEAN",
        "reviews": [review()],
        "statusCheckRollup": [
            check_run("Analyze (javascript-typescript)"),
            status_context("example-project/example-api"),
        ],
        **overrides,
    }


SQUASH_ONLY = {"squashMergeAllowed": True, "mergeCommitAllowed": False, "rebaseMergeAllowed": False}

FAKE_GH = """#!/bin/sh
printf '%s\\n' "$*" >> "$GH_CALLS"
case "$*" in
  "pr merge"*)
    if [ -n "$GH_MERGE_FAIL" ]; then echo "$GH_MERGE_FAIL" >&2; exit 1; fi ;;
  "pr view"*"--json mergeCommit"*) cat "$GH_MERGED" ;;
  "pr view"*) if [ -n "$GH_READ_FAIL" ]; then echo "HTTP 502" >&2; exit 1; fi; cat "$GH_PR" ;;
  "repo view"*) cat "$GH_REPO" ;;
  *) echo "unexpected gh call: $*" >&2; exit 9 ;;
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
        self.calls = tmp_path / "gh_calls"
        self.pr = tmp_path / "pr.json"
        self.repo = tmp_path / "repo.json"
        merged = tmp_path / "merged.json"
        merged.write_text(json.dumps({"mergeCommit": {"oid": MERGED}}))
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            "GH_CALLS": str(self.calls),
            "GH_PR": str(self.pr),
            "GH_REPO": str(self.repo),
            "GH_MERGED": str(merged),
        }

    def run(
        self,
        pr: dict[str, Any],
        *extra: str,
        repo: dict[str, Any] = SQUASH_ONLY,
        head: str = HEAD,
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        self.pr.write_text(json.dumps(pr))
        self.repo.write_text(json.dumps(repo))
        return subprocess.run(
            [sys.executable, str(SCRIPT), PR, "--repo", REPO, "--head", head, *extra],
            check=False,
            capture_output=True,
            text=True,
            env={**self.env, **(env or {})},
        )

    def merge_calls(self) -> list[str]:
        if not self.calls.exists():
            return []
        return [c for c in self.calls.read_text().splitlines() if c.startswith("pr merge")]


@pytest.fixture
def h(tmp_path: Path) -> Harness:
    return Harness(tmp_path)


def test_a_ready_pr_is_merged_once_with_the_allowed_method_and_the_checked_head(h: Harness) -> None:
    result = h.run(pull_request())

    assert result.returncode == 0, result.stderr
    assert h.merge_calls() == [f"pr merge {PR} -R {REPO} --squash --match-head-commit {HEAD}"]
    assert MERGED in result.stdout


def test_an_approval_on_an_older_head_still_counts(h: Harness) -> None:
    # A push to an approved PR never undoes its approval, whatever the push changes.
    result = h.run(pull_request(reviews=[review(commit=OLD)]))

    assert result.returncode == 0, result.stdout + result.stderr
    assert h.merge_calls() == [f"pr merge {PR} -R {REPO} --squash --match-head-commit {HEAD}"]


@pytest.mark.parametrize(
    "reviews",
    [[], [review(state="COMMENTED")], [review(), review(state="DISMISSED")]],
    ids=["no-reviews", "only-comments", "approval-dismissed"],
)
def test_a_pr_nobody_has_approved_is_refused(h: Harness, reviews: list[dict[str, Any]]) -> None:
    result = h.run(pull_request(reviews=reviews))

    assert result.returncode == 1
    assert h.merge_calls() == []
    assert "nobody has approved" in result.stdout


def test_a_head_that_moved_since_the_check_is_refused_naming_both_commits(h: Harness) -> None:
    result = h.run(pull_request(), head=OLD)

    assert result.returncode == 1
    assert h.merge_calls() == []
    assert OLD in result.stdout
    assert HEAD in result.stdout


@pytest.mark.parametrize(
    ("checks", "named"),
    [
        ([check_run("tests", conclusion="FAILURE")], "tests"),
        ([status_context("deploy", state="ERROR")], "deploy"),
        ([], "no checks"),
    ],
)
def test_a_failed_or_missing_check_is_refused(
    h: Harness, checks: list[dict[str, Any]], named: str
) -> None:
    result = h.run(pull_request(statusCheckRollup=checks))

    assert result.returncode == 1
    assert h.merge_calls() == []
    assert named in result.stdout


@pytest.mark.parametrize(
    "checks",
    [
        [check_run("tests", conclusion="", status="IN_PROGRESS")],
        [check_run("tests", conclusion="", status="QUEUED")],
        [status_context("deploy", state="PENDING")],
        [status_context("deploy", state="EXPECTED")],
    ],
    ids=["in-progress", "queued", "status-pending", "status-expected"],
)
@pytest.mark.parametrize("merge_state", ["CLEAN", "BLOCKED", "UNSTABLE"])
def test_a_check_still_running_is_a_wait_that_exits_3_and_merges_nothing(
    h: Harness, checks: list[dict[str, Any]], merge_state: str
) -> None:
    result = h.run(pull_request(statusCheckRollup=checks, mergeStateStatus=merge_state))

    assert result.returncode == 3, result.stdout + result.stderr
    assert h.merge_calls() == []
    assert "still running" in result.stdout


def test_a_running_check_beside_a_real_refusal_is_not_a_wait(h: Harness) -> None:
    pr = pull_request(
        statusCheckRollup=[
            check_run("tests", conclusion="", status="IN_PROGRESS"),
            check_run("lint", conclusion="FAILURE"),
        ]
    )

    result = h.run(pr)

    assert result.returncode == 1
    assert "lint" in result.stdout
    assert "tests" in result.stdout


def test_github_blocking_with_every_check_passed_is_not_a_wait(h: Harness) -> None:
    result = h.run(pull_request(mergeStateStatus="BLOCKED"))

    assert result.returncode == 1
    assert "BLOCKED" in result.stdout


def test_an_outstanding_change_request_is_refused(h: Harness) -> None:
    pr = pull_request(
        reviews=[review(), review(state="CHANGES_REQUESTED", login="second-reviewer")]
    )

    result = h.run(pr)

    assert result.returncode == 1
    assert "second-reviewer" in result.stdout


def test_check_only_reports_readiness_and_never_merges(h: Harness) -> None:
    result = h.run(pull_request(), "--check-only")

    assert result.returncode == 0, result.stderr
    assert h.merge_calls() == []
    assert "ready" in result.stdout.lower()


def test_a_merge_github_refuses_is_reported_as_not_merged(h: Harness) -> None:
    result = h.run(pull_request(), env={"GH_MERGE_FAIL": "Head branch was modified"})

    assert result.returncode == 1
    assert "Head branch was modified" in result.stdout + result.stderr
    assert "not merged" in (result.stdout + result.stderr).lower()


def test_a_failed_read_exits_2_and_merges_nothing(h: Harness) -> None:
    result = h.run(pull_request(), env={"GH_READ_FAIL": "1"})

    assert result.returncode == 2
    assert h.merge_calls() == []


def test_a_head_that_is_not_a_full_sha_is_refused_before_any_call(h: Harness) -> None:
    result = h.run(pull_request(), head="a332bda")

    assert result.returncode == 2
    assert not h.calls.exists()


CONDITIONS = ["closed", "draft", "unapproved", "changes", "failing", "unmergeable"]


def broken_pull_request(broken: set[str], running: bool = False) -> dict[str, Any]:
    """A ready PR with each named condition broken, each one independently of the others."""
    reviews = [] if "unapproved" in broken else [review(commit=OLD)]
    if "changes" in broken:
        reviews.append(review(state="CHANGES_REQUESTED", login="second-reviewer"))
    checks = [check_run("tests", conclusion="FAILURE" if "failing" in broken else "SUCCESS")]
    if running:
        checks.append(check_run("deploy", conclusion="", status="IN_PROGRESS"))
    return pull_request(
        state="MERGED" if "closed" in broken else "OPEN",
        isDraft="draft" in broken,
        reviews=reviews,
        statusCheckRollup=checks,
        mergeStateStatus="DIRTY" if "unmergeable" in broken else "CLEAN",
    )


@given(
    broken=st.sets(st.sampled_from(CONDITIONS), min_size=1),
    moved=st.booleans(),
    running=st.booleans(),
)
def test_no_combination_of_failing_conditions_is_judged_ready_or_a_wait(
    broken: set[str], moved: bool, running: bool
) -> None:
    state = mg.parse_pull_request(broken_pull_request(broken, running), SQUASH_ONLY)

    verdict = mg.judge(state, mg.CommitSha(OLD if moved else HEAD))

    assert isinstance(verdict, mg.NotReady)
    assert len(verdict.refusals) >= len(broken) + (1 if moved else 0)


def test_every_condition_met_is_judged_ready_with_squash() -> None:
    state = mg.parse_pull_request(pull_request(), SQUASH_ONLY)

    verdict = mg.judge(state, mg.CommitSha(HEAD))

    assert verdict == mg.Ready(method="squash")
