"""Black-box tests for reply_to_comment.py.

The script runs as a subprocess with a fake `gh` first on PATH, so no test can reach GitHub. The
fake logs every call, answers a reply POST the way GitHub does, and serves two review threads to
the thread lookup: PRRT_100 holding comment 100, and PRRT_123 holding comment 123.

Run:
  uv run --with pytest pytest \
    tools/agents/config/skills/review-pr-comments-converge/scripts/test_reply_to_comment.py
"""

import json
import os
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).with_name("reply_to_comment.py")

FAKE_GH = """#!/usr/bin/env python3
import json, os, sys

args = sys.argv[1:]
with open(os.environ["FAKE_LOG"], "a") as log:
    log.write(json.dumps(args) + "\\n")

if os.environ.get("GH_FAIL"):
    print("gh: Not Found (HTTP 404)", file=sys.stderr)
    sys.exit(1)

if args[1] == "graphql":
    query = next(a for a in args if a.startswith("query="))
    if "resolveReviewThread" in query:
        print(json.dumps({"data": {"resolveReviewThread": {"thread": {"isResolved": True}}}}))
    else:
        threads = [
            {"id": f"PRRT_{cid}", "comments": {"nodes": [{"databaseId": cid}]}} for cid in (100, 123)
        ]
        print(json.dumps({"data": {"repository": {"pullRequest": {"reviewThreads": {"nodes": threads}}}}}))
else:
    print(json.dumps({"id": 4242, "body": "posted"}))
"""


def setup(tmp_path: Path, **extra: str) -> dict[str, str]:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    gh = bin_dir / "gh"
    gh.write_text(FAKE_GH.replace("#!/usr/bin/env python3", f"#!{sys.executable}"))
    gh.chmod(0o755)
    return {
        **os.environ,
        "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
        "FAKE_LOG": str(tmp_path / "gh.log"),
        **extra,
    }


def reply(env: dict[str, str], *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args], capture_output=True, text=True, env=env
    )


def calls(env: dict[str, str]) -> list[list[str]]:
    log = Path(env["FAKE_LOG"])
    return [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []


def posts(env: dict[str, str]) -> list[list[str]]:
    return [call for call in calls(env) if "POST" in call]


def graphql(env: dict[str, str]) -> list[list[str]]:
    return [call for call in calls(env) if call[1] == "graphql"]


def test_a_reply_posts_its_body_to_the_comments_replies(tmp_path: Path) -> None:
    env = setup(tmp_path)
    result = reply(env, "5", "123", "Fixed `x` (abc1234)", "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    [post] = posts(env)
    assert post[1] == "repos/octo/widgets/pulls/5/comments/123/replies"
    assert "body=Fixed `x` (abc1234)" in post
    assert "Target: octo/widgets#5, comment 123" in result.stdout


def test_a_body_that_starts_with_a_dash_is_posted_as_the_body(tmp_path: Path) -> None:
    env = setup(tmp_path)
    result = reply(env, "5", "123", "--not a flag", "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    [post] = posts(env)
    assert "body=--not a flag" in post


def test_the_repo_can_be_given_with_an_equals_sign(tmp_path: Path) -> None:
    env = setup(tmp_path)
    result = reply(env, "--repo=octo/widgets", "5", "123", "Thanks")
    assert result.returncode == 0, result.stderr
    [post] = posts(env)
    assert post[1] == "repos/octo/widgets/pulls/5/comments/123/replies"


def test_resolve_closes_the_thread_holding_that_comment(tmp_path: Path) -> None:
    env = setup(tmp_path)
    result = reply(env, "5", "123", "Fixed", "--resolve", "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    lookup, resolve = graphql(env)
    assert "owner=octo" in lookup and "name=widgets" in lookup and "number=5" in lookup
    assert "threadId=PRRT_123" in resolve
    assert "Resolved thread PRRT_123." in result.stdout


def test_without_resolve_no_thread_is_touched(tmp_path: Path) -> None:
    env = setup(tmp_path)
    result = reply(env, "5", "123", "Fixed", "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    assert graphql(env) == []


def test_resolve_for_a_comment_in_no_thread_exits_with_a_sentence(tmp_path: Path) -> None:
    env = setup(tmp_path)
    result = reply(env, "5", "999", "Fixed", "--resolve", "--repo", "octo/widgets")
    assert result.returncode != 0
    assert "no thread found for comment_id 999" in result.stderr
    assert "Traceback" not in result.stderr


def test_a_failed_post_resolves_nothing(tmp_path: Path) -> None:
    env = setup(tmp_path, GH_FAIL="1")
    result = reply(env, "5", "123", "Fixed", "--resolve", "--repo", "octo/widgets")
    assert result.returncode != 0
    assert graphql(env) == []


def test_an_extra_argument_is_refused_before_anything_is_posted(tmp_path: Path) -> None:
    env = setup(tmp_path)
    result = reply(env, "5", "123", "Fixed", "--reslove", "--repo", "octo/widgets")
    assert result.returncode != 0
    assert "Usage:" in result.stderr
    assert calls(env) == []


def test_a_missing_body_is_refused_before_anything_is_posted(tmp_path: Path) -> None:
    env = setup(tmp_path)
    result = reply(env, "5", "123", "--repo", "octo/widgets")
    assert result.returncode != 0
    assert "Usage:" in result.stderr
    assert calls(env) == []


def test_a_malformed_repo_is_refused_before_anything_is_posted(tmp_path: Path) -> None:
    env = setup(tmp_path)
    result = reply(env, "5", "123", "Fixed", "--repo", "widgets")
    assert result.returncode != 0
    assert "repo must be OWNER/NAME" in result.stderr
    assert calls(env) == []
