#!/usr/bin/env -S uv run --offline --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Moves every Claude Code session on the work laptop between the subscription and Vertex AI.

A state file says which one sessions should use, and until when they stay on Vertex AI. The status
line, which Claude Code runs every few seconds in every session, calls `tick`. It moves sessions to
Vertex AI when a usage window it reports is used up, moves them back once their time passes, and
makes CLAUDE_CODE_USE_VERTEX in the user settings file match the state. Claude Code reloads that
file in every running session, so they all move together. While sessions are on Vertex AI, a
used-up window a status line reports that resets later than their stay ends extends the stay to that
reset. The StopFailure hook in settings.json runs this script with --stop-failure, which moves
sessions when a subscription session's turn failed on a rate limit, whatever Claude Code's
wording. The Vertex AI project comes from ANTHROPIC_VERTEX_PROJECT_ID, which cc.bash exports on
the work laptop when private.env sets PRIVATE_VERTEX_PROJECT, so nothing here writes a private
value. Without it nothing moves, which keeps personal Macs on the subscription.

Run with: cc-switch [vertex | subscription]. With no argument it says which one sessions use.
"""

from __future__ import annotations

import fcntl
import json
import os
import sys
import tempfile
import time
from collections.abc import Callable, Generator, Iterable, Mapping
from contextlib import contextmanager, suppress
from dataclasses import dataclass, field, replace
from datetime import datetime, tzinfo
from enum import StrEnum
from pathlib import Path
from typing import assert_never

SWITCH_KEY = "CLAUDE_CODE_USE_VERTEX"
PROJECT_KEY = "ANTHROPIC_VERTEX_PROJECT_ID"
FIVE_HOURS_S = 5 * 3600
# How long each of the subscription's usage windows lasts, by the key the status line reports it
# under, for a used-up window whose reset time is unknown
WINDOW_LENGTHS_S = {"five_hour": FIVE_HOURS_S, "seven_day": 7 * 24 * 3600}
# What Claude Code shows when a turn fails on a usage window, by window. A subscription session's
# turn that fails with error "rate_limit" moves sessions; the wording only says which window ran
# out, and so how long they stay. The wording isn't a supported interface: transcripts on the work
# laptop hold both "You've hit your session limit" and "You've hit your 5-hour limit" for the 5-hour
# window, and the errors page names only the first. Each entry is a lowercase piece of the wording,
# with a straight apostrophe, under a key in WINDOW_LENGTHS_S; a test checks both, since a wrong key
# fails an assertion inside the hook, where nothing shows it.
# See: https://code.claude.com/docs/en/errors
LIMIT_MESSAGES = {
    "five_hour": ("you've hit your session limit", "you've hit your 5-hour limit"),
    "seven_day": ("you've hit your weekly limit",),
}
# How long sessions stay on Vertex AI after a rate limit in wording the switch doesn't know, when no
# reported window is used up. Claude Code retries a brief 429 itself, so this is short enough that
# one that outlasts its retries costs little. A real limit that a status line still reports extends
# the stay; a session running on Vertex AI from its start reports no usage windows.
UNRECOGNISED_LIMIT_S = 30 * 60
# How much of a failure's wording the state file keeps, so a long message can't swell it
MESSAGE_LENGTH_MAX = 200
# The status line refreshes every 5 seconds, so a tick that waits longer for another session's
# tick would delay the line. A tick that gives up changes nothing, and the next one tries again.
LOCK_TIMEOUT_S = 0.5


# Each value is also what the state file stores, so rewording one makes saved stays unreadable
class Reason(StrEnum):
    MANUAL = "chosen with cc-switch"
    USAGE_LIMIT = "the status line saw a usage limit reached"
    LIMIT_ERROR = "a turn failed on a usage limit"
    UNRECOGNISED_WORDING = "a turn failed on a rate limit in wording the switch doesn't know"


@dataclass(frozen=True)
class UnknownWording:
    """The latest rate-limit wording the switch didn't know, kept past the stay it caused so it can
    be added to LIMIT_MESSAGES."""

    at: float  # Unix seconds
    message: str

    def __post_init__(self) -> None:
        assert len(self.message) <= MESSAGE_LENGTH_MAX, (
            f"a kept message is {len(self.message)} characters, over {MESSAGE_LENGTH_MAX}"
        )


@dataclass(frozen=True)
class KnownLimit:
    """A turn that failed on a rate limit in wording LIMIT_MESSAGES knows, naming its window."""

    window: str

    def __post_init__(self) -> None:
        assert self.window in WINDOW_LENGTHS_S, f"no window {self.window}"


@dataclass(frozen=True)
class UnknownLimit:
    """A turn that failed on a rate limit in wording the switch doesn't know, kept to be added."""

    message: str

    def __post_init__(self) -> None:
        assert len(self.message) <= MESSAGE_LENGTH_MAX, (
            f"a failure's message is {len(self.message)} characters, over {MESSAGE_LENGTH_MAX}"
        )


LimitFailure = KnownLimit | UnknownLimit


@dataclass(frozen=True)
class UsageSeen:
    """One of the subscription's usage windows, as the status line last reported it."""

    used_percent: float
    resets_at: float | None  # Unix seconds


@dataclass(frozen=True)
class OnSubscription:
    # Moved back by hand while a window was used up: no trigger moves sessions before this time
    held_until: float | None = None  # Unix seconds


@dataclass(frozen=True)
class OnVertex:
    since: float  # Unix seconds
    until: float
    reason: Reason

    def __post_init__(self) -> None:
        assert self.until > self.since, f"Vertex AI until {self.until} is not after {self.since}"


Switch = OnSubscription | OnVertex


@dataclass(frozen=True)
class State:
    switch: Switch = OnSubscription()
    # Each of the subscription's usage windows as the status line last reported it, by its key
    usage: Mapping[str, UsageSeen] = field(default_factory=dict)
    unknown_wording: UnknownWording | None = None


@dataclass(frozen=True)
class Unchanged:
    pass


@dataclass(frozen=True)
class Wrote:
    value: str


@dataclass(frozen=True)
class Skipped:
    why: str


SettingsSync = Unchanged | Wrote | Skipped


@dataclass(frozen=True)
class Paths:
    state: Path
    lock: Path
    settings: Path

    @classmethod
    def under(cls, home: Path) -> Paths:
        state_dir = home / ".local" / "state" / "claude"
        return cls(
            state=state_dir / "provider.json",
            lock=state_dir / "provider.lock",
            settings=home / ".claude" / "settings.json",
        )


class Busy(Exception):
    """Another session held the lock for longer than LOCK_TIMEOUT_S."""


class NotWritten(Exception):
    """The settings file could not take the switch, so sessions stay where they are."""


def parse_state(text: str | None) -> State:
    """The state a file holds. A missing or unreadable file means the subscription, since a person
    can edit the file and an interrupted write can leave it empty."""
    try:
        data = json.loads(text or "")
        usage = {
            str(key): UsageSeen(
                float(seen["used_percent"]),
                None if seen.get("resets_at") is None else float(seen["resets_at"]),
            )
            for key, seen in data.get("usage", {}).items()
        }
        kept = _parse_unknown_wording(data.get("unknown_wording"))
        wording = kept or _wording_beside_reason(data)
        if data.get("provider") != "vertex":
            held = data.get("held_until")
            return State(OnSubscription(None if held is None else float(held)), usage, wording)
        switch = OnVertex(float(data["since"]), float(data["until"]), Reason(data["reason"]))
        return State(switch, usage, wording)
    except (ValueError, TypeError, KeyError, AttributeError, AssertionError):
        return State()


def _parse_unknown_wording(data: object) -> UnknownWording | None:
    """The kept wording, or None when it is absent or malformed, so a bad edit to it can't discard
    the rest of the state."""
    try:
        assert isinstance(data, Mapping)
        return UnknownWording(float(data["at"]), _capped(str(data["message"])))
    except (ValueError, TypeError, KeyError, AssertionError):
        return None


def _wording_beside_reason(data: Mapping[str, object]) -> UnknownWording | None:
    """The wording a state file written by 89dfaee1's hook keeps as `message` beside a stay's
    reason, seen when the stay began, or None when the file holds no such stay. dump_state never
    writes this shape, so the first write after reading it moves the wording to unknown_wording."""
    message, since = data.get("message"), data.get("since")
    if data.get("reason") != Reason.UNRECOGNISED_WORDING or not isinstance(message, str):
        return None
    if not isinstance(since, int | float):
        return None
    return UnknownWording(float(since), _capped(message))


def _capped(message: str) -> str:
    return message[:MESSAGE_LENGTH_MAX]


def dump_state(state: State) -> str:
    data: dict[str, object] = {"provider": "subscription"}
    if isinstance(state.switch, OnSubscription) and state.switch.held_until is not None:
        data["held_until"] = state.switch.held_until
    if isinstance(state.switch, OnVertex):
        data = {
            "provider": "vertex",
            "since": state.switch.since,
            "until": state.switch.until,
            "reason": state.switch.reason.value,
        }
    data["usage"] = {
        key: {"used_percent": seen.used_percent, "resets_at": seen.resets_at}
        for key, seen in state.usage.items()
    }
    if state.unknown_wording is not None:
        data["unknown_wording"] = {
            "at": state.unknown_wording.at,
            "message": state.unknown_wording.message,
        }
    return json.dumps(data, indent=2) + "\n"


def after_tick(state: State, now: float, windows: Mapping[str, UsageSeen]) -> State:
    """The state once `now` has come. On Vertex AI for longer when a used-up window resets after the
    stay ends, back on the subscription when the Vertex AI time is up, and on Vertex AI when a window
    that has not reset yet is used up, until the latest such reset. It also holds the latest reset
    time each window reported."""
    switch = state.switch
    if isinstance(switch, OnVertex):
        # Only a known reset extends the stay: one guessed from a window's length would move later
        # on every tick, so the stay would never end
        later = _latest_used_up_reset(windows.values(), now)
        extended = (
            replace(switch, until=later) if later is not None and later > switch.until else switch
        )
        assert extended.until >= switch.until, (
            f"the stay shrank from {switch.until} to {extended.until}"
        )
        switch = extended
    if isinstance(switch, OnVertex) and now >= switch.until:
        switch = OnSubscription()
    if isinstance(switch, OnSubscription) and _held(switch, now):
        return replace(state, switch=switch, usage={**state.usage, **windows})
    if isinstance(switch, OnSubscription):
        # A window whose reset has passed can still say 100% until Claude Code next reports it
        used_up = [
            seen.resets_at if seen.resets_at is not None else now + WINDOW_LENGTHS_S[key]
            for key, seen in windows.items()
            if seen.used_percent >= 100 and (seen.resets_at is None or seen.resets_at > now)
        ]
        if used_up:
            switch = OnVertex(now, max(used_up), Reason.USAGE_LIMIT)
    return replace(state, switch=switch, usage={**state.usage, **windows})


def _held(switch: OnSubscription, now: float) -> bool:
    return switch.held_until is not None and now < switch.held_until


def _latest_used_up_reset(windows: Iterable[UsageSeen], now: float) -> float | None:
    """The latest reset still ahead of a used-up window, or None when no window has one."""
    resets = [
        seen.resets_at
        for seen in windows
        if seen.used_percent >= 100 and seen.resets_at is not None and seen.resets_at > now
    ]
    return max(resets) if resets else None


def parse_limit_failure(payload: Mapping[str, object]) -> LimitFailure | None:
    """The rate limit a turn failed on, from the StopFailure hook's input, or None when the turn
    failed for another reason. The wording names the window when the switch knows it."""
    if payload.get("error") != "rate_limit":
        return None
    parts = [str(payload.get(key) or "") for key in ("last_assistant_message", "error_details")]
    message = " ".join(part for part in parts if part)
    window = _window_named(message)
    return UnknownLimit(_capped(message)) if window is None else KnownLimit(window)


def _window_named(message: str) -> str | None:
    """The usage window a failure's wording names, or None when LIMIT_MESSAGES doesn't know it."""
    text = message.replace("\u2019", "'").lower()
    return next(
        (key for key, wordings in LIMIT_MESSAGES.items() if any(w in text for w in wordings)),
        None,
    )


def after_limit_failure(state: State, now: float, failure: LimitFailure) -> State:
    """Vertex AI after a turn failed on a rate limit. A known window stays until it resets, or for
    its full length when no reset time is recorded. Unknown wording stays until the latest reset of
    a used-up window, or for UNRECOGNISED_LIMIT_S when none is used up. Sessions already on Vertex
    AI keep their time, and a hold keeps them on the subscription. Unknown wording is kept whether
    or not sessions move."""
    if isinstance(failure, UnknownLimit):
        state = replace(state, unknown_wording=UnknownWording(now, failure.message))
    if isinstance(state.switch, OnVertex) or _held(state.switch, now):
        return state
    match failure:
        case UnknownLimit():
            latest = _latest_used_up_reset(state.usage.values(), now)
            until = latest if latest is not None else now + UNRECOGNISED_LIMIT_S
            cause = Reason.UNRECOGNISED_WORDING
        case KnownLimit(window):
            seen = state.usage.get(window)
            resets = seen.resets_at if seen is not None else None
            until = (
                resets if resets is not None and resets > now else now + WINDOW_LENGTHS_S[window]
            )
            cause = Reason.LIMIT_ERROR
        case unexpected:
            assert_never(unexpected)
    return replace(state, switch=OnVertex(now, until, cause))


def choose_vertex(state: State, now: float) -> State:
    """Vertex AI until the 5-hour window resets, or for 5 hours when no reset time is known."""
    seen = state.usage.get("five_hour")
    resets = seen.resets_at if seen is not None else None
    until = resets if resets is not None and resets > now else now + FIVE_HOURS_S
    return replace(state, switch=OnVertex(now, until, Reason.MANUAL))


def choose_subscription(state: State, now: float) -> State:
    """The subscription, held until the latest used-up window resets, so neither trigger moves
    sessions straight back to Vertex AI. No hold when no window is used up."""
    return replace(state, switch=OnSubscription(_latest_used_up_reset(state.usage.values(), now)))


def switch_value(switch: Switch) -> str:
    return "1" if isinstance(switch, OnVertex) else ""


def _write_atomically(path: Path, text: str) -> None:
    """Replace the file `path` leads to, through any symlink, so a reader sees the old text or the
    new, never part of either, and the symlink stays."""
    target = path.resolve()
    mode = target.stat().st_mode & 0o777 if target.exists() else 0o644
    with tempfile.NamedTemporaryFile("w", dir=target.parent, delete=False) as tmp:
        tmp.write(text)
    os.chmod(tmp.name, mode)
    os.replace(tmp.name, target)


def sync_settings(settings: Path, switch: Switch, env: Mapping[str, str]) -> SettingsSync:
    """Make the settings file's switch match `switch`, changing nothing else in the file."""
    if not env.get(PROJECT_KEY):
        return Skipped(f"{PROJECT_KEY} is unset, so there is no Vertex AI project to move to")
    try:
        old_text = settings.read_text()
        old = json.loads(old_text)
        old_env = old["env"]
    except (OSError, ValueError, KeyError, TypeError):
        return Skipped(f"{settings} has no readable env block")
    value = switch_value(switch)
    if old_env.get(SWITCH_KEY) == value:
        return Unchanged()
    new = {**old, "env": {**old_env, SWITCH_KEY: value}}
    new_text = json.dumps(new, indent=2, ensure_ascii=False) + "\n"
    assert json.loads(new_text)["env"][SWITCH_KEY] == value, "the new text lost the switch"
    assert {k: v for k, v in json.loads(new_text).items() if k != "env"} == {
        k: v for k, v in old.items() if k != "env"
    }, "the new text changed more than the env block"
    _write_atomically(settings, new_text)
    return Wrote(value)


@contextmanager
def _locked(lock: Path) -> Generator[None]:
    lock.parent.mkdir(parents=True, exist_ok=True)
    deadline = time.monotonic() + LOCK_TIMEOUT_S
    with lock.open("a") as handle:
        while True:
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise Busy from None
                time.sleep(0.01)
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def _read_state(paths: Paths) -> State:
    try:
        return parse_state(paths.state.read_text())
    except OSError:
        return State()


def _update(paths: Paths, env: Mapping[str, str], change: Callable[[State], State]) -> State:
    """Apply `change` to the saved state under the lock, save it, and sync the settings file."""
    with _locked(paths.lock):
        old = _read_state(paths)
        new = change(old)
        if new != old:
            _write_atomically(paths.state, dump_state(new))
        result = sync_settings(paths.settings, new.switch, env)
        if isinstance(result, Skipped):
            raise NotWritten(result.why)
        return new


def tick(
    now: float, windows: Mapping[str, UsageSeen], paths: Paths, env: Mapping[str, str]
) -> Switch:
    """What the status line runs on each refresh. Returns the provider sessions should now use."""
    if not env.get(PROJECT_KEY):
        return OnSubscription()
    try:
        return _update(paths, env, lambda state: after_tick(state, now, windows)).switch
    except Busy:
        return _read_state(paths).switch


def clock(at: float, now: float, zone: tzinfo | None = None) -> str:
    """`at` on a 12-hour clock, such as 3pm or 2:50am, with its weekday when it falls on another day
    than `now`, and its date instead when six days or more away, before or after, since a weekday
    then reads as this week's.
    `zone` sets the time zone: None is local."""
    when = datetime.fromtimestamp(at, zone)
    hour = when.hour % 12 or 12
    minutes = f":{when.minute:02d}" if when.minute else ""
    clock = f"{hour}{minutes}{'am' if when.hour < 12 else 'pm'}"
    if abs(at - now) >= 6 * 24 * 3600:
        month = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
        return f"{month[when.month - 1]} {when.day} {clock}"
    if when.date() == datetime.fromtimestamp(now, zone).date():
        return clock
    weekday = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")[when.weekday()]
    return f"{weekday} {clock}"


def describe(state: State, now: float) -> str:
    """What cc-switch prints: where sessions are, and any kept wording LIMIT_MESSAGES lacks."""
    wording = state.unknown_wording
    if wording is None or _window_named(wording.message) is not None:
        return _describe_switch(state.switch, now)
    seen = clock(wording.at, now)
    return (
        f"{_describe_switch(state.switch, now)}\n"
        f'Rate-limit wording the switch doesn\'t know, seen {seen}: "{wording.message}"\n'
        "If it is a usage limit, add it to LIMIT_MESSAGES in tools/claude/provider_switch.py, as the "
        "comment above it says."
    )


def _describe_switch(switch: Switch, now: float) -> str:
    if isinstance(switch, OnVertex):
        return (
            f"Sessions use Vertex AI until {clock(switch.until, now)} "
            f"(since {clock(switch.since, now)}, {switch.reason.value}).\n"
            "To move them back to the subscription now: cc-switch subscription"
        )
    if switch.held_until is not None and now < switch.held_until:
        return (
            f"Sessions stay on the subscription until {clock(switch.held_until, now)}, when the "
            "used-up limit resets, and nothing moves them to Vertex AI before then.\n"
            "To move them to Vertex AI now: cc-switch vertex"
        )
    return (
        "Sessions use the subscription.\n"
        "To move them to Vertex AI until the 5-hour limit resets: cc-switch vertex"
    )


def stop_failure(payload_text: str, paths: Paths, env: Mapping[str, str], now: float) -> int:
    """The StopFailure hook: move sessions to Vertex AI when a turn failed on a rate limit. Claude
    Code ignores the hook's output and exit status, so it always exits 0. A session already on
    Vertex AI, such as one cc-vertex started, does nothing: its 429 comes from Vertex AI itself, so
    moving the other sessions there would put them on the project that is throttling."""
    try:
        payload = json.loads(payload_text)
    except ValueError:
        return 0
    failure = parse_limit_failure(payload) if isinstance(payload, dict) else None
    if failure is None or not env.get(PROJECT_KEY) or env.get(SWITCH_KEY) == "1":
        return 0
    with suppress(Busy, NotWritten):
        _update(paths, env, lambda state: after_limit_failure(state, now, failure))
    return 0


def main(argv: list[str], paths: Paths, env: Mapping[str, str], now: float) -> int:
    if argv == ["--stop-failure"]:
        return stop_failure(sys.stdin.read(), paths, env, now)
    choice = argv[0] if argv else None
    if choice not in (None, "vertex", "subscription") or len(argv) > 1:
        print("Usage: cc-switch [vertex | subscription]", file=sys.stderr)
        return 2
    if choice is not None and not env.get(PROJECT_KEY):
        print(
            f"{PROJECT_KEY} is unset, so there is no Vertex AI project to move to", file=sys.stderr
        )
        return 1
    if choice is None:
        print(describe(_read_state(paths), now))
        return 0
    change = (
        (lambda s: choose_vertex(s, now))
        if choice == "vertex"
        else (lambda s: choose_subscription(s, now))
    )
    try:
        state = _update(paths, env, change)
    except Busy:
        print("Another session is changing the switch; try again.", file=sys.stderr)
        return 1
    except NotWritten as error:
        print(f"Sessions did not move: {error}", file=sys.stderr)
        return 1
    print(describe(state, now))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:], Paths.under(Path.home()), os.environ, time.time()))
