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
finds `Rex Beta` and `fox` does not find `Firefox`. `--title` narrows by any part of the window's
title, in any case. `--window-id` picks one of the app's windows by the ID a failure message
printed, which is how an untitled window beside others is chosen.

Window titles can hold private information, so nothing about another app's windows is ever printed,
even when the run fails. Every expected failure exits 1 with a sentence: no window, several windows
(listing only that app's titles), any of that app's titles hidden because the terminal lacks
macOS's Screen Recording permission, anything already at the output path, an output folder it
cannot create, either tool missing, failing, taking longer than 30 seconds or returning nothing
usable, and an image it cannot put in place. The output path is never written over, even by a file
that appears while it captures, so earlier evidence is never replaced. Problems with the arguments
exit 2, all reported together, except a flag argparse cannot read at all (an unknown flag, or one
missing its value), which argparse reports alone.

Caller: the prove-it-works skill. Open the image afterwards and check it shows the expected window
and nothing secret; this script cannot judge that.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import NewType, assert_never

from pydantic import BaseModel, ConfigDict, TypeAdapter, ValidationError

WindowId = NewType("WindowId", int)
AppName = NewType("AppName", str)
TitleFilter = NewType("TitleFilter", str)
EvidencePath = NewType("EvidencePath", Path)

# Both tools normally finish in well under a second. This bounds a hang; it was not measured.
TOOL_TIMEOUT_SECONDS = 30

# What prove-it-works does with a run that could not observe the app. Its bar allows "not
# observable" only after a retry, so the message asks for one first.
NOT_OBSERVABLE = (
    "Run this once more, and if it fails again, record the claim as not observable from the app, "
    "quoting this message."
)

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
class Chosen:
    window: Window


@dataclass(frozen=True)
class NoWindow:
    app: AppName
    pick: Pick
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
class Done:
    message: str


@dataclass(frozen=True)
class Failed:
    message: str


Listing = Windows | ListingFailed
Choice = Chosen | NoWindow | SeveralWindows | TitlesHidden
CaptureOutcome = Captured | CaptureFailed | OutTaken
Outcome = Done | Failed


def build_parser() -> argparse.ArgumentParser:
    # Nothing is required here, so parse_arguments can report every missing argument at once.
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
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


def prepare(out: EvidencePath) -> Failed | None:
    """Refuse anything already at `out`, even a dangling symlink, and create its folder."""
    if os.path.lexists(out):
        return Failed(f"{out} already exists, so it was left unchanged. Choose a new name.")
    try:
        out.parent.mkdir(parents=True, exist_ok=True)
    except OSError as error:
        return Failed(
            f"Could not create {out.parent}: {error.strerror or error}. "
            "Choose an --out in a folder you can write to."
        )
    return None


def list_windows() -> Listing:
    try:
        result = subprocess.run(
            ["osascript", "-l", "JavaScript", "-e", LIST_WINDOWS_JXA],
            capture_output=True,
            text=True,
            timeout=TOOL_TIMEOUT_SECONDS,
        )
    except FileNotFoundError:
        return ListingFailed(
            "osascript was not found. This script needs macOS's own tools, so run it on a Mac."
        )
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


def windows_of(app: AppName, windows: Windows) -> tuple[Window, ...]:
    return tuple(w for w in windows.all if belongs_to(app, w.owner))


def choose(request: CaptureRequest, windows: Windows) -> Choice:
    mine = windows_of(request.app, windows)
    # macOS hides another app's titles from a terminal without Screen Recording, while still showing
    # the terminal's own, so one hidden title among this app's windows means the permission is
    # missing, and a capture would not show the window's content.
    if any(w.title is None for w in mine):
        return TitlesHidden(request.app)
    match request.pick:
        case AnyWindow():
            candidates = mine
        case ByTitle(title):
            candidates = tuple(
                w for w in mine if w.title is not None and title.casefold() in w.title.casefold()
            )
        case ById(window_id):
            candidates = tuple(w for w in mine if w.id == window_id)
        case _:
            assert_never(request.pick)
    match len(candidates):
        case 0:
            return NoWindow(request.app, request.pick, mine)
        case 1:
            return Chosen(candidates[0])
        case _:
            return SeveralWindows(request.app, candidates)


def capture(window: Window, out: EvidencePath) -> CaptureOutcome:
    """Capture into a staging folder beside `out`, then link the image to `out`, which refuses
    if anything has appeared there. Nothing writes to `out` itself."""
    try:
        staging = Path(tempfile.mkdtemp(prefix=".capture_window-", dir=out.parent))
    except OSError as error:
        return CaptureFailed(
            window, f"no staging folder could be made in {out.parent}: {error.strerror or error}"
        )
    try:
        return capture_through(window, staging / "window.png", out)
    finally:
        shutil.rmtree(staging, ignore_errors=True)


def capture_through(window: Window, image: Path, out: EvidencePath) -> CaptureOutcome:
    try:
        result = subprocess.run(
            ["screencapture", "-o", "-x", f"-l{window.id}", str(image)],
            capture_output=True,
            text=True,
            timeout=TOOL_TIMEOUT_SECONDS,
        )
    except FileNotFoundError:
        return CaptureFailed(
            window,
            "screencapture was not found, and this script needs macOS's own tools, so run it on "
            "a Mac",
        )
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
        return CaptureFailed(
            window, f"the image could not be placed at {out}: {error.strerror or error}"
        )
    return Captured(window, out)


def describe(app: AppName, window: Window) -> str:
    """The text printed about a window. Only ever called on the named app's windows."""
    assert belongs_to(app, window.owner), f"refusing to describe window {window.id} of another app"
    return f'window {window.id} "{window.title or ""}" of {window.owner}'


def listed(app: AppName, windows: tuple[Window, ...]) -> str:
    return "\n".join(f"  {describe(app, w)}" for w in windows)


def explain_no_window(app: AppName, pick: Pick, candidates: tuple[Window, ...]) -> str:
    """Why `pick` matched none of `candidates`, the app's own windows."""
    if not candidates:
        return f"No on-screen window of {app} found. Is the app open and visible?"
    match pick:
        case AnyWindow():
            raise AssertionError(f"{app} has windows, so AnyWindow cannot have matched none")
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
            assert_never(pick)


def explain(choice: NoWindow | SeveralWindows | TitlesHidden) -> str:
    match choice:
        case NoWindow(app, pick, candidates):
            return explain_no_window(app, pick, candidates)
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
    """Capture the requested window, or say why not. Nothing here prints or exits."""
    match prepare(request.out):
        case Failed() as refused:
            return refused
        case None:
            pass
        case _ as unreachable:
            assert_never(unreachable)
    match list_windows():
        case ListingFailed(reason):
            return Failed(f"{reason} {NOT_OBSERVABLE}")
        case Windows() as windows:
            choice = choose(request, windows)
        case _ as unreachable:
            assert_never(unreachable)
    match choice:
        case Chosen(window):
            assert belongs_to(request.app, window.owner), (
                f"refusing to capture window {window.id} of another app"
            )
            outcome = capture(window, request.out)
        case NoWindow() | SeveralWindows() | TitlesHidden():
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
        case OutTaken(out):
            return Failed(
                f"{out} appeared while the window was being captured, so it was left unchanged. "
                "Choose a new name."
            )
        case _:
            assert_never(outcome)


def main(argv: list[str]) -> None:
    """The one place that prints an outcome and turns it into an exit status."""
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
