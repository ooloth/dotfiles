"""Black-box tests for check_jira_markdown.py.

Each test of the check runs the script as a subprocess, on a body written to a temporary file or on
hook input sent to stdin, so the script stays a single file. The tests of the hook's entry read
settings.json, and one test compares the dependency range with the check scripts.

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
CODE_IN_BOLD = re.compile(
    r"code inside bold: Jira ends the bold where `([^`]+)` starts\. Fix: (.*)"
)


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


@pytest.mark.parametrize(
    "body",
    ["See https://a.com/a|b here.\n", "See https://x.com/a&gt; here.\n"],
    ids=["pipe", "entity"],
)
def test_url_that_cannot_be_split_off_cleanly_gets_no_word_keeping_fix(
    tmp_path: Path, body: str
) -> None:
    result = check(tmp_path, body)
    assert reported_lines(result, "bare URL") == [1]
    assert "write it as [" not in result.stdout, result.stdout


@pytest.mark.parametrize(
    ("body", "fix"),
    [
        ("**Uses `x`** here.\n", "end the bold before the code"),
        ("**`x` is used** here.\n", "start the bold after the code"),
        ("**`x`** here.\n", "take the bold off the code"),
        ("**Uses `x` here.**\n", "end the bold before the code and start it again after"),
    ],
    ids=["code ends the bold", "code starts the bold", "code is the bold", "code in the middle"],
)
def test_code_inside_bold_fix_fits_where_the_code_sits(tmp_path: Path, body: str, fix: str) -> None:
    result = check(tmp_path, body)
    found = CODE_IN_BOLD.search(result.stdout)
    assert found is not None, result.stdout
    assert found.group(2) == fix or found.group(2).startswith(f"{fix}, or"), found.group(2)


def test_code_inside_bold_after_a_url_with_emphasis_is_reported_on_its_own_line(
    tmp_path: Path,
) -> None:
    body = "See https://e.com/__x__ and **the `x` docs**\nlater **the `x` docs**\n"
    assert reported_lines(check(tmp_path, body), "code inside bold") == [1, 2]


@pytest.mark.parametrize("newline", ["\r", "\r\n"], ids=["bare CR", "CRLF"])
def test_hook_checks_a_body_with_any_line_ending(newline: str) -> None:
    body = newline.join(["Hi.", "", "**Uses `x`** and https://x.com/y"])
    result = hook("addCommentToJiraIssue", {"commentBody": body})
    assert result.returncode == 2
    assert "crashed" not in result.stderr, result.stderr
    assert "commentBody:3: code inside bold" in result.stderr, result.stderr


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
BACKTICKS_OUT = "leave the backticks out"


def split_bold(body: str, code: str, fix: str) -> str:
    """Apply the fix the check printed for code inside bold, as an agent would.

    Whitespace beside a bold marker moves outside it, since `**see **` does not close the bold.
    """
    pattern = re.compile(r"\*\*([^*`]*?)`" + re.escape(code) + r"`([^*`]*?)\*\*")
    found = pattern.search(body)
    assert found is not None, (body, code)
    before, after = found.group(1).strip(), found.group(2).strip()
    span = f"`{code}`"
    if fix.startswith("take the bold off the code"):
        assert not before and not after, fix
        replacement = span
    elif fix.startswith("start the bold after the code"):
        assert not before and after, fix
        replacement = f"{span} **{after}**"
    elif fix.startswith("end the bold before the code and start it again after"):
        assert before and after, fix
        replacement = f"**{before}** {span} **{after}**"
    elif fix.startswith("end the bold before the code"):
        assert before and not after, fix
        replacement = f"**{before}** {span}"
    else:
        raise AssertionError(f"no fix to apply in: {fix}")
    return body[: found.start()] + replacement + body[found.end() :]


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
        [
            f"https://e.com/p{index}",
            f"https://e.com/a_b{index}",
            f"https://e.com/__i{index}__.py",
            f"https://e.com/a*b{index}*c",
            f"https://e.com/p{index}|b",
            f"https://e.com/a{index}&gt;",
            f"https://e.com/q{index}?a=1&amp;b=2",
        ]
    )
    beside_code = st.one_of(st.just(""), word)
    return st.one_of(
        word,
        url,
        code.map(lambda c: f"`{c}`"),
        st.tuples(beside_code, code, beside_code).map(
            lambda t: "**" + " ".join(part for part in (t[0], f"`{t[1]}`", t[2]) if part) + "**"
        ),
    )


bodies = st.integers(min_value=1, max_value=6).flatmap(
    lambda n: st.tuples(*(fragment(i) for i in range(n))).map(lambda parts: " ".join(parts) + "\n")
)


def reports_in(result: subprocess.CompletedProcess[str]) -> list[str]:
    """The report lines of a check, without the closing count."""
    return [
        line for line in result.stdout.splitlines() if ": " in line and not line.endswith(SENTINEL)
    ]


@settings(max_examples=60, deadline=None)
@given(body=bodies, take_backticks_out=st.booleans())
def test_word_keeping_fixes_leave_the_body_reading_the_same(
    tmp_path_factory: pytest.TempPathFactory, body: str, take_backticks_out: bool
) -> None:
    tmp_path = tmp_path_factory.mktemp("body")
    before = check(tmp_path, body)
    urls_as_written = {part for part in body.split() if part.startswith("https://")}
    fixed = body
    applied = 0
    for line in before.stdout.splitlines():
        if url := WORD_KEEPING_URL_FIX.search(line):
            # The link must point at the whole URL the body holds, not a piece of it.
            assert url.group(1) in urls_as_written, (line, body)
            fixed = fixed.replace(url.group(1), f"[{url.group(1)}]({url.group(1)})", 1)
            applied += 1
        elif bold := CODE_IN_BOLD.search(line):
            code, fix = bold.group(1), bold.group(2)
            if take_backticks_out and BACKTICKS_OUT in fix:
                fixed = fixed.replace(f"`{code}`", code, 1)
            else:
                fixed = split_bold(fixed, code, fix)
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
    ("tool", "tool_input", "field"),
    [
        ("addWorklogToJiraIssue", {"timeSpent": "1h", "commentBody": f"See {URL}"}, "commentBody"),
        ("createIssueLink", {"type": "Relates", "comment": f"See {URL}"}, "comment"),
    ],
    ids=["worklog", "issue link"],
)
def test_hook_refuses_a_worklog_or_link_comment_with_a_bare_url(
    tool: str, tool_input: dict[str, object], field: str
) -> None:
    result = hook(tool, tool_input)
    assert result.returncode == 2
    assert f"{field}:1: bare URL" in result.stderr


@pytest.mark.parametrize(
    ("tool", "tool_input"),
    [
        ("addWorklogToJiraIssue", {"timeSpent": "1h"}),
        ("createIssueLink", {"type": "Relates"}),
    ],
    ids=["worklog without a comment", "issue link without a comment"],
)
def test_hook_lets_a_worklog_or_link_without_a_comment_through(
    tool: str, tool_input: dict[str, object]
) -> None:
    result = hook(tool, tool_input)
    assert result.returncode == 0, result.stderr


def post(tool: str, tool_input: object) -> str:
    return json.dumps({"tool_name": f"mcp__atlassian-rovo__{tool}", "tool_input": tool_input})


@pytest.mark.parametrize(
    "stdin",
    [
        "not json",
        "",
        "[]",
        "null",
        json.dumps({"tool_name": "mcp__atlassian-rovo__addCommentToJiraIssue"}),
        post("addCommentToJiraIssue", {}),
        post("addCommentToJiraIssue", {"commentBody": 5}),
        post("getJiraIssue", {}),
    ],
    ids=[
        "not json",
        "empty",
        "array",
        "null",
        "no tool_input",
        "comment without a body",
        "comment body not a string",
        "not a post tool",
    ],
)
def test_hook_refuses_a_post_it_cannot_read(stdin: str) -> None:
    result = run("--hook", stdin=stdin)
    assert result.returncode == 2
    assert result.stderr


def test_a_body_file_and_hook_together_are_refused(tmp_path: Path) -> None:
    path = tmp_path / "body.md"
    path.write_text("Fine.\n")
    assert run(str(path), "--hook").returncode == 2


# A crash must exit 2, because the hook lets any other non-zero exit through unless onFailure blocks
# it, and the skill reads exit 1 as a list of fixes.
CRASH = """
import runpy, sys
import markdown_it
def broken(*args, **kwargs):
    raise RuntimeError("parse failed")
markdown_it.MarkdownIt.parse = broken
sys.argv = [sys.argv[1], *sys.argv[2:]]
runpy.run_path(sys.argv[0], run_name="__main__")
"""


@pytest.mark.parametrize("mode", ["file", "hook"])
def test_a_crash_exits_2(tmp_path: Path, mode: str) -> None:
    path = tmp_path / "body.md"
    path.write_text("Fine.\n")
    args = ["--hook"] if mode == "hook" else [str(path)]
    result = subprocess.run(
        [sys.executable, "-I", "-c", CRASH, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        input=post("addCommentToJiraIssue", {"commentBody": "Fine."}),
    )
    assert result.returncode == 2, result.stderr
    assert "The check crashed" in result.stderr


def hook_entry() -> dict[str, object]:
    settings_json = json.loads((REPO / "tools/claude/config/settings.json").read_text())
    entries = [
        (group["matcher"], hook)
        for group in settings_json["hooks"]["PreToolUse"]
        for hook in group["hooks"]
        if "check_jira_markdown.py" in hook["command"]
    ]
    assert len(entries) == 1, entries
    matcher, entry = entries[0]
    return {"matcher": matcher, **entry}


def hook_matcher() -> re.Pattern[str]:
    return re.compile(str(hook_entry()["matcher"]))


def test_hook_refuses_the_post_when_the_check_cannot_run() -> None:
    # A uv failure exits 1, a missing uv 127, and a timeout has no exit code: Claude Code lets each
    # of these through unless the hook sets onFailure to block.
    entry = hook_entry()
    assert entry["onFailure"] == "block"
    assert isinstance(entry["timeout"], int)


def test_hook_runs_this_script_in_hook_mode() -> None:
    words = str(hook_entry()["command"]).split()
    assert words[:3] == ["uv", "run", "--quiet"] and "--script" in words, words
    assert words[-1] == "--hook", words
    script = words[-2]
    assert script.startswith("~/Repos/ooloth/dotfiles/"), script
    assert REPO / script.removeprefix("~/Repos/ooloth/dotfiles/") == SCRIPT, script


@pytest.mark.parametrize("server", ["atlassian-rovo", "claude_ai_Atlassian_MCP"])
@pytest.mark.parametrize(
    "tool",
    [
        "addCommentToJiraIssue",
        "createJiraIssue",
        "editJiraIssue",
        "addWorklogToJiraIssue",
        "createIssueLink",
    ],
)
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
