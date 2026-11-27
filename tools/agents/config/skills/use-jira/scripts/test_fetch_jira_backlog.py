"""Tests for fetch_jira_backlog.py.

The script is loaded in-process, and `main` is called with a fake Jira and a fake Keychain in place
of the two system boundaries it reaches, so no test sends a request to Jira or reads the real
Keychain. The tests of the real HTTP sender point it at local sockets: servers that never answer,
answer too slowly, cut a body short or redirect, and a TLS server whose certificate macOS does not
trust.

`fixtures/search_page.json` is a search response whose first issue is a real ticket with every value
replaced by a made-up one, and whose other two issues are made up from node shapes seen in real
tickets.

Run with `bash scripts/checks/tests.bash` from the repo root, which installs what these tests need.
"""

import base64
import http.server
import importlib.util
import io
import json
import re
import socket
import ssl
import subprocess
import sys
import tempfile
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

SCRIPT = Path(__file__).with_name("fetch_jira_backlog.py")
FIXTURE = Path(__file__).with_name("fixtures") / "search_page.json"
REPO = SCRIPT.resolve().parents[6]

spec = importlib.util.spec_from_file_location("fetch_jira_backlog", SCRIPT)
assert spec is not None and spec.loader is not None
fjb = importlib.util.module_from_spec(spec)
sys.modules["fetch_jira_backlog"] = fjb
spec.loader.exec_module(fjb)

CLOUD_ID = "00000000-0000-0000-0000-000000000000"
EMAIL = "alice@example.com"
TOKEN = "example-token-not-a-real-one"


# --- fakes for the two boundaries ------------------------------------------------------------


def issue(n: int, comments: int = 0, total: int | None = None) -> dict[str, Any]:
    """A made-up issue EXAMPLE-n holding `comments` comments, claiming `total` (default: all)."""
    bodies = [
        {
            "id": str(n * 1000 + i),
            "author": {"displayName": "Bob Example", "emailAddress": "bob@example.com"},
            "created": "2026-11-20T10:00:00.000-0500",
            "body": doc(paragraph(text(f"comment {i} on {n}"))),
        }
        for i in range(comments)
    ]
    return {
        "key": f"EXAMPLE-{n}",
        "fields": {
            "summary": f"Ticket {n}",
            "status": {"name": "To Do"},
            "description": doc(paragraph(text(f"description of {n}"))),
            "comment": {
                "total": comments if total is None else total,
                "maxResults": comments,
                "startAt": 0,
                "comments": bodies,
            },
            "parent": None,
            "issuelinks": [],
        },
    }


def doc(*blocks: dict[str, Any]) -> dict[str, Any]:
    return {"type": "doc", "version": 1, "content": list(blocks)}


def paragraph(*inline: dict[str, Any]) -> dict[str, Any]:
    return {"type": "paragraph", "content": list(inline)}


def text(value: str, *marks: dict[str, Any]) -> dict[str, Any]:
    node: dict[str, Any] = {"type": "text", "text": value}
    if marks:
        node["marks"] = list(marks)
    return node


@dataclass
class FakeJira:
    """Answers search and comment requests from a list of issues, 100 per page by default.

    `script` maps a request number (1-based) to a response sent instead of the real one, so a test
    can make any request fail. `full_comments` holds the complete comment list the comment
    endpoint returns for a key, for issues whose search result is short.
    """

    issues: list[dict[str, Any]]
    page_size: int = 100
    script: dict[int, Any] = field(default_factory=dict)
    full_comments: dict[str, list[dict[str, Any]]] = field(default_factory=dict)
    comment_page_size: int = 100
    never_last: bool = False
    comment_total: int | None = None  # a total the comment endpoint claims, if not the real one
    comment_start_shift: int = 0  # added to the startAt the comment endpoint claims
    projects: frozenset[str] = frozenset({"EXAMPLE"})
    lookup_answer: Any = None  # sent instead of the real answer to the project lookup
    requests: list[Any] = field(
        default_factory=list
    )  # search and comment requests, numbered for script
    project_lookups: list[str] = field(default_factory=list)

    def __call__(self, request: Any) -> Any:
        url = urlparse(request.url)
        lookup = re.search(r"/rest/api/3/project/([^/]+)$", url.path)
        if lookup:
            self.project_lookups.append(lookup.group(1))
            if self.lookup_answer is not None:
                return self.lookup_answer
            if lookup.group(1) in self.projects:
                return response(200, {"key": lookup.group(1), "name": "Example project"})
            return response(404, {"errorMessages": ["No project could be found with key."]})
        self.requests.append(request)
        scripted = self.script.get(len(self.requests))
        if scripted is not None:
            return scripted
        if url.path.endswith("/rest/api/3/search/jql"):
            return self.search(json.loads(request.body))
        match = re.search(r"/rest/api/3/issue/([A-Z0-9_]+-\d+)/comment$", url.path)
        if match:
            return self.comments(match.group(1), parse_qs(url.query))
        return response(404, {"errorMessages": ["no such endpoint"]})

    def search(self, body: dict[str, Any]) -> Any:
        start = int(body.get("nextPageToken") or 0)
        page = self.issues[start : start + self.page_size]
        end = start + len(page)
        is_last = end >= len(self.issues) and not self.never_last
        result: dict[str, Any] = {"issues": page, "isLast": is_last}
        if not is_last:
            result["nextPageToken"] = str(end)
        return response(200, result)

    def comments(self, key: str, query: dict[str, list[str]]) -> Any:
        everything = self.full_comments[key]
        start = int(query.get("startAt", ["0"])[0])
        page = everything[start : start + self.comment_page_size]
        return response(
            200,
            {
                "startAt": start + self.comment_start_shift,
                "maxResults": len(page),
                "total": len(everything) if self.comment_total is None else self.comment_total,
                "comments": page,
            },
        )


def response(status: int, body: Any, headers: dict[str, str] | None = None) -> Any:
    raw = body if isinstance(body, bytes) else json.dumps(body).encode()
    return fjb.HttpResponse(status=status, headers=headers or {}, body=raw)


ITEM_ARGS = ["find-generic-password", "-s", "jira-backlog-read"]
NOT_FOUND = fjb.KeychainAnswer(
    returncode=44,
    stdout="",
    stderr="security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain.\n",
)


def keychain(email: str = EMAIL, token: str = TOKEN, present: bool = True) -> Any:
    """Answers only the two reads `security` would answer for the item, so another item is absent."""

    def read(args: list[str]) -> Any:
        if not present or args not in (ITEM_ARGS, [*ITEM_ARGS, "-w"]):
            return NOT_FOUND
        if args[-1] == "-w":
            return fjb.KeychainAnswer(returncode=0, stdout=token + "\n", stderr="")
        return fjb.KeychainAnswer(
            returncode=0,
            stdout=f'keychain: "login.keychain-db"\nattributes:\n    "acct"<blob>="{email}"\n',
            stderr="",
        )

    return read


@dataclass
class Clock:
    """A monotonic clock that only moves when the script sleeps."""

    now: float = 0.0
    sleeps: list[float] = field(default_factory=list)

    def __call__(self) -> float:
        return self.now

    def sleep(self, seconds: float) -> None:
        self.sleeps.append(seconds)
        self.now += seconds


@dataclass
class Run:
    code: int
    out: str
    err: str
    files: dict[str, str]
    sleeps: list[float]


def run(
    jira: Any,
    tmp: Path,
    project: str = "EXAMPLE",
    environ: dict[str, str] | None = None,
    read_keychain: Any = None,
    clock: Clock | None = None,
    workers: int = fjb.COMMENT_WORKERS,
) -> Run:
    out, err = io.StringIO(), io.StringIO()
    clock = clock or Clock()
    sleeps = clock.sleeps
    code = fjb.main(
        [project, "--out-dir", str(tmp)],
        environ={"PRIVATE_JIRA_CLOUD_ID": CLOUD_ID} if environ is None else environ,
        send=jira,
        read_keychain=read_keychain or keychain(),
        sleep=clock.sleep,
        clock=clock,
        workers=workers,
        out=out,
        err=err,
    )
    files = {p.name: p.read_text() for p in sorted(tmp.iterdir())}
    return Run(code, out.getvalue(), err.getvalue(), files, sleeps)


# --- converting ADF to text -----------------------------------------------------------------

words = st.from_regex(r"[A-Za-z0-9]([A-Za-z0-9 .,]{0,10}[A-Za-z0-9])?", fullmatch=True)


@st.composite
def inline_node(draw: Any) -> dict[str, Any]:
    kind = draw(st.sampled_from(["text", "code", "strong", "link", "unknown"]))
    value = draw(words)
    match kind:
        case "text":
            return text(value)
        case "code":
            return text(value, {"type": "code"})
        case "strong":
            return text(value, {"type": "strong"})
        case "link":
            return text(value, {"type": "link", "attrs": {"href": "https://example.com/x"}})
        case _:
            return {"type": "futureInline", "content": [text(value)]}


inlines = st.lists(inline_node(), min_size=1, max_size=4)


def block_nodes() -> Any:
    leaf_blocks = st.one_of(
        inlines.map(lambda xs: paragraph(*xs)),
        inlines.map(lambda xs: {"type": "heading", "attrs": {"level": 2}, "content": xs}),
        words.map(lambda w: {"type": "codeBlock", "content": [text(w)]}),
    )

    def nest(children: Any) -> Any:
        item = children.map(lambda b: {"type": "listItem", "content": [b]})
        cell = inlines.map(lambda xs: {"type": "tableCell", "content": [paragraph(*xs)]})
        row = st.lists(cell, min_size=1, max_size=3).map(
            lambda cs: {"type": "tableRow", "content": cs}
        )
        return st.one_of(
            st.lists(item, min_size=1, max_size=3).map(
                lambda xs: {"type": "bulletList", "content": xs}
            ),
            st.lists(item, min_size=1, max_size=3).map(
                lambda xs: {"type": "orderedList", "attrs": {"order": 1}, "content": xs}
            ),
            st.lists(children, min_size=1, max_size=2).map(
                lambda xs: {"type": "blockquote", "content": xs}
            ),
            st.lists(children, min_size=1, max_size=2).map(
                lambda xs: {"type": "futureBlock", "content": xs}
            ),
            st.lists(row, min_size=1, max_size=3).map(lambda rs: {"type": "table", "content": rs}),
        )

    return st.recursive(leaf_blocks, nest, max_leaves=8)


def text_leaves(node: Any) -> list[str]:
    if isinstance(node, dict):
        found = [node["text"]] if node.get("type") == "text" else []
        for child in node.get("content", []):
            found += text_leaves(child)
        return found
    return []


@settings(max_examples=300)
@given(st.lists(block_nodes(), min_size=1, max_size=4))
def test_every_text_in_any_adf_document_appears_in_its_rendered_text(blocks: list[Any]) -> None:
    document = doc(*blocks)
    rendered = fjb.render_adf(document)
    for leaf in text_leaves(document):
        assert leaf in rendered


def test_a_node_type_with_no_text_and_no_children_renders_as_its_type() -> None:
    document = doc(paragraph(text("before "), {"type": "futureLeaf"}, text(" after")))
    assert fjb.render_adf(document) == "before [futureLeaf] after"


def test_the_fixture_page_renders_every_node_type_as_text(tmp_path: Path) -> None:
    page = json.loads(FIXTURE.read_text())
    result = run(FakeJira(issues=page["issues"]), tmp_path)

    assert result.code == 0, result.err
    assert list(result.files) == ["part-1.txt"]
    rendered = result.files["part-1.txt"]
    expected_tail = (
        "=== EXAMPLE-20: Made-up ticket with the node types the real sample lacked\n"
        "status: To Do\n"
        "parent: none\n"
        "links: none\n"
        "\n"
        "--- description\n"
        "\n"
        "  See @Bob Example 👍\n"
        "  second line with emphasis and underline\n"
        "\n"
        "  ```python\n"
        '  print("hello")\n'
        '  print("bye")\n'
        "  ```\n"
        "\n"
        "  1. first step\n"
        "     - nested point\n"
        "  2. second step\n"
        "\n"
        "  - [x] finished task\n"
        "  - [ ] open task\n"
        "\n"
        "  ---\n"
        "\n"
        "  https://example.com/card\n"
        "\n"
        "  inline https://example.com/inline\n"
        "\n"
        "  [media: diagram.png]\n"
        "\n"
        "--- comment 1 of 1: Carol Example, 2026-11-20T10:00:00.000-0500\n"
        "\n"
        "  Looks good, see the doc (https://example.com/doc)\n"
        "\n"
        "=== EXAMPLE-21: Made-up ticket with no description and no comments\n"
        "status: Backlog\n"
        "parent: none\n"
        "links: none\n"
        "\n"
        "--- description\n"
        "\n"
        "  (none)\n"
        "\n"
        "--- no comments\n"
    )
    assert rendered.endswith(expected_tail)
    assert rendered.startswith(
        "# Open backlog of EXAMPLE, part 1 of 1: EXAMPLE-4 to EXAMPLE-21 (tickets 1 to 3 of 3)\n"
    )


def test_the_real_ticket_in_the_fixture_keeps_its_structure(tmp_path: Path) -> None:
    page = json.loads(FIXTURE.read_text())
    rendered = run(FakeJira(issues=page["issues"]), tmp_path).files["part-1.txt"]
    real = rendered.split("=== EXAMPLE-20")[0]
    lines = real.splitlines()

    assert "=== EXAMPLE-4: " + page["issues"][0]["fields"]["summary"] in lines
    assert "status: In Progress" in lines
    assert (
        "parent: EXAMPLE-5 (" + page["issues"][0]["fields"]["parent"]["fields"]["summary"] + ")"
        in lines
    )
    assert "links: relates to EXAMPLE-1; relates to EXAMPLE-2; blocks EXAMPLE-3" in lines
    assert any(line.startswith("  ## ") for line in lines), "a heading"
    assert any(line.startswith("  - ") for line in lines), "a bullet"
    assert any(re.fullmatch(r"  \| --- (\| --- )*\|", line) for line in lines), (
        "a table header rule"
    )
    assert any(line.startswith("  | ") for line in lines), "a table row"
    assert any(line.startswith("  > ") for line in lines), "a blockquote"
    assert re.search(r"`[a-z]+`", real), "inline code"
    assert "--- comment 1 of 2: Alice Example, " in real
    assert "--- comment 2 of 2: Bob Example, " in real
    for leaf in text_leaves(page["issues"][0]["fields"]["description"]):
        assert leaf.strip() in real


def test_no_author_email_reaches_the_output(tmp_path: Path) -> None:
    page = json.loads(FIXTURE.read_text())
    result = run(FakeJira(issues=page["issues"]), tmp_path)

    assert "@example.com" not in result.files["part-1.txt"]
    assert "@example.com" not in result.out


# --- paging and splitting -------------------------------------------------------------------


def test_every_page_is_read_and_250_tickets_become_three_files_in_key_order(
    tmp_path: Path,
) -> None:
    numbers = list(range(1, 251))
    jira = FakeJira(issues=[issue(n, comments=n % 3) for n in reversed(numbers)], page_size=40)
    result = run(jira, tmp_path)

    assert result.code == 0, result.err
    assert list(result.files) == ["part-1.txt", "part-2.txt", "part-3.txt"]
    keys = [
        int(m)
        for name in result.files
        for m in re.findall(r"^=== EXAMPLE-(\d+):", result.files[name], re.MULTILINE)
    ]
    assert keys == numbers
    counts = [len(re.findall(r"^=== ", body, re.MULTILINE)) for body in result.files.values()]
    assert counts == [100, 100, 50]
    assert result.files["part-3.txt"].startswith(
        "# Open backlog of EXAMPLE, part 3 of 3: EXAMPLE-201 to EXAMPLE-250 "
        "(tickets 201 to 250 of 250)\n"
    )
    assert len(jira.requests) == 7
    # n % 3 comments each: 84 tickets with one and 83 with two
    assert "250 open tickets and 250 comments" in result.out


def test_search_asks_only_for_open_tickets_of_the_project_with_the_fields_it_reads(
    tmp_path: Path,
) -> None:
    jira = FakeJira(issues=[issue(1)])
    run(jira, tmp_path)

    (request,) = jira.requests
    assert request.method == "POST"
    assert request.url == f"https://api.atlassian.com/ex/jira/{CLOUD_ID}/rest/api/3/search/jql"
    body = json.loads(request.body)
    assert body["jql"] == "project = EXAMPLE AND statusCategory != Done ORDER BY key"
    assert set(body["fields"]) == {
        "summary",
        "status",
        "description",
        "comment",
        "parent",
        "issuelinks",
    }
    expected = base64.b64encode(f"{EMAIL}:{TOKEN}".encode()).decode()
    assert request.headers["Authorization"] == f"Basic {expected}"


def test_a_short_comment_list_is_completed_from_the_comment_endpoint(tmp_path: Path) -> None:
    full = issue(7, comments=230)["fields"]["comment"]["comments"]
    short = issue(7, comments=20, total=230)
    jira = FakeJira(issues=[short], full_comments={"EXAMPLE-7": full})
    result = run(jira, tmp_path)

    assert result.code == 0, result.err
    rendered = result.files["part-1.txt"]
    assert "--- comment 230 of 230: " in rendered
    assert "comment 229 on 7" in rendered
    comment_requests = [r for r in jira.requests if "/comment" in r.url]
    assert len(comment_requests) == 3


def test_a_comment_endpoint_that_still_comes_up_short_fails_and_writes_nothing(
    tmp_path: Path,
) -> None:
    short = issue(7, comments=2, total=5)
    full = issue(7, comments=3)["fields"]["comment"]["comments"]
    jira = FakeJira(issues=[short], full_comments={"EXAMPLE-7": full}, comment_total=5)
    result = run(jira, tmp_path)

    assert result.code == 1
    assert "EXAMPLE-7" in result.err
    assert "5" in result.err and "3" in result.err
    assert result.files == {}


def test_paging_that_never_ends_stops_at_the_page_limit_and_writes_nothing(tmp_path: Path) -> None:
    jira = FakeJira(
        issues=[issue(n) for n in range(1, fjb.MAX_PAGES + 50)], page_size=1, never_last=True
    )
    result = run(jira, tmp_path)

    assert result.code == 1
    assert len(jira.requests) == fjb.MAX_PAGES
    assert "page" in result.err
    assert result.files == {}


def test_a_ticket_on_two_pages_fails_and_says_to_run_again(tmp_path: Path) -> None:
    jira = FakeJira(issues=[issue(1), issue(2), issue(2), issue(3)], page_size=2)
    result = run(jira, tmp_path)

    assert result.code == 1
    assert "EXAMPLE-2" in result.err
    assert "again" in result.err
    assert result.files == {}


def test_an_issue_missing_a_field_fails_and_names_the_ticket_and_field(tmp_path: Path) -> None:
    broken = issue(9)
    del broken["fields"]["status"]
    result = run(FakeJira(issues=[issue(8), broken]), tmp_path)

    assert result.code == 1
    assert "EXAMPLE-9" in result.err
    assert "status" in result.err
    assert result.files == {}


def test_a_project_with_no_open_tickets_writes_nothing_and_says_so(tmp_path: Path) -> None:
    result = run(FakeJira(issues=[]), tmp_path)

    assert result.code == 0, result.err
    assert result.files == {}
    assert "0 open tickets" in result.out


# --- retries and refusals -------------------------------------------------------------------


def test_a_rate_limit_is_waited_out_and_the_run_completes(tmp_path: Path) -> None:
    jira = FakeJira(issues=[issue(1)], script={1: response(429, b"", {"Retry-After": "7"})})
    result = run(jira, tmp_path)

    assert result.code == 0, result.err
    assert result.sleeps == [7]
    assert len(jira.requests) == 2


def test_a_retry_after_longer_than_the_time_left_fails_at_once_and_says_so(tmp_path: Path) -> None:
    jira = FakeJira(issues=[issue(1)], script={1: response(429, b"", {"Retry-After": "3600"})})
    result = run(jira, tmp_path)

    assert result.code == 1
    assert result.sleeps == []
    assert "3600" in result.err
    assert result.files == {}


def test_server_errors_on_every_attempt_fail_with_the_request_and_write_nothing(
    tmp_path: Path,
) -> None:
    failing = {n: response(503, {"errorMessages": ["try later"]}) for n in range(1, 10)}
    jira = FakeJira(issues=[issue(1)], script=failing)
    result = run(jira, tmp_path)

    assert result.code == 1
    assert len(jira.requests) == fjb.ATTEMPTS
    assert "search" in result.err
    assert "503" in result.err
    assert result.files == {}


def test_a_network_error_is_retried(tmp_path: Path) -> None:
    jira = FakeJira(issues=[issue(1)], script={1: fjb.NetworkError(reason="timed out")})
    result = run(jira, tmp_path)

    assert result.code == 0, result.err
    assert len(jira.requests) == 2


@pytest.mark.parametrize("status", [401, 403])
def test_a_refused_token_fails_at_once_with_the_steps_to_replace_it(
    tmp_path: Path, status: int
) -> None:
    refusal = response(status, {"errorMessages": ["Client must be authenticated"]})
    jira = FakeJira(issues=[issue(1)], script={1: refusal})
    result = run(jira, tmp_path)

    assert result.code == 1
    assert len(jira.requests) == 1
    assert "Client must be authenticated" in result.err
    assert "read:jira-work" in result.err
    assert "secret add jira-backlog-read" in result.err
    assert result.files == {}


# --- credentials and arguments --------------------------------------------------------------


def test_a_missing_keychain_item_fails_with_the_setup_step_before_any_request(
    tmp_path: Path,
) -> None:
    jira = FakeJira(issues=[issue(1)])
    result = run(jira, tmp_path, read_keychain=keychain(present=False))

    assert result.code == 1
    assert jira.requests == []
    assert "secret add jira-backlog-read" in result.err


def test_a_missing_cloud_id_fails_with_the_setup_step_before_any_request(tmp_path: Path) -> None:
    jira = FakeJira(issues=[issue(1)])
    result = run(jira, tmp_path, environ={})

    assert result.code == 1
    assert jira.requests == []
    assert "PRIVATE_JIRA_CLOUD_ID" in result.err


@pytest.mark.parametrize(
    "project", ["example", "EX AMPLE", "EXAMPLE OR project = OTHER", 'EXAMPLE"', "1EX", ""]
)
def test_a_project_key_that_could_change_the_query_is_refused_before_anything_runs(
    tmp_path: Path, project: str
) -> None:
    jira = FakeJira(issues=[issue(1)])
    reads: list[list[str]] = []

    def read_keychain(args: list[str]) -> Any:
        reads.append(args)
        return keychain()(args)

    result = run(jira, tmp_path, project=project, read_keychain=read_keychain)

    assert result.code == 2
    assert jira.requests == []
    assert reads == []


def test_an_output_directory_that_is_not_empty_is_refused_before_anything_runs(
    tmp_path: Path,
) -> None:
    (tmp_path / "part-1.txt").write_text("from an earlier run")
    jira = FakeJira(issues=[issue(1)])
    result = run(jira, tmp_path)

    assert result.code == 2
    assert jira.requests == []
    assert result.files == {"part-1.txt": "from an earlier run"}


# --- the token stays secret -----------------------------------------------------------------

tokens = st.text(
    alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789=_-",
    min_size=20,
    max_size=200,
)


@settings(max_examples=60, deadline=None)
@given(token=tokens, scenario=st.sampled_from(["ok", "refused", "server", "malformed"]))
def test_the_token_reaches_no_output_whatever_happens(token: str, scenario: str) -> None:
    auth = base64.b64encode(f"{EMAIL}:{token}".encode()).decode()
    echo = {"errorMessages": [f"bad credentials {token} Basic {auth}"]}
    broken = issue(2)
    del broken["fields"]["summary"]
    jira = {
        "ok": FakeJira(issues=[issue(1, comments=2)]),
        "refused": FakeJira(issues=[issue(1)], script={1: response(401, echo)}),
        "server": FakeJira(
            issues=[issue(1)], script={n: response(500, echo) for n in range(1, 10)}
        ),
        "malformed": FakeJira(issues=[issue(1), broken]),
    }[scenario]
    with tempfile.TemporaryDirectory() as directory:
        result = run(jira, Path(directory), read_keychain=keychain(token=token))
    everything = result.out + result.err + "".join(result.files.values())
    assert token not in everything
    assert auth not in everything


def test_the_token_does_not_show_in_its_repr() -> None:
    assert TOKEN not in repr(fjb.Token(TOKEN))


# --- the real HTTP sender, and the dependency it uses -------------------------------------------------------------------


def test_the_real_sender_gives_up_on_a_server_that_never_answers() -> None:
    server = socket.socket()
    server.bind(("127.0.0.1", 0))
    server.listen(1)
    port = server.getsockname()[1]
    accepted: list[socket.socket] = []
    threading.Thread(target=lambda: accepted.append(server.accept()[0]), daemon=True).start()
    request = fjb.HttpRequest(method="GET", url=f"http://127.0.0.1:{port}/", headers={}, body=None)

    started = time.monotonic()
    result = fjb.urllib_send(request, timeout=0.5)

    assert isinstance(result, fjb.NetworkError)
    assert time.monotonic() - started < 5
    server.close()


def test_the_real_sender_rejects_a_certificate_macos_does_not_trust(tmp_path: Path) -> None:
    key, cert = tmp_path / "key.pem", tmp_path / "cert.pem"
    subprocess.run(
        ["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1"]
        + ["-subj", "/CN=127.0.0.1", "-keyout", str(key), "-out", str(cert)],
        check=True,
        capture_output=True,
    )
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(cert, key)
    server = http.server.HTTPServer(("127.0.0.1", 0), http.server.BaseHTTPRequestHandler)
    server.socket = context.wrap_socket(server.socket, server_side=True)
    threading.Thread(target=server.handle_request, daemon=True).start()
    port = server.server_address[1]
    request = fjb.HttpRequest(method="GET", url=f"https://127.0.0.1:{port}/", headers={}, body=None)

    result = fjb.urllib_send(request, timeout=5)

    assert isinstance(result, fjb.CertificateRejected), result
    server.server_close()


def test_a_rejected_certificate_fails_at_once_and_names_a_tls_inspecting_proxy(
    tmp_path: Path,
) -> None:
    rejected = fjb.CertificateRejected(reason="self-signed certificate in certificate chain")
    jira = FakeJira(issues=[issue(1)], script={1: rejected})
    result = run(jira, tmp_path)

    assert result.code == 1
    assert len(jira.requests) == 1
    assert result.sleeps == []
    assert "self-signed certificate in certificate chain" in result.err
    assert "TLS-inspecting proxy" in result.err
    assert "again later" not in result.err
    assert result.files == {}


def test_the_pinned_dependencies_match_the_test_and_type_check_installs() -> None:
    header = re.search(r"# dependencies = \[(.+)\]", SCRIPT.read_text())
    assert header is not None
    specs = re.findall(r'"([^"]+)"', header.group(1))
    assert specs and all("==" in spec for spec in specs), specs
    for check_script in ("scripts/checks/tests.bash", "scripts/checks/types.bash"):
        for spec in specs:
            assert f"'{spec}'" in (REPO / check_script).read_text(), (check_script, spec)


# --- the project lookup and requests Jira rejects -------------------------------------------


def test_a_request_jira_rejects_fails_at_once_without_claiming_it_was_retried(
    tmp_path: Path,
) -> None:
    jira = FakeJira(issues=[issue(1)], script={1: response(404, b"")})
    result = run(jira, tmp_path)

    assert result.code == 1
    assert len(jira.requests) == 1
    assert "HTTP 404" in result.err
    assert "times" not in result.err
    assert "again later" not in result.err
    assert result.files == {}


def test_a_comment_request_jira_rejects_is_reported_for_its_ticket(tmp_path: Path) -> None:
    short = issue(7, comments=1, total=4)
    jira = FakeJira(issues=[short], script={2: response(404, b"")})
    result = run(jira, tmp_path)

    assert result.code == 1
    assert "comments of EXAMPLE-7" in result.err
    assert "HTTP 404" in result.err
    assert result.files == {}


def test_the_project_is_looked_up_before_the_search(tmp_path: Path) -> None:
    jira = FakeJira(issues=[issue(1)])
    result = run(jira, tmp_path)

    assert result.code == 0, result.err
    assert jira.project_lookups == ["EXAMPLE"]


def test_a_project_that_does_not_exist_fails_instead_of_looking_empty(tmp_path: Path) -> None:
    jira = FakeJira(issues=[], projects=frozenset())
    result = run(jira, tmp_path)

    assert result.code == 1
    assert jira.requests == []
    assert "EXAMPLE" in result.err
    assert "0 open tickets" not in result.out
    assert result.files == {}


def test_a_token_refused_at_the_project_lookup_fails_before_any_search(tmp_path: Path) -> None:
    refusal = response(401, {"errorMessages": ["Client must be authenticated"]})
    jira = FakeJira(issues=[issue(1)], lookup_answer=refusal)
    result = run(jira, tmp_path)

    assert result.code == 1
    assert jira.project_lookups == ["EXAMPLE"]
    assert jira.requests == []
    assert "secret add jira-backlog-read" in result.err
    assert result.files == {}


def test_help_prints_the_usage_and_exits_0(tmp_path: Path) -> None:
    out, err = io.StringIO(), io.StringIO()
    code = fjb.main(
        ["--help"],
        environ={},
        send=FakeJira(issues=[]),
        read_keychain=keychain(),
        sleep=lambda _: None,
        out=out,
        err=err,
    )

    assert code == 0
    assert "--out-dir" in out.getvalue()
    assert err.getvalue() == ""


# --- a backlog read is complete or fails ----------------------------------------------------


def test_a_page_that_says_more_follow_but_gives_no_token_fails_and_writes_nothing(
    tmp_path: Path,
) -> None:
    jira = FakeJira(issues=[], script={1: response(200, {"issues": [issue(1)], "isLast": False})})
    result = run(jira, tmp_path)

    assert result.code == 1
    assert "search page 1" in result.err
    assert result.files == {}


@pytest.mark.parametrize("page", [{"isLast": True}, {"issues": []}, {"issues": {}, "isLast": True}])
def test_a_page_without_its_issues_or_its_last_page_flag_fails_and_writes_nothing(
    tmp_path: Path, page: dict[str, Any]
) -> None:
    result = run(FakeJira(issues=[], script={1: response(200, page)}), tmp_path)

    assert result.code == 1
    assert "search page 1" in result.err
    assert "0 open tickets" not in result.out
    assert result.files == {}


def test_a_comment_page_for_another_offset_fails_and_writes_nothing(tmp_path: Path) -> None:
    short = issue(7, comments=1, total=3)
    full = issue(7, comments=3)["fields"]["comment"]["comments"]
    jira = FakeJira(issues=[short], full_comments={"EXAMPLE-7": full}, comment_start_shift=5)
    result = run(jira, tmp_path)

    assert result.code == 1
    assert "EXAMPLE-7" in result.err
    assert result.files == {}


def test_short_comment_lists_among_complete_tickets_are_completed_in_key_order(
    tmp_path: Path,
) -> None:
    issues = [issue(n, comments=1, total=3) if n % 2 == 0 else issue(n) for n in range(1, 7)]
    full = {
        f"EXAMPLE-{n}": issue(n, comments=3)["fields"]["comment"]["comments"] for n in (2, 4, 6)
    }
    jira = FakeJira(issues=issues, full_comments=full)
    result = run(jira, tmp_path)

    assert result.code == 0, result.err
    keys = re.findall(r"^=== (EXAMPLE-\d+):", result.files["part-1.txt"], re.MULTILINE)
    assert keys == [f"EXAMPLE-{n}" for n in range(1, 7)]
    # the project lookup, one search page and one comment page for each of the three
    assert "in 5 requests" in result.out


def test_every_ticket_whose_comments_jira_rejects_is_reported(tmp_path: Path) -> None:
    issues = [issue(n, comments=1, total=3) for n in (2, 4, 6)]
    full = {
        f"EXAMPLE-{n}": issue(n, comments=3)["fields"]["comment"]["comments"] for n in (2, 4, 6)
    }
    jira = FakeJira(
        issues=issues, full_comments=full, script={2: response(404, b""), 3: response(404, b"")}
    )
    result = run(jira, tmp_path, workers=1)

    assert result.code == 1
    assert "comments of EXAMPLE-2" in result.err
    assert "comments of EXAMPLE-4" in result.err
    assert result.files == {}


def test_a_refused_token_stops_the_remaining_comment_fetches(tmp_path: Path) -> None:
    issues = [issue(n, comments=1, total=3) for n in range(1, 21)]
    full = {
        f"EXAMPLE-{n}": issue(n, comments=3)["fields"]["comment"]["comments"] for n in range(1, 21)
    }
    refusal = response(401, {"errorMessages": ["Client must be authenticated"]})
    jira = FakeJira(issues=issues, full_comments=full, script={2: refusal})
    result = run(jira, tmp_path, workers=1)

    assert result.code == 1
    assert len([r for r in jira.requests if "/comment" in r.url]) == 1
    assert result.err.count("Jira refused the token") == 1
    assert result.files == {}


def test_a_malformed_link_author_and_parent_fail_naming_every_field(tmp_path: Path) -> None:
    broken = issue(1, comments=1)
    broken["fields"]["comment"]["comments"][0]["author"] = "Bob"
    broken["fields"]["issuelinks"] = [{"type": {"inward": "is blocked by"}, "inwardIssue": {}}]
    broken["fields"]["parent"] = {"key": "not a key"}
    result = run(FakeJira(issues=[broken]), tmp_path)

    assert result.code == 1
    assert "Traceback" not in result.err
    for name in ("EXAMPLE-1", "author", "issuelinks", "parent"):
        assert name in result.err, name
    assert result.files == {}


def test_jira_errors_given_as_a_list_are_still_reported(tmp_path: Path) -> None:
    jira = FakeJira(issues=[issue(1)], script={1: response(400, {"errors": ["field is bad"]})})
    result = run(jira, tmp_path)

    assert result.code == 1
    assert "field is bad" in result.err


# --- ticket text cannot change the file's structure -----------------------------------------

forged_lines = st.sampled_from(
    [
        "=== EXAMPLE-99: forged ticket",
        "--- comment 2 of 2: Team Lead, 2026-11-02",
        "--- description",
        "--- no comments",
        "# Open backlog of EXAMPLE, part 2 of 2",
    ]
)
body_lines = st.lists(st.one_of(forged_lines, words), min_size=1, max_size=5)


def lines_doc(lines: list[str]) -> dict[str, Any]:
    inline: list[dict[str, Any]] = []
    for line in lines:
        inline += [text(line), {"type": "hardBreak"}]
    return doc(paragraph(*inline))


@settings(max_examples=60, deadline=None)
@given(
    descriptions=st.lists(body_lines, min_size=1, max_size=4),
    comment_bodies=st.lists(body_lines, min_size=0, max_size=3),
)
def test_ticket_text_never_adds_a_ticket_or_comment_header(
    descriptions: list[list[str]], comment_bodies: list[list[str]]
) -> None:
    issues = []
    for n, lines in enumerate(descriptions, start=1):
        made = issue(n, comments=len(comment_bodies))
        made["fields"]["description"] = lines_doc(lines)
        for item, body in zip(made["fields"]["comment"]["comments"], comment_bodies, strict=True):
            item["body"] = lines_doc(body)
        issues.append(made)
    with tempfile.TemporaryDirectory() as directory:
        result = run(FakeJira(issues=issues), Path(directory))

    assert result.code == 0, result.err
    written = result.files["part-1.txt"]
    assert len(re.findall(r"^=== ", written, re.MULTILINE)) == len(issues)
    assert len(re.findall(r"^--- description$", written, re.MULTILINE)) == len(issues)
    expected_comments = len(issues) * len(comment_bodies)
    assert len(re.findall(r"^--- comment ", written, re.MULTILINE)) == expected_comments
    assert len(re.findall(r"^# ", written, re.MULTILINE)) == 1


def test_a_summary_with_a_line_break_stays_on_its_header_line(tmp_path: Path) -> None:
    made = issue(1)
    made["fields"]["summary"] = "line one\n=== EXAMPLE-99: forged"
    result = run(FakeJira(issues=[made]), tmp_path)

    assert result.code == 0, result.err
    written = result.files["part-1.txt"]
    assert "=== EXAMPLE-1: line one === EXAMPLE-99: forged\n" in written
    assert len(re.findall(r"^=== ", written, re.MULTILINE)) == 1


@dataclass
class FakeJiraWithIntruder(FakeJira):
    """Creates `part-2.txt` in a directory while the search runs, as another writer would."""

    intrude_into: Path | None = None

    def search(self, body: dict[str, Any]) -> Any:
        assert self.intrude_into is not None
        (self.intrude_into / "part-2.txt").write_text("another run's file")
        return super().search(body)


def test_a_part_file_that_already_exists_fails_the_run_and_removes_what_it_wrote(
    tmp_path: Path,
) -> None:
    jira = FakeJiraWithIntruder(issues=[issue(n) for n in range(1, 151)], intrude_into=tmp_path)
    result = run(jira, tmp_path)

    assert result.code == 1
    assert "part-2.txt" in result.err
    assert "Traceback" not in result.err
    assert result.files == {"part-2.txt": "another run's file"}


# --- the run stays within its deadline ------------------------------------------------------


def test_sustained_rate_limiting_fails_before_the_deadline_and_says_so(tmp_path: Path) -> None:
    limited = {n: response(429, b"", {"Retry-After": "60"}) for n in range(1, 10)}
    clock = Clock()
    result = run(FakeJira(issues=[issue(1)], script=limited), tmp_path, clock=clock)

    assert result.code == 1
    assert clock.sleeps == [60]
    assert clock.now <= fjb.DEADLINE_SECONDS
    assert "search page 1" in result.err
    assert f"{fjb.DEADLINE_SECONDS}" in result.err
    assert result.files == {}


def test_a_retry_after_that_is_not_a_finite_number_waits_the_default(tmp_path: Path) -> None:
    jira = FakeJira(issues=[issue(1)], script={1: response(429, b"", {"Retry-After": "nan"})})
    result = run(jira, tmp_path)

    assert result.code == 0, result.err
    assert result.sleeps == [1.0]


def serve(handler: type[http.server.BaseHTTPRequestHandler]) -> http.server.HTTPServer:
    server = http.server.HTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


class Quiet(http.server.BaseHTTPRequestHandler):
    def log_message(self, format: str, *args: Any) -> None:  # noqa: A002
        pass


def test_the_real_sender_bounds_a_response_that_trickles_in() -> None:
    class Trickle(Quiet):
        def do_GET(self) -> None:
            self.send_response(200)
            self.send_header("Content-Length", "20")
            self.end_headers()
            for _ in range(20):
                self.wfile.write(b" ")
                self.wfile.flush()
                time.sleep(0.2)

    server = serve(Trickle)
    request = fjb.HttpRequest(
        method="GET", url=f"http://127.0.0.1:{server.server_port}/", headers={}, body=None
    )
    started = time.monotonic()
    result = fjb.urllib_send(request, timeout=1.0)

    assert isinstance(result, fjb.NetworkError), result
    assert time.monotonic() - started < 2.5
    server.shutdown()


def test_the_real_sender_reports_a_body_cut_short_as_a_network_error() -> None:
    class CutShort(Quiet):
        def do_GET(self) -> None:
            self.send_response(200)
            self.send_header("Content-Length", "100")
            self.end_headers()
            self.wfile.write(b"{")
            self.close_connection = True

    server = serve(CutShort)
    request = fjb.HttpRequest(
        method="GET", url=f"http://127.0.0.1:{server.server_port}/", headers={}, body=None
    )

    assert isinstance(fjb.urllib_send(request, timeout=3), fjb.NetworkError)
    server.shutdown()


def test_the_real_sender_never_follows_a_redirect_with_the_token() -> None:
    received: list[str | None] = []

    class Elsewhere(Quiet):
        def do_GET(self) -> None:
            received.append(self.headers.get("Authorization"))
            self.send_response(200)
            self.end_headers()

    other = serve(Elsewhere)

    class Redirecting(Quiet):
        def do_GET(self) -> None:
            self.send_response(302)
            self.send_header("Location", f"http://localhost:{other.server_port}/x")
            self.end_headers()

    server = serve(Redirecting)
    request = fjb.HttpRequest(
        method="GET",
        url=f"http://127.0.0.1:{server.server_port}/",
        headers={"Authorization": "Basic SECRET"},
        body=None,
    )
    result = fjb.urllib_send(request, timeout=3)

    assert isinstance(result, fjb.HttpResponse) and result.status == 302, result
    assert received == []
    server.shutdown()
    other.shutdown()


def test_a_redirect_fails_the_run_at_once_naming_where_it_pointed(tmp_path: Path) -> None:
    moved = response(302, b"", {"Location": "https://elsewhere.example/rest"})
    jira = FakeJira(issues=[issue(1)], script={1: moved})
    result = run(jira, tmp_path)

    assert result.code == 1
    assert len(jira.requests) == 1
    assert "elsewhere.example" in result.err
    assert result.files == {}


# --- the Keychain ---------------------------------------------------------------------------


def test_the_token_is_read_from_the_named_keychain_item_only(tmp_path: Path) -> None:
    reads: list[list[str]] = []

    def read_keychain(args: list[str]) -> Any:
        reads.append(args)
        return keychain()(args)

    result = run(FakeJira(issues=[issue(1)]), tmp_path, read_keychain=read_keychain)

    assert result.code == 0, result.err
    assert reads == [ITEM_ARGS, [*ITEM_ARGS, "-w"]]


def test_a_keychain_that_cannot_be_read_says_why_instead_of_asking_for_a_new_token(
    tmp_path: Path,
) -> None:
    locked = fjb.KeychainAnswer(
        returncode=51, stdout="", stderr="security: User interaction is not allowed.\n"
    )
    result = run(FakeJira(issues=[issue(1)]), tmp_path, read_keychain=lambda args: locked)

    assert result.code == 1
    assert "51" in result.err
    assert "User interaction is not allowed" in result.err
    assert "No API token is stored" not in result.err


def test_a_machine_without_the_security_command_says_the_macos_keychain_is_needed(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("PATH", str(tmp_path))
    answer = fjb.security_read(ITEM_ARGS)
    assert isinstance(answer, fjb.KeychainUnavailable)

    out_dir = tmp_path / "out"
    out_dir.mkdir()
    result = run(FakeJira(issues=[issue(1)]), out_dir, read_keychain=lambda args: answer)
    assert result.code == 1
    assert "macOS Keychain" in result.err


def test_an_account_that_is_not_an_email_says_how_to_store_it_again(tmp_path: Path) -> None:
    result = run(FakeJira(issues=[issue(1)]), tmp_path, read_keychain=keychain(email="alice"))

    assert result.code == 1
    assert "Atlassian email" in result.err
    assert "security delete-generic-password -s jira-backlog-read" in result.err


# --- arguments ------------------------------------------------------------------------------


def test_a_missing_project_prints_only_argparses_message(tmp_path: Path) -> None:
    out, err = io.StringIO(), io.StringIO()
    code = fjb.main(
        ["--out-dir", str(tmp_path)],
        environ={},
        send=FakeJira(issues=[]),
        read_keychain=keychain(),
        sleep=lambda _: None,
        out=out,
        err=err,
    )

    assert code == 2
    assert err.getvalue().startswith("the following arguments are required: project")
    assert "--help" in err.getvalue()
