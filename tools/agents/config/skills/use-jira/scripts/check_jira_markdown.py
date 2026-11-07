#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["markdown-it-py>=4,<5"]
# ///
"""Say whether Jira's markdown conversion would post a body with its formatting or links broken.

The use-jira skill runs this on every body it posts through the Atlassian MCP tool with
`contentFormat: "markdown"`, and in Claude Code a PreToolUse hook runs it with `--hook` on every such
post, refusing the post when it finds something. That conversion succeeds on each construct
reported here, and on all but the untested autolink it renders it wrong, so nothing at post time
says anything went wrong:

  code inside bold    Jira ends the bold where the code starts.
  code as link text   Jira keeps the code and drops the link.
  bare URL            Jira posts it as text, not a link.
  autolink            <https://...> is untested in Jira, so the bracket form is asked for instead.

A URL in a code span or code block is never reported: there it is a command to copy, not a link.
A fix that keeps every word is offered only when the fixed text still parses to the same
characters, so code such as `__init__` is never offered as bare text inside bold. A bare URL's
`[url](url)` fix is also withheld when the URL stops at `<`, `>` or `|`, because the URL may go on
past it and the link would point at only part of it.
Structure Jira cannot hold at all, such as a table inside a list item, is not checked here, because
the tool refuses the whole post and posts nothing.

The body is parsed as CommonMark with tables, the closest model of Jira's converter available.
acli posts ADF, so it is not checked by this.

Usage:
  check_jira_markdown.py <body.md>
  check_jira_markdown.py --hook < <PreToolUse hook input JSON>

Exit codes for a file:
  0  nothing to fix; post the file's text unchanged
  1  each problem is printed as `<file>:<line>: <kind>: <what happens>. Fix: <how>`, and the last
     line ends `post nothing until then`, which tells this list from uv failing with exit 1
  2  the body could not be checked, or the check crashed; stderr says why. Never read this as 0.

Exit codes for --hook:
  0  the post goes ahead: nothing to fix, or no markdown body to check
  2  the post is refused: each problem, or why the post could not be read, is on stderr, where
     Claude Code shows it to the agent as the reason
"""

import argparse
import json
import re
import sys
import traceback
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import NewType, assert_never

try:
    from markdown_it import MarkdownIt
    from markdown_it.token import Token
except ImportError as error:
    # Exit 1 means a list of problems to fix, so a missing dependency must not end with it.
    print(f"Could not import markdown-it-py ({error}); run this with `uv run`.", file=sys.stderr)
    sys.exit(2)

LineNumber = NewType("LineNumber", int)  # 1-based, as an editor shows it

# A URL in prose or a table cell runs to whitespace, `<`, `>` or `|`. Punctuation after it ends a
# sentence rather than belonging to it, and so does a `)` the URL never opened.
TRAILING_PUNCTUATION = ".,;:!?'\"]"
# A `;` that closes an HTML entity such as `&gt;` belongs to it, so trimming it would change what
# the URL shows.
ENDS_IN_ENTITY = re.compile(r"&(?:#[0-9]+|#[xX][0-9a-fA-F]+|[A-Za-z][A-Za-z0-9]*);$")
# The characters other than whitespace that end a URL run. A URL stopped by one of them may go on
# past it, so a fix that links only the part before it could link the wrong place.
URL_STOPS = "<>|"
URL_RUN = re.compile(r"https?://[^\s" + re.escape(URL_STOPS) + "]+")
SENTINEL = "post nothing until then"

PARSER = MarkdownIt("commonmark").enable("table")


def trimmed(run: str) -> str:
    while (
        run
        and not ENDS_IN_ENTITY.search(run)
        and (
            run[-1] in TRAILING_PUNCTUATION or (run[-1] == ")" and run.count(")") > run.count("("))
        )
    ):
        run = run[:-1]
    return run


def urls_in(text: str) -> list[str]:
    return [trimmed(run) for run in URL_RUN.findall(text)]


def visible_text(tokens: list[Token]) -> str:
    """The characters a reader sees in a run of inline tokens, with formatting and targets dropped."""
    seen = []
    for token in tokens:
        match token.type:
            case "text" | "code_inline":
                seen.append(token.content)
            case "softbreak" | "hardbreak":
                seen.append("\n")
            case "image":
                seen.append(visible_text(token.children or []))
            case _:
                pass
    return "".join(seen)


def reads_as_written(source: str, start: int, end: int, replacement: str, written: str) -> bool:
    """Whether replacing source[start:end] shows a reader `written` there, character for character.

    The expected reading puts `written` in a code span, the one construct that shows its text
    literally, so emphasis characters inside a URL or a piece of code cannot hide in both readings.
    """
    fence = "`" * (max((len(run) for run in re.findall("`+", written)), default=0) + 1)
    literal = f"{fence} {written} {fence}"
    expected = PARSER.parseInline(source[:start] + literal + source[end:])[0].children or []
    after = PARSER.parseInline(source[:start] + replacement + source[end:])[0].children or []
    return visible_text(after) == visible_text(expected)


def code_span_source(markup: str, code: str) -> re.Pattern[str]:
    """How a code span reads in the source: markdown-it turns its line breaks into spaces."""
    body = "".join(r"\s" if char == " " else re.escape(char) for char in code)
    return re.compile(re.escape(markup) + r"\s?" + body + r"\s?" + re.escape(markup))


@dataclass(frozen=True)
class Body:
    path: Path
    text: str


@dataclass(frozen=True)
class Unreadable:
    path: Path
    reason: str


# Each breakage below records whether its fix that keeps every word, when it has one, leaves the
# body reading the same and, for a URL, links all of it. When it would not, only a fix that changes
# the text is offered.


class BoldSplit(Enum):
    """Where the code sits in its bold phrase, which decides how the bold is split around it."""

    CODE_IS_BOLD = "take the bold off the code"
    CODE_STARTS_BOLD = "start the bold after the code"
    CODE_ENDS_BOLD = "end the bold before the code"
    CODE_INSIDE_BOLD = "end the bold before the code and start it again after"


@dataclass(frozen=True)
class CodeInBold:
    line: LineNumber
    code: str
    split: BoldSplit
    renders_as_written: bool


@dataclass(frozen=True)
class CodeAsLinkText:
    line: LineNumber
    code: str
    href: str
    renders_as_written: bool


@dataclass(frozen=True)
class BareUrl:
    line: LineNumber
    url: str
    renders_as_written: bool


@dataclass(frozen=True)
class Autolink:
    line: LineNumber
    text: str
    href: str
    renders_as_written: bool


Breakage = CodeInBold | CodeAsLinkText | BareUrl | Autolink


@dataclass(frozen=True)
class CheckFile:
    path: Path


@dataclass(frozen=True)
class CheckHookInput:
    pass


Mode = CheckFile | CheckHookInput


def parse_args(argv: list[str]) -> Mode:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "body", type=Path, nargs="?", help="the markdown file whose text will be posted"
    )
    parser.add_argument(
        "--hook", action="store_true", help="read a PreToolUse hook's input on stdin instead"
    )
    args = parser.parse_args(argv)
    match (args.hook, args.body):
        case (True, None):
            return CheckHookInput()
        case (False, Path() as path):
            return CheckFile(path)
        case _:
            parser.error("pass either a body file or --hook, not both or neither")


def read_body(path: Path) -> Body | Unreadable:
    try:
        return Body(path, path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError) as error:
        return Unreadable(path, str(error))


class SourceCursor:
    """Where the walk over one paragraph's tokens has reached in that paragraph's source.

    Each construct's line is found by searching the source forward from the last match, because a
    code span hides the line breaks inside it from the tokens. Where the source search finds
    nothing, the line breaks the tokens show are counted instead.
    """

    def __init__(self, source: str, first_line: int, line_count: int) -> None:
        self.source = source
        self.first_line = first_line
        self.line_count = line_count
        self.position = 0
        self.breaks_seen = 0
        # Where the last URL read whole from the source ends. Emphasis inside it puts later pieces
        # of it in tokens of their own, and those pieces are not URLs to report again.
        self.url_end = 0

    def locate(self, pattern: re.Pattern[str]) -> tuple[LineNumber, re.Match[str] | None]:
        match = pattern.search(self.source, self.position)
        if match is None:
            n = self.first_line + self.breaks_seen
        else:
            n = self.first_line + self.source.count("\n", 0, match.start())
            self.position = match.end()
        assert 1 <= n <= self.line_count, f"line {n} is outside the body's {self.line_count} lines"
        return LineNumber(n), match

    def keeps_reading(self, match: re.Match[str] | None, replacement: str, written: str) -> bool:
        # A construct whose place in the source was not found gets no fix that keeps every word.
        return match is not None and reads_as_written(
            self.source, match.start(), match.end(), replacement, written
        )

    def skip_destination(self, target: str) -> None:
        # A link or image's target follows its text in the source, and no token holds it, so a
        # bare URL further on must not be matched there.
        match = re.compile(r"\(\s*<?" + re.escape(target)).search(self.source, self.position)
        if match is not None:
            self.position = match.end()


def bare_urls(cursor: SourceCursor, text: str) -> list[BareUrl]:
    """The bare URLs in one text token, each read whole from the source."""
    found: list[BareUrl] = []
    start = cursor.source.find(text, cursor.position) if text else -1
    if start >= 0:
        cursor.position = start
    for url in urls_in(text):
        line, match = cursor.locate(re.compile(re.escape(url)))
        cleanly_ended = True
        if match is not None:
            if match.start() < cursor.url_end:
                continue
            # Emphasis inside a URL splits it across tokens, so the URL as written is read from
            # the source, where it runs on past this token.
            whole = URL_RUN.match(cursor.source, match.start())
            assert whole is not None, "a URL found in the source is matched there"
            stopped_by = cursor.source[whole.end() : whole.end() + 1]
            cleanly_ended = stopped_by == "" or stopped_by not in URL_STOPS
            url = trimmed(whole.group())
            cursor.url_end = match.start() + len(url)
            match = re.compile(re.escape(url)).match(cursor.source, match.start())
        readable = cleanly_ended and cursor.keeps_reading(match, f"[{url}]({url})", url)
        found.append(BareUrl(line, url, readable))
    if start >= 0:
        cursor.position = max(cursor.position, start + len(text))
    return found


def has_text_beside(children: list[Token], index: int, step: int, edge: str) -> bool:
    """Whether a reader sees text between children[index] and the bold's edge in one direction."""
    i = index + step
    while 0 <= i < len(children) and children[i].type != edge:
        if children[i].type in ("text", "code_inline") and children[i].content.strip():
            return True
        i += step
    return False


def bold_split(children: list[Token], index: int) -> BoldSplit:
    match (
        has_text_beside(children, index, -1, "strong_open"),
        has_text_beside(children, index, 1, "strong_close"),
    ):
        case (False, False):
            return BoldSplit.CODE_IS_BOLD
        case (False, True):
            return BoldSplit.CODE_STARTS_BOLD
        case (True, False):
            return BoldSplit.CODE_ENDS_BOLD
        case (True, True):
            return BoldSplit.CODE_INSIDE_BOLD
        case _ as unreachable:
            raise AssertionError(unreachable)


def inline_breakages(inline: Token, line_count: int) -> list[Breakage]:
    """The breakages in one paragraph, heading or table cell."""
    assert inline.map is not None, "markdown-it-py gave an inline token no line map"
    cursor = SourceCursor(inline.content, inline.map[0] + 1, line_count)
    bold_depth = 0
    link: Token | None = None
    found: list[Breakage] = []
    children = inline.children or []

    for index, child in enumerate(children):
        match child.type:
            case "softbreak" | "hardbreak":
                cursor.breaks_seen += 1
            case "strong_open":
                bold_depth += 1
            case "strong_close":
                bold_depth -= 1
            case "link_open":
                link = child
                if child.markup == "autolink":
                    following = children[index + 1] if index + 1 < len(children) else None
                    text = following.content if following is not None else ""
                    href = str(child.attrGet("href"))
                    line, match = cursor.locate(re.compile(re.escape("<" + text + ">")))
                    readable = cursor.keeps_reading(match, f"[{text}]({href})", text)
                    found.append(Autolink(line, text, href, readable))
            case "link_close":
                if link is not None and link.markup != "autolink":
                    cursor.skip_destination(str(link.attrGet("href")))
                link = None
            case "image":
                cursor.skip_destination(str(child.attrGet("src")))
            case "code_inline":
                pattern = code_span_source(child.markup, child.content)
                line, match = cursor.locate(pattern)
                in_link = link is not None and link.markup != "autolink"
                if not in_link and bold_depth == 0:
                    continue
                readable = cursor.keeps_reading(match, child.content, child.content)
                if link is not None and in_link:
                    href = str(link.attrGet("href"))
                    found.append(CodeAsLinkText(line, child.content, href, readable))
                else:
                    split = bold_split(children, index)
                    found.append(CodeInBold(line, child.content, split, readable))
            case "text" if link is None:
                found.extend(bare_urls(cursor, child.content))
            case _:
                pass
    return found


def find_breakages(text: str) -> tuple[Breakage, ...]:
    # markdown-it reads a lone `\r` as a line break too, so every line ending is counted as one.
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    line_count = text.count("\n") + 1
    found: list[Breakage] = []
    for token in PARSER.parse(text):
        if token.type == "inline":
            found.extend(inline_breakages(token, line_count))
    return tuple(found)


LABEL_FIX = "give it a label of its own, which adds words to approve"


def report(breakage: Breakage) -> str:
    match breakage:
        case CodeInBold(line, code, split, renders_as_written):
            alternative = (
                ", or leave the backticks out of the bold phrase" if renders_as_written else ""
            )
            return (
                f"{line}: code inside bold: Jira ends the bold where `{code}` starts."
                f" Fix: {split.value}{alternative}"
            )
        case CodeAsLinkText(line, code, href, renders_as_written):
            fix = (
                "write the link text without backticks"
                if renders_as_written
                else "write the link text without the code, which changes words to approve"
            )
            return (
                f"{line}: code as link text: Jira keeps `{code}` and drops the link to {href}."
                f" Fix: {fix}"
            )
        case BareUrl(line, url, renders_as_written):
            fix = f"write it as [{url}]({url}), or {LABEL_FIX}" if renders_as_written else LABEL_FIX
            return (
                f"{line}: bare URL: Jira posts {url} as text, not a link. Fix: {fix}, or put it in"
                " inline code if it is not meant to be opened"
            )
        case Autolink(line, text, href, renders_as_written):
            fix = f"write it as [{text}]({href})" if renders_as_written else LABEL_FIX
            return f"{line}: autolink: how Jira converts <{text}> is untested. Fix: {fix}"
        case _:
            assert_never(breakage)


# The Jira MCP tools that post a body. parse_hook_input reads each one's body field.
POST_TOOLS = (
    "addCommentToJiraIssue",
    "createJiraIssue",
    "editJiraIssue",
    "addWorklogToJiraIssue",
    "createIssueLink",
)


@dataclass(frozen=True)
class JiraPost:
    field: str
    text: str


@dataclass(frozen=True)
class NothingToCheck:
    pass


@dataclass(frozen=True)
class MalformedHookInput:
    reason: str


def parse_hook_input(raw: str) -> JiraPost | NothingToCheck | MalformedHookInput:
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as error:
        return MalformedHookInput(f"the hook input is not JSON: {error}")
    if not isinstance(payload, dict):
        return MalformedHookInput("the hook input is not a JSON object")
    tool = str(payload.get("tool_name", ""))
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        return MalformedHookInput(f"{tool} has no tool_input object")
    if tool_input.get("contentFormat") == "adf":
        return NothingToCheck()
    match tool.rsplit("__", 1)[-1]:
        case "addCommentToJiraIssue":
            body = tool_input.get("commentBody")
            if not isinstance(body, str):
                return MalformedHookInput(f"{tool} has no commentBody string")
            return JiraPost("commentBody", body)
        case "createJiraIssue":
            body = tool_input.get("description")
            return JiraPost("description", body) if isinstance(body, str) else NothingToCheck()
        case "editJiraIssue":
            fields = tool_input.get("fields")
            body = fields.get("description") if isinstance(fields, dict) else None
            return (
                JiraPost("fields.description", body) if isinstance(body, str) else NothingToCheck()
            )
        case "addWorklogToJiraIssue":
            body = tool_input.get("commentBody")
            return JiraPost("commentBody", body) if isinstance(body, str) else NothingToCheck()
        case "createIssueLink":
            body = tool_input.get("comment")
            return JiraPost("comment", body) if isinstance(body, str) else NothingToCheck()
        case other:
            return MalformedHookInput(f"{other} is not one of the Jira post tools {POST_TOOLS}")


ExitCode = NewType("ExitCode", int)  # the codes the module docstring lists


def check_file(path: Path) -> ExitCode:
    match read_body(path):
        case Unreadable(path, reason):
            print(f"Could not read {path}: {reason}", file=sys.stderr)
            return ExitCode(2)
        case Body(path, text):
            breakages = find_breakages(text)
            if not breakages:
                return ExitCode(0)
            for breakage in breakages:
                print(f"{path}:{report(breakage)}")
            print(f"{len(breakages)} to fix before posting; {SENTINEL}")
            return ExitCode(1)
        case _ as unreachable:
            assert_never(unreachable)


def check_hook_input(raw: str) -> ExitCode:
    match parse_hook_input(raw):
        case NothingToCheck():
            return ExitCode(0)
        case MalformedHookInput(reason):
            print(
                f"The Jira markdown check could not read this post, so it is refused: {reason}",
                file=sys.stderr,
            )
            return ExitCode(2)
        case JiraPost(field, text):
            breakages = find_breakages(text)
            if not breakages:
                return ExitCode(0)
            for breakage in breakages:
                print(f"{field}:{report(breakage)}", file=sys.stderr)
            print(
                f"Refused: Jira would post {len(breakages)} of these wrong. Fix the body as the"
                " use-jira skill describes and post again.",
                file=sys.stderr,
            )
            return ExitCode(2)
        case _ as unreachable:
            assert_never(unreachable)


def main() -> ExitCode:
    match parse_args(sys.argv[1:]):
        case CheckFile(path):
            return check_file(path)
        case CheckHookInput():
            return check_hook_input(sys.stdin.read())
        case _ as unreachable:
            assert_never(unreachable)


if __name__ == "__main__":
    try:
        code = main()
    except Exception:
        # Exit 1 means a list of problems to fix, so a crash must not end with it.
        traceback.print_exc()
        print("The check crashed, so the body was not checked.", file=sys.stderr)
        sys.exit(2)
    sys.exit(code)
