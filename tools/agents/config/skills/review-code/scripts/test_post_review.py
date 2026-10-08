"""Black-box tests for post_review.py.

The script runs as a subprocess, never imported, so it stays a single file. A fake `gh` on PATH
records every call, so no test can reach GitHub.

Run:
  uv run --with pytest pytest tools/agents/config/skills/review-code/scripts/test_post_review.py
"""

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

import pytest

SCRIPT = Path(__file__).with_name("post_review.py")
REPO = "octo/widgets"
PATH_ = "deploy/app.yaml"

# Taken from the PR 508 review: backticks, $(...), double quotes, a fenced block, newlines, colons.
TRICKY_BODY = (
    "Any objection to also setting `X-Forwarded-Uri` here?\n\n"
    "```nginx\nproxy_set_header X-Forwarded-Uri $request_uri;\n```\n\n"
    'The old "remember to `rollout restart`" note: see $(whoami) and `a:b:c`.'
)

FAKE_GH = """#!/bin/sh
printf '%s\\n' "$*" >> "$GH_CALLS"
cat > "$GH_STDIN"
if [ -n "$GH_FAIL" ]; then echo "HTTP 422: Unprocessable Entity" >&2; exit 1; fi
echo '{"html_url": "https://github.com/octo/widgets/pull/7#pullrequestreview-1"}'
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
        self.stdin = tmp_path / "gh_stdin"
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            "GH_CALLS": str(self.calls),
            "GH_STDIN": str(self.stdin),
        }

    def write_review(self, review: Any) -> Path:
        path = self.tmp_path / "review.json"
        path.write_text(review if isinstance(review, str) else json.dumps(review))
        return path

    def run(self, *args: str, fail_gh: bool = False) -> subprocess.CompletedProcess[str]:
        env = {**self.env, **({"GH_FAIL": "1"} if fail_gh else {})}
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            check=False,
            capture_output=True,
            text=True,
            env=env,
        )

    def gh_was_called(self) -> bool:
        return self.calls.exists()


@pytest.fixture
def h(tmp_path: Path) -> Harness:
    return Harness(tmp_path)


def comment(**overrides: Any) -> dict[str, Any]:
    return {
        "path": PATH_,
        "line": 12,
        "side": "RIGHT",
        "body": "Looks off.",
        **overrides,
    }


def review(**overrides: Any) -> dict[str, Any]:
    return {
        "event": "COMMENT",
        "body": "Summary.",
        "comments": [comment()],
        **overrides,
    }


def dry_run(h: Harness, rev: Any) -> dict[str, Any]:
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO, "--dry-run")
    assert result.returncode == 0, result.stderr
    assert not h.gh_was_called()
    return json.loads(result.stdout)


def test_comment_and_review_bodies_reach_the_payload_unchanged(h: Harness) -> None:
    payload = dry_run(h, review(body=TRICKY_BODY, comments=[comment(body=TRICKY_BODY)]))
    assert payload["body"] == TRICKY_BODY
    assert payload["comments"][0]["body"] == TRICKY_BODY


def test_comment_without_side_is_placed_on_the_new_side(h: Harness) -> None:
    bare = {k: v for k, v in comment().items() if k != "side"}
    payload = dry_run(h, review(comments=[bare]))
    assert payload["comments"][0]["side"] == "RIGHT"


def test_commit_id_is_passed_through_when_given(h: Harness) -> None:
    payload = dry_run(h, review(commit_id="abc123"))
    assert payload["commit_id"] == "abc123"


def test_commit_id_is_omitted_when_not_given(h: Harness) -> None:
    payload = dry_run(h, review())
    assert "commit_id" not in payload


def test_approve_may_have_an_empty_body_and_no_comments(h: Harness) -> None:
    payload = dry_run(h, {"event": "APPROVE", "body": ""})
    assert payload == {"event": "APPROVE", "body": "", "comments": []}


def test_posts_the_payload_to_the_named_repo_and_prints_the_review_url(
    h: Harness,
) -> None:
    rev = review(body=TRICKY_BODY)
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO)
    assert result.returncode == 0, result.stderr
    assert f"repos/{REPO}/pulls/7/reviews" in h.calls.read_text()
    assert json.loads(h.stdin.read_text())["body"] == TRICKY_BODY
    assert "pullrequestreview-1" in result.stdout


def test_github_rejection_exits_non_zero_with_its_error(h: Harness) -> None:
    result = h.run("7", str(h.write_review(review())), "--repo", REPO, fail_gh=True)
    assert result.returncode != 0
    assert "HTTP 422" in result.stderr


def test_missing_repo_is_a_usage_error(h: Harness) -> None:
    result = h.run("7", str(h.write_review(review())))
    assert result.returncode != 0
    assert "--repo" in result.stderr
    assert not h.gh_was_called()


@pytest.mark.parametrize(
    ("rev", "expected_in_message"),
    [
        ("{not json", "not valid JSON"),
        (review(event="LGTM"), "event"),
        (review(event="REQUEST_CHANGES", body=""), "needs a non-empty body"),
        (
            review(comments=[{k: v for k, v in comment().items() if k != "line"}]),
            "comments[0].line",
        ),
        (review(comments=[comment(), comment(line=0)]), "comments[1].line"),
        (review(comments=[comment(line="12")]), "comments[0].line"),
        (review(comments=[comment(side="right")]), "comments[0].side"),
        (review(comments=[comment(path="")]), "comments[0].path"),
        (review(comments=[comment(body="")]), "comments[0].body"),
    ],
    ids=[
        "invalid-json",
        "unknown-event",
        "request-changes-without-body",
        "comment-missing-line",
        "comment-line-zero",
        "comment-line-string",
        "comment-side-lowercase",
        "comment-empty-path",
        "comment-empty-body",
    ],
)
def test_invalid_review_is_rejected_before_posting(
    h: Harness, rev: Any, expected_in_message: str
) -> None:
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO)
    assert result.returncode != 0
    assert expected_in_message in result.stderr
    assert "Traceback" not in result.stderr
    assert not h.gh_was_called()


def test_missing_review_file_is_rejected_before_posting(h: Harness) -> None:
    result = h.run("7", str(h.tmp_path / "nope.json"), "--repo", REPO)
    assert result.returncode != 0
    assert "nope.json" in result.stderr
    assert "Traceback" not in result.stderr
    assert not h.gh_was_called()
