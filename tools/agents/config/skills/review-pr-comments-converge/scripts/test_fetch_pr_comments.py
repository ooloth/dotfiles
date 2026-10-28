"""Black-box tests for fetch_pr_comments.py.

The script runs as a subprocess, never imported, so it stays a single file. A fake `gh` on PATH
serves canned GraphQL pages from a fixture, keyed by the cursor variables the script sends, so no
test can reach GitHub. Each cursor is `<list>:<page index>`, which lets a test see exactly which
page each request asked for.

Run:
  uv run --with pytest pytest \
    tools/agents/config/skills/review-pr-comments-converge/scripts/test_fetch_pr_comments.py
"""

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).with_name("fetch_pr_comments.py")
REPO = "octo/widgets"
PR = "5"

FAKE_GH = """#!/usr/bin/env python3
import json, os, sys

args = sys.argv[1:]
with open(os.environ["FAKE_LOG"], "a") as log:
    log.write(json.dumps(args) + "\\n")

if os.environ.get("GH_FAIL"):
    print("gh: Could not resolve to a PullRequest with the number of 5.", file=sys.stderr)
    sys.exit(1)

variables = {}
for i, arg in enumerate(args):
    if arg in ("-F", "-f") and not args[i + 1].startswith("query="):
        key, value = args[i + 1].split("=", 1)
        variables[key] = value

fixture = json.load(open(os.environ["FAKE_FIXTURE"]))
pull_request = {}
for key, field in (("threads", "reviewThreads"), ("reviews", "reviews"), ("comments", "comments")):
    if variables.get("with" + key.capitalize(), "true") == "false":
        continue
    after = variables.get(key + "After")
    index = int(after.split(":")[1]) + 1 if after else 0
    pages = fixture[key]
    if fixture.get("endless") == key:
        nodes, has_next = [], True
    else:
        nodes = pages[index] if index < len(pages) else []
        has_next = index < len(pages) - 1
    cursor = f"{key}:{index}" if nodes or has_next else None
    pull_request[field] = {
        "pageInfo": {"hasNextPage": has_next, "endCursor": cursor},
        "nodes": nodes,
    }

print(json.dumps({"data": {"repository": {"pullRequest": pull_request}}}))
"""


def review(review_id: int, body: str, sha: str = "a" * 40) -> dict:
    return {
        "databaseId": review_id,
        "author": {"login": "reviewer"},
        "state": "COMMENTED",
        "body": body,
        "submittedAt": "2026-10-01T12:00:00Z",
        "commit": {"oid": sha},
    }


def thread(
    comment_id: int,
    body: str,
    review_id: int | None = None,
    *,
    outdated: bool = False,
    replies: list[str] | None = None,
    more_replies: bool = False,
    path: str = "src/app.py",
    line: int = 12,
) -> dict:
    def comment(cid: int, text: str) -> dict:
        return {
            "databaseId": cid,
            "author": {"login": "reviewer"},
            "path": path,
            "line": None if outdated else line,
            "originalLine": line,
            "diffHunk": "@@ -1,1 +1,1 @@\n-old\n+new",
            "body": text,
            "pullRequestReview": {"databaseId": review_id} if review_id else None,
        }

    comments = [comment(comment_id, body)] + [
        comment(comment_id + n + 1, text) for n, text in enumerate(replies or [])
    ]
    return {
        "id": f"PRRT_{comment_id}",
        "isResolved": False,
        "isOutdated": outdated,
        "comments": {
            "pageInfo": {"hasNextPage": more_replies},
            "totalCount": 150 if more_replies else len(comments),
            "nodes": comments,
        },
    }


def conversation(comment_id: int, body: str) -> dict:
    return {
        "databaseId": comment_id,
        "author": {"login": "bot"},
        "body": body,
        "url": f"https://github.com/{REPO}/pull/{PR}#issuecomment-{comment_id}",
        "createdAt": "2026-10-02T08:30:00Z",
    }


# One page of each list, covering every block the output has: a review with an overview and an
# inline thread (with a suggestion and a reply), an outdated thread, an orphaned thread, and a
# conversation comment.
FULL = {
    "threads": [
        [
            thread(
                101,
                "Rename this.\n```suggestion\nnew_name = 1\n```",
                review_id=1,
                replies=["Done."],
            ),
            thread(201, "Old concern.", review_id=1, outdated=True, line=40),
            thread(301, "Orphan note.", path="src/other.py", line=7),
        ]
    ],
    "reviews": [[review(1, "Overall looks good.")]],
    "comments": [[conversation(9001, "Bot review body.")]],
}

# Captured from fetch_pr_comments.py before commit info and paging were added. Every line here is
# something the review-pr-comments-converge skill may read, so each must survive, in order.
OUTPUT_BEFORE_PAGING = """\
# Source: octo/widgets#5

################################################################################
# REVIEW by reviewer (COMMENTED)  [review_id: 1]
################################################################################

OVERVIEW:
  Overall looks good.

────────────────────────────────────────────────────────────────────────────────
COMMENT [1 of 2]  src/app.py:12
  comment_id : 101
  thread_id  : PRRT_101  (resolved: no)

  DIFF HUNK:
    @@ -1,1 +1,1 @@
    -old
    +new

  BODY:
    Rename this.

  SUGGESTION:
    ```suggestion
    new_name = 1
    ```

  REPLIES:
    reviewer: Done.

────────────────────────────────────────────────────────────────────────────────
COMMENT [2 of 2]  src/app.py:40
  comment_id : 201
  thread_id  : PRRT_201  (resolved: no)

  DIFF HUNK:
    @@ -1,1 +1,1 @@
    -old
    +new

  BODY:
    Old concern.

################################################################################

################################################################################
# ORPHANED COMMENTS (no parent review)
################################################################################

────────────────────────────────────────────────────────────────────────────────
COMMENT [3]  reviewer @ src/other.py:7
  comment_id : 301
  thread_id  : PRRT_301  (resolved: no)

  DIFF HUNK:
    @@ -1,1 +1,1 @@
    -old
    +new

  BODY:
    Orphan note.

################################################################################

################################################################################
# PR CONVERSATION COMMENTS (oldest first; reply with gh pr comment)
################################################################################

────────────────────────────────────────────────────────────────────────────────
CONVERSATION COMMENT  bot
  comment_id : 9001
  url        : https://github.com/octo/widgets/pull/5#issuecomment-9001

  BODY:
    Bot review body.

################################################################################

"""


class Harness:
    def __init__(self, tmp_path: Path) -> None:
        bin_dir = tmp_path / "bin"
        bin_dir.mkdir()
        gh = bin_dir / "gh"
        gh.write_text(FAKE_GH)
        gh.chmod(0o755)
        self.log = tmp_path / "gh.log"
        self.fixture = tmp_path / "fixture.json"
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            "FAKE_LOG": str(self.log),
            "FAKE_FIXTURE": str(self.fixture),
        }
        self.env.pop("GH_REPO", None)

    def run(self, fixture: dict, **env: str) -> subprocess.CompletedProcess[str]:
        self.fixture.write_text(json.dumps(fixture))
        return subprocess.run(
            [sys.executable, str(SCRIPT), PR, "--repo", REPO],
            capture_output=True,
            text=True,
            env={**self.env, **env},
            timeout=60,
        )

    def calls(self) -> list[list[str]]:
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]


@pytest.fixture
def harness(tmp_path: Path) -> Harness:
    return Harness(tmp_path)


def test_items_on_every_page_are_each_printed_once(harness: Harness) -> None:
    fixture = {
        "threads": [
            [thread(101, "thread-one", review_id=1), thread(111, "thread-two", review_id=1)],
            [thread(121, "thread-three", review_id=2)],
        ],
        "reviews": [
            [review(1, "review-one")],
            [review(2, "review-two")],
            [review(3, "review-three")],
        ],
        "comments": [[conversation(9001, "comment-one"), conversation(9002, "comment-two")]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    for marker in (
        "thread-one",
        "thread-two",
        "thread-three",
        "review-one",
        "review-two",
        "review-three",
        "comment-one",
        "comment-two",
    ):
        assert result.stdout.count(marker) == 1, marker


def test_a_pr_that_fits_in_one_page_costs_one_call(harness: Harness) -> None:
    result = harness.run(FULL)

    assert result.returncode == 0, result.stderr
    assert len(harness.calls()) == 1


def test_a_thread_with_more_replies_than_fetched_stops_the_run(harness: Harness) -> None:
    fixture = {
        "threads": [[thread(101, "long-thread", review_id=1, more_replies=True)]],
        "reviews": [[review(1, "review-body")]],
        "comments": [[]],
    }

    result = harness.run(fixture)

    assert result.returncode == 1
    assert "src/app.py:12" in result.stderr
    assert "150" in result.stderr
    assert "review-body" not in result.stdout
    assert "Traceback" not in result.stderr


def test_a_list_still_paging_at_the_cap_stops_the_run(harness: Harness) -> None:
    fixture = {"threads": [[]], "reviews": [[]], "comments": [[]], "endless": "reviews"}

    result = harness.run(fixture)

    assert result.returncode == 1
    assert "reviews" in result.stderr
    assert "Traceback" not in result.stderr
    assert len(harness.calls()) == 50


def test_each_item_says_which_code_it_describes(harness: Harness) -> None:
    result = harness.run(FULL)

    assert result.returncode == 0, result.stderr
    lines = result.stdout.splitlines()
    review_header = lines.index("# REVIEW by reviewer (COMMENTED)  [review_id: 1]")
    assert lines[review_header + 1] == f"# commit {'a' * 40}  submitted 2026-10-01T12:00:00Z"
    assert "  outdated   : no" in lines
    assert "  outdated   : yes" in lines
    url = lines.index(f"  url        : https://github.com/{REPO}/pull/{PR}#issuecomment-9001")
    assert lines[url + 1] == "  created    : 2026-10-02T08:30:00Z"


def test_every_line_printed_before_paging_is_still_printed_in_order(harness: Harness) -> None:
    result = harness.run(FULL)

    assert result.returncode == 0, result.stderr
    remaining = iter(result.stdout.splitlines())
    missing = [line for line in OUTPUT_BEFORE_PAGING.splitlines() if line not in remaining]
    assert missing == []


def test_a_gh_failure_exits_with_a_sentence(harness: Harness) -> None:
    result = harness.run(FULL, GH_FAIL="1")

    assert result.returncode == 1
    assert f"{REPO}#{PR}" in result.stderr
    assert "Could not resolve to a PullRequest" in result.stderr
    assert "Traceback" not in result.stderr
