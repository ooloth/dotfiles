#!/usr/bin/env -S uv run --offline --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Print the Claude Code status line: location and git state on the left, and on the right the model,
the context used, and how much of the subscription's 5-hour and 7-day limits is left and when each
resets.

Run by Claude Code, which pipes the session's JSON to stdin and sets COLUMNS. To try it by hand:
  echo '{"workspace": {"current_dir": "."}}' | COLUMNS=100 tools/claude/statusline.py

The JSON's fields are described at https://code.claude.com/docs/en/statusline#full-json-schema.
"""

from __future__ import annotations

import json
import math
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, tzinfo
from enum import Enum, StrEnum


class Colour(StrEnum):
    GREEN = "\033[32m"
    CYAN = "\033[36m"
    YELLOW = "\033[33m"
    RED = "\033[31m"


RESET = "\033[0m"
BRANCH_ICON = "\ue725"  # nf-dev-git_branch, as in tools/tmux/config/gitmux.conf
# Followed by two spaces, because Rex draws this glyph wider than one cell and covers a single space
FOLDER_ICON = "\uf07b"  # nf-fa-folder

# Claude Code indents the status line by 2 columns and cuts it off with "…" past COLUMNS - 4
EDGE_MARGIN = 4

# Context colours by tokens used: yellow from 125k, red from 250k, where measured long-context
# quality stops being near its best and then clearly drops. Quality follows the token count, not
# the share of the window, so the thresholds only shrink to half and three quarters of a window too
# small to reach them, which still warns before the window fills.
CONTEXT_YELLOW_K = 125
CONTEXT_RED_K = 250

# A rate limit window is coloured by the use it is on pace to reach by its reset: yellow from 80%,
# red from 100%. Before a tenth of the window has passed, a projection from so little time swings
# too much to trust, so it projects as if a tenth had passed. That never warns falsely, since a pace
# that reaches 80% from a tenth of the window is at least as fast, and the colour never jumps up as
# time passes with no new use. A window with no reset time is coloured by its use so far.
USAGE_YELLOW_PERCENT = 80
USAGE_RED_PERCENT = 100
MIN_ELAPSED_TO_PROJECT = 0.1

# Nerd Font batteries by tenths of the limit left, from md-battery_outline when nothing is left
# through md-battery_10 to md-battery_90, then md-battery when the whole limit is left. They are
# narrow, so one space follows, unlike the wider folder icon.
BATTERY_ICONS = ("\U000f008e", *(chr(0xF0079 + tenths) for tenths in range(1, 10)), "\U000f0079")
# Spelled out rather than taken from strftime, which follows the system locale
WEEKDAYS = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")


class WindowKind(Enum):
    """The rate limit windows Claude Code reports for a claude.ai subscription, in display order."""

    FIVE_HOUR = ("five_hour", 5 * 3600, False)
    SEVEN_DAY = ("seven_day", 7 * 24 * 3600, True)

    def __init__(self, key: str, length_s: int, shows_weekday: bool) -> None:
        self.key = key
        self.length_s = length_s
        # The weekly reset always names its day, even today, and the 5-hour one never does, so the
        # two can be told apart without labels
        self.shows_weekday = shows_weekday


@dataclass(frozen=True)
class ContextUsage:
    used_k: int
    window_k: int


@dataclass(frozen=True)
class UsageWindow:
    """How much of one of the subscription's rate limits is used, and when it resets."""

    kind: WindowKind
    used_percent: float
    resets_at: float | None  # Unix seconds


@dataclass(frozen=True)
class Session:
    model_id: str
    directory: str
    context: ContextUsage
    usage: tuple[UsageWindow, ...]  # only the windows Claude Code reported, in WindowKind order


@dataclass(frozen=True)
class Checkout:
    """Where the session is and what git says about it. Counts of 0 are shown as nothing."""

    location: str
    branch: str | None  # None on a detached HEAD or outside a repo
    behind: int
    ahead: int
    insertions: int
    deletions: int


@dataclass(frozen=True)
class Segment:
    text: str
    colour: Colour | None = None


@dataclass(frozen=True)
class StatusLine:
    left: list[Segment]
    right: list[Segment]


def _field(data: object, *keys: str) -> object:
    """The value at a path of keys, or None where any key along it is missing."""
    for key in keys:
        if not isinstance(data, dict):
            return None
        data = data.get(key)
    return data


def _text(value: object, default: str) -> str:
    return value if isinstance(value, str) else default


def _number_or_none(value: object) -> float | None:
    if isinstance(value, bool) or not isinstance(value, int | float):
        return None
    return value


def _number(value: object, default: float) -> float:
    number = _number_or_none(value)
    return default if number is None else number


def _round(value: float) -> int:
    """Round half away from zero, so 0.5 rounds up, rather than Python's half to even."""
    return int(math.copysign(math.floor(abs(value) + 0.5), value))


def parse_session(raw: str) -> Session:
    data = json.loads(raw)
    window = _number(_field(data, "context_window", "context_window_size"), 200_000)
    # Claude Code computes used_percentage itself, so the token counts are not added up here
    used_percentage = _number(_field(data, "context_window", "used_percentage"), 0)
    directory = _field(data, "workspace", "current_dir") or _field(data, "cwd")
    # rate_limits comes only for claude.ai subscribers, after the session's first response, and
    # each window can be absent on its own
    usage = []
    for kind in WindowKind:
        used = _number_or_none(_field(data, "rate_limits", kind.key, "used_percentage"))
        if used is not None:
            resets_at = _number_or_none(_field(data, "rate_limits", kind.key, "resets_at"))
            usage.append(UsageWindow(kind, used, resets_at))
    return Session(
        model_id=_text(_field(data, "model", "id"), "claude"),
        directory=_text(directory, "."),
        context=ContextUsage(
            used_k=_round(used_percentage * window / 100_000), window_k=_round(window / 1000)
        ),
        usage=tuple(usage),
    )


def _git(directory: str, *args: str) -> str | None:
    """git's stdout, or None when git fails or is missing."""
    try:
        result = subprocess.run(
            ["git", "-C", directory, *args],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
    except OSError:
        return None
    return result.stdout if result.returncode == 0 else None


def _basename(path: str) -> str:
    """The last part of a path, as the `basename` command gives it."""
    stripped = path.rstrip("/")
    return os.path.basename(stripped) if stripped else ("/" if path else "")


def _count(pattern: str, text: str) -> int:
    match = re.search(pattern, text)
    return int(match[1]) if match else 0


def read_checkout(directory: str) -> Checkout:
    # The checkout root's name plus the path below it, so a linked worktree shows its own directory.
    # git computes the prefix itself, which stays right when the directory reaches the checkout
    # through a symlink.
    toplevel = _git(directory, "rev-parse", "--show-toplevel", "--show-prefix")
    if toplevel is None:
        location = _basename(directory)
    else:
        root, _, rest = toplevel.partition("\n")
        prefix = rest.split("\n", 1)[0].removesuffix("/")
        location = _basename(root) + (f"/{prefix}" if prefix else "")

    # Empty on a detached HEAD or outside a repo
    branch = (_git(directory, "branch", "--show-current") or "").strip() or None

    # Commits behind and ahead of the upstream as of the last fetch, then the lines inserted and
    # deleted by staged and unstaged changes against HEAD. git gives nothing here without an
    # upstream or a first commit.
    divergence = (
        _git(directory, "rev-list", "--left-right", "--count", "@{upstream}...HEAD") or ""
    ).split()
    shortstat = _git(directory, "diff", "HEAD", "--shortstat") or ""
    behind, ahead = (int(divergence[0]), int(divergence[1])) if len(divergence) == 2 else (0, 0)

    return Checkout(
        location=location,
        branch=branch,
        behind=behind,
        ahead=ahead,
        insertions=_count(r" (\d+) insertions?\(\+\)", shortstat),
        deletions=_count(r" (\d+) deletions?\(-\)", shortstat),
    )


def _counted(count: int, symbol: str) -> str:
    return f"{symbol}{count}" if count > 0 else ""


def _git_segments(checkout: Checkout) -> list[Segment]:
    """The branch and the counts after it, or the counts alone on a detached HEAD."""
    segments = [Segment(f"{BRANCH_ICON} {checkout.branch}")] if checkout.branch else []
    stats = [
        (_counted(checkout.behind, "↓") + _counted(checkout.ahead, "↑"), Colour.CYAN),
        (_counted(checkout.insertions, "+"), Colour.GREEN),
        (_counted(checkout.deletions, "-"), Colour.RED),
    ]
    for text, colour in stats:
        if text:
            if segments:
                segments.append(Segment(" "))
            segments.append(Segment(text, colour))
    return segments


def _context_colour(context: ContextUsage) -> Colour | None:
    yellow_k = min(context.window_k // 2, CONTEXT_YELLOW_K)
    red_k = min(context.window_k * 3 // 4, CONTEXT_RED_K)
    if context.used_k >= red_k:
        return Colour.RED
    if context.used_k >= yellow_k:
        return Colour.YELLOW
    return None


def _usage_colour(window: UsageWindow, now: float) -> Colour | None:
    used = window.used_percent
    projected = used
    if window.resets_at is not None:
        length_s = window.kind.length_s
        started_at = window.resets_at - length_s
        elapsed = min(max((now - started_at) / length_s, MIN_ELAPSED_TO_PROJECT), 1.0)
        projected = used / elapsed
    assert projected >= used, f"projected {projected}% is below the {used}% already used"
    if projected >= USAGE_RED_PERCENT:
        return Colour.RED
    if projected >= USAGE_YELLOW_PERCENT:
        return Colour.YELLOW
    return None


def _battery(remaining_percent: int) -> str:
    """The battery icon nearest to the share of the limit left."""
    tenths = _round(remaining_percent / 10)
    assert 0 <= tenths < len(BATTERY_ICONS), f"no battery for {remaining_percent}% left"
    return BATTERY_ICONS[tenths]


def _reset_time(window: UsageWindow, zone: tzinfo | None) -> str:
    """When the window resets on a 12-hour clock, such as 2:50am or Mon 8am, or "" if unknown."""
    if window.resets_at is None:
        return ""
    resets = datetime.fromtimestamp(window.resets_at, zone)
    hour = resets.hour % 12 or 12
    minutes = f":{resets.minute:02d}" if resets.minute else ""
    clock = f"{hour}{minutes}{'am' if resets.hour < 12 else 'pm'}"
    return f"{WEEKDAYS[resets.weekday()]} {clock}" if window.kind.shows_weekday else clock


def _usage_text(window: UsageWindow, zone: tzinfo | None) -> str:
    # Usage beyond the limit shows as nothing left
    remaining = min(max(_round(100 - window.used_percent), 0), 100)
    reset_time = _reset_time(window, zone)
    return f"{_battery(remaining)} {remaining}%" + (f" {reset_time}" if reset_time else "")


def _usage_segments(
    usage: tuple[UsageWindow, ...], now: float, zone: tzinfo | None
) -> list[Segment]:
    segments = []
    for window in usage:
        # Claude Code drops a window once it resets, and so does this between its refreshes
        if window.resets_at is not None and window.resets_at <= now:
            continue
        segments += [
            Segment(" · "),
            Segment(_usage_text(window, zone), _usage_colour(window, now)),
        ]
    return segments


def compose_line(
    session: Session, checkout: Checkout, now: float, zone: tzinfo | None
) -> StatusLine:
    """The line's segments. `zone` sets the time zone reset times are shown in: None is local."""
    left = [Segment(f"{FOLDER_ICON}  {checkout.location}")]
    git_segments = _git_segments(checkout)
    if git_segments:
        left += [Segment(" · "), *git_segments]

    context = session.context
    right = [
        Segment(f"{session.model_id} · "),
        Segment(f"{context.used_k}k/{context.window_k}k", _context_colour(context)),
        *_usage_segments(session.usage, now, zone),
    ]
    return StatusLine(left=left, right=right)


def width(segments: list[Segment]) -> int:
    """Screen columns taken, which colour codes do not add to."""
    return sum(len(segment.text) for segment in segments)


def gap(line: StatusLine, columns: int | None) -> int:
    """Spaces between the sides: enough to put the right side at the edge, or one if it won't fit."""
    if columns is None:
        return 1
    free = columns - EDGE_MARGIN - width(line.left) - width(line.right)
    return max(free, 1)


def _render(segments: list[Segment]) -> str:
    return "".join(
        f"{segment.colour}{segment.text}{RESET}" if segment.colour else segment.text
        for segment in segments
    )


def render(line: StatusLine, columns: int | None) -> str:
    return _render(line.left) + " " * gap(line, columns) + _render(line.right)


def parse_columns(value: str | None) -> int | None:
    return int(value) if value is not None and re.fullmatch(r"[0-9]+", value) else None


def main() -> None:
    session = parse_session(sys.stdin.read())
    line = compose_line(session, read_checkout(session.directory), time.time(), None)
    print(render(line, parse_columns(os.environ.get("COLUMNS"))))


if __name__ == "__main__":
    main()
