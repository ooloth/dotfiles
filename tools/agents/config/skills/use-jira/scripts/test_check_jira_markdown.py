"""Black-box tests for check_jira_markdown.py.

Each test runs the script as a subprocess, on a body written to a temporary file or on hook input
sent to stdin, so the script stays a single file.

Run with `bash scripts/checks/tests.bash` from the repo root, which installs what these tests need.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st
from markdown_it import MarkdownIt

SCRIPT = Path(__file__).with_name("check_jira_markdown.py")
REPO = Path(__file__).resolve().parents[6]
URL = "https://github.com/example/repo/pull/7"
SENTINEL = "post nothing until then"


def run(*args: str, stdin: str | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-I", str(SCRIPT), *args], capture_output=True, text=True, input=stdin
    )


def check(tmp_path: Path, body: str) -> subprocess.CompletedProcess[str]:
    path = tmp_path / "body.md"
    path.write_text(body)
    return run(str(path))


def reported_lines(result: subprocess.CompletedProcess[str], kind: str) -> list[int]:
    """The line numbers of every report of one kind, read from lines `body.md:<n>: <kind>: …`."""
    lines = []
    for line in result.stdout.splitlines():
        location, _, rest = line.partition(": ")
        if rest.startswith(f"{kind}:"):
            lines.append(int(location.rsplit(":", 1)[1]))
    return lines


@pytest.mark.parametrize(
    ("body", "line"),
    [
        ("**Uses `x` here.** Then more.\n", 1),
        ("Intro.\n\n- **No test passes `groups` beside it.** Rest.\n", 3),
        ("| a | b |\n|---|---|\n| **cell `x`** | y |\n", 3),
    ],
    ids=["paragraph", "list item", "table cell"],
)
def test_code_inside_bold_is_reported_on_its_line(tmp_path: Path, body: str, line: int) -> None:
    result = check(tmp_path, body)
    assert result.returncode == 1, result.stdout + result.stderr
    assert reported_lines(result, "code inside bold") == [line]


def test_bold_wrapping_onto_a_second_line_is_reported_where_the_code_is(tmp_path: Path) -> None:
    result = check(tmp_path, "Para.\n\n**Bold starts here\nand `code` is here.** End.\n")
    assert reported_lines(result, "code inside bold") == [4]


def test_code_span_wrapping_onto_a_second_line_does_not_shift_later_lines(tmp_path: Path) -> None:
    result = check(tmp_path, "A `code span that\nwraps` here, then **bold `x`.**\n")
    assert reported_lines(result, "code inside bold") == [2]


def test_code_as_link_text_is_reported(tmp_path: Path) -> None:
    result = check(tmp_path, f"See\n[`DECISIONS.md`]({URL}).\n")
    assert result.returncode == 1
    assert reported_lines(result, "code as link text") == [2]


@pytest.mark.parametrize(
    ("body", "line"),
    [
        (f"Draft PR: {URL}\n", 1),
        (f"- first\n- see {URL} for more\n", 2),
        (f"| a | b |\n|---|---|\n| {URL} | y |\n", 3),
    ],
    ids=["paragraph", "list item", "table cell"],
)
def test_bare_url_is_reported_on_its_line(tmp_path: Path, body: str, line: int) -> None:
    result = check(tmp_path, body)
    assert result.returncode == 1, result.stdout + result.stderr
    assert reported_lines(result, "bare URL") == [line]


def test_url_keeps_parentheses_it_opens_and_drops_punctuation_after_it(tmp_path: Path) -> None:
    result = check(tmp_path, "See https://x.com/a_(b) and (https://x.com/c).\n")
    assert "[https://x.com/a_(b)](https://x.com/a_(b))" in result.stdout
    assert "[https://x.com/c](https://x.com/c)" in result.stdout


def test_email_autolink_fix_keeps_the_visible_text(tmp_path: Path) -> None:
    result = check(tmp_path, "Mail <me@example.com>.\n")
    assert reported_lines(result, "autolink") == [1]
    assert "[me@example.com](mailto:me@example.com)" in result.stdout


def test_autolink_is_reported(tmp_path: Path) -> None:
    result = check(tmp_path, f"Draft PR: <{URL}>\n")
    assert result.returncode == 1
    assert reported_lines(result, "autolink") == [1]


@pytest.mark.parametrize(
    "body",
    [
        "**Bold lead-in.** Then `code` after it.\n",
        "**Bold with no code.**\n",
        f"[a label]({URL})\n",
        f"[{URL}]({URL})\n",
        f"```\ncurl {URL}\n**x `y`**\n```\n",
        f"Text.\n\n    curl {URL}\n    **x `y`**\n",
        f"Run `curl {URL}` first.\n",
        "Run `a**b` and `c**d` here.\n",
        "",
    ],
    ids=[
        "code after bold",
        "bold without code",
        "labelled link",
        "url as its own label",
        "fenced code block",
        "indented code block",
        "url in code span",
        "stars in code spans",
        "empty body",
    ],
)
def test_body_jira_converts_intact_is_clean(tmp_path: Path, body: str) -> None:
    result = check(tmp_path, body)
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout == ""


def test_every_problem_is_reported_not_only_the_first(tmp_path: Path) -> None:
    body = f"**One `a`.**\n\n**Two `b`.**\n\nSee {URL}\n"
    result = check(tmp_path, body)
    assert reported_lines(result, "code inside bold") == [1, 3]
    assert reported_lines(result, "bare URL") == [5]


@pytest.mark.parametrize(
    ("body", "fix"),
    [
        ("**Uses `x`.**\n", "end the bold before the code"),
        (f"[`x`]({URL})\n", "write the link text without backticks"),
        (f"See {URL}\n", f"[{URL}]({URL})"),
        (f"See <{URL}>\n", f"[{URL}]({URL})"),
    ],
    ids=["code inside bold", "code as link text", "bare URL", "autolink"],
)
def test_each_report_says_how_to_fix_it(tmp_path: Path, body: str, fix: str) -> None:
    assert fix in check(tmp_path, body).stdout


def test_missing_file_cannot_be_checked(tmp_path: Path) -> None:
    result = run(str(tmp_path / "absent.md"))
    assert result.returncode == 2
    assert "absent.md" in result.stderr


def test_unreadable_file_cannot_be_checked(tmp_path: Path) -> None:
    path = tmp_path / "locked.md"
    path.write_text("x\n")
    path.chmod(0)
    try:
        result = run(str(path))
    finally:
        path.chmod(0o600)
    assert result.returncode == 2
    assert "locked.md" in result.stderr


def test_no_argument_cannot_be_checked() -> None:
    result = run()
    assert result.returncode == 2
    assert result.stderr


# Shaped like two real comments: one posted with code inside its bold lead-ins, and a PR link
# posted as a bare URL.
FIRST_POST = (
    f"Reviewing [org/repo#1]({URL}) found two things in `other-repo`:\n"
    "\n"
    "- **No test passes `field` beside other `bag` keys.** The table has rows for one.\n"
    '- **The `parse_field` docstring quotes `claims = ["x"]`.** It now passes more.\n'
)
CORRECTED_POST = (
    f"Reviewing [org/repo#1]({URL}) found two things in `other-repo`:\n"
    "\n"
    "- **No test passes field beside other bag keys.** The table has rows for one.\n"
    '- **The parse_field docstring quotes claims = ["x"].** It now passes more.\n'
)


def test_first_post_shape_reports_every_code_span_in_both_bold_lead_ins(tmp_path: Path) -> None:
    assert reported_lines(check(tmp_path, FIRST_POST), "code inside bold") == [3, 3, 4, 4]


def test_corrected_post_shape_is_clean(tmp_path: Path) -> None:
    assert check(tmp_path, CORRECTED_POST).returncode == 0


def test_pr_link_comment_shape_reports_the_bare_url(tmp_path: Path) -> None:
    assert reported_lines(check(tmp_path, f"Draft PR: {URL}"), "bare URL") == [1]


def test_pr_link_comment_with_a_labelled_link_is_clean(tmp_path: Path) -> None:
    assert check(tmp_path, f"Draft PR: [org/repo#7]({URL})").returncode == 0


def test_a_list_of_fixes_ends_with_the_line_use_jira_reads(tmp_path: Path) -> None:
    result = check(tmp_path, f"See {URL}\n")
    assert result.returncode == 1
    assert result.stdout.splitlines()[-1].endswith(SENTINEL)


def test_without_markdown_it_py_the_body_cannot_be_checked(tmp_path: Path) -> None:
    path = tmp_path / "body.md"
    path.write_text("x\n")
    result = subprocess.run(
        [sys.executable, "-I", "-S", str(SCRIPT), str(path)], capture_output=True, text=True
    )
    assert result.returncode == 2, result.stderr
    assert "markdown-it-py" in result.stderr


def test_url_with_emphasis_characters_is_reported_whole_with_no_fix_that_keeps_words(
    tmp_path: Path,
) -> None:
    url = "https://github.com/o/r/blob/main/pkg/__init__.py"
    result = check(tmp_path, f"See {url} here\n")
    assert f"Jira posts {url} as text" in result.stdout
    assert f"[{url}]({url})" not in result.stdout


def test_url_with_an_intraword_underscore_keeps_the_fix_that_keeps_words(tmp_path: Path) -> None:
    url = "https://x.com/a_b"
    assert f"[{url}]({url})" in check(tmp_path, f"See {url} here\n").stdout


@pytest.mark.parametrize("code", ["__init__", "*args"])
def test_code_that_parses_as_markdown_is_not_offered_backtick_removal(
    tmp_path: Path, code: str
) -> None:
    result = check(tmp_path, f"**The `{code}` docs.** More.\n")
    assert reported_lines(result, "code inside bold") == [1]
    assert "end the bold before the code" in result.stdout
    assert "leave the backticks out" not in result.stdout


def test_plain_code_inside_bold_is_offered_backtick_removal(tmp_path: Path) -> None:
    assert "leave the backticks out" in check(tmp_path, "**Uses `x` here.**\n").stdout


def test_code_link_text_that_parses_as_markdown_is_not_offered_backtick_removal(
    tmp_path: Path,
) -> None:
    result = check(tmp_path, f"[`__init__`]({URL})\n")
    assert reported_lines(result, "code as link text") == [1]
    assert "without backticks" not in result.stdout


def test_bold_that_spans_two_table_cells_is_not_bold(tmp_path: Path) -> None:
    result = check(tmp_path, "| a | b |\n|---|---|\n| **a `x` | b** |\n")
    assert result.returncode == 0, result.stdout


@pytest.mark.parametrize(
    "body",
    [f"[x]({URL})\n{URL}\n", f"![{URL}]({URL})\n{URL}\n"],
    ids=["link", "image"],
)
def test_bare_url_after_a_link_to_it_is_reported_on_its_own_line(tmp_path: Path, body: str) -> None:
    assert reported_lines(check(tmp_path, body), "bare URL") == [2]


def test_dependency_range_matches_the_test_and_type_check_installs() -> None:
    header = re.search(r'# dependencies = \["([^"]+)"\]', SCRIPT.read_text())
    assert header is not None
    spec = header.group(1)
    for check_script in ("scripts/checks/tests.bash", "scripts/checks/types.bash"):
        assert f"'{spec}'" in (REPO / check_script).read_text(), check_script


# Applying the fixes the check says keep every word must leave the body reading the same.

PARSER = MarkdownIt("commonmark").enable("table")
WORD_KEEPING_URL_FIX = re.compile(
    r"bare URL: Jira posts (\S+) as text, not a link\. Fix: write it as \["
)
WORD_KEEPING_CODE_FIX = re.compile(
    r"code inside bold: Jira ends the bold where `([^`]+)` starts\..*leave the backticks out"
)


def rendered_text(body: str) -> str:
    """The characters a reader sees, with formatting and link targets dropped."""
    seen = []
    for token in PARSER.parse(body):
        for child in token.children or []:
            if child.type in ("text", "code_inline"):
                seen.append(child.content)
            elif child.type in ("softbreak", "hardbreak"):
                seen.append("\n")
    return "".join(seen)


def fragment(index: int) -> st.SearchStrategy[str]:
    word = st.sampled_from(["see", "the", "run"])
    code = st.sampled_from([f"x{index}", f"__init{index}__", f"*args{index}", f"a_b{index}"])
    url = st.sampled_from(
        [f"https://e.com/p{index}", f"https://e.com/a_b{index}", f"https://e.com/__i{index}__.py"]
    )
    return st.one_of(
        word,
        url,
        code.map(lambda c: f"`{c}`"),
        st.tuples(word, code, word).map(lambda t: f"**{t[0]} `{t[1]}` {t[2]}**"),
    )


bodies = st.integers(min_value=1, max_value=6).flatmap(
    lambda n: st.tuples(*(fragment(i) for i in range(n))).map(lambda parts: " ".join(parts) + "\n")
)


def reports_in(result: subprocess.CompletedProcess[str]) -> list[str]:
    """The report lines of a check, without the closing count."""
    return [
        line for line in result.stdout.splitlines() if ": " in line and not line.endswith(SENTINEL)
    ]


@settings(max_examples=40, deadline=None)
@given(body=bodies)
def test_word_keeping_fixes_leave_the_body_reading_the_same(tmp_path_factory, body: str) -> None:
    tmp_path = tmp_path_factory.mktemp("body")
    before = check(tmp_path, body)
    fixed = body
    applied = 0
    for line in before.stdout.splitlines():
        if url := WORD_KEEPING_URL_FIX.search(line):
            fixed = fixed.replace(url.group(1), f"[{url.group(1)}]({url.group(1)})", 1)
            applied += 1
        elif code := WORD_KEEPING_CODE_FIX.search(line):
            fixed = fixed.replace(f"`{code.group(1)}`", code.group(1), 1)
            applied += 1
    after = check(tmp_path, fixed)
    assert len(reports_in(after)) == len(reports_in(before)) - applied, (fixed, after.stdout)
    assert rendered_text(fixed) == rendered_text(body), fixed


# The hook mode reads the tool call Claude Code is about to make, on stdin.


def hook(tool: str, tool_input: dict[str, object]) -> subprocess.CompletedProcess[str]:
    payload = {"tool_name": f"mcp__atlassian-rovo__{tool}", "tool_input": tool_input}
    return run("--hook", stdin=json.dumps(payload))


def test_hook_refuses_a_comment_with_code_inside_bold() -> None:
    result = hook("addCommentToJiraIssue", {"commentBody": "Hi.\n\n**Uses `x`.**"})
    assert result.returncode == 2
    assert "commentBody:3: code inside bold" in result.stderr


@pytest.mark.parametrize(
    ("tool", "tool_input"),
    [
        ("addCommentToJiraIssue", {"commentBody": f"[a label]({URL})"}),
        ("addCommentToJiraIssue", {"commentBody": f"See {URL}", "contentFormat": "adf"}),
        ("editJiraIssue", {"fields": {"summary": f"See {URL}"}}),
        ("createJiraIssue", {"summary": "x"}),
    ],
    ids=["clean comment", "adf comment", "edit without description", "create without description"],
)
def test_hook_lets_a_post_with_nothing_to_fix_through(
    tool: str, tool_input: dict[str, object]
) -> None:
    result = hook(tool, tool_input)
    assert result.returncode == 0, result.stderr
    assert result.stdout == result.stderr == ""


@pytest.mark.parametrize(
    ("tool", "tool_input", "field"),
    [
        ("createJiraIssue", {"description": f"See {URL}"}, "description"),
        ("editJiraIssue", {"fields": {"description": f"See {URL}"}}, "fields.description"),
    ],
    ids=["create", "edit"],
)
def test_hook_refuses_a_description_with_a_bare_url(
    tool: str, tool_input: dict[str, object], field: str
) -> None:
    result = hook(tool, tool_input)
    assert result.returncode == 2
    assert f"{field}:1: bare URL" in result.stderr


@pytest.mark.parametrize(
    "stdin",
    [
        "not json",
        json.dumps({"tool_name": "mcp__atlassian-rovo__addCommentToJiraIssue", "tool_input": {}}),
    ],
    ids=["not json", "comment without a body"],
)
def test_hook_refuses_a_post_it_cannot_read(stdin: str) -> None:
    result = run("--hook", stdin=stdin)
    assert result.returncode == 2
    assert result.stderr


def hook_matcher() -> re.Pattern[str]:
    settings_json = json.loads((REPO / "tools/claude/config/settings.json").read_text())
    groups = settings_json["hooks"]["PreToolUse"]
    matchers = [
        g["matcher"]
        for g in groups
        if any("check_jira_markdown.py" in h["command"] for h in g["hooks"])
    ]
    assert len(matchers) == 1, matchers
    return re.compile(matchers[0])


@pytest.mark.parametrize("server", ["atlassian-rovo", "claude_ai_Atlassian_MCP"])
@pytest.mark.parametrize("tool", ["addCommentToJiraIssue", "createJiraIssue", "editJiraIssue"])
def test_hook_runs_on_every_jira_post_tool(server: str, tool: str) -> None:
    assert hook_matcher().search(f"mcp__{server}__{tool}")


@pytest.mark.parametrize(
    "tool",
    [
        "mcp__atlassian-rovo__getJiraIssue",
        "mcp__atlassian-rovo__createConfluencePage",
        "Bash",
        "Edit",
    ],
)
def test_hook_does_not_run_on_any_other_tool(tool: str) -> None:
    assert not hook_matcher().search(tool)
