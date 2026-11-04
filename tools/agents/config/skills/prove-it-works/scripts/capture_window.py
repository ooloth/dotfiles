#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic>=2,<3"]
# ///
"""Capture one app window as a PNG, as evidence of what that app shows.

Run:
  uv run capture_window.py --app Rex --title "Agent scaling" --out <evidence folder>/rex-tab.png

Asks macOS for the on-screen app windows with `osascript`, keeps only the named app's windows, and
captures exactly one of them with `screencapture -o -x -l<id>`, so nothing else on the screen is
recorded. The app name matches a window's owner as a whole word at its start, in any case, so `Rex`
finds `Rex Beta` and `fox` does not find `Firefox`. An owner that is exactly the name wins over
longer ones, so while Safari has a window open `Safari` never captures Safari Technology Preview,
and a name that starts the names of several apps captures nothing. `--title` narrows by any part of the window's title, in any case.
`--window-id` picks one of the app's windows by the ID a failure message printed, which is how an
untitled window beside others is chosen.

Window titles can hold private information, so nothing about another app's windows is ever printed,
even when the run fails. Every expected failure exits 1 with a sentence: no window, several windows
(listing only that app's titles), a name that fits several apps, any of that app's titles hidden
because the terminal lacks macOS's Screen Recording permission, anything already at the output
path, an output folder it cannot create, write in or make a hard link in, either tool missing,
failing, taking longer than 30 seconds or returning nothing usable, and an image it cannot put in
place. The output folder is checked before either tool runs. The output path is never written over,
even by a file that appears while it captures, so earlier evidence is never replaced. Problems with
the arguments exit 2, all reported together, except a flag argparse cannot read at all (an unknown
flag, or one missing its value), which argparse reports alone. SIGTERM or SIGHUP stops the tool,
removes the staging folder and exits 128 plus the signal's number.

Caller: the prove-it-works skill. Open the image afterwards and check it shows the expected window
and nothing secret; this script cannot judge that.
"""

from __future__ import annotations

import argparse
import enum
import os
import shutil
import signal
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from types import FrameType
from typing import NewType, assert_never

from pydantic import BaseModel, ConfigDict, TypeAdapter, ValidationError

WindowId = NewType("WindowId", int)
AppName = NewType("AppName", str)
TitleFilter = NewType("TitleFilter", str)
EvidencePath = NewType("EvidencePath", Path)
StagingFolder = NewType("StagingFolder", Path)

# This bounds a hang; it was not measured.
TOOL_TIMEOUT_SECONDS = 30

# What prove-it-works does with a run that could not observe the app. Its bar allows "not
# observable" only after a retry, so the message asks for one first. It is added when a tool ran
# and failed, and left off when a tool is missing or the --out folder is the problem, where only a
# different command or machine helps.
NOT_OBSERVABLE = (
    "Run this once more, and if it fails again, record the claim as not observable from the app, "
    "quoting this message."
)

# Where every problem with the --out folder ends: the fix is a different folder, not a retry.
CHOOSE_ANOTHER_OUT = "Choose an --out in a folder you can write to."

# Lists every on-screen app window (layer 0) as JSON. A title is null when macOS hides it, which it
# does for every other app's window when the caller lacks Screen Recording permission.
LIST_WINDOWS_JXA = """
ObjC.import("CoreGraphics");
const options = $.kCGWindowListOptionOnScreenOnly | $.kCGWindowListExcludeDesktopElements;
const info = ObjC.deepUnwrap(
  ObjC.castRefToObject($.CGWindowListCopyWindowInfo(options, $.kCGNullWindowID))
);
JSON.stringify(
  info
    .filter((w) => w.kCGWindowLayer === 0)
    .map((w) => ({
      id: w.kCGWindowNumber,
      owner: w.kCGWindowOwnerName,
      title: w.kCGWindowName === undefined ? null : w.kCGWindowName,
    }))
);
"""


# Boundary: what osascript hands the script.


class ListedWindow(BaseModel):
    """One window as osascript reports it."""

    model_config = ConfigDict(frozen=True, strict=True)

    id: int
    owner: str
    title: str | None


WINDOW_LIST = TypeAdapter(list[ListedWindow])


# Domain.


@dataclass(frozen=True)
class AnyWindow:
    """No narrowing: the app must have exactly one on-screen window."""


@dataclass(frozen=True)
class ByTitle:
    title: TitleFilter


@dataclass(frozen=True)
class ById:
    id: WindowId


Pick = AnyWindow | ByTitle | ById


@dataclass(frozen=True)
class CaptureRequest:
    app: AppName
    pick: Pick
    out: EvidencePath


@dataclass(frozen=True)
class BadArguments:
    problems: tuple[str, ...]


class FolderStep(enum.Enum):
    """Which part of setting up the output folder failed."""

    CREATE = "create"
    WRITE = "write"
    LINK = "link"


@dataclass(frozen=True)
class Prepared:
    """The output folder exists, and a staging folder in it can hold an image and link it out."""

    staging: StagingFolder


@dataclass(frozen=True)
class OutExists:
    out: EvidencePath


@dataclass(frozen=True)
class FolderUnusable:
    folder: Path
    step: FolderStep
    reason: str


@dataclass(frozen=True)
class ToolMissing:
    tool: str


@dataclass(frozen=True)
class Window:
    id: WindowId
    owner: str
    title: str | None


@dataclass(frozen=True)
class Windows:
    """Every on-screen app window. Held in memory only: printing any of it could leak another
    app's window titles."""

    all: tuple[Window, ...]


@dataclass(frozen=True)
class ListingFailed:
    reason: str


@dataclass(frozen=True)
class AppWindows:
    """The windows of the one app the name resolved to. All share one owner, ignoring case."""

    windows: tuple[Window, ...]


@dataclass(frozen=True)
class AppHasNoWindow:
    app: AppName


@dataclass(frozen=True)
class AmbiguousApp:
    """The name starts the names of several apps. Holds only the name given, never theirs."""

    app: AppName


@dataclass(frozen=True)
class Chosen:
    window: Window


@dataclass(frozen=True)
class NoMatch:
    app: AppName
    pick: ByTitle | ById
    candidates: tuple[Window, ...]


@dataclass(frozen=True)
class SeveralWindows:
    app: AppName
    candidates: tuple[Window, ...]


@dataclass(frozen=True)
class TitlesHidden:
    app: AppName


@dataclass(frozen=True)
class Captured:
    window: Window
    out: EvidencePath


@dataclass(frozen=True)
class CaptureFailed:
    window: Window
    reason: str


@dataclass(frozen=True)
class OutTaken:
    out: EvidencePath


@dataclass(frozen=True)
class OutUnusable:
    out: EvidencePath
    reason: str


@dataclass(frozen=True)
class Done:
    message: str


@dataclass(frozen=True)
class Failed:
    message: str


Preparation = Prepared | OutExists | FolderUnusable
Listing = Windows | ListingFailed | ToolMissing
Resolution = AppWindows | AppHasNoWindow | AmbiguousApp
Choice = Chosen | NoMatch | SeveralWindows | TitlesHidden
CaptureOutcome = Captured | CaptureFailed | ToolMissing | OutTaken | OutUnusable
Outcome = Done | Failed


def build_parser() -> argparse.ArgumentParser:
    # Nothing is required here, so parse_arguments can report every missing argument at once. The
    # usage line says which are required instead.
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        usage="%(prog)s --app APP --out OUT [--title TITLE | --window-id WINDOW_ID]",
    )
    parser.add_argument("--app", help="the app's name, such as Rex or Safari (required)")
    parser.add_argument("--title", help="any part of the window's title, to pick one of several")
    parser.add_argument("--window-id", help="the ID of one of the app's windows, to pick it")
    parser.add_argument("--out", help="the PNG to write; nothing may exist there (required)")
    return parser


def parse_arguments(argv: list[str]) -> CaptureRequest | BadArguments:
    """The command line as a request, or every problem with it. The Namespace is read only here."""
    raw = build_parser().parse_args(argv)
    app_text: str | None = raw.app
    title_text: str | None = raw.title
    id_text: str | None = raw.window_id
    out_text: str | None = raw.out
    problems: list[str] = []

    app = app_text.strip() if app_text is not None else ""
    if app_text is None:
        problems.append("--app is required: the app's name, such as Rex or Safari")
    elif not app:
        problems.append("--app needs an app name")

    if out_text is None:
        problems.append("--out is required: the PNG to write")
    elif Path(out_text).suffix.lower() != ".png":
        problems.append(f"--out must be a .png file, not {Path(out_text).name}")

    if title_text is not None and not title_text.strip():
        problems.append(
            "--title needs some text. To pick an untitled window, pass --window-id instead"
        )

    window_id: int | None = None
    if id_text is not None:
        if id_text.strip().isdecimal() and int(id_text) > 0:
            window_id = int(id_text)
        else:
            problems.append(f"--window-id must be a positive whole number, not {id_text!r}")

    if title_text is not None and id_text is not None:
        problems.append("--title and --window-id each pick a window, so pass only one")

    if problems or out_text is None:
        return BadArguments(tuple(problems))
    pick: Pick
    if window_id is not None:
        pick = ById(WindowId(window_id))
    elif title_text is not None:
        pick = ByTitle(TitleFilter(title_text))
    else:
        pick = AnyWindow()
    return CaptureRequest(app=AppName(app), pick=pick, out=EvidencePath(Path(out_text)))


def prepare(out: EvidencePath) -> Preparation:
    """Refuse anything already at `out`, even a dangling symlink, create its folder, and make a
    staging folder there that has shown it can hold a file and link it to another name. Runs before
    any tool, so a folder problem is never mistaken for a problem with the app."""
    if os.path.lexists(out):
        return OutExists(out)
    folder = out.parent
    try:
        folder.mkdir(parents=True, exist_ok=True)
    except OSError as error:
        return FolderUnusable(folder, FolderStep.CREATE, str(error.strerror or error))
    try:
        staging = StagingFolder(Path(tempfile.mkdtemp(prefix=".capture_window-", dir=folder)))
    except OSError as error:
        return FolderUnusable(folder, FolderStep.WRITE, str(error.strerror or error))
    probe = staging / "probe"
    try:
        probe.touch()
        os.link(probe, staging / "probe-link")
    except OSError as error:
        shutil.rmtree(staging, ignore_errors=True)
        return FolderUnusable(folder, FolderStep.LINK, str(error.strerror or error))
    (staging / "probe-link").unlink()
    probe.unlink()
    return Prepared(staging)


def list_windows() -> Listing:
    try:
        result = subprocess.run(
            ["osascript", "-l", "JavaScript", "-e", LIST_WINDOWS_JXA],
            capture_output=True,
            text=True,
            timeout=TOOL_TIMEOUT_SECONDS,
        )
    except FileNotFoundError:
        return ToolMissing("osascript")
    except subprocess.TimeoutExpired:
        return ListingFailed(
            f"osascript did not finish within {TOOL_TIMEOUT_SECONDS} seconds while listing windows."
        )
    except OSError as error:
        return ListingFailed(f"Could not run osascript: {error.strerror or error}.")
    if result.returncode != 0:
        return ListingFailed(
            f"Could not list windows: osascript exited {result.returncode}: "
            f"{result.stderr.strip()}."
        )
    try:
        listed = WINDOW_LIST.validate_json(result.stdout)
    except ValidationError:
        # The error would quote the list, and the list holds other apps' titles.
        return ListingFailed(
            "osascript returned an unexpected window list, so nothing was captured."
        )
    return Windows(tuple(Window(WindowId(w.id), w.owner, w.title) for w in listed))


def belongs_to(app: AppName, owner: str) -> bool:
    """Whether `owner` is `app`, or starts with `app` followed by a space, in any case."""
    name, owner = app.casefold(), owner.casefold()
    return owner == name or owner.startswith(f"{name} ")


def resolve_app(app: AppName, windows: Windows) -> Resolution:
    """The windows of the one app `app` names. An owner that is exactly the name wins; otherwise
    owners that start with it count, but only when they are all the same app."""
    name = app.casefold()
    exact = tuple(w for w in windows.all if w.owner.casefold() == name)
    longer = tuple(w for w in windows.all if w.owner.casefold().startswith(f"{name} "))
    if exact:
        mine = exact
    elif len({w.owner.casefold() for w in longer}) > 1:
        return AmbiguousApp(app)
    else:
        mine = longer
    if not mine:
        return AppHasNoWindow(app)
    assert len({w.owner.casefold() for w in mine}) == 1, f"{app} resolved to several owners"
    return AppWindows(mine)


def choose(app: AppName, pick: Pick, resolved: AppWindows) -> Choice:
    mine = resolved.windows
    # macOS hides another app's titles from a terminal without Screen Recording, while still showing
    # the terminal's own, so one hidden title among this app's windows means the permission is
    # missing, and a capture would not show the window's content.
    if any(w.title is None for w in mine):
        return TitlesHidden(app)
    narrowed: ByTitle | ById
    match pick:
        case AnyWindow():
            return Chosen(mine[0]) if len(mine) == 1 else SeveralWindows(app, mine)
        case ByTitle(title):
            narrowed = pick
            candidates = tuple(
                w for w in mine if w.title is not None and title.casefold() in w.title.casefold()
            )
        case ById(window_id):
            narrowed = pick
            candidates = tuple(w for w in mine if w.id == window_id)
        case _:
            assert_never(pick)
    match len(candidates):
        case 0:
            return NoMatch(app, narrowed, mine)
        case 1:
            return Chosen(candidates[0])
        case _:
            return SeveralWindows(app, candidates)


def capture(window: Window, staging: StagingFolder, out: EvidencePath) -> CaptureOutcome:
    """Capture into the staging folder, then link the image to `out`, which refuses if anything
    has appeared there. Nothing writes to `out` itself."""
    image = staging / "window.png"
    try:
        result = subprocess.run(
            ["screencapture", "-o", "-x", f"-l{window.id}", str(image)],
            capture_output=True,
            text=True,
            timeout=TOOL_TIMEOUT_SECONDS,
        )
    except FileNotFoundError:
        return ToolMissing("screencapture")
    except subprocess.TimeoutExpired:
        return CaptureFailed(
            window, f"screencapture did not finish within {TOOL_TIMEOUT_SECONDS} seconds"
        )
    except OSError as error:
        return CaptureFailed(window, f"it could not be run: {error.strerror or error}")
    if result.returncode != 0:
        return CaptureFailed(window, f"exited {result.returncode}: {result.stderr.strip()}")
    if not image.is_file() or image.stat().st_size == 0:
        return CaptureFailed(window, "it reported success but wrote no image")
    try:
        os.link(image, out)
    except FileExistsError:
        return OutTaken(out)
    except OSError as error:
        return OutUnusable(out, str(error.strerror or error))
    return Captured(window, out)


def describe(app: AppName, window: Window) -> str:
    """The text printed about a window. Only ever called on the named app's windows."""
    assert belongs_to(app, window.owner), f"refusing to describe window {window.id} of another app"
    return f'window {window.id} "{window.title or ""}" of {window.owner}'


def listed(app: AppName, windows: tuple[Window, ...]) -> str:
    return "\n".join(f"  {describe(app, w)}" for w in windows)


def explain_folder(problem: FolderUnusable) -> str:
    match problem.step:
        case FolderStep.CREATE:
            what = f"Could not create {problem.folder}: {problem.reason}."
        case FolderStep.WRITE:
            what = f"Could not write in {problem.folder}: {problem.reason}."
        case FolderStep.LINK:
            what = (
                f"{problem.folder} cannot hold a hard link ({problem.reason}), which is what keeps "
                "earlier evidence from being written over."
            )
        case _:
            assert_never(problem.step)
    return f"{what} {CHOOSE_ANOTHER_OUT}"


def explain_tool_missing(missing: ToolMissing) -> str:
    return f"{missing.tool} was not found. This script needs macOS's own tools, so run it on a Mac."


def explain_no_match(no_match: NoMatch) -> str:
    """Why the pick matched none of the app's own windows, listing them so one can be picked."""
    app, candidates = no_match.app, no_match.candidates
    match no_match.pick:
        case ByTitle(title):
            return (
                f'No on-screen window of {app} has "{title}" in its title. Pass --title with part '
                f"of one of these titles, or --window-id with its ID:\n{listed(app, candidates)}"
            )
        case ById(window_id):
            return (
                f"{app} has no on-screen window {window_id}. Pass --window-id with one of these "
                f"IDs:\n{listed(app, candidates)}"
            )
        case _:
            assert_never(no_match.pick)


def explain(choice: AppHasNoWindow | AmbiguousApp | NoMatch | SeveralWindows | TitlesHidden) -> str:
    match choice:
        case AppHasNoWindow(app):
            return f"No on-screen window of {app} found. Is the app open and visible?"
        case AmbiguousApp(app):
            return (
                f"--app {app} matches windows of more than one app, so none was captured. Pass the "
                "app's full name."
            )
        case NoMatch() as no_match:
            return explain_no_match(no_match)
        case SeveralWindows(app, candidates):
            return (
                f"{app} has {len(candidates)} on-screen windows, so none was captured. Pass "
                "--title with part of one of these titles, or --window-id with its ID:\n"
                f"{listed(app, candidates)}"
            )
        case TitlesHidden(app):
            return (
                f"macOS hides {app}'s window titles, so its window cannot be identified or "
                "captured. Grant Screen Recording to this terminal app in System Settings > "
                "Privacy & Security, then run this again."
            )
        case _:
            assert_never(choice)


def run(request: CaptureRequest) -> Outcome:
    """Capture the requested window, or say why not. Nothing here prints or exits. The staging
    folder `prepare` makes is removed however the run ends."""
    match prepare(request.out):
        case OutExists(out):
            return Failed(f"{out} already exists, so it was left unchanged. Choose a new name.")
        case FolderUnusable() as problem:
            return Failed(explain_folder(problem))
        case Prepared(staging):
            pass
        case _ as unreachable:
            assert_never(unreachable)
    try:
        return capture_requested(request, staging)
    finally:
        shutil.rmtree(staging, ignore_errors=True)


def capture_requested(request: CaptureRequest, staging: StagingFolder) -> Outcome:
    match list_windows():
        case ListingFailed(reason):
            return Failed(f"{reason} {NOT_OBSERVABLE}")
        case ToolMissing() as missing:
            return Failed(explain_tool_missing(missing))
        case Windows() as windows:
            resolution = resolve_app(request.app, windows)
        case _ as unreachable:
            assert_never(unreachable)
    match resolution:
        case AppWindows() as resolved:
            choice = choose(request.app, request.pick, resolved)
        case AppHasNoWindow() | AmbiguousApp():
            return Failed(explain(resolution))
        case _:
            assert_never(resolution)
    match choice:
        case Chosen(window):
            assert belongs_to(request.app, window.owner), (
                f"refusing to capture window {window.id} of another app"
            )
            outcome = capture(window, staging, request.out)
        case NoMatch() | SeveralWindows() | TitlesHidden():
            return Failed(explain(choice))
        case _:
            assert_never(choice)
    match outcome:
        case Captured(window, out):
            return Done(f"Captured {describe(request.app, window)} to {out}")
        case CaptureFailed(window, reason):
            return Failed(
                f"screencapture could not capture {describe(request.app, window)}: {reason}. "
                f"{NOT_OBSERVABLE}"
            )
        case ToolMissing() as missing:
            return Failed(explain_tool_missing(missing))
        case OutTaken(out):
            return Failed(
                f"{out} appeared while the window was being captured, so it was left unchanged. "
                "Choose a new name."
            )
        case OutUnusable(out, reason):
            return Failed(f"The image could not be placed at {out}: {reason}. {CHOOSE_ANOTHER_OUT}")
        case _:
            assert_never(outcome)


def stop_on_signal(signum: int, _frame: FrameType | None) -> None:
    """Turn SIGTERM or SIGHUP into an exit, so cleanup runs and the running tool is killed."""
    print(f"Stopped by {signal.Signals(signum).name}; nothing was captured.", file=sys.stderr)
    raise SystemExit(128 + signum)


def main(argv: list[str]) -> None:
    """The one place that prints an outcome and turns it into an exit status."""
    for signum in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(signum, stop_on_signal)
    match parse_arguments(argv):
        case BadArguments(problems):
            parser = build_parser()
            parser.print_usage(sys.stderr)
            for problem in problems:
                print(f"{parser.prog}: error: {problem}", file=sys.stderr)
            raise SystemExit(2)
        case CaptureRequest() as request:
            pass
        case _ as unreachable:
            assert_never(unreachable)
    match run(request):
        case Done(message):
            print(message)
        case Failed(message):
            raise SystemExit(message)
        case _ as unreachable:
            assert_never(unreachable)


if __name__ == "__main__":
    main(sys.argv[1:])
