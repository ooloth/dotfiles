"""Black-box tests for reply_to_comment.py.

The script runs as a subprocess with a fake `gh` first on PATH, so no test can reach GitHub. The
fake logs every call, answers a reply POST the way GitHub does, and serves two review threads to
the thread lookup: PRRT_100 holding comment 100, and PRRT_123 holding comment 123. A call
whose arguments contain GH_FAIL_MATCH fails with gh's 404 message, and every other call is answered.

Run:
  uv run --with pytest pytest \
    tools/agents/config/skills/review-pr-comments-converge/scripts/test_reply_to_comment.py
"""

import json
import os
import subprocess
import sys
from collections.abc import Callable, Iterator
from pathlib import Path

import pytest

SCRIPT = Path(__file__).with_name("reply_to_comment.py")

FAKE_GH = """#!/usr/bin/env python3
import json, os, sys

args = sys.argv[1:]
with open(os.environ["FAKE_LOG"], "a") as log:
    log.write(json.dumps(args) + "\\n")

fail = os.environ.get("GH_FAIL_MATCH")
if fail and fail in " ".join(args):
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


@pytest.fixture(scope="module")
def stubs(tmp_path_factory: pytest.TempPathFactory) -> Iterator[Path]:
    """The fake `gh`, written once and made read-only, so no test can change what another runs."""
    folder = tmp_path_factory.mktemp("stubs")
    gh = folder / "gh"
    gh.write_text(FAKE_GH.replace("#!/usr/bin/env python3", f"#!{sys.executable}"))
    gh.chmod(0o755)
    folder.chmod(0o555)
    yield folder
    folder.chmod(0o755)


@pytest.fixture
def setup(tmp_path: Path, stubs: Path) -> Callable[..., dict[str, str]]:
    """Builds a test's environment: the shared fake first on PATH, and a call log of its own."""

    def env(**extra: str) -> dict[str, str]:
        return {
            **os.environ,
            "PATH": f"{stubs}{os.pathsep}{os.environ['PATH']}",
            "FAKE_LOG": str(tmp_path / "gh.log"),
            **extra,
        }

    return env


def test_a_test_cannot_write_beside_the_shared_stub(stubs: Path) -> None:
    with pytest.raises(PermissionError):
        (stubs / "other").write_text("x")


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


def test_a_reply_posts_its_body_to_the_comments_replies(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup()
    result = reply(env, "5", "123", "Fixed `x` (abc1234)", "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    [post] = posts(env)
    assert post[1] == "repos/octo/widgets/pulls/5/comments/123/replies"
    assert "body=Fixed `x` (abc1234)" in post
    assert "Target: octo/widgets#5, comment 123" in result.stdout


def test_a_body_that_starts_with_a_dash_is_posted_as_the_body(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup()
    result = reply(env, "5", "123", "--not a flag", "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    [post] = posts(env)
    assert "body=--not a flag" in post


def test_the_repo_can_be_given_with_an_equals_sign(setup: Callable[..., dict[str, str]]) -> None:
    env = setup()
    result = reply(env, "--repo=octo/widgets", "5", "123", "Thanks")
    assert result.returncode == 0, result.stderr
    [post] = posts(env)
    assert post[1] == "repos/octo/widgets/pulls/5/comments/123/replies"


def test_resolve_closes_the_thread_holding_that_comment(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup()
    result = reply(env, "5", "123", "Fixed", "--resolve", "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    lookup, resolve = graphql(env)
    assert "owner=octo" in lookup and "name=widgets" in lookup and "number=5" in lookup
    assert "threadId=PRRT_123" in resolve
    assert "Resolved thread PRRT_123." in result.stdout


def test_without_resolve_no_thread_is_touched(setup: Callable[..., dict[str, str]]) -> None:
    env = setup()
    result = reply(env, "5", "123", "Fixed", "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    assert graphql(env) == []


def test_resolve_for_a_comment_in_no_thread_exits_with_a_sentence(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup()
    result = reply(env, "5", "999", "Fixed", "--resolve", "--repo", "octo/widgets")
    assert result.returncode != 0
    assert "no thread found for comment_id 999" in result.stderr
    assert "Traceback" not in result.stderr


def test_resolve_for_a_comment_in_no_thread_posts_nothing(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup()
    result = reply(env, "5", "999", "Fixed", "--resolve", "--repo", "octo/widgets")
    assert result.returncode != 0
    assert posts(env) == []


def test_a_failed_post_resolves_nothing(setup: Callable[..., dict[str, str]]) -> None:
    env = setup(GH_FAIL_MATCH="POST")
    result = reply(env, "5", "123", "Fixed", "--resolve", "--repo", "octo/widgets")
    assert result.returncode != 0
    [lookup] = graphql(env)
    assert "resolveReviewThread" not in " ".join(lookup)
    assert len(posts(env)) == 1


def test_an_extra_argument_is_refused_before_anything_is_posted(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup()
    result = reply(env, "5", "123", "Fixed", "--reslove", "--repo", "octo/widgets")
    assert result.returncode != 0
    assert "Usage:" in result.stderr
    assert "unexpected argument(s): --reslove" in result.stderr
    assert calls(env) == []


def test_a_missing_body_is_refused_before_anything_is_posted(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup()
    result = reply(env, "5", "123", "--repo", "octo/widgets")
    assert result.returncode != 0
    assert "Usage:" in result.stderr
    assert calls(env) == []


def test_a_malformed_repo_is_refused_before_anything_is_posted(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup()
    result = reply(env, "5", "123", "Fixed", "--repo", "widgets")
    assert result.returncode != 0
    assert "repo must be OWNER/NAME" in result.stderr
    assert calls(env) == []


def test_a_failed_lookup_says_nothing_was_posted_and_why(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup(GH_FAIL_MATCH="reviewThreads")
    result = reply(env, "5", "123", "Fixed", "--resolve", "--repo", "octo/widgets")
    assert result.returncode == 1
    assert "could not look up the thread for comment 123; nothing was posted" in result.stderr
    assert "HTTP 404" in result.stderr
    assert "Traceback" not in result.stderr
    assert posts(env) == []


def test_a_failed_post_says_nothing_was_posted_and_why(
    setup: Callable[..., dict[str, str]],
) -> None:
    env = setup(GH_FAIL_MATCH="POST")
    result = reply(env, "5", "123", "Fixed", "--repo", "octo/widgets")
    assert result.returncode == 1
    assert "could not post the reply; nothing was posted" in result.stderr
    assert "HTTP 404" in result.stderr
    assert "Traceback" not in result.stderr


def test_a_failed_resolve_says_the_reply_is_live(setup: Callable[..., dict[str, str]]) -> None:
    env = setup(GH_FAIL_MATCH="resolveReviewThread")
    result = reply(env, "5", "123", "Fixed", "--resolve", "--repo", "octo/widgets")
    assert result.returncode == 1
    assert "the reply was posted, but resolving thread PRRT_123 failed" in result.stderr
    assert "HTTP 404" in result.stderr
    assert "Traceback" not in result.stderr
    assert len(posts(env)) == 1


def test_a_body_file_posts_the_files_contents_exactly(
    setup: Callable[..., dict[str, str]], tmp_path: Path
) -> None:
    env = setup()
    text = "✅ Renamed `fetchAll` to `fetchPage`, since it's paged $(abc1234)\nsecond line\n"
    body_file = tmp_path / "reply.md"
    body_file.write_text(text, encoding="utf-8")
    result = reply(env, "5", "123", "--body-file", str(body_file), "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    [post] = posts(env)
    assert f"body={text}" in post


def test_a_body_file_can_be_given_with_an_equals_sign(
    setup: Callable[..., dict[str, str]], tmp_path: Path
) -> None:
    env = setup()
    body_file = tmp_path / "reply.md"
    body_file.write_text("Thanks", encoding="utf-8")
    result = reply(env, "5", "123", f"--body-file={body_file}", "--repo", "octo/widgets")
    assert result.returncode == 0, result.stderr
    [post] = posts(env)
    assert "body=Thanks" in post


def test_a_body_file_and_a_body_together_are_refused_before_anything_is_posted(
    setup: Callable[..., dict[str, str]], tmp_path: Path
) -> None:
    env = setup()
    body_file = tmp_path / "reply.md"
    body_file.write_text("From the file", encoding="utf-8")
    result = reply(
        env, "5", "123", "Inline too", "--body-file", str(body_file), "--repo", "octo/widgets"
    )
    assert result.returncode != 0
    assert "Usage:" in result.stderr
    assert "unexpected argument(s): Inline too" in result.stderr
    assert calls(env) == []


def test_a_missing_body_file_is_refused_with_its_path_before_anything_is_posted(
    setup: Callable[..., dict[str, str]], tmp_path: Path
) -> None:
    env = setup()
    missing = tmp_path / "nope.md"
    result = reply(env, "5", "123", "--body-file", str(missing), "--repo", "octo/widgets")
    assert result.returncode == 1
    assert f"could not read the reply body from {missing}" in result.stderr
    assert "nothing was posted" in result.stderr
    assert "Traceback" not in result.stderr
    assert calls(env) == []


def test_a_body_file_that_is_not_utf8_is_refused_before_anything_is_posted(
    setup: Callable[..., dict[str, str]], tmp_path: Path
) -> None:
    env = setup()
    body_file = tmp_path / "reply.md"
    body_file.write_bytes(b"\xff\xfe bad")
    result = reply(env, "5", "123", "--body-file", str(body_file), "--repo", "octo/widgets")
    assert result.returncode == 1
    assert f"could not read the reply body from {body_file}" in result.stderr
    assert "Traceback" not in result.stderr
    assert calls(env) == []
