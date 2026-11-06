"""Black-box tests for check_jira_markdown.py.

Each test writes a markdown body to a temporary file and runs the script on it as a subprocess, so
the script stays a single file.

Run:
  uv run --with pytest --with markdown-it-py pytest \
    tools/agents/config/skills/use-jira/scripts/test_check_jira_markdown.py
"""

import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).with_name("check_jira_markdown.py")
URL = "https://github.com/example/repo/pull/7"


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-I", str(SCRIPT), *args], capture_output=True, text=True
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
