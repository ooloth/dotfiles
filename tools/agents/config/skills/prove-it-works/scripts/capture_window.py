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
title, in any case.

Window titles can hold private information, so nothing about another app's windows is ever printed,
even when the run fails. The script exits 1 with a sentence when it finds no window, finds several
(listing only that app's titles, so a `--title` can pick one), sees every title hidden because the
terminal lacks macOS's Screen Recording permission, or when either tool fails. It refuses to write
over an existing file, so earlier evidence is never replaced.

Caller: the prove-it-works skill. Open the image afterwards and check it shows the expected window
and nothing secret; this script cannot judge that.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import NewType, assert_never

from pydantic import BaseModel, ConfigDict, TypeAdapter, ValidationError, field_validator

WindowId = NewType("WindowId", int)
AppName = NewType("AppName", str)
TitleFilter = NewType("TitleFilter", str)
EvidencePath = NewType("EvidencePath", Path)

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


# Boundary: what the caller and osascript hand the script.


class CaptureArgs(BaseModel):
    """The command line, validated before anything runs."""

    model_config = ConfigDict(frozen=True, strict=True)

    app: str
    title: str | None
    out: Path

    @field_validator("app")
    @classmethod
    def app_is_named(cls, app: str) -> str:
        if not app.strip():
            raise ValueError("--app needs an app name")
        return app

    @field_validator("out")
    @classmethod
    def out_is_a_png(cls, out: Path) -> Path:
        if out.suffix.lower() != ".png":
            raise ValueError(f"--out must be a .png file, not {out.name}")
        return out


class ListedWindow(BaseModel):
    """One window as osascript reports it."""

    model_config = ConfigDict(frozen=True, strict=True)

    id: int
    owner: str
    title: str | None


WINDOW_LIST = TypeAdapter(list[ListedWindow])


# Domain.


@dataclass(frozen=True)
class CaptureRequest:
    app: AppName
    title: TitleFilter | None
    out: EvidencePath


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
    title: TitleFilter | None


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


Listing = Windows | ListingFailed
Choice = Chosen | NoWindow | SeveralWindows | TitlesHidden
CaptureOutcome = Captured | CaptureFailed


def parse_request(argv: list[str]) -> CaptureRequest:
    parser = argparse.ArgumentParser(description=(__doc__ or "").splitlines()[0])
    parser.add_argument("--app", required=True, help="the app's name, such as Rex or Safari")
    parser.add_argument("--title", help="any part of the window's title, to pick one of several")
    parser.add_argument("--out", required=True, type=Path, help="the PNG to write; must not exist")
    raw = parser.parse_args(argv)
    try:
        args = CaptureArgs(app=raw.app, title=raw.title, out=raw.out)
    except ValidationError as error:
        parser.error("; ".join(str(e["ctx"]["error"]) for e in error.errors() if "ctx" in e))
    return CaptureRequest(
        app=AppName(args.app),
        title=TitleFilter(args.title) if args.title is not None else None,
        out=EvidencePath(args.out),
    )


def list_windows() -> Listing:
    result = subprocess.run(
        ["osascript", "-l", "JavaScript", "-e", LIST_WINDOWS_JXA],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return ListingFailed(
            f"Could not list windows: osascript exited {result.returncode}: {result.stderr.strip()}"
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
    if windows.all and all(w.title is None for w in windows.all):
        return TitlesHidden(request.app)
    mine = windows_of(request.app, windows)
    title = request.title
    if title is not None:
        mine = tuple(
            w for w in mine if w.title is not None and title.casefold() in w.title.casefold()
        )
    match len(mine):
        case 0:
            return NoWindow(request.app, title)
        case 1:
            return Chosen(mine[0])
        case _:
            return SeveralWindows(request.app, mine)


def capture(window: Window, out: EvidencePath) -> CaptureOutcome:
    out.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        ["screencapture", "-o", "-x", f"-l{window.id}", str(out)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return CaptureFailed(window, f"exited {result.returncode}: {result.stderr.strip()}")
    if not out.is_file() or out.stat().st_size == 0:
        return CaptureFailed(window, "it reported success but wrote no image")
    return Captured(window, out)


def describe(app: AppName, window: Window) -> str:
    """The text printed about a window. Only ever called on the named app's windows."""
    assert belongs_to(app, window.owner), f"refusing to describe window {window.id} of another app"
    return f'window {window.id} "{window.title or ""}" of {window.owner}'


def explain(app: AppName, choice: NoWindow | SeveralWindows | TitlesHidden) -> str:
    match choice:
        case NoWindow(_, None):
            return f"No on-screen window of {app} found. Is the app open and visible?"
        case NoWindow(_, title):
            return f'No on-screen window of {app} has "{title}" in its title.'
        case SeveralWindows(_, candidates):
            listed = "\n".join(f"  {describe(app, w)}" for w in candidates)
            return (
                f"{app} has {len(candidates)} on-screen windows, so none was captured. "
                f"Pass --title with part of one of these titles:\n{listed}"
            )
        case TitlesHidden():
            return (
                f"macOS hides every window title, so {app}'s window cannot be identified. Grant "
                "Screen Recording to this terminal app in System Settings > Privacy & Security, "
                "then run this again."
            )
        case _:
            assert_never(choice)


def run(request: CaptureRequest) -> str:
    """The sentence to print on success. Every expected failure exits 1 with its own sentence."""
    if request.out.exists():
        raise SystemExit(
            f"{request.out} already exists, so it was left unchanged. Choose a new name."
        )
    match list_windows():
        case ListingFailed(reason):
            raise SystemExit(reason)
        case Windows() as windows:
            choice = choose(request, windows)
        case _ as unreachable:
            assert_never(unreachable)
    match choice:
        case Chosen(window):
            outcome = capture(window, request.out)
        case NoWindow() | SeveralWindows() | TitlesHidden():
            raise SystemExit(explain(request.app, choice))
        case _:
            assert_never(choice)
    match outcome:
        case Captured(window, out):
            return f"Captured {describe(request.app, window)} to {out}"
        case CaptureFailed(window, reason):
            raise SystemExit(
                f"screencapture could not capture {describe(request.app, window)}: {reason}"
            )
        case _:
            assert_never(outcome)


if __name__ == "__main__":
    print(run(parse_request(sys.argv[1:])))
