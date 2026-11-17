"""Black-box tests for fetch_pr_comments.py.

The script runs as a subprocess, never imported, so it stays a single file. A fake `gh` on PATH
serves canned GraphQL pages from a fixture, keyed by the cursor variables the script sends, so no
test can reach GitHub. Each cursor is `<list>:<page index>`, which lets a test see exactly which
page each request asked for. Every page also carries the viewer (the gh login) and the PR's
author, which default to `me`, so a fixture names them only when a test is about them. Like
GitHub, the fake returns only the fields the script's query names, so a field the script reads
without requesting it is missing here too.

Field names in the fixtures are GitHub's own (`state`, `createdAt`, `lastEditedAt`, `submittedAt`,
`resolvedBy`), so the script reads them as it would read a real response.

Run:
  uv run --with pytest --with hypothesis pytest \
    tools/agents/config/skills/review-pr-comments-converge/scripts/test_fetch_pr_comments.py
"""

import ast
import json
import os
import re
import subprocess
import sys
import tempfile
from collections.abc import Iterator
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta, timezone
from pathlib import Path

import pytest
from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st

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

pull_request["author"] = fixture.get("pr_author", {"login": "me", "__typename": "User"})
data = {"repository": {"pullRequest": pull_request}}
if not fixture.get("omit_viewer"):
    data["viewer"] = fixture.get("viewer", {"login": "me"})


def selection(query):
    # The fields the query names, as nested dicts: arguments, variable definitions and directives
    # are dropped, leaving names and braces.
    kept, depth = [], 0
    for ch in query:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif depth == 0:
            kept.append(ch)
    tokens = "".join(kept).replace("{", " { ").replace("}", " } ").split()
    tokens = [token for token in tokens if not token.startswith("@")]

    def fields(i):
        found = {}
        while tokens[i] != "}":
            name = tokens[i]
            if tokens[i + 1] == "{":
                found[name], i = fields(i + 2)
            else:
                found[name], i = None, i + 1
        return found, i + 1

    return fields(tokens.index("{") + 1)[0]


def prune(value, fields):
    if fields is None or value is None:
        return value
    if isinstance(value, list):
        return [prune(item, fields) for item in value]
    return {key: prune(value[key], sub) for key, sub in fields.items() if key in value}


# Like GitHub, answer only with what the query asks for, so a field the script reads but never
# requests reaches it as missing, here as it would in a real run.
query = next(arg[len("query="):] for arg in args if arg.startswith("query="))
print(json.dumps({"data": prune(data, selection(query))}))
"""


def author(login: str, kind: str = "User") -> dict:
    return {"login": login, "__typename": kind}


# Who wrote each item when a test doesn't say. Never mutated, so sharing one dict is safe.
REVIEWER = author("reviewer")
BOT = author("bot", "Bot")
# The fake's default viewer and PR author.
ME = author("me")
ALICE = author("alice")

T0 = datetime(2026, 10, 1, 12, 0, 0, tzinfo=UTC)


def ts(seconds: float = 0, offset_hours: int = 0) -> str:
    """A GitHub timestamp `seconds` after T0, written in the given UTC offset."""
    moment = (T0 + timedelta(seconds=seconds)).astimezone(timezone(timedelta(hours=offset_hours)))
    text = moment.strftime("%Y-%m-%dT%H:%M:%S")
    if moment.microsecond:
        text += f".{moment.microsecond:06d}".rstrip("0")
    return text + ("Z" if offset_hours == 0 else f"{offset_hours:+03d}:00")


def review(
    review_id: int,
    body: str,
    sha: str = "a" * 40,
    by: dict | None = REVIEWER,
    *,
    state: str = "COMMENTED",
    at: str = "2026-10-01T12:00:00Z",
    edited: str | None = None,
) -> dict:
    return {
        "databaseId": review_id,
        "author": by,
        "state": state,
        "body": body,
        # GitHub gives a pending review no submit time.
        "submittedAt": None if state == "PENDING" else at,
        "createdAt": at,
        "lastEditedAt": edited,
        "commit": {"oid": sha},
    }


DIFF_HUNK = "@@ -1,1 +1,1 @@\n-old\n+new"


def thread_comment(
    comment_id: int,
    body: str | None = None,
    *,
    by: dict | None = REVIEWER,
    at: str = "2026-10-01T12:00:00Z",
    edited: str | None = None,
    state: str | None = "SUBMITTED",
    review_id: int | None = None,
    path: str = "src/app.py",
    line: int = 12,
    outdated: bool = False,
) -> dict:
    return {
        "databaseId": comment_id,
        "author": by,
        "path": path,
        "line": None if outdated else line,
        "originalLine": line,
        "diffHunk": DIFF_HUNK,
        "body": f"comment-{comment_id}" if body is None else body,
        "pullRequestReview": {"databaseId": review_id} if review_id else None,
        "state": state,
        "createdAt": at,
        "lastEditedAt": edited,
    }


def thread_of(
    comments: list[dict],
    *,
    resolved_by: dict | None = None,
    resolved: bool = False,
    outdated: bool = False,
    more_replies: bool = False,
) -> dict:
    """A review thread holding `comments`, oldest first. Its id is `PRRT_<first comment id>`."""
    return {
        "id": f"PRRT_{comments[0]['databaseId']}",
        "isResolved": resolved or resolved_by is not None,
        "resolvedBy": resolved_by,
        "isOutdated": outdated,
        "comments": {
            "pageInfo": {"hasNextPage": more_replies},
            "totalCount": 150 if more_replies else len(comments),
            "nodes": comments,
        },
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
    def comment(cid: int, text: str, rid: int | None) -> dict:
        return thread_comment(cid, text, review_id=rid, path=path, line=line, outdated=outdated)

    # Only the first comment's review groups the thread, so the replies name none.
    comments = [comment(comment_id, body, review_id)] + [
        comment(comment_id + n + 1, text, None) for n, text in enumerate(replies or [])
    ]
    return thread_of(comments, outdated=outdated, more_replies=more_replies)


def conversation(
    comment_id: int,
    body: str,
    by: dict | None = BOT,
    edited: str | None = None,
    *,
    at: str = "2026-10-02T08:30:00Z",
) -> dict:
    return {
        "databaseId": comment_id,
        "author": by,
        "body": body,
        "url": f"https://github.com/{REPO}/pull/{PR}#issuecomment-{comment_id}",
        "createdAt": at,
        "lastEditedAt": edited,
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

# Lines the review-pr-comments-converge skill may read. Each must appear in the output in this
# order, with other lines allowed between them.
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


@pytest.fixture(scope="module")
def stubs(tmp_path_factory: pytest.TempPathFactory) -> Iterator[Path]:
    """The fake `gh`, written once and made read-only, so no test can change what another runs."""
    folder = tmp_path_factory.mktemp("stubs")
    gh = folder / "gh"
    gh.write_text(FAKE_GH)
    gh.chmod(0o755)
    folder.chmod(0o555)
    yield folder
    folder.chmod(0o755)


def test_a_test_cannot_write_beside_the_shared_stub(stubs: Path) -> None:
    with pytest.raises(PermissionError):
        (stubs / "other").write_text("x")


class Harness:
    def __init__(self, tmp_path: Path, bin_dir: Path) -> None:
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
            # Only catches a hang. A run takes seconds alone and has taken over 60 s with every
            # test running at once on a busy machine.
            timeout=300,
        )

    def calls(self) -> list[list[str]]:
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]


@pytest.fixture
def harness(tmp_path: Path, stubs: Path) -> Harness:
    return Harness(tmp_path, stubs)


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


def test_a_comment_edited_after_posting_says_when(harness: Harness) -> None:
    # rex-rx posts a placeholder and later edits its whole review into that same comment, so a
    # comment whose created time has not changed can still hold new feedback.
    fixture = {
        "threads": [[]],
        "reviews": [[]],
        "comments": [
            [
                conversation(9001, "Never edited."),
                conversation(9002, "Full review.", edited="2026-10-03T10:00:00Z"),
            ]
        ],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    lines = result.stdout.splitlines()
    for comment_id, edited in ((9001, "no"), (9002, "2026-10-03T10:00:00Z")):
        url = lines.index(
            f"  url        : https://github.com/{REPO}/pull/{PR}#issuecomment-{comment_id}"
        )
        assert lines[url + 2] == f"  edited     : {edited}"


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


def thank_lines(stdout: str) -> list[str]:
    return [line for line in stdout.splitlines() if line.startswith("  thank      :")]


def test_a_person_who_reviewed_is_tagged_in_the_greeting(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[review(1, "Looks good.", by=author("first-reviewer"))]],
        "comments": [[]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    lines = result.stdout.splitlines()
    header = lines.index("# REVIEW by first-reviewer (COMMENTED)  [review_id: 1]")
    assert "  thank      : @first-reviewer Thanks for the feedback:" in lines[header:]
    assert thank_lines(result.stdout) == ["  thank      : @first-reviewer Thanks for the feedback:"]


def test_a_bot_with_a_name_is_thanked_by_name_and_never_tagged(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[]],
        "comments": [[conversation(9001, "Review body.", by=author("rex-rx-agent", "Bot"))]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert thank_lines(result.stdout) == ["  thank      : Thanks for the feedback, Rex:"]
    assert "@" not in thank_lines(result.stdout)[0]


def test_copilots_review_is_thanked_as_copilot_and_never_tagged(harness: Harness) -> None:
    copilot = author("copilot-pull-request-reviewer", "Bot")
    fixture = {
        "threads": [[]],
        "reviews": [[review(1, "No open issues.", by=copilot)]],
        "comments": [[]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert thank_lines(result.stdout) == ["  thank      : Thanks for the feedback, Copilot:"]


def test_a_bot_without_a_name_asks_for_one(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[]],
        "comments": [[conversation(9001, "Review body.", by=author("copilot", "Bot"))]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert thank_lines(result.stdout) == ["  thank      : UNKNOWN (bot copilot)"]


def test_an_actor_type_the_script_does_not_know_asks_rather_than_failing(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[review(1, "Imported.", by=author("old-user", "Mannequin"))]],
        "comments": [[]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert thank_lines(result.stdout) == ["  thank      : UNKNOWN (Mannequin old-user)"]


def test_a_deleted_account_is_thanked_without_a_tag(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[review(1, "Gone now.", by=None)]],
        "comments": [[conversation(9001, "Also gone.", by=None)]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert thank_lines(result.stdout) == ["  thank      : Thanks for the feedback:"] * 2


def test_inline_comments_carry_no_greeting(harness: Harness) -> None:
    result = harness.run(FULL)

    assert result.returncode == 0, result.stderr
    # FULL has one review and one conversation comment, and three inline threads.
    assert len(thank_lines(result.stdout)) == 2
    assert len(refer_as_lines(result.stdout)) == 2
    for block in result.stdout.split("─" * 80)[1:]:
        if block.lstrip("\n").startswith("COMMENT ["):
            assert "thank      :" not in block
            assert "refer_as   :" not in block


def refer_as_lines(stdout: str) -> list[str]:
    return [line for line in stdout.splitlines() if line.startswith("  refer_as   :")]


def bot_names() -> dict[str, str]:
    """BOT_NAMES as the script defines it, read from its source so the script is never imported."""
    tree = ast.parse(SCRIPT.read_text())
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(
            isinstance(target, ast.Name) and target.id == "BOT_NAMES" for target in node.targets
        ):
            return ast.literal_eval(node.value)
    raise AssertionError("fetch_pr_comments.py defines no BOT_NAMES")


def test_a_person_who_reviewed_is_referred_to_by_tag(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[review(1, "Looks good.", by=author("first-reviewer"))]],
        "comments": [[]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert refer_as_lines(result.stdout) == ["  refer_as   : @first-reviewer"]


@pytest.mark.parametrize(("login", "name"), sorted(bot_names().items()))
def test_every_named_bot_is_referred_to_by_name_and_never_tagged(
    harness: Harness, login: str, name: str
) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[review(1, "Review body.", by=author(login, "Bot"))]],
        "comments": [[conversation(9001, "Review body.", by=author(login, "Bot"))]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert refer_as_lines(result.stdout) == [f"  refer_as   : {name}"] * 2
    assert "@" not in name


def test_rex_is_referred_to_as_rex(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[]],
        "comments": [[conversation(9001, "Review body.", by=author("rex-rx-agent", "Bot"))]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert refer_as_lines(result.stdout) == ["  refer_as   : Rex"]


def test_an_author_with_no_known_name_is_referred_to_as_unknown(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[review(1, "Imported.", by=author("old-user", "Mannequin"))]],
        "comments": [[conversation(9001, "Review body.", by=author("copilot", "Bot"))]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert refer_as_lines(result.stdout) == [
        "  refer_as   : UNKNOWN (Mannequin old-user)",
        "  refer_as   : UNKNOWN (bot copilot)",
    ]


def test_a_deleted_account_is_referred_to_without_a_tag(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[review(1, "Gone now.", by=None)]],
        "comments": [[conversation(9001, "Also gone.", by=None)]],
    }

    result = harness.run(fixture)

    assert result.returncode == 0, result.stderr
    assert refer_as_lines(result.stdout) == ["  refer_as   : a deleted account"] * 2


# --- Which items are already answered (#262) -------------------------------------------------
#
# Each review body, inline thread and conversation comment carries one `answered` line: `yes` with
# the evidence that counted, `no`, or `n/a (yours)`. An answerer is the PR's author or the gh login
# running the fetch, and a deleted account never is. The expectations below are written from the
# rule's wording, not from the script.


def pr(
    threads: list[dict] | None = None,
    reviews: list[dict] | None = None,
    comments: list[dict] | None = None,
    who: dict[str, dict | None] | None = None,
    **identities: dict | bool | None,
) -> dict:
    """A one-page fixture. `viewer=`, `pr_author=` or `omit_viewer=`, given directly or in `who`,
    override the fake's `me`."""
    return {
        "threads": [threads or []],
        "reviews": [reviews or []],
        "comments": [comments or []],
        **(who or {}),
        **identities,
    }


def verdicts(stdout: str) -> dict[tuple[str, str], list[str]]:
    """Every `answered` line, keyed by the item it sits in: ("review", review_id),
    ("thread", first comment_id) or ("conversation", comment_id)."""
    found: dict[tuple[str, str], list[str]] = {}
    kind: str | None = None
    item_id: str | None = None
    for line in stdout.splitlines():
        if match := re.match(r"# REVIEW by .*\[review_id: (\d+)\]$", line):
            kind, item_id = "review", match[1]
        elif line.startswith("COMMENT ["):
            kind, item_id = "thread", None
        elif line.startswith("CONVERSATION COMMENT"):
            kind, item_id = "conversation", None
        elif line.startswith("  comment_id : ") and kind in ("thread", "conversation"):
            item_id = item_id or line.split(":", 1)[1].strip()
        elif line.startswith("  answered   :"):
            assert kind and item_id, f"an answered line outside any item: {line!r}"
            found.setdefault((kind, item_id), []).append(line.split(":", 1)[1].strip())
    return found


def verdict_of(stdout: str, kind: str, item_id: int) -> str:
    lines = verdicts(stdout).get((kind, str(item_id)), [])
    assert len(lines) == 1, f"{kind} {item_id} has answered lines {lines}\n{stdout}"
    return lines[0]


def run_ok(harness: Harness, fixture: dict) -> str:
    result = harness.run(fixture)
    assert result.returncode == 0, result.stderr
    return result.stdout


# Threads


def test_a_reply_from_a_deleted_account_prints_as_ghost_and_never_answers(
    harness: Harness,
) -> None:
    comments = [
        thread_comment(101, "Rename this.", review_id=1, at=ts(0)),
        thread_comment(102, "Agreed.", by=None, at=ts(5)),
    ]
    stdout = run_ok(harness, pr([thread_of(comments)], [review(1, "")]))

    assert "    ghost: Agreed." in stdout.splitlines()
    assert verdict_of(stdout, "thread", 101) == "no"


def test_an_orphan_thread_opened_by_a_deleted_account_prints(harness: Harness) -> None:
    comments = [thread_comment(301, "Orphan note.", by=None, path="src/other.py", line=7)]

    stdout = run_ok(harness, pr([thread_of(comments)]))

    assert "COMMENT [1]  ghost @ src/other.py:7" in stdout.splitlines()


@pytest.mark.parametrize(
    ("identities", "expected"),
    [
        pytest.param({}, "# Answerers: me (PR author and gh login)", id="same-account"),
        pytest.param(
            {"pr_author": ALICE},
            "# Answerers: alice (PR author), me (gh login)",
            id="different-accounts",
        ),
        pytest.param(
            {"pr_author": None},
            "# Answerers: me (gh login); the PR author's account was deleted",
            id="deleted-pr-author",
        ),
    ],
)
def test_the_answerers_line_names_the_pr_author_and_the_gh_login(
    harness: Harness, identities: dict, expected: str
) -> None:
    stdout = run_ok(harness, pr(comments=[conversation(9001, "Hi.")], **identities))

    lines = stdout.splitlines()
    assert lines[0] == f"# Source: {REPO}#{PR}"
    assert expected in lines
    # Under the source line, before the first item.
    assert lines.index(expected) < lines.index("#" * 80)


@pytest.mark.parametrize(
    ("resolver", "expected"),
    [
        pytest.param(ME, "yes (resolved by me)", id="by-the-author"),
        pytest.param(REVIEWER, "yes (resolved by reviewer)", id="by-the-reviewer"),
    ],
)
def test_a_resolved_thread_is_answered_by_its_resolution(
    harness: Harness, resolver: dict, expected: str
) -> None:
    comments = [thread_comment(101, review_id=1, at=ts(0))]
    stdout = run_ok(harness, pr([thread_of(comments, resolved_by=resolver)], [review(1, "")]))

    assert verdict_of(stdout, "thread", 101) == expected


def test_a_thread_whose_newest_comment_is_the_pr_authors_is_answered_by_that_reply(
    harness: Harness,
) -> None:
    comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Done.", by=ME, at=ts(5)),
    ]
    stdout = run_ok(harness, pr([thread_of(comments)], [review(1, "")]))

    assert verdict_of(stdout, "thread", 101).startswith("yes (reply 102 by me at ")


@pytest.mark.parametrize(
    "replier", [pytest.param(ME, id="the-viewer"), pytest.param(ALICE, id="the-pr-author")]
)
def test_when_the_viewer_is_not_the_pr_author_either_ones_reply_answers(
    harness: Harness, replier: dict
) -> None:
    comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Done.", by=replier, at=ts(5)),
    ]
    fixture = pr([thread_of(comments)], [review(1, "")], pr_author=ALICE)

    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "thread", 101).startswith(f"yes (reply 102 by {replier['login']} at ")


def test_an_orphan_thread_is_judged_by_the_same_rule(harness: Harness) -> None:
    answered = [thread_comment(301, at=ts(0)), thread_comment(302, by=ME, at=ts(5))]
    followed_up = [
        thread_comment(401, at=ts(0)),
        thread_comment(402, by=ME, at=ts(5)),
        thread_comment(403, at=ts(9)),
    ]
    stdout = run_ok(harness, pr([thread_of(answered), thread_of(followed_up)]))

    assert verdict_of(stdout, "thread", 301).startswith("yes (reply 302 by me at ")
    assert verdict_of(stdout, "thread", 401) == "no"


def test_a_reviewers_follow_up_after_the_authors_reply_reopens_the_thread(
    harness: Harness,
) -> None:
    comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Done.", by=ME, at=ts(5)),
        thread_comment(103, "Not quite.", at=ts(9)),
    ]
    stdout = run_ok(harness, pr([thread_of(comments)], [review(1, "")]))

    assert verdict_of(stdout, "thread", 101) == "no"


# The author replies at ts(5). Each case is a reviewer's second comment, posted or edited at or
# after that reply, given as seconds after T0 and the UTC offset its times are written in.
@pytest.mark.parametrize(
    ("posted", "edited", "offset"),
    [
        pytest.param(5, None, 0, id="posted-in-the-same-second"),
        pytest.param(1, 5, 0, id="edited-in-the-same-second"),
        pytest.param(7, None, 0, id="posted-later"),
        pytest.param(1, 7, 0, id="edited-later"),
        # As strings "…:05.5Z" sorts before "…:05Z", so only a time comparison sees this as later.
        pytest.param(1, 5.5, 0, id="edited-half-a-second-later"),
        # As strings "13:…" sorts after "12:…" the other way round, so only a time comparison
        # sees this as the same second.
        pytest.param(1, 5, 1, id="edited-in-the-same-second-in-another-zone"),
        pytest.param(5, None, 1, id="posted-in-the-same-second-in-another-zone"),
    ],
)
def test_a_thread_comment_at_or_after_the_reply_reopens_the_thread(
    harness: Harness, posted: float, edited: float | None, offset: int
) -> None:
    opener = thread_comment(101, review_id=1, at=ts(0))
    answer = thread_comment(102, "Done.", by=ME, at=ts(5))
    second = thread_comment(
        103,
        "Also this.",
        at=ts(posted, offset),
        edited=None if edited is None else ts(edited, offset),
    )
    # Oldest first, as GitHub returns them.
    comments = [opener, second, answer] if posted < 5 else [opener, answer, second]

    stdout = run_ok(harness, pr([thread_of(comments)], [review(1, "")]))

    assert verdict_of(stdout, "thread", 101) == "no"


@pytest.mark.parametrize(
    "edited",
    [
        pytest.param(ts(3), id="edited-before"),
        # As strings "13:…" sorts after "12:…", so a string comparison would call this edit later.
        pytest.param(ts(4, offset_hours=1), id="edited-before-in-another-zone"),
        pytest.param(ts(4.5), id="edited-half-a-second-before"),
    ],
)
def test_an_edit_made_before_the_reply_leaves_the_thread_answered(
    harness: Harness, edited: str
) -> None:
    comments = [
        thread_comment(101, review_id=1, at=ts(0), edited=edited),
        thread_comment(102, "Done.", by=ME, at=ts(5)),
    ]
    stdout = run_ok(harness, pr([thread_of(comments)], [review(1, "")]))

    assert verdict_of(stdout, "thread", 101).startswith("yes (reply 102 by me at ")


def test_a_pending_reply_from_the_author_does_not_answer_the_thread(harness: Harness) -> None:
    comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Draft.", by=ME, at=ts(5), state="PENDING"),
    ]
    stdout = run_ok(harness, pr([thread_of(comments)], [review(1, "")]))

    assert verdict_of(stdout, "thread", 101) == "no"


@pytest.mark.parametrize(
    ("identities", "writers"),
    [
        pytest.param({}, [ME, ME], id="the-author-alone"),
        pytest.param({"pr_author": ALICE}, [ALICE, ME], id="the-pr-author-and-the-viewer"),
    ],
)
def test_a_thread_only_answerers_wrote_in_is_not_feedback(
    harness: Harness, identities: dict, writers: list[dict]
) -> None:
    comments = [
        thread_comment(101 + n, by=by, at=ts(n), review_id=1 if n == 0 else None)
        for n, by in enumerate(writers)
    ]
    fixture = pr([thread_of(comments)], [review(1, "", by=writers[0])], **identities)

    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "thread", 101) == "n/a (yours)"


def test_a_reviewers_reply_in_a_thread_the_author_started_is_feedback(harness: Harness) -> None:
    comments = [
        thread_comment(101, "Note to reviewers.", by=ME, review_id=1, at=ts(0)),
        thread_comment(102, "Why?", at=ts(5)),
    ]
    stdout = run_ok(harness, pr([thread_of(comments)], [review(1, "", by=ME)]))

    assert verdict_of(stdout, "thread", 101) == "no"


@pytest.mark.parametrize(
    "replier",
    [
        pytest.param(None, id="a-deleted-account"),
        # A real account that happens to be named ghost is not the deleted PR author either.
        pytest.param(author("ghost"), id="an-account-named-ghost"),
    ],
)
def test_a_deleted_account_never_answers_even_when_the_pr_authors_account_was_deleted(
    harness: Harness, replier: dict | None
) -> None:
    thread_comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Done.", by=replier, at=ts(5)),
    ]
    fixture = pr(
        [thread_of(thread_comments)],
        [review(1, "Please fix.", at=ts(0))],
        [conversation(9001, "Fixed.", by=replier, at=ts(6))],
        pr_author=None,
    )

    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "thread", 101) == "no"
    assert verdict_of(stdout, "review", 1) == "no"
    # The deleted or ghost-named account's own comment is feedback, not the author's.
    assert verdict_of(stdout, "conversation", 9001) == "no"


# Review bodies and conversation comments
#
# An answerer's top-level post answers one only when it names the item's author: `@login` for a
# person, where GitHub would render it as a mention (the `@` follows no word character, `.` or
# `-`), or the BOT_NAMES name as a whole word for a bot. A reply that opens with the item's `thank`
# line does, because the thank line names them.

# An answer that addresses the default reviewer, `reviewer`.
TO_REVIEWER = "@reviewer Thanks for the feedback:\n\n- ✅ Fixed."
DANA = author("dana")
REX = author("rex-rx-agent", "Bot")


def test_a_review_body_is_answered_by_the_authors_later_comment_addressed_to_the_reviewer(
    harness: Harness,
) -> None:
    fixture = pr(
        reviews=[review(1, "Please fix.", at=ts(0))],
        comments=[conversation(9002, TO_REVIEWER, by=ME, at=ts(5))],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1).startswith("yes (conversation comment 9002 by me at ")


def test_a_review_body_is_answered_by_the_authors_later_review_addressed_to_the_reviewer(
    harness: Harness,
) -> None:
    fixture = pr(
        reviews=[review(1, "Please fix.", at=ts(0)), review(2, TO_REVIEWER, by=ME, at=ts(5))]
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1).startswith("yes (review 2 by me at ")


def test_a_conversation_comment_is_answered_by_the_authors_later_comment_addressed_to_the_reviewer(
    harness: Harness,
) -> None:
    fixture = pr(
        comments=[
            conversation(9001, "Please fix.", by=REVIEWER, at=ts(0)),
            conversation(9002, TO_REVIEWER, by=ME, at=ts(5)),
        ]
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "conversation", 9001).startswith(
        "yes (conversation comment 9002 by me at "
    )


def test_the_earliest_answer_after_the_feedback_is_the_evidence(harness: Harness) -> None:
    fixture = pr(
        reviews=[review(1, "Please fix.", at=ts(3))],
        comments=[
            conversation(9001, "Before.", by=ME, at=ts(1)),
            conversation(9002, TO_REVIEWER, by=ME, at=ts(5)),
            conversation(9003, TO_REVIEWER, by=ME, at=ts(8)),
        ],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1).startswith("yes (conversation comment 9002 by me at ")


@pytest.mark.parametrize("body", [pytest.param("", id="empty"), pytest.param(" \n", id="blank")])
def test_the_empty_review_an_inline_reply_creates_does_not_answer_a_review_body(
    harness: Harness, body: str
) -> None:
    thread_comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Done.", by=ME, at=ts(5)),
    ]
    fixture = pr(
        [thread_of(thread_comments)],
        [review(1, "Please fix.", at=ts(0)), review(2, body, by=ME, at=ts(5))],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == "no"


def test_a_pending_review_from_the_author_does_not_answer(harness: Harness) -> None:
    fixture = pr(
        reviews=[
            review(1, "Please fix.", at=ts(0)),
            review(2, TO_REVIEWER, by=ME, state="PENDING", at=ts(5)),
        ]
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == "no"


def test_a_later_comment_from_someone_who_is_not_an_answerer_does_not_answer(
    harness: Harness,
) -> None:
    fixture = pr(
        reviews=[review(1, "Please fix.", at=ts(0))],
        comments=[
            conversation(9001, "Please fix.", by=REVIEWER, at=ts(1)),
            conversation(9002, TO_REVIEWER, by=ALICE, at=ts(5)),
            conversation(9003, TO_REVIEWER, by=BOT, at=ts(6)),
        ],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == "no"
    assert verdict_of(stdout, "conversation", 9001) == "no"


# The answer is the author's conversation comment at ts(5). Each case is the feedback's own times.
TIES = [
    pytest.param(ts(5), None, id="posted-in-the-same-second"),
    pytest.param(ts(0), ts(5), id="edited-in-the-same-second"),
    pytest.param(ts(0), ts(9), id="edited-after"),
    # As strings "…:05.5Z" sorts before "…:05Z", so only a time comparison sees this as after.
    pytest.param(ts(0), ts(5.5), id="edited-half-a-second-after"),
    pytest.param(ts(0), ts(5, offset_hours=1), id="edited-in-the-same-second-in-another-zone"),
]


@pytest.mark.parametrize(("posted", "edited"), TIES)
def test_a_review_body_posted_or_edited_at_or_after_the_answer_is_unanswered(
    harness: Harness, posted: str, edited: str | None
) -> None:
    fixture = pr(
        reviews=[review(1, "Please fix.", at=posted, edited=edited)],
        comments=[conversation(9002, TO_REVIEWER, by=ME, at=ts(5))],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == "no"


@pytest.mark.parametrize(("posted", "edited"), TIES)
def test_a_conversation_comment_posted_or_edited_at_or_after_the_answer_is_unanswered(
    harness: Harness, posted: str, edited: str | None
) -> None:
    feedback = conversation(9001, "Please fix.", by=REVIEWER, at=posted, edited=edited)
    answer = conversation(9002, TO_REVIEWER, by=ME, at=ts(5))
    fixture = pr(comments=[feedback, answer])

    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "conversation", 9001) == "no"


def test_a_bot_comment_edited_into_a_full_review_after_the_answer_is_unanswered(
    harness: Harness,
) -> None:
    rex = author("rex-rx-agent", "Bot")
    fixture = pr(
        comments=[
            conversation(9001, "Reviewing…", by=rex, at=ts(0), edited=ts(60)),
            conversation(9002, "Thanks for the feedback, Rex:", by=ME, at=ts(5)),
        ]
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "conversation", 9001) == "no"


def test_a_newer_review_after_the_answer_is_unanswered(harness: Harness) -> None:
    fixture = pr(
        reviews=[review(1, "Please fix.", at=ts(0)), review(3, "One more thing.", at=ts(9))],
        comments=[conversation(9002, TO_REVIEWER, by=ME, at=ts(5))],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1).startswith("yes (conversation comment 9002 by me at ")
    assert verdict_of(stdout, "review", 3) == "no"


@pytest.mark.parametrize(
    ("identities", "by"),
    [
        pytest.param({}, ME, id="the-pr-author-who-runs-it"),
        pytest.param({"pr_author": ALICE}, ALICE, id="the-pr-author"),
        pytest.param({"pr_author": ALICE}, ME, id="the-viewer"),
    ],
)
def test_an_answerers_own_review_and_conversation_comment_are_not_feedback(
    harness: Harness, identities: dict, by: dict
) -> None:
    fixture = pr(
        reviews=[review(1, "Notes for reviewers.", by=by, at=ts(0))],
        comments=[conversation(9001, "Ready for review.", by=by, at=ts(1))],
        **identities,
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == "n/a (yours)"
    assert verdict_of(stdout, "conversation", 9001) == "n/a (yours)"


# Every item, and the output around the new line


def test_every_review_body_thread_and_conversation_comment_prints_exactly_one_answered_line(
    harness: Harness,
) -> None:
    fixture = {
        **FULL,
        # Review 2 has no body but holds a thread, so it prints with no answered line of its own.
        "threads": [[*FULL["threads"][0], thread(501, "Under a bare review.", review_id=2)]],
        "reviews": [[*FULL["reviews"][0], review(2, "")]],
    }
    stdout = run_ok(harness, fixture)

    found = verdicts(stdout)
    expected = {
        ("review", "1"),
        ("thread", "101"),
        ("thread", "201"),
        ("thread", "301"),
        ("thread", "501"),
        ("conversation", "9001"),
    }
    assert set(found) == expected
    assert all(len(lines) == 1 for lines in found.values()), found
    assert sum(line.startswith("  answered   :") for line in stdout.splitlines()) == len(expected)


def test_each_answered_line_follows_the_line_the_design_puts_it_after(harness: Harness) -> None:
    stdout = run_ok(harness, FULL)

    lines = stdout.splitlines()
    preceding = [
        lines[n - 1].split(":")[0]
        for n, line in enumerate(lines)
        if line.startswith("  answered   :")
    ]
    # FULL has one review with a body, three threads and one conversation comment.
    assert sorted(preceding) == sorted(
        ["  edited     ", "  outdated   ", "  outdated   ", "  outdated   ", "  refer_as   "]
    )


def test_an_answered_item_is_still_printed_in_full(harness: Harness) -> None:
    thread_comments = [
        thread_comment(101, "Rename this.", review_id=1, at=ts(0)),
        thread_comment(102, "Renamed.", by=ME, at=ts(5)),
    ]
    fixture = pr(
        [thread_of(thread_comments)],
        [review(1, "Overall looks good.", at=ts(0))],
        [
            conversation(9001, "Bot review body.", by=REX, at=ts(1)),
            conversation(9002, f"{TO_REVIEWER}\n\nThanks, Rex, fixed too.", by=ME, at=ts(6)),
        ],
    )
    stdout = run_ok(harness, fixture)

    lines = stdout.splitlines()
    assert verdict_of(stdout, "thread", 101).startswith("yes")
    assert verdict_of(stdout, "review", 1).startswith("yes")
    assert verdict_of(stdout, "conversation", 9001).startswith("yes")
    for expected in (
        "# REVIEW by reviewer (COMMENTED)  [review_id: 1]",
        "  Overall looks good.",
        "  comment_id : 101",
        "  thread_id  : PRRT_101  (resolved: no)",
        "    Rename this.",
        "    me: Renamed.",
        "  comment_id : 9001",
        "    Bot review body.",
    ):
        assert expected in lines, expected


def test_the_same_pr_fetched_before_and_after_a_follow_up_is_answered_and_then_not(
    harness: Harness,
) -> None:
    before = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Done.", by=ME, at=ts(5)),
    ]
    after = [*before, thread_comment(103, "Not quite.", at=ts(9))]

    first = run_ok(harness, pr([thread_of(before)], [review(1, "")]))
    second = run_ok(harness, pr([thread_of(after)], [review(1, "")]))

    assert verdict_of(first, "thread", 101).startswith("yes (reply 102 by me at ")
    assert verdict_of(second, "thread", 101) == "no"


def test_an_answer_on_a_later_page_is_seen_with_one_request_per_page(harness: Harness) -> None:
    fixture = {
        "threads": [[]],
        "reviews": [[review(1, "Please fix.", at=ts(0))]],
        "comments": [
            [conversation(9001, "Please fix.", by=REVIEWER, at=ts(1))],
            [conversation(9002, TO_REVIEWER, by=ME, at=ts(5))],
        ],
    }
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1).startswith("yes (conversation comment 9002 by me at ")
    assert verdict_of(stdout, "conversation", 9001).startswith(
        "yes (conversation comment 9002 by me at "
    )
    assert len(harness.calls()) == 2


def unjudgeable_review() -> dict:
    return review(4242, "Please fix.", at="2026-13-45T99:00:00Z")


@pytest.mark.parametrize(
    ("fixture", "names"),
    [
        pytest.param(pr(omit_viewer=True), ["viewer"], id="no-viewer"),
        pytest.param(pr(viewer=None), ["viewer"], id="null-viewer"),
        pytest.param(pr(viewer={}), ["viewer"], id="viewer-without-a-login"),
        pytest.param(pr(viewer={"login": ""}), ["viewer"], id="viewer-with-an-empty-login"),
        pytest.param(
            pr(comments=[{**conversation(9001, "Hi."), "lastEditedAt": 123}]),
            ["9001", "edited"],
            id="edit-time-that-is-not-a-string",
        ),
        pytest.param(
            pr(comments=[{**conversation(9001, "Hi."), "createdAt": None}]),
            ["9001", "created"],
            id="conversation-comment-with-no-created-time",
        ),
        pytest.param(
            pr(
                [
                    thread_of(
                        [thread_comment(101, at=ts(0)), {**thread_comment(102), "createdAt": None}]
                    )
                ]
            ),
            ["102", "created"],
            id="posted-thread-comment-with-no-created-time",
        ),
        pytest.param(
            pr([thread_of([thread_comment(101, at=ts(0)), thread_comment(102, at="yesterday")])]),
            ["102", "created"],
            id="unreadable-thread-comment-time",
        ),
        pytest.param(
            pr(comments=[conversation(9001, "Hi.", edited="2026-10-02T09:00:00")]),
            ["9001", "edited"],
            id="edit-time-without-a-timezone",
        ),
        pytest.param(
            pr(reviews=[unjudgeable_review()]), ["4242", ("submitted", "created")], id="bad-review"
        ),
        pytest.param(
            pr([thread_of([thread_comment(101, at=ts(0)), thread_comment(102, state="DRAFT")])]),
            ["102", "state"],
            id="unknown-comment-state",
        ),
        pytest.param(
            pr([thread_of([thread_comment(101, at=ts(0)), thread_comment(102, state=None)])]),
            ["102", "state"],
            id="missing-comment-state",
        ),
    ],
)
def test_a_fetch_that_cannot_judge_an_item_prints_nothing_and_exits_with_a_sentence(
    harness: Harness, fixture: dict, names: list[str | tuple[str, ...]]
) -> None:
    result = harness.run(fixture)

    assert result.returncode == 1
    assert result.stdout == ""
    assert "Traceback" not in result.stderr
    for name in names:
        options = name if isinstance(name, tuple) else (name,)
        assert any(o in result.stderr.lower() for o in options), (name, result.stderr)


# Edges the examples above left open


def test_editing_the_reply_does_not_move_it_after_a_later_follow_up(harness: Harness) -> None:
    # The reply counts from when it was posted. Its later edit does not answer a follow-up that
    # came between the two.
    comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Done.", by=ME, at=ts(1), edited=ts(3)),
        thread_comment(103, "Not quite.", at=ts(2)),
    ]
    stdout = run_ok(harness, pr([thread_of(comments)], [review(1, "")]))

    assert verdict_of(stdout, "thread", 101) == "no"


@pytest.mark.parametrize(
    "edited", [pytest.param(ts(2), id="in-the-same-second"), pytest.param(ts(4), id="later")]
)
def test_an_earlier_answerer_reply_edited_at_or_after_the_latest_reopens_the_thread(
    harness: Harness, edited: str
) -> None:
    # The rule compares the latest reply with every other comment, answerers' own included.
    comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Partly done.", by=ALICE, at=ts(1), edited=edited),
        thread_comment(103, "Done.", by=ME, at=ts(2)),
    ]
    stdout = run_ok(harness, pr([thread_of(comments)], [review(1, "")], pr_author=ALICE))

    assert verdict_of(stdout, "thread", 101) == "no"


@pytest.mark.parametrize(
    ("by", "expected"),
    [
        pytest.param(REVIEWER, "no", id="from-a-reviewer"),
        pytest.param(ME, "n/a (yours)", id="from-the-author"),
    ],
)
def test_a_review_with_a_body_and_no_submit_time_is_judged_by_its_author(
    harness: Harness, by: dict, expected: str
) -> None:
    unsubmitted = {**review(1, "Please fix.", by=by, at=ts(0)), "submittedAt": None}
    fixture = pr(reviews=[unsubmitted], comments=[conversation(9002, TO_REVIEWER, by=ME, at=ts(5))])

    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == expected


def test_a_bot_with_the_viewers_login_is_not_the_viewer(harness: Harness) -> None:
    # The viewer is a person; a bot account that happens to share the login is someone else.
    namesake = author("me", "Bot")
    thread_comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Done.", by=namesake, at=ts(5)),
    ]
    fixture = pr(
        [thread_of(thread_comments)],
        [review(1, "")],
        [conversation(9001, "Bot note.", by=namesake, at=ts(1))],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "thread", 101) == "no"
    assert verdict_of(stdout, "conversation", 9001) == "no"


def test_a_review_answers_from_when_it_was_submitted_not_when_it_was_started(
    harness: Harness,
) -> None:
    # Started before the feedback and submitted after it, so it answers it.
    answer = {**review(2, TO_REVIEWER, by=ME, at=ts(2)), "createdAt": ts(0)}
    fixture = pr(
        reviews=[answer], comments=[conversation(9001, "Please fix.", by=REVIEWER, at=ts(1))]
    )
    stdout = run_ok(harness, fixture)

    assert (
        verdict_of(stdout, "conversation", 9001) == "yes (review 2 by me at 2026-10-01T12:00:02Z)"
    )


def test_a_pending_review_with_a_submit_time_does_not_answer(harness: Harness) -> None:
    pending = {**review(2, TO_REVIEWER, by=ME, state="PENDING", at=ts(5)), "submittedAt": ts(5)}
    fixture = pr(
        reviews=[pending], comments=[conversation(9001, "Please fix.", by=REVIEWER, at=ts(0))]
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "conversation", 9001) == "no"
    assert verdict_of(stdout, "review", 2) == "n/a (yours)"


def test_the_earliest_answer_is_chosen_by_when_it_was_posted_not_last_edited(
    harness: Harness,
) -> None:
    fixture = pr(
        comments=[
            conversation(9001, "Please fix.", by=REVIEWER, at=ts(0)),
            conversation(9002, TO_REVIEWER, by=ME, at=ts(1), edited=ts(3)),
            conversation(9003, TO_REVIEWER, by=ME, at=ts(2)),
        ]
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "conversation", 9001) == (
        "yes (conversation comment 9002 by me at 2026-10-01T12:00:01Z)"
    )


def test_the_evidence_gives_when_the_answer_was_posted_not_last_edited(harness: Harness) -> None:
    thread_comments = [
        thread_comment(101, review_id=1, at=ts(0)),
        thread_comment(102, "Done.", by=ME, at=ts(5), edited=ts(9)),
    ]
    fixture = pr(
        [thread_of(thread_comments)],
        [review(1, "Please fix.", at=ts(0))],
        [conversation(9002, TO_REVIEWER, by=ME, at=ts(5), edited=ts(9))],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "thread", 101) == "yes (reply 102 by me at 2026-10-01T12:00:05Z)"
    assert verdict_of(stdout, "review", 1) == (
        "yes (conversation comment 9002 by me at 2026-10-01T12:00:05Z)"
    )


def test_a_thread_counts_as_resolved_only_when_github_says_it_is(harness: Harness) -> None:
    # resolvedBy can outlive an unresolve, and is null when the resolver's account was deleted.
    unresolved = {**thread_of([thread_comment(101, review_id=1, at=ts(0))]), "resolvedBy": ME}
    by_deleted = {
        **thread_of([thread_comment(201, review_id=1, at=ts(0))]),
        "isResolved": True,
        "resolvedBy": None,
    }
    stdout = run_ok(harness, pr([unresolved, by_deleted], [review(1, "")]))

    assert verdict_of(stdout, "thread", 101) == "no"
    assert verdict_of(stdout, "thread", 201) == "yes (resolved by ghost)"


def test_a_finished_list_is_not_requested_again(harness: Harness) -> None:
    fixture = {
        "threads": [[thread(101, "first", review_id=1)], [thread(201, "second", review_id=1)]],
        "reviews": [[review(1, "Body.")]],
        "comments": [[conversation(9001, "Hi.")]],
    }

    run_ok(harness, fixture)

    calls = harness.calls()
    assert len(calls) == 2
    second = calls[1]
    for flag in ("withThreads=true", "withReviews=false", "withComments=false"):
        assert flag in second, (flag, second)


# Who an answer addresses


def answered_by_9002(by: dict | None, body: str) -> dict:
    """A fixture: conversation comment 9001 by `by`, then the author's only later post,
    conversation comment 9002 holding `body`."""
    return pr(
        comments=[
            conversation(9001, "Please fix.", by=by, at=ts(0)),
            conversation(9002, body, by=ME, at=ts(5)),
        ]
    )


EVIDENCE_9002 = "yes (conversation comment 9002 by me at 2026-10-01T12:00:05Z)"


@pytest.mark.parametrize(
    ("by", "body"),
    [
        pytest.param(DANA, "@dana Thanks for the feedback:\n\n- ✅ Done.", id="person"),
        pytest.param(REX, "Thanks for the feedback, Rex:\n\n- ✅ Done.", id="named-bot"),
        pytest.param(
            DANA, "\n  @dana Thanks for the feedback:\n\n- ✅ Done.", id="after-whitespace"
        ),
    ],
)
def test_a_reply_opening_with_the_thank_line_answers_because_the_thank_line_names_the_author(
    harness: Harness, by: dict, body: str
) -> None:
    stdout = run_ok(harness, answered_by_9002(by, body))

    assert verdict_of(stdout, "conversation", 9001) == EVIDENCE_9002


@pytest.mark.parametrize(
    "body",
    [
        pytest.param("Done, and thanks @dana for spotting it.", id="in-the-middle"),
        pytest.param("Fixed, see @dana's note.", id="before-an-apostrophe"),
        pytest.param("Rebased on main.\n\ncc @dana", id="at-the-end"),
        # Where the thank line sits does not matter: it answers because it names dana.
        pytest.param("- ✅ Done.\n\n@dana Thanks for the feedback:", id="thank-line-not-first"),
        pytest.param("@DANA thanks, fixed.", id="different-case"),
        pytest.param("(@dana) fixed.", id="after-a-bracket"),
        pytest.param("cc,@dana fixed.", id="after-a-comma"),
        # GitHub logins hold no underscore, so `@dana_` mentions dana.
        pytest.param("Thanks @dana_, fixed.", id="before-an-underscore"),
    ],
)
def test_an_answer_that_mentions_the_author_anywhere_answers_it(
    harness: Harness, body: str
) -> None:
    stdout = run_ok(harness, answered_by_9002(DANA, body))

    assert verdict_of(stdout, "conversation", 9001) == EVIDENCE_9002


def test_an_answer_that_addresses_another_reviewer_does_not_answer(harness: Harness) -> None:
    fixture = pr(
        comments=[
            conversation(9001, "Please fix.", by=DANA, at=ts(0)),
            conversation(9002, "Also this.", by=ALICE, at=ts(1)),
            conversation(9003, "@alice Thanks for the feedback:\n\n- ✅ Done.", by=ME, at=ts(5)),
        ]
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "conversation", 9001) == "no"
    assert verdict_of(stdout, "conversation", 9002).startswith("yes (conversation comment 9003 ")


@pytest.mark.parametrize(
    "body",
    [
        pytest.param("cc foo@dana: fixed.", id="after-another-word"),
        pytest.param("Mailed x@dana.io about it.", id="in-an-email-address"),
        pytest.param("See team.@dana for the plan.", id="after-a-dot"),
        pytest.param("Ask ops-@dana about it.", id="after-a-hyphen"),
        pytest.param("Ask ops_@dana about it.", id="after-an-underscore"),
    ],
)
def test_an_at_login_github_would_not_render_as_a_mention_does_not_address_them(
    harness: Harness, body: str
) -> None:
    stdout = run_ok(harness, answered_by_9002(DANA, body))

    assert verdict_of(stdout, "conversation", 9001) == "no"


@pytest.mark.parametrize(
    "body",
    [
        pytest.param("Thanks dana, fixed.", id="bare-login"),
        pytest.param("Fixed the madana import.", id="inside-another-word"),
    ],
)
def test_a_login_without_its_at_sign_does_not_address_them(harness: Harness, body: str) -> None:
    stdout = run_ok(harness, answered_by_9002(DANA, body))

    assert verdict_of(stdout, "conversation", 9001) == "no"


@pytest.mark.parametrize(
    "mention",
    [
        pytest.param("@danasmith", id="longer-login"),
        pytest.param("@dana-smith", id="hyphenated-login"),
        pytest.param("@dana2", id="login-with-a-digit"),
    ],
)
def test_a_longer_login_that_starts_with_the_authors_does_not_address_them(
    harness: Harness, mention: str
) -> None:
    stdout = run_ok(harness, answered_by_9002(DANA, f"{mention} Thanks for the feedback: done."))

    assert verdict_of(stdout, "conversation", 9001) == "no"


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        pytest.param("Done, thanks Rex.", EVIDENCE_9002, id="whole-word"),
        pytest.param("REX: done.", EVIDENCE_9002, id="different-case"),
        pytest.param("Thanks, Rexford, done.", "no", id="inside-a-longer-word"),
        pytest.param("Updated the Trex parser.", "no", id="ending-another-word"),
    ],
)
def test_a_bot_is_addressed_only_by_its_name_as_a_whole_word(
    harness: Harness, body: str, expected: str
) -> None:
    stdout = run_ok(harness, answered_by_9002(REX, body))

    assert verdict_of(stdout, "conversation", 9001) == expected


COPILOT = author("copilot-pull-request-reviewer", "Bot")
EVIDENCE_REVIEW_ANSWER = "yes (conversation comment 9002 by me at 2026-10-01T12:00:05Z)"


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        pytest.param("Thanks copilot", EVIDENCE_REVIEW_ANSWER, id="after-a-space"),
        pytest.param("Thanks, Copilot.", EVIDENCE_REVIEW_ANSWER, id="before-a-final-dot"),
        pytest.param("Fixed (Copilot).", EVIDENCE_REVIEW_ANSWER, id="in-brackets"),
        pytest.param("Copilot: fixed.", EVIDENCE_REVIEW_ANSWER, id="before-a-colon"),
        # Seen at d251d966: a file path holding the name marked Copilot's reviews answered.
        pytest.param(
            "Rebased on main and updated .github/copilot-instructions.md.",
            "no",
            id="in-a-dotfile-path",
        ),
        pytest.param("Renamed copilot-instructions.", "no", id="before-a-hyphen"),
        pytest.param("See skills/shared/copilot-review.md.", "no", id="after-a-slash"),
        pytest.param("Moved notes to copilot.md.", "no", id="before-a-file-extension"),
        pytest.param("Moved it under foo/copilot.", "no", id="ending-a-path"),
        pytest.param("Renamed my_copilot.", "no", id="after-an-underscore"),
        pytest.param("Edited copilot/settings.", "no", id="before-a-slash"),
        pytest.param("See settings.copilot for it.", "no", id="after-a-dot"),
        pytest.param("Set up pre-copilot hooks.", "no", id="after-a-hyphen"),
        pytest.param("Edit copilot_instructions.", "no", id="before-an-underscore"),
        pytest.param("Bumped to Copilot.2 today.", "no", id="before-a-dot-and-a-digit"),
    ],
)
def test_a_bot_is_addressed_only_where_its_name_stands_as_a_name(
    harness: Harness, body: str, expected: str
) -> None:
    fixture = pr(
        reviews=[review(1, "Copilot reviewed 3 files.", by=COPILOT, at=ts(0))],
        comments=[conversation(9002, body, by=ME, at=ts(5))],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == expected


def test_an_unrelated_closing_remark_answers_nothing(harness: Harness) -> None:
    # Seen on michaeluloth.com#83: after several reviews the author left one closing remark, and
    # every review body was skipped as answered.
    copilot = author("copilot-pull-request-reviewer", "Bot")
    fixture = pr(
        reviews=[
            review(1, "Please split this function.", by=DANA, at=ts(0)),
            review(2, "Two suggestions below.", by=copilot, at=ts(10)),
            review(3, "Ready for another look.", by=ME, at=ts(70)),
        ],
        comments=[
            conversation(9001, "## Rex review\n\n- One finding.", by=REX, at=ts(20)),
            conversation(9002, "Rebased on main and resolved the conflicts.", by=ME, at=ts(60)),
        ],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == "no"
    assert verdict_of(stdout, "review", 2) == "no"
    assert verdict_of(stdout, "conversation", 9001) == "no"


def test_the_earliest_answer_that_addresses_the_author_is_the_evidence(harness: Harness) -> None:
    fixture = pr(
        reviews=[review(1, "Please fix.", by=DANA, at=ts(0))],
        comments=[
            conversation(9002, "Rebased.", by=ME, at=ts(2)),
            conversation(9003, "@dana Thanks for the feedback:\n\n- ✅ Done.", by=ME, at=ts(4)),
            conversation(9004, "@dana one more thing is done too.", by=ME, at=ts(6)),
        ],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == (
        "yes (conversation comment 9003 by me at 2026-10-01T12:00:04Z)"
    )


def test_an_answering_review_is_judged_by_the_same_rule(harness: Harness) -> None:
    fixture = pr(
        reviews=[
            review(2, "Rebased.", by=ME, at=ts(2)),
            review(3, "@dana Thanks for the feedback:\n\n- ✅ Done.", by=ME, at=ts(4)),
        ],
        comments=[conversation(9001, "Please fix.", by=DANA, at=ts(0))],
    )
    stdout = run_ok(harness, fixture)

    assert (
        verdict_of(stdout, "conversation", 9001) == "yes (review 3 by me at 2026-10-01T12:00:04Z)"
    )


def test_an_author_who_cannot_be_addressed_is_never_answered_by_a_top_level_post(
    harness: Harness,
) -> None:
    # A deleted account and an unknown bot or actor have no name to address them by.
    fixture = pr(
        reviews=[review(1, "Please fix.", by=None, at=ts(0))],
        comments=[
            conversation(9001, "Please fix.", by=author("copilot", "Bot"), at=ts(1)),
            conversation(9002, "Please fix.", by=author("old-user", "Mannequin"), at=ts(2)),
            conversation(
                9003,
                "Thanks for the feedback:\n\n@ghost @copilot @old-user Copilot ghost UNKNOWN",
                by=ME,
                at=ts(9),
            ),
        ],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == "no"
    assert verdict_of(stdout, "conversation", 9001) == "no"
    assert verdict_of(stdout, "conversation", 9002) == "no"


def test_one_post_to_an_author_answers_all_their_earlier_feedback(harness: Harness) -> None:
    fixture = pr(
        reviews=[
            review(1, "First review.", by=DANA, at=ts(0)),
            review(2, "Second review.", by=DANA, at=ts(2)),
        ],
        comments=[
            conversation(9001, "And this.", by=DANA, at=ts(1)),
            conversation(9002, "@dana Thanks for the feedback:\n\n- ✅ All done.", by=ME, at=ts(5)),
            conversation(9003, "One more.", by=DANA, at=ts(8)),
        ],
    )
    stdout = run_ok(harness, fixture)

    assert verdict_of(stdout, "review", 1) == EVIDENCE_9002
    assert verdict_of(stdout, "review", 2) == EVIDENCE_9002
    assert verdict_of(stdout, "conversation", 9001) == EVIDENCE_9002
    assert verdict_of(stdout, "conversation", 9003) == "no"


# Generated timelines
#
# Times are half-second ticks after T0, shaped toward ties and same-second edits, and written in
# UTC or UTC+1 so that a string comparison would order some of them wrongly.

ANSWERER_SETUPS: dict[str, tuple[dict[str, dict | None], set[str]]] = {
    # identities given to the fake, and the logins that count as answerers
    "same-account": ({}, {"me"}),
    "different-accounts": ({"pr_author": ALICE}, {"me", "alice"}),
    "deleted-pr-author": ({"pr_author": None}, {"me"}),
}
AUTHORS = [ME, ALICE, REVIEWER, author("ghost"), None, author("rex-rx-agent", "Bot")]

ticks = st.integers(min_value=0, max_value=12)
offsets = st.sampled_from([0, 0, 1])
setups = st.sampled_from(sorted(ANSWERER_SETUPS))


def at_tick(tick: int, offset_hours: int) -> str:
    return ts(tick / 2, offset_hours)


def identities_for(setup: str) -> dict[str, dict | None]:
    """The fake's viewer and PR author for a named answerer setup."""
    return ANSWERER_SETUPS[setup][0]


def is_answerer(by: dict | None, setup: str) -> bool:
    return (
        by is not None and by["__typename"] == "User" and by["login"] in ANSWERER_SETUPS[setup][1]
    )


@dataclass(frozen=True)
class GenPost:
    """One generated post: who wrote it, when (ticks), whether it was posted, and an edit."""

    by: dict | None
    posted: int
    edited: int | None
    pending: bool
    offset: int

    @property
    def changed(self) -> int:
        return max(self.posted, self.edited if self.edited is not None else self.posted)


def gen_post(
    authors: list[dict | None], posted: st.SearchStrategy[int], *, can_pend: bool, setup: str
) -> st.SearchStrategy[GenPost]:
    @st.composite
    def build(draw: st.DrawFn) -> GenPost:
        by = draw(st.sampled_from(authors))
        when = draw(posted)
        edit = draw(st.none() | st.integers(min_value=0, max_value=6))
        # GitHub shows only the viewer's own pending posts, so only an answerer's can be pending.
        pending = can_pend and is_answerer(by, setup) and draw(st.booleans())
        return GenPost(by, when, None if edit is None else when + edit, pending, draw(offsets))

    return build()


def thread_nodes(posts: list[GenPost], first_id: int) -> list[dict]:
    ordered = sorted(posts, key=lambda p: p.posted)
    return [
        thread_comment(
            first_id + n,
            by=p.by,
            at=at_tick(p.posted, p.offset),
            edited=None if p.edited is None else at_tick(p.edited, p.offset),
            state="PENDING" if p.pending else "SUBMITTED",
        )
        for n, p in enumerate(ordered)
    ]


def run_generated(stubs: Path, fixture: dict) -> str:
    with tempfile.TemporaryDirectory() as folder:
        result = Harness(Path(folder), stubs).run(fixture)
    assert result.returncode == 0, result.stderr
    return result.stdout


GENERATED = settings(max_examples=60, deadline=None, suppress_health_check=[HealthCheck.too_slow])


@st.composite
def threads_with_activity_at_or_after_the_answer(draw: st.DrawFn) -> tuple[str, list[GenPost]]:
    """A thread whose latest answerer reply is matched or followed by a non-answerer's post or
    edit. Earlier posts by anyone, and pending answerer posts at any time, surround it."""
    setup = draw(setups)
    answerers = [a for a in AUTHORS if is_answerer(a, setup)]
    others = [a for a in AUTHORS if not is_answerer(a, setup)]
    answer_tick = draw(st.integers(min_value=1, max_value=8))
    answer = GenPost(draw(st.sampled_from(answerers)), answer_tick, None, False, draw(offsets))
    gap = draw(st.integers(min_value=0, max_value=3))
    late_by = draw(st.sampled_from(others))
    if draw(st.booleans()):
        late = GenPost(late_by, answer_tick + gap, None, False, draw(offsets))
    else:
        posted = draw(st.integers(min_value=0, max_value=answer_tick))
        late = GenPost(late_by, posted, answer_tick + gap, False, draw(offsets))
    # Every other posted comment is no later than the answer, so the answer stays the latest
    # answerer reply. Pending answerer posts may come at any time.
    earlier = draw(
        st.lists(
            gen_post(AUTHORS, st.integers(0, answer_tick), can_pend=False, setup=setup),
            max_size=3,
        )
    )
    return setup, [answer, late, *earlier, *draw(pending_answerer_posts(setup))]


def pending_answerer_posts(setup: str) -> st.SearchStrategy[list[GenPost]]:
    answerers = [a for a in AUTHORS if is_answerer(a, setup)]
    pending = st.builds(
        GenPost, st.sampled_from(answerers), ticks, st.none(), st.just(True), offsets
    )
    return st.lists(pending, max_size=2)


@GENERATED
@given(case=threads_with_activity_at_or_after_the_answer())
def test_any_thread_with_activity_at_or_after_the_latest_answer_is_unanswered(
    stubs: Path, case: tuple[str, list[GenPost]]
) -> None:
    setup, posts = case
    nodes = thread_nodes(posts, 101)

    stdout = run_generated(stubs, pr([thread_of(nodes)], who=identities_for(setup)))

    assert verdict_of(stdout, "thread", 101) == "no", json.dumps(nodes, indent=1)


@st.composite
def threads_answered_after_all_other_activity(draw: st.DrawFn) -> tuple[str, list[GenPost]]:
    """A thread whose answerer reply comes strictly after every other posted comment's last
    change. Pending answerer posts may come at any time, later ones included."""
    setup = draw(setups)
    answerers = [a for a in AUTHORS if is_answerer(a, setup)]
    others = [a for a in AUTHORS if not is_answerer(a, setup)]
    answer_tick = draw(st.integers(min_value=2, max_value=12))
    answer = GenPost(draw(st.sampled_from(answerers)), answer_tick, None, False, draw(offsets))

    @st.composite
    def settled(draw: st.DrawFn, authors: list[dict | None]) -> GenPost:
        posted = draw(st.integers(0, answer_tick - 1))
        edited = draw(st.none() | st.integers(posted, answer_tick - 1))
        return GenPost(draw(st.sampled_from(authors)), posted, edited, False, draw(offsets))

    feedback = draw(settled(others))
    rest = draw(st.lists(settled(AUTHORS), max_size=3))
    return setup, [feedback, answer, *rest, *draw(pending_answerer_posts(setup))]


@GENERATED
@given(case=threads_answered_after_all_other_activity())
def test_any_thread_answered_after_all_other_activity_is_answered_by_that_reply(
    stubs: Path, case: tuple[str, list[GenPost]]
) -> None:
    setup, posts = case
    nodes = thread_nodes(posts, 101)
    ordered = sorted(posts, key=lambda p: p.posted)
    answer_node = nodes[next(n for n, p in enumerate(ordered) if p is posts[1])]

    stdout = run_generated(stubs, pr([thread_of(nodes)], who=identities_for(setup)))

    login = answer_node["author"]["login"]
    expected = f"yes (reply {answer_node['databaseId']} by {login} at "
    assert verdict_of(stdout, "thread", 101).startswith(expected), json.dumps(nodes, indent=1)


@dataclass(frozen=True)
class GenTopLevel:
    kind: str  # "review" or "conversation comment"
    item_id: int
    post: GenPost
    body: str


# Words an answer may hold. Some address an author in the pool; the rest come close and must not.
ADDRESS_WORDS = [
    "@reviewer",
    "@REVIEWER",
    "@reviewer,",
    "@reviewers",
    "@reviewer-two",
    "foo@reviewer",
    "(@reviewer)",
    "@alice",
    "@ghost",
    "@me",
    "Rex",
    "rex:",
    "Rexford",
    "Trex",
    "Thanks for the feedback, Rex:",
    "@reviewer Thanks for the feedback:",
    "Thanks for the feedback:",
]


def gen_body() -> st.SearchStrategy[str]:
    words = st.lists(st.sampled_from(ADDRESS_WORDS), max_size=3)
    return st.builds(
        lambda w, lead: " ".join([lead, *w]).strip() or "Note.",
        words,
        st.sampled_from(["", "Note.", "  \n"]),
    )


# Written from the rule, not read from the script.
NAMED_BOTS = {"rex-rx-agent": "Rex", "copilot-pull-request-reviewer": "Copilot"}


def addresses(body: str, by: dict | None) -> bool:
    if by is None:
        return False
    if by["__typename"] == "User":
        mention = rf"(?<![\w.-])@{re.escape(by['login'])}(?![A-Za-z0-9-])"
    elif by["__typename"] == "Bot" and by["login"] in NAMED_BOTS:
        name = re.escape(NAMED_BOTS[by["login"]])
        mention = rf"(?<![\w./-]){name}(?![\w/-])(?!\.\w)"
    else:
        return False
    return re.search(mention, body, re.IGNORECASE) is not None


# For each author, words that address them and words that come close without addressing them.
NEAR_MISS_AUTHORS: dict[str, dict | None] = {
    "reviewer": REVIEWER,
    "rex": REX,
    "ghost-named-person": author("ghost"),
    "deleted": None,
}
# Near misses come first because Hypothesis draws early elements more often, and reviewer and
# Rex first because they are the authors a near miss can wrongly address.
NEAR_MISSES: list[tuple[str, list[str]]] = [
    (
        "reviewer",
        [
            "@reviewers",
            "@reviewer-two",
            "@reviewer2",
            "foo@reviewer",
            "x@reviewer.io",
            "a.@reviewer",
            "a-@reviewer",
            "@reviewer",
            "@REVIEWER",
            "@reviewer,",
            "(@reviewer)",
            ",@reviewer",
        ],
    ),
    (
        "rex",
        [
            ".github/rex-instructions.md",
            "rex-instructions",
            "skills/rex.md",
            "rex.md",
            "foo/rex",
            "rex/notes",
            "my_rex",
            "Rexford",
            "Trex",
            "rexes",
            "Rex",
            "REX",
            "rex:",
            "(Rex)",
            "Rex.",
            "Thanks, Rex.",
        ],
    ),
    ("ghost-named-person", ["@ghosts", "Thanks for the feedback:", "@ghost", "@Ghost"]),
    ("deleted", ["@ghost", "Thanks for the feedback:", "a deleted account"]),
]
NEAR_MISS_PAIRS = [(key, word) for key, words in NEAR_MISSES for word in words]


@st.composite
def top_level_timelines(draw: st.DrawFn) -> tuple[str, list[GenTopLevel]]:
    # Drawn first, as one (author, word) pair, so every near miss is as likely as any other.
    feedback_by, word = draw(st.sampled_from(NEAR_MISS_PAIRS))
    setup = draw(setups)
    items: list[GenTopLevel] = []
    for n in range(draw(st.integers(min_value=1, max_value=6))):
        kind = draw(st.sampled_from(["review", "conversation comment"]))
        post = draw(gen_post(AUTHORS, ticks, can_pend=kind == "review", setup=setup))
        text = draw(gen_body())
        body = draw(st.sampled_from([text, "", " \n"])) if kind == "review" else text
        item_id = n + 1 if kind == "review" else 9001 + n
        items.append(GenTopLevel(kind, item_id, post, body))
    # Every timeline also ends with one feedback item, after all the activity above, and then an
    # answerer post holding one word: an address of that item's author or a near miss. Nothing
    # earlier can answer the item, so each example tests that one word.
    feedback = GenPost(NEAR_MISS_AUTHORS[feedback_by], 20, None, False, draw(offsets))
    answerers = [a for a in AUTHORS if is_answerer(a, setup)]
    answer = GenPost(draw(st.sampled_from(answerers)), 22 + draw(st.integers(0, 4)), None, False, 0)
    items.append(GenTopLevel("conversation comment", 9101, feedback, "Please fix."))
    items.append(GenTopLevel("conversation comment", 9102, answer, word))
    return setup, items


@GENERATED
@given(case=top_level_timelines())
def test_any_review_body_or_conversation_comment_is_answered_exactly_when_an_answer_to_its_author_follows_its_last_change(
    stubs: Path, case: tuple[str, list[GenTopLevel]]
) -> None:
    setup, items = case

    def at(tick: int, item: GenTopLevel) -> str:
        return at_tick(tick, item.post.offset)

    def edit(item: GenTopLevel) -> str | None:
        return None if item.post.edited is None else at(item.post.edited, item)

    reviews = [
        review(
            i.item_id,
            i.body,
            by=i.post.by,
            state="PENDING" if i.post.pending else "COMMENTED",
            at=at(i.post.posted, i),
            edited=edit(i),
        )
        for i in sorted(items, key=lambda i: i.post.posted)
        if i.kind == "review"
    ]
    comments = [
        conversation(i.item_id, i.body, by=i.post.by, at=at(i.post.posted, i), edited=edit(i))
        for i in sorted(items, key=lambda i: i.post.posted)
        if i.kind == "conversation comment"
    ]
    answers = [
        i
        for i in items
        if is_answerer(i.post.by, setup)
        and not i.post.pending
        and (i.kind == "conversation comment" or i.body.strip())
    ]

    stdout = run_generated(stubs, pr(reviews=reviews, comments=comments, who=identities_for(setup)))

    for item in items:
        if item.kind == "review" and not item.body.strip():
            continue  # not printed, so it has no line
        key = "review" if item.kind == "review" else "conversation"
        actual = verdict_of(stdout, key, item.item_id)
        if is_answerer(item.post.by, setup):
            assert actual == "n/a (yours)", (item, actual)
            continue
        later = [
            a
            for a in answers
            if a.post.posted > item.post.changed and addresses(a.body, item.post.by)
        ]
        if not later:
            assert actual == "no", (item, actual)
            continue
        first = min(a.post.posted for a in later)
        evidence = [
            f"yes ({a.kind} {a.item_id} by {(a.post.by or {}).get('login')} at "
            for a in later
            if a.post.posted == first
        ]
        assert actual.startswith(tuple(evidence)), (item, actual, evidence)
