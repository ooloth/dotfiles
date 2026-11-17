#!/usr/bin/env -S uv run --offline --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Moves every Claude Code session on the work laptop between the subscription and Vertex AI.

A state file says which one sessions should use, and until when they stay on Vertex AI. The status
line, which Claude Code runs every few seconds in every session, calls `tick`. It moves sessions to
Vertex AI when a usage window it reports is used up, moves them back once their time passes, and
makes CLAUDE_CODE_USE_VERTEX in the user settings file match the state. The StopFailure hook in
settings.json runs this script with --stop-failure, which moves sessions when a turn failed on a
usage limit.
Claude Code reloads that file in every running session, so they all move together. The Vertex AI
project comes from ANTHROPIC_VERTEX_PROJECT_ID, which cc.bash exports for every session it starts
on the work laptop, so nothing here writes a private value. Without it nothing moves, which keeps
personal Macs on the subscription.

Run with: cc-switch [vertex | subscription]. With no argument it says which one sessions use.
"""

from __future__ import annotations

import fcntl
import json
import os
import sys
import tempfile
import time
from collections.abc import Callable, Generator, Mapping
from contextlib import contextmanager, suppress
from dataclasses import dataclass, field, replace
from datetime import datetime, tzinfo
from enum import StrEnum
from pathlib import Path

SWITCH_KEY = "CLAUDE_CODE_USE_VERTEX"
PROJECT_KEY = "ANTHROPIC_VERTEX_PROJECT_ID"
FIVE_HOURS_S = 5 * 3600
# How long each of the subscription's usage windows lasts, by the key the status line reports it
# under, for a used-up window whose reset time is unknown
WINDOW_LENGTHS_S = {"five_hour": FIVE_HOURS_S, "seven_day": 7 * 24 * 3600}
# What Claude Code shows when a turn fails on a usage window, by window. Claude Code retries a
# brief 429 itself and words it differently, so only these move sessions.
# See: https://code.claude.com/docs/en/errors
LIMIT_MESSAGES = {
    "five_hour": "you've hit your session limit",
    "seven_day": "you've hit your weekly limit",
}
# The status line refreshes every 5 seconds, so a tick that waits longer for another session's
# tick would delay the line. A tick that gives up changes nothing, and the next one tries again.
LOCK_TIMEOUT_S = 0.5


class Reason(StrEnum):
    MANUAL = "chosen with cc-switch"
    USAGE_LIMIT = "the status line saw a usage limit reached"
    LIMIT_ERROR = "a turn failed on a usage limit"


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
        if data.get("provider") != "vertex":
            held = data.get("held_until")
            return State(OnSubscription(None if held is None else float(held)), usage)
        switch = OnVertex(float(data["since"]), float(data["until"]), Reason(data["reason"]))
        return State(switch, usage)
    except (ValueError, TypeError, KeyError, AttributeError, AssertionError):
        return State()


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
    return json.dumps(data, indent=2) + "\n"


def after_tick(state: State, now: float, windows: Mapping[str, UsageSeen]) -> State:
    """The state once `now` has come. Back on the subscription when the Vertex AI time is up, and
    on Vertex AI when a window that has not reset yet is used up, until the latest such reset. It
    also holds the latest reset time each window reported."""
    switch = state.switch
    if isinstance(switch, OnVertex) and now >= switch.until:
        switch = OnSubscription()
    if isinstance(switch, OnSubscription) and _held(switch, now):
        return State(switch, {**state.usage, **windows})
    if isinstance(switch, OnSubscription):
        # A window whose reset has passed can still say 100% until Claude Code next reports it
        used_up = [
            seen.resets_at if seen.resets_at is not None else now + WINDOW_LENGTHS_S[key]
            for key, seen in windows.items()
            if seen.used_percent >= 100 and (seen.resets_at is None or seen.resets_at > now)
        ]
        if used_up:
            switch = OnVertex(now, max(used_up), Reason.USAGE_LIMIT)
    return State(switch, {**state.usage, **windows})


def _held(switch: OnSubscription, now: float) -> bool:
    return switch.held_until is not None and now < switch.held_until


def parse_limit_error(payload: Mapping[str, object]) -> str | None:
    """The usage window a failed turn ran out of, from the StopFailure hook's input, or None when
    the turn failed for another reason."""
    if payload.get("error") != "rate_limit":
        return None
    text = " ".join(
        str(payload.get(key) or "") for key in ("last_assistant_message", "error_details")
    )
    text = text.replace("\u2019", "'").lower()
    return next((key for key, message in LIMIT_MESSAGES.items() if message in text), None)


def after_limit_error(state: State, now: float, window: str) -> State:
    """Vertex AI until the window that ran out resets, or for its full length when no reset time
    is recorded. Sessions already on Vertex AI keep their time."""
    if isinstance(state.switch, OnVertex) or _held(state.switch, now):
        return state
    seen = state.usage.get(window)
    resets = seen.resets_at if seen is not None else None
    until = resets if resets is not None and resets > now else now + WINDOW_LENGTHS_S[window]
    return replace(state, switch=OnVertex(now, until, Reason.LIMIT_ERROR))


def choose_vertex(state: State, now: float) -> State:
    """Vertex AI until the 5-hour window resets, or for 5 hours when no reset time is known."""
    seen = state.usage.get("five_hour")
    resets = seen.resets_at if seen is not None else None
    until = resets if resets is not None and resets > now else now + FIVE_HOURS_S
    return replace(state, switch=OnVertex(now, until, Reason.MANUAL))


def choose_subscription(state: State, now: float) -> State:
    """The subscription, held until the latest used-up window resets, so neither trigger moves
    sessions straight back to Vertex AI. No hold when no window is used up."""
    used_up = [
        seen.resets_at
        for seen in state.usage.values()
        if seen.used_percent >= 100 and seen.resets_at is not None and seen.resets_at > now
    ]
    return replace(state, switch=OnSubscription(max(used_up) if used_up else None))


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
    """`at` on a 12-hour clock, such as 3pm or 2:50am, with its weekday when a day or more away.
    `zone` sets the time zone: None is local."""
    when = datetime.fromtimestamp(at, zone)
    hour = when.hour % 12 or 12
    minutes = f":{when.minute:02d}" if when.minute else ""
    clock = f"{hour}{minutes}{'am' if when.hour < 12 else 'pm'}"
    weekday = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")[when.weekday()]
    return clock if at - now < 24 * 3600 else f"{weekday} {clock}"


def describe(switch: Switch, now: float) -> str:
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
    """The StopFailure hook: move sessions to Vertex AI when a turn failed on a usage limit. Claude
    Code ignores the hook's output and exit status, so it always exits 0."""
    try:
        payload = json.loads(payload_text)
    except ValueError:
        return 0
    window = parse_limit_error(payload) if isinstance(payload, dict) else None
    if window is None or not env.get(PROJECT_KEY):
        return 0
    with suppress(Busy, NotWritten):
        _update(paths, env, lambda state: after_limit_error(state, now, window))
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
        print(describe(_read_state(paths).switch, now))
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
    print(describe(state.switch, now))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:], Paths.under(Path.home()), os.environ, time.time()))
