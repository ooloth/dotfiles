#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["markdown-it-py>=4,<5"]
# ///
"""Say whether a PR body would post with its layout broken, before it is posted.

The write-pr-description skill runs this on every body it hands back. GitHub renders a broken
layout without complaint, so these are found only by checking:

  Rendered through GitHub's markdown API (`gh api markdown`), the HTML has
    every <details> directly inside an <li>, starting with its <summary>
    every <summary> directly inside a <details>; a row whose content fell out of its list item
      leaves its summary outside, and GitHub gives the emptied <details> a <summary>Details</summary>
    no empty code block, which is what a block whose lines sit left of its fence becomes
    no ``` shown as text outside a code block
    no code block left outside the task-list step it belongs to

  In the markdown itself,
    no <summary> or </details> on a list item's line, and no <details> on a bullet's line
      (`1. <details>` is how a row starts, so a numbered <details> is allowed)
    no fenced code block in the What section
    at least one bullet, and only bullets, under each `#### 🧾 Proven by` heading
    no property number such as P1
    no link to a local path: ](/ , ](~ or ](file:
    no Pre-merge heading, since After merge is the outline's last row

  With --live-copy and --pr, the PR's description on GitHub is still the copy that was read, so
  posting the body cannot overwrite someone else's edit.

  With --commands, every code block under a `#### 🔍 Verification steps` heading or inside the
  Setup or Clean up row appears, as written, in the file of commands that were actually run.

Usage:
  check_pr_body.py <body.md> --repo <owner>/<repo> [--live-copy <saved.md> --pr <n>]
                   [--commands <commands file>]

Exit codes:
  0  every check passed; post the file's text unchanged
  1  each problem is printed as `<file>:<line>: <kind>: <what happens>. Fix: <how>`, or with
     `rendered` in place of the line for one found in the HTML, and the last line ends
     `post nothing until then`, which tells this list from uv failing with exit 1
  2  a check could not run (gh missing or failing, a file unreadable, bad arguments), or the
     script crashed; stderr says which. Never read this as 0.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import traceback
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from typing import Literal, NewType, assert_never

try:
    from markdown_it import MarkdownIt
    from markdown_it.token import Token
except ImportError as error:
    # Exit 1 means a list of problems to fix, so a missing dependency must not end with it.
    print(f"Could not import markdown-it-py ({error}); run this with `uv run`.", file=sys.stderr)
    sys.exit(2)

LineNumber = NewType("LineNumber", int)  # 1-based, as an editor shows it
Repo = NewType("Repo", str)  # owner/name
PrNumber = NewType("PrNumber", int)
ExitCode = NewType("ExitCode", int)  # the codes the module docstring lists

SENTINEL = "post nothing until then"
REPO_PATTERN = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")
PARSER = MarkdownIt("commonmark").enable("table")


# Where a problem is when it has no line: in the rendered HTML, or in the PR's live body.
Elsewhere = Literal["rendered", "live"]


@dataclass(frozen=True)
class Problem:
    """One thing to fix, at a line of the body or elsewhere."""

    where: LineNumber | Elsewhere
    kind: str
    what: str
    fix: str


# ---------------------------------------------------------------------------------------------
# The rendered HTML


class Element:
    """One element of the rendered HTML, with its children in order. Text children are strings."""

    def __init__(self, tag: str, attrs: dict[str, str], parent: Element | None) -> None:
        self.tag = tag
        self.attrs = attrs
        self.parent = parent
        self.children: list[Element | str] = []

    def elements(self) -> list[Element]:
        return [child for child in self.children if isinstance(child, Element)]

    def walk(self) -> Iterator[Element]:
        yield self
        for child in self.elements():
            yield from child.walk()

    def text(self) -> str:
        return "".join(child if isinstance(child, str) else child.text() for child in self.children)

    def classes(self) -> list[str]:
        return self.attrs.get("class", "").split()

    def ancestors(self) -> Iterator[Element]:
        node = self.parent
        while node is not None:
            yield node
            node = node.parent


VOID_TAGS = {"area", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "wbr"}
HEADINGS = {"h1", "h2", "h3", "h4", "h5", "h6"}


class TreeBuilder(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.root = Element("root", {}, None)
        self.current = self.root

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        element = Element(tag, {k: v or "" for k, v in attrs}, self.current)
        self.current.children.append(element)
        if tag not in VOID_TAGS:
            self.current = element

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.current.children.append(Element(tag, {k: v or "" for k, v in attrs}, self.current))

    def handle_endtag(self, tag: str) -> None:
        # An end tag with no open element of its name is ignored, as a browser does.
        node: Element | None = self.current
        while node is not None and node.tag != tag:
            node = node.parent
        if node is not None and node.parent is not None:
            self.current = node.parent

    def handle_data(self, data: str) -> None:
        self.current.children.append(data)


def parse_html(html: str) -> Element:
    builder = TreeBuilder()
    builder.feed(html)
    builder.close()
    return builder.root


def squeeze(text: str) -> str:
    return " ".join(text.split())


def place(element: Element) -> str:
    """Where an element is, named by the summary of the row that holds it."""
    for node in [element, *element.ancestors()]:
        if node.tag == "details":
            summary = next((child for child in node.elements() if child.tag == "summary"), None)
            if summary is not None:
                return f'in the row "{squeeze(summary.text())}"'
            return "in a row with no summary"
    return "outside every row"


def holds_code(element: Element) -> bool:
    return element.tag == "pre" or (
        element.tag == "div" and any(child.tag == "pre" for child in element.elements())
    )


def rendered(kind: str, what: str, fix: str) -> Problem:
    return Problem("rendered", kind, what, fix)


SUMMARY_FIX = (
    "put `<summary>…</summary>` alone on the line after `<details>`, indented to the row's text,"
    " with no list marker"
)


def details_problems(details: Element) -> list[Problem]:
    found: list[Problem] = []
    if details.parent is None or details.parent.tag != "li":
        found.append(
            rendered(
                "row outside a list item",
                f"a <details> {place(details)} is not directly inside a list item, so it drops"
                " out of the numbered outline",
                "start the row with `1. <details>` and indent everything in it to the row's text",
            )
        )
    first = next(
        (child for child in details.children if not (isinstance(child, str) and not child.strip())),
        None,
    )
    # A <details> always has a summary here: GitHub gives one with none a <summary>Details</summary>
    # of its own, so a row whose content fell out shows as a summary outside its row instead.
    if not (isinstance(first, Element) and first.tag == "summary"):
        before = squeeze(first) if isinstance(first, str) else f"<{first.tag if first else ''}>"
        found.append(
            rendered(
                "text before summary",
                f'"{before}" comes before the <summary> {place(details)}, usually a list marker'
                " on the summary's line",
                SUMMARY_FIX,
            )
        )
    return found


def stray_fence_problems(root: Element) -> list[Problem]:
    found: list[Problem] = []

    def visit(element: Element, in_code: bool) -> None:
        in_code = in_code or element.tag in ("pre", "code")
        for child in element.children:
            if isinstance(child, Element):
                visit(child, in_code)
            elif not in_code and "```" in child:
                found.append(
                    rendered(
                        "fence shown as text",
                        f"``` shows as text {place(element)}, so a code fence did not open or"
                        " close where it was meant to",
                        "start and end each fence on its own line, indented exactly as far as the"
                        " step it belongs to",
                    )
                )

    visit(root, False)
    return found


def fallen_code_problems(root: Element) -> list[Problem]:
    """Code blocks after a task list and before the next heading, which left their step."""
    found: list[Problem] = []
    for parent in root.walk():
        after_task_list = False
        for child in parent.elements():
            if child.tag in HEADINGS:
                after_task_list = False
            elif child.tag in ("ul", "ol") and "contains-task-list" in child.classes():
                after_task_list = True
            elif after_task_list and holds_code(child):
                found.append(
                    rendered(
                        "code outside its step",
                        f"a code block {place(child)} follows a checklist instead of sitting"
                        " inside its step, so the step's command shows apart from it",
                        "indent the fence and every line inside it to the step's text",
                    )
                )
    return found


def check_html(html: str) -> list[Problem]:
    """Every problem in a body as GitHub's markdown API rendered it."""
    root = parse_html(html)
    found: list[Problem] = []
    for element in root.walk():
        if element.tag == "details":
            found.extend(details_problems(element))
        elif element.tag == "pre" and not element.text().strip():
            found.append(
                rendered(
                    "empty code block",
                    f"a code block {place(element)} renders empty, which is what happens when its"
                    " lines are indented less than its fence: they end the step and show below it",
                    "indent every line inside the block exactly as far as its fence",
                )
            )
        elif element.tag == "summary" and (
            element.parent is None or element.parent.tag != "details"
        ):
            # GitHub gives every <details> without a summary a <summary>Details</summary> of its
            # own, so a row that lost its content shows no missing summary. Its real summary,
            # left outside, is the trace.
            found.append(
                rendered(
                    "summary outside its row",
                    f'the summary "{squeeze(element.text())}" is outside every <details>, so its row'
                    ' shows as an empty "Details" and its content shows below the list',
                    "indent everything in the row to where its `<details>` starts, which is one"
                    " column further under a two-digit number such as `10.` than under `9.`",
                )
            )
    found.extend(stray_fence_problems(root))
    found.extend(fallen_code_problems(root))
    return found


# ---------------------------------------------------------------------------------------------
# The markdown source

BULLET_TAG = re.compile(r"^\s*[-*+]\s+(<details>|</details>|<summary>)")
NUMBERED_TAG = re.compile(r"^\s*\d+[.)]\s+(</details>|<summary>)")
PROVEN_BY = re.compile(r"^\s*####\s.*Proven by")
H4 = re.compile(r"^\s*####\s")
BULLET = re.compile(r"^\s*[-*+]\s")
# Properties start at P1. P0 and the percentiles a latency figure names are not property numbers.
PROPERTY_NUMBER = re.compile(r"\bP(?!(?:0|50|75|90|95|99|999)\b)[0-9]+\b")
LOCAL_LINK = re.compile(r"\]\((/|~|file:)")
SUMMARY = re.compile(r"<summary>(.*?)</summary>", re.DOTALL)
TAG = re.compile(r"<[^>]+>")
HEADING_LINE = re.compile(r"^\s*(#{1,6}\s|\*\*|<summary>|\d+[.)]\s+\*\*)")


def code_lines(tokens: list[Token]) -> set[int]:
    """The 0-based lines that are fenced or indented code, fences included."""
    lines: set[int] = set()
    for token in tokens:
        if token.type in ("fence", "code_block") and token.map is not None:
            lines.update(range(token.map[0], token.map[1]))
    return lines


def tag_problems(lines: list[str], code: set[int]) -> list[Problem]:
    found: list[Problem] = []
    for index, line in enumerate(lines):
        if index in code:
            continue
        match = BULLET_TAG.match(line) or NUMBERED_TAG.match(line)
        if match is None:
            continue
        tag = match.group(1)
        fix = (
            "start the row with `1. <details>` instead"
            if tag == "<details>"
            else f"put `{tag}` on a line of its own, indented to the row's text, with no marker"
        )
        found.append(
            Problem(
                LineNumber(index + 1),
                "tag on a list item",
                f"{tag} is on a list item's line, so GitHub shows the marker as text and the"
                " row's layout breaks",
                fix,
            )
        )
    return found


def what_section_problems(tokens: list[Token]) -> list[Problem]:
    found: list[Problem] = []
    in_what = False
    for index, token in enumerate(tokens):
        if token.type == "heading_open" and token.tag == "h2":
            in_what = "What" in tokens[index + 1].content
        elif in_what and token.type in ("fence", "code_block") and token.map is not None:
            found.append(
                Problem(
                    LineNumber(token.map[0] + 1),
                    "code block in What",
                    "a code block in What makes GitHub space out every bullet in the list",
                    "say it in a bullet with inline code, or move the commands to How to verify",
                )
            )
    return found


def empty_proven_by(heading: int) -> Problem:
    return Problem(
        LineNumber(heading + 1),
        "Proven by has no bullet",
        "the row's Proven by is empty, so it claims a behaviour and shows nothing that proves it",
        "list what proves the row, or stop the PR if nothing does",
    )


def proven_by_problems(lines: list[str]) -> list[Problem]:
    found: list[Problem] = []
    heading: int | None = None
    has_bullet = False
    for index, line in enumerate(lines):
        ends_section = PROVEN_BY.match(line) or H4.match(line) or "</details>" in line
        if heading is not None and ends_section:
            if not has_bullet:
                found.append(empty_proven_by(heading))
            heading = None
        if PROVEN_BY.match(line):
            heading, has_bullet = index, False
            continue
        if heading is None:
            continue
        if BULLET.match(line):
            has_bullet = True
        elif line.strip():
            found.append(
                Problem(
                    LineNumber(index + 1),
                    "Proven by line not a bullet",
                    "a line under Proven by is not a bullet, so it reads as a paragraph after the"
                    " list rather than one more thing that proves the row",
                    "make it a `- ` bullet, or move it under What I saw if it is output",
                )
            )
    if heading is not None and not has_bullet:
        found.append(empty_proven_by(heading))
    return found


def line_pattern_problems(lines: list[str], code: set[int]) -> list[Problem]:
    found: list[Problem] = []
    for index, line in enumerate(lines):
        if index in code:
            continue
        for number in PROPERTY_NUMBER.findall(line):
            found.append(
                Problem(
                    LineNumber(index + 1),
                    "property number",
                    f"{number} is the approach's shorthand, which a reviewer of the PR has never"
                    " seen",
                    "say the property in words",
                )
            )
        if LOCAL_LINK.search(line):
            found.append(
                Problem(
                    LineNumber(index + 1),
                    "local link",
                    "a link points at a path on this machine, which no reviewer can open",
                    "link the file on GitHub, or name it in inline code without a link",
                )
            )
    return found


def pre_merge_problems(lines: list[str], code: set[int]) -> list[Problem]:
    return [
        Problem(
            LineNumber(index + 1),
            "Pre-merge heading",
            "a Pre-merge heading splits the outline, where After merge is its last row",
            "drop the heading; every row runs before merge except the After merge row",
        )
        for index, line in enumerate(lines)
        if index not in code and HEADING_LINE.match(line) and "pre-merge" in line.lower()
    ]


def check_markdown(text: str) -> list[Problem]:
    """Every problem in a body's markdown source."""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    lines = text.split("\n")
    tokens = PARSER.parse(text)
    code = code_lines(tokens)
    return [
        *tag_problems(lines, code),
        *what_section_problems(tokens),
        *proven_by_problems(lines),
        *line_pattern_problems(lines, code),
        *pre_merge_problems(lines, code),
    ]


# ---------------------------------------------------------------------------------------------
# Commands that were run


def summary_text(html_block: str) -> str | None:
    match = SUMMARY.search(html_block)
    return squeeze(TAG.sub("", match.group(1))) if match else None


def without_trailing_space(text: str) -> str:
    return "\n".join(line.rstrip() for line in text.replace("\r\n", "\n").split("\n")).strip("\n")


def check_commands(text: str, commands: str, commands_name: str) -> list[Problem]:
    """Every step code block that does not appear, as written, among the commands that were run.

    A block counts when it sits under a Verification steps heading, or anywhere in the Setup or
    Clean up row. markdown-it gives each block's content with its indentation removed.
    """
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    ran = without_trailing_space(commands)
    found: list[Problem] = []
    row: str | None = None
    heading = ""
    tokens = PARSER.parse(text)
    for index, token in enumerate(tokens):
        if token.type == "html_block":
            if "</details>" in token.content:
                row, heading = None, ""
            summary = summary_text(token.content)
            if summary is not None:
                row, heading = summary, ""
        elif token.type == "heading_open":
            heading = tokens[index + 1].content
        elif token.type in ("fence", "code_block") and token.map is not None:
            in_steps = "Verification steps" in heading
            in_setup = row is not None and ("Setup" in row or "Clean up" in row)
            block = without_trailing_space(token.content)
            if (in_steps or in_setup) and block and block not in ran:
                where = (
                    f'the Verification steps of "{row}"'
                    if in_steps and row
                    else f'"{row}"'
                    if row
                    else "Verification steps outside every row"
                )
                found.append(
                    Problem(
                        LineNumber(token.map[0] + 1),
                        "command not run",
                        f"the code block in {where} does not appear in {commands_name} as written,"
                        " so nothing shows it was run",
                        "run it exactly as shown and add it to the commands file, or change the"
                        " block to what was run",
                    )
                )
    return found


# ---------------------------------------------------------------------------------------------
# The live copy


def check_live_copy(saved: str, live: str, pr: PrNumber, saved_name: str) -> list[Problem]:
    if without_trailing_space(saved).rstrip() == without_trailing_space(live).rstrip():
        return []
    return [
        Problem(
            "live",
            "live body changed",
            f"PR #{pr}'s description on GitHub differs from {saved_name}, so someone edited it"
            " since it was read, and posting this body would overwrite their change",
            "read the live body again, merge their change into this body, save the new live copy"
            " and check again",
        )
    ]


# ---------------------------------------------------------------------------------------------
# The boundary: arguments, files and gh


@dataclass(frozen=True)
class LiveCopy:
    saved: Path
    pr: PrNumber


@dataclass(frozen=True)
class Args:
    body: Path
    repo: Repo
    live_copy: LiveCopy | None
    commands: Path | None


def positive_int(value: str) -> int:
    if not value.isdigit() or int(value) < 1:
        raise argparse.ArgumentTypeError(f"{value!r} is not a PR number")
    return int(value)


def repo_name(value: str) -> str:
    if not REPO_PATTERN.fullmatch(value):
        raise argparse.ArgumentTypeError(f"{value!r} is not <owner>/<repo>")
    return value


def parse_args(argv: list[str]) -> Args:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("body", type=Path, help="the markdown file whose text will be posted")
    parser.add_argument(
        "--repo",
        required=True,
        type=repo_name,
        help="<owner>/<repo> the PR belongs to, which GitHub renders #123 references against",
    )
    parser.add_argument(
        "--live-copy",
        type=Path,
        help="the PR body as it was read from GitHub before editing; needs --pr",
    )
    parser.add_argument(
        "--pr", type=positive_int, help="the PR whose live body --live-copy is compared with"
    )
    parser.add_argument(
        "--commands", type=Path, help="a file holding, as text, every command that was run"
    )
    args = parser.parse_args(argv)
    if (args.live_copy is None) != (args.pr is None):
        parser.error("--live-copy and --pr go together: pass both or neither")
    live_copy = None if args.pr is None else LiveCopy(args.live_copy, PrNumber(args.pr))
    return Args(args.body, Repo(args.repo), live_copy, args.commands)


@dataclass(frozen=True)
class GhOutput:
    stdout: str


@dataclass(frozen=True)
class CouldNotRun:
    reason: str


GhResult = GhOutput | CouldNotRun
Gh = Callable[[list[str], str | None], GhResult]


def run_gh(args: list[str], stdin: str | None) -> GhResult:
    command = " ".join(["gh", *args])
    try:
        result = subprocess.run(["gh", *args], input=stdin, capture_output=True, text=True)
    except FileNotFoundError:
        return CouldNotRun(f"`{command}` could not run: gh is not installed or not on PATH")
    if result.returncode != 0:
        return CouldNotRun(
            f"`{command}` exited {result.returncode}: {result.stderr.strip() or 'no error text'}"
        )
    return GhOutput(result.stdout)


def render(gh: Gh, body: str, repo: Repo) -> GhResult:
    request = json.dumps({"text": body, "mode": "gfm", "context": repo})
    return gh(["api", "markdown", "--input", "-"], request)


def fetch_live_body(gh: Gh, pr: PrNumber, repo: Repo) -> GhResult:
    return gh(["pr", "view", str(pr), "-R", repo, "--json", "body", "-q", ".body"], None)


def read_text(path: Path) -> str | CouldNotRun:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        return CouldNotRun(f"could not read {path}: {error}")


def report(path: Path, problem: Problem) -> str:
    return f"{path}:{problem.where}: {problem.kind}: {problem.what}. Fix: {problem.fix}"


def run_checks(args: Args, gh: Gh) -> tuple[list[Problem], list[str]]:
    """The problems found, and the reasons any check could not run."""
    problems: list[Problem] = []
    failures: list[str] = []

    body = read_text(args.body)
    if isinstance(body, CouldNotRun):
        return [], [body.reason]

    problems.extend(check_markdown(body))

    match render(gh, body, args.repo):
        case GhOutput(html):
            problems.extend(check_html(html))
        case CouldNotRun(reason):
            failures.append(f"the rendered checks did not run: {reason}")
        case _ as unreachable:
            assert_never(unreachable)

    if args.commands is not None:
        commands = read_text(args.commands)
        if isinstance(commands, CouldNotRun):
            failures.append(f"the commands check did not run: {commands.reason}")
        else:
            problems.extend(check_commands(body, commands, str(args.commands)))

    if args.live_copy is not None:
        saved = read_text(args.live_copy.saved)
        if isinstance(saved, CouldNotRun):
            failures.append(f"the live copy check did not run: {saved.reason}")
        else:
            match fetch_live_body(gh, args.live_copy.pr, args.repo):
                case GhOutput(live):
                    problems.extend(
                        check_live_copy(saved, live, args.live_copy.pr, str(args.live_copy.saved))
                    )
                case CouldNotRun(reason):
                    failures.append(f"the live copy check did not run: {reason}")
                case _ as unreachable:
                    assert_never(unreachable)

    return problems, failures


def main(argv: list[str], gh: Gh = run_gh) -> ExitCode:
    args = parse_args(argv)
    problems, failures = run_checks(args, gh)
    for problem in problems:
        print(report(args.body, problem))
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        print(
            f"{len(failures)} check(s) could not run, so {args.body} is not known to be ready;"
            f" {SENTINEL}",
            file=sys.stderr,
        )
        return ExitCode(2)
    if problems:
        print(f"{len(problems)} to fix before posting; {SENTINEL}")
        return ExitCode(1)
    print(f"{args.body}: every check passed")
    return ExitCode(0)


if __name__ == "__main__":
    try:
        code = main(sys.argv[1:])
    except Exception:
        # Exit 1 means a list of problems to fix, so a crash must not end with it.
        traceback.print_exc()
        print("The check crashed, so the body was not checked.", file=sys.stderr)
        sys.exit(2)
    sys.exit(code)
