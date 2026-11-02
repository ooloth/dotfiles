#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
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
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

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


@dataclass(frozen=True)
class Window:
    id: int
    owner: str
    title: str | None


@dataclass(frozen=True)
class Chosen:
    window: Window


@dataclass(frozen=True)
class NoWindow:
    app: str
    title: str | None


@dataclass(frozen=True)
class SeveralWindows:
    app: str
    candidates: tuple[Window, ...]


@dataclass(frozen=True)
class TitlesHidden:
    app: str


Choice = Chosen | NoWindow | SeveralWindows | TitlesHidden


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--app", required=True, help="the app's name, such as Rex or Safari")
    parser.add_argument("--title", help="any part of the window's title, to pick one of several")
    parser.add_argument("--out", required=True, type=Path, help="the PNG to write; must not exist")
    args = parser.parse_args(argv)
    if not args.app.strip():
        parser.error("--app needs an app name")
    if args.out.suffix.lower() != ".png":
        parser.error(f"--out must be a .png file, not {args.out.name}")
    return args


def list_windows() -> list[Window]:
    """Every on-screen app window. The result stays in memory: printing any of it could leak
    another app's window titles."""
    result = subprocess.run(
        ["osascript", "-l", "JavaScript", "-e", LIST_WINDOWS_JXA],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit(
            f"Could not list windows: osascript exited {result.returncode}: {result.stderr.strip()}"
        )
    try:
        raw = json.loads(result.stdout)
    except json.JSONDecodeError:
        raw = None
    windows = parse_window_list(raw)
    if windows is None:
        raise SystemExit("osascript returned an unexpected window list, so nothing was captured.")
    return windows


def parse_window_list(raw: object) -> list[Window] | None:
    """The window list, or None when its shape is not what LIST_WINDOWS_JXA prints."""
    if not isinstance(raw, list):
        return None
    windows = []
    for item in raw:
        if not isinstance(item, dict):
            return None
        id_, owner, title = item.get("id"), item.get("owner"), item.get("title")
        if not isinstance(id_, int) or not isinstance(owner, str):
            return None
        if title is not None and not isinstance(title, str):
            return None
        windows.append(Window(id_, owner, title))
    return windows


def belongs_to(app: str, owner: str) -> bool:
    """Whether `owner` is `app`, or starts with `app` followed by a space, in any case."""
    app, owner = app.casefold(), owner.casefold()
    return owner == app or owner.startswith(f"{app} ")


def windows_of(app: str, windows: list[Window]) -> list[Window]:
    return [w for w in windows if belongs_to(app, w.owner)]


def choose(app: str, title: str | None, windows: list[Window]) -> Choice:
    if windows and all(w.title is None for w in windows):
        return TitlesHidden(app)
    mine = windows_of(app, windows)
    if title is not None:
        mine = [w for w in mine if w.title is not None and title.casefold() in w.title.casefold()]
    match len(mine):
        case 0:
            return NoWindow(app, title)
        case 1:
            return Chosen(mine[0])
        case _:
            return SeveralWindows(app, tuple(mine))


def describe(app: str, window: Window) -> str:
    """The text printed about a window. Only ever called on the named app's windows."""
    assert belongs_to(app, window.owner), f"refusing to describe window {window.id} of another app"
    return f'window {window.id} "{window.title or ""}" of {window.owner}'


def capture(app: str, window: Window, out: Path) -> None:
    result = subprocess.run(
        ["screencapture", "-o", "-x", f"-l{window.id}", str(out)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit(
            f"screencapture could not capture {describe(app, window)}: exited {result.returncode}: "
            f"{result.stderr.strip()}"
        )
    if not out.is_file() or out.stat().st_size == 0:
        raise SystemExit(
            f"screencapture reported success but wrote no image for {describe(app, window)}."
        )


def main(argv: list[str]) -> None:
    args = parse_args(argv)
    if args.out.exists():
        raise SystemExit(f"{args.out} already exists, so it was left unchanged. Choose a new name.")
    match choose(args.app, args.title, list_windows()):
        case Chosen(window):
            args.out.parent.mkdir(parents=True, exist_ok=True)
            capture(args.app, window, args.out)
            print(f"Captured {describe(args.app, window)} to {args.out}")
        case NoWindow(app, None):
            raise SystemExit(f"No on-screen window of {app} found. Is the app open and visible?")
        case NoWindow(app, title):
            raise SystemExit(f'No on-screen window of {app} has "{title}" in its title.')
        case SeveralWindows(app, candidates):
            listed = "\n".join(f"  {describe(app, w)}" for w in candidates)
            raise SystemExit(
                f"{app} has {len(candidates)} on-screen windows, so none was captured. "
                f"Pass --title with part of one of these titles:\n{listed}"
            )
        case TitlesHidden(app):
            raise SystemExit(
                f"macOS hides every window title, so {app}'s window cannot be identified. Grant "
                "Screen Recording to this terminal app in System Settings > Privacy & Security, "
                "then run this again."
            )


if __name__ == "__main__":
    main(sys.argv[1:])
