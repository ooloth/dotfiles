#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["markdown-it-py>=4,<5"]
# ///
"""Say whether Jira's markdown conversion would post a body with its formatting or links broken.

The use-jira skill runs this on every body it posts through the Atlassian MCP tool with
`contentFormat: "markdown"`. That conversion succeeds on each construct reported here and renders it
wrong, so nothing at post time says anything went wrong:

  code inside bold    Jira ends the bold where the code starts.
  code as link text   Jira keeps the code and drops the link.
  bare URL            Jira posts it as text, not a link.
  autolink            <https://...> is untested in Jira, so the form Jira is known to link is used.

Code spans and code blocks are never reported: a URL there is a command to copy, not a link.
Structure Jira cannot hold at all, such as a table inside a list item, is not checked here, because
the tool refuses the whole post and posts nothing.

The body is parsed as CommonMark with tables, the closest model of Jira's converter available.
acli posts ADF, so it is not checked by this.

Usage:
  check_jira_markdown.py <body.md>

Exit codes:
  0  nothing to fix; post the file's text unchanged
  1  each problem is printed as `<file>:<line>: <kind>: <what happens>. Fix: <how>`
  2  the body could not be checked, or the check crashed; stderr says why. Never read this as 0.
"""

import argparse
import re
import sys
import traceback
from dataclasses import dataclass
from pathlib import Path
from typing import NewType, assert_never

from markdown_it import MarkdownIt
from markdown_it.token import Token

LineNumber = NewType("LineNumber", int)  # 1-based, as an editor shows it

# A URL in prose or a table cell runs to whitespace, `<`, `>` or `|`. Punctuation after it ends a
# sentence rather than belonging to it, and so does a `)` the URL never opened.
URL_RUN = re.compile(r"https?://[^\s<>|]+")
TRAILING_PUNCTUATION = ".,;:!?'\"]"


def urls_in(text: str) -> list[str]:
    urls = []
    for run in URL_RUN.findall(text):
        while run and (
            run[-1] in TRAILING_PUNCTUATION or (run[-1] == ")" and run.count(")") > run.count("("))
        ):
            run = run[:-1]
        urls.append(run)
    return urls


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


@dataclass(frozen=True)
class CodeInBold:
    line: LineNumber
    code: str


@dataclass(frozen=True)
class CodeAsLinkText:
    line: LineNumber
    code: str
    href: str


@dataclass(frozen=True)
class BareUrl:
    line: LineNumber
    url: str


@dataclass(frozen=True)
class Autolink:
    line: LineNumber
    text: str
    href: str


Breakage = CodeInBold | CodeAsLinkText | BareUrl | Autolink


@dataclass(frozen=True)
class Clean:
    pass


@dataclass(frozen=True)
class Broken:
    breakages: tuple[Breakage, ...]


def parse_args(argv: list[str]) -> Path:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("body", type=Path, help="the markdown file whose text will be posted")
    return parser.parse_args(argv).body


def read_body(path: Path) -> Body | Unreadable:
    try:
        return Body(path, path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError) as error:
        return Unreadable(path, str(error))


def inline_breakages(inline: Token, line_count: int) -> list[Breakage]:
    """The breakages in one paragraph, heading or table cell.

    Each one's line is found by searching the paragraph's source forward from the last match,
    because a code span hides the line breaks inside it from the tokens. Where the source search
    finds nothing, the line breaks the tokens show are counted instead.
    """
    assert inline.map is not None, "markdown-it-py gave an inline token no line map"
    first_line = inline.map[0] + 1
    source = inline.content
    cursor = 0
    breaks_seen = 0
    bold_depth = 0
    link: Token | None = None
    found: list[Breakage] = []
    children = inline.children or []

    def locate(pattern: re.Pattern[str]) -> LineNumber:
        nonlocal cursor
        match = pattern.search(source, cursor)
        if match is None:
            n = first_line + breaks_seen
        else:
            n = first_line + source.count("\n", 0, match.start())
            cursor = match.end()
        assert 1 <= n <= line_count, f"line {n} is outside the body's {line_count} lines"
        return LineNumber(n)

    for index, child in enumerate(children):
        match child.type:
            case "softbreak" | "hardbreak":
                breaks_seen += 1
            case "strong_open":
                bold_depth += 1
            case "strong_close":
                bold_depth -= 1
            case "link_open":
                link = child
                if child.markup == "autolink":
                    following = children[index + 1] if index + 1 < len(children) else None
                    text = following.content if following is not None else ""
                    line = locate(re.compile(re.escape("<" + text + ">")))
                    found.append(Autolink(line, text, str(child.attrGet("href"))))
            case "link_close":
                link = None
            case "code_inline":
                pattern = code_span_source(child.markup, child.content)
                if link is not None and link.markup != "autolink":
                    href = str(link.attrGet("href"))
                    found.append(CodeAsLinkText(locate(pattern), child.content, href))
                elif bold_depth > 0:
                    found.append(CodeInBold(locate(pattern), child.content))
                else:
                    locate(pattern)
            case "text" if link is None:
                start = source.find(child.content, cursor) if child.content else -1
                if start >= 0:
                    cursor = start
                found.extend(
                    BareUrl(locate(re.compile(re.escape(url))), url)
                    for url in urls_in(child.content)
                )
                if start >= 0:
                    cursor = max(cursor, start + len(child.content))
            case _:
                pass
    return found


def find_breakages(text: str) -> tuple[Breakage, ...]:
    parser = MarkdownIt("commonmark").enable("table")
    line_count = text.count("\n") + 1
    found: list[Breakage] = []
    for token in parser.parse(text):
        if token.type == "inline":
            found.extend(inline_breakages(token, line_count))
    return tuple(found)


def verdict(breakages: tuple[Breakage, ...]) -> Clean | Broken:
    return Broken(breakages) if breakages else Clean()


def report(breakage: Breakage) -> str:
    match breakage:
        case CodeInBold(line, code):
            return (
                f"{line}: code inside bold: Jira ends the bold where `{code}` starts. Fix: end the"
                " bold before the code, or leave the backticks out of the bold phrase"
            )
        case CodeAsLinkText(line, code, href):
            return (
                f"{line}: code as link text: Jira keeps `{code}` and drops the link to {href}."
                " Fix: write the link text without backticks"
            )
        case BareUrl(line, url):
            return (
                f"{line}: bare URL: Jira posts {url} as text, not a link. Fix: write it as"
                f" [{url}]({url}), or with a label of its own, which adds words to approve, or put"
                " it in inline code if it is not meant to be opened"
            )
        case Autolink(line, text, href):
            return (
                f"{line}: autolink: how Jira converts <{text}> is untested. Fix: write it as"
                f" [{text}]({href})"
            )
        case _:
            assert_never(breakage)


def main() -> None:
    match read_body(parse_args(sys.argv[1:])):
        case Unreadable(path, reason):
            print(f"Could not read {path}: {reason}", file=sys.stderr)
            sys.exit(2)
        case Body(path, text):
            match verdict(find_breakages(text)):
                case Clean():
                    sys.exit(0)
                case Broken(breakages):
                    for breakage in breakages:
                        print(f"{path}:{report(breakage)}")
                    print(f"{len(breakages)} to fix before posting; post nothing until then")
                    sys.exit(1)
                case _ as unreachable:
                    assert_never(unreachable)
        case _ as unreachable:
            assert_never(unreachable)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Exit 1 means a list of problems to fix, so a crash must not end with it.
        traceback.print_exc()
        print("The check crashed, so the body was not checked.", file=sys.stderr)
        sys.exit(2)
