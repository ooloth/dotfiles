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
if [ "$1" = pr ] && [ "$2" = view ]; then
  if [ -n "$GH_VIEW_FAIL" ]; then echo "HTTP 404: Not Found" >&2; exit 1; fi
  printf '%s\\n' "$GH_PR_VIEW"; exit 0
fi
cat > "$GH_STDIN"
if [ -n "$GH_FAIL" ]; then echo "HTTP 422: Unprocessable Entity" >&2; exit 1; fi
echo '{"html_url": "https://github.com/octo/widgets/pull/7#pullrequestreview-1"}'
"""

# What the script's `gh pr view --jq` reduces a PR to: whether a bot opened it, and its files.
HUMAN_PR: dict[str, Any] = {"bot": False, "files": ["src/app.py"]}
BOT_BUMP: dict[str, Any] = {"bot": True, "files": ["Cargo.lock", "ui/tui/Cargo.toml"]}
HUMAN_BUMP: dict[str, Any] = {"bot": False, "files": ["package.json", "package-lock.json"]}


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
            "GH_PR_VIEW": json.dumps(HUMAN_PR),
        }

    def pr_is(self, pr: dict[str, Any]) -> None:
        self.env["GH_PR_VIEW"] = json.dumps(pr)

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

    def review_was_posted(self) -> bool:
        return self.calls.exists() and "/reviews" in self.calls.read_text()


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
    assert not h.review_was_posted()
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


# Shaped like every comment first posted on PR 257: the point and its reasoning run together in
# one paragraph, so a skimming reader cannot pick the point out.
UNBROKEN = "Can you add a bootstrap test for this line? Every frontend test mocks `useAuth`."
BROKEN = "Can you add a bootstrap test for this line?\n\nEvery frontend test mocks `useAuth`."


def test_dry_run_notes_a_comment_written_as_one_multi_sentence_paragraph(h: Harness) -> None:
    rev = review(comments=[comment(body=BROKEN), comment(body=UNBROKEN, line=81)])
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO, "--dry-run")
    assert result.returncode == 0, result.stderr
    assert f"comments[1] {PATH_}:81" in result.stderr
    assert "comments[0]" not in result.stderr
    assert json.loads(result.stdout)["comments"][1]["body"] == UNBROKEN


def test_dry_run_notes_a_review_body_written_as_one_multi_sentence_paragraph(h: Harness) -> None:
    result = h.run("7", str(h.write_review(review(body=UNBROKEN))), "--repo", REPO, "--dry-run")
    assert result.returncode == 0, result.stderr
    assert "body" in result.stderr


@pytest.mark.parametrize(
    "body",
    [
        BROKEN,
        # How GitHub's web editor saved the same split on PR 257: a trailing space, then CRLF.
        BROKEN.replace("?\n\n", "? \r\n\r\n"),
        "Looks off, can you check the empty-queue case?",
    ],
    ids=["point-split-off", "point-split-off-crlf", "single-sentence"],
)
def test_dry_run_says_nothing_about_bodies_that_already_read_well(h: Harness, body: str) -> None:
    rev = review(body=body, comments=[comment(body=body)])
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO, "--dry-run")
    assert result.returncode == 0, result.stderr
    assert result.stderr == ""


def test_posting_prints_no_note(h: Harness) -> None:
    rev = review(body=UNBROKEN, comments=[comment(body=UNBROKEN)])
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO)
    assert result.returncode == 0, result.stderr
    assert result.stderr == ""


def test_missing_review_file_is_rejected_before_posting(h: Harness) -> None:
    result = h.run("7", str(h.tmp_path / "nope.json"), "--repo", REPO)
    assert result.returncode != 0
    assert "nope.json" in result.stderr
    assert "Traceback" not in result.stderr
    assert not h.gh_was_called()


# A bot cannot read a review or push a fix, so findings on its PR are for the user to fix on the
# branch, and a change request would sit there with nobody to answer it.


@pytest.mark.parametrize(
    "rev",
    [
        review(event="REQUEST_CHANGES", comments=[]),
        review(event="COMMENT"),
        review(event="APPROVE"),
    ],
    ids=["request-changes", "inline-comment-on-comment", "inline-comment-on-approve"],
)
@pytest.mark.parametrize("dry", [True, False], ids=["dry-run", "post"])
def test_a_bot_authored_pr_refuses_a_change_request_or_inline_comments(
    h: Harness, rev: dict[str, Any], dry: bool
) -> None:
    h.pr_is(BOT_BUMP)
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO, *(["--dry-run"] if dry else []))
    assert result.returncode != 0
    assert "bot" in result.stderr
    assert "fix" in result.stderr
    assert not h.review_was_posted()


def test_a_bot_authored_pr_accepts_an_approval_without_inline_comments(h: Harness) -> None:
    h.pr_is(BOT_BUMP)
    rev = {"event": "APPROVE", "body": "Approving.\n\n- **Tests:** pass.", "comments": []}
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO)
    assert result.returncode == 0, result.stderr
    assert h.review_was_posted()


def test_a_pr_that_cannot_be_read_posts_nothing(h: Harness) -> None:
    h.env["GH_VIEW_FAIL"] = "1"
    result = h.run("7", str(h.write_review(review())), "--repo", REPO)
    assert result.returncode != 0
    assert "HTTP 404" in result.stderr
    assert not h.review_was_posted()


# An approval of a dependency update is only as good as the checks behind it, and nobody reading
# the PR can see them unless the body lists them.

UNLISTED = "Approving, everything checks out."
LISTED = "Approving.\n\n- **Releases:** none yanked.\n- **Tests:** pass at abc123."


@pytest.mark.parametrize("pr", [BOT_BUMP, HUMAN_BUMP], ids=["bot", "human"])
def test_dry_run_notes_a_dependency_approval_that_lists_no_checks(
    h: Harness, pr: dict[str, Any]
) -> None:
    h.pr_is(pr)
    rev = {"event": "APPROVE", "body": UNLISTED, "comments": []}
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO, "--dry-run")
    assert result.returncode == 0, result.stderr
    assert "dependency" in result.stderr
    assert "what the approval rests on" in result.stderr


@pytest.mark.parametrize(
    ("pr", "event", "body"),
    [
        (BOT_BUMP, "APPROVE", LISTED),
        (HUMAN_PR, "APPROVE", UNLISTED),
        (HUMAN_BUMP, "COMMENT", UNLISTED),
    ],
    ids=["listed", "not-a-dependency-change", "not-an-approval"],
)
def test_dry_run_says_nothing_when_no_check_list_is_owed(
    h: Harness, pr: dict[str, Any], event: str, body: str
) -> None:
    h.pr_is(pr)
    rev = {"event": event, "body": body, "comments": []}
    result = h.run("7", str(h.write_review(rev)), "--repo", REPO, "--dry-run")
    assert result.returncode == 0, result.stderr
    assert "dependency" not in result.stderr
