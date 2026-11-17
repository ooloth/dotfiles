#!/usr/bin/env -S uv run --offline --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Moves every Claude Code session on the work laptop between the subscription and Vertex AI.

A state file says which one sessions should use, and until when they stay on Vertex AI. The status
line, which Claude Code runs every few seconds in every session, calls `tick` to move sessions back
once that time passes and to make CLAUDE_CODE_USE_VERTEX in the user settings file match the state.
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
from contextlib import contextmanager
from dataclasses import dataclass, field, replace
from datetime import datetime, tzinfo
from enum import StrEnum
from pathlib import Path

SWITCH_KEY = "CLAUDE_CODE_USE_VERTEX"
PROJECT_KEY = "ANTHROPIC_VERTEX_PROJECT_ID"
FIVE_HOURS_S = 5 * 3600
# The status line refreshes every 5 seconds, so a tick that waits longer for another session's
# tick would delay the line. A tick that gives up changes nothing, and the next one tries again.
LOCK_TIMEOUT_S = 0.5


class Reason(StrEnum):
    MANUAL = "chosen with cc-switch"


@dataclass(frozen=True)
class OnSubscription:
    pass


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
    # When each of the subscription's usage windows last said it resets, by the status line's key
    resets_at: Mapping[str, float] = field(default_factory=dict)


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


def parse_state(text: str | None) -> State:
    """The state a file holds. A missing or unreadable file means the subscription, since a person
    can edit the file and an interrupted write can leave it empty."""
    try:
        data = json.loads(text or "")
        resets_at = {str(k): float(v) for k, v in data.get("resets_at", {}).items()}
        if data.get("provider") != "vertex":
            return State(OnSubscription(), resets_at)
        switch = OnVertex(float(data["since"]), float(data["until"]), Reason(data["reason"]))
        return State(switch, resets_at)
    except (ValueError, TypeError, KeyError, AttributeError, AssertionError):
        return State()


def dump_state(state: State) -> str:
    data: dict[str, object] = {"provider": "subscription"}
    if isinstance(state.switch, OnVertex):
        data = {
            "provider": "vertex",
            "since": state.switch.since,
            "until": state.switch.until,
            "reason": state.switch.reason.value,
        }
    data["resets_at"] = dict(state.resets_at)
    return json.dumps(data, indent=2) + "\n"


def after_tick(state: State, now: float, resets_seen: Mapping[str, float]) -> State:
    """The state once `now` has come: back on the subscription when the Vertex AI time is up, and
    holding the latest reset time each usage window reported."""
    switch = state.switch
    if isinstance(switch, OnVertex) and now >= switch.until:
        switch = OnSubscription()
    return State(switch, {**state.resets_at, **resets_seen})


def choose_vertex(state: State, now: float) -> State:
    """Vertex AI until the 5-hour window resets, or for 5 hours when no reset time is known."""
    resets = state.resets_at.get("five_hour")
    until = resets if resets is not None and resets > now else now + FIVE_HOURS_S
    return replace(state, switch=OnVertex(now, until, Reason.MANUAL))


def choose_subscription(state: State) -> State:
    return replace(state, switch=OnSubscription())


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
        sync_settings(paths.settings, new.switch, env)
        return new


def tick(
    now: float, resets_seen: Mapping[str, float], paths: Paths, env: Mapping[str, str]
) -> Switch:
    """What the status line runs on each refresh. Returns the provider sessions should now use."""
    if not env.get(PROJECT_KEY):
        return OnSubscription()
    try:
        return _update(paths, env, lambda state: after_tick(state, now, resets_seen)).switch
    except Busy:
        return _read_state(paths).switch


def clock(at: float, now: float, zone: tzinfo | None = None) -> str:
    """`at` on a 12-hour clock, such as 3pm or 2:50am, with its weekday when a day or more away.
    `zone` sets the time zone: None is local."""
    when = datetime.fromtimestamp(at, zone)
    hour = when.hour % 12 or 12
    minutes = f":{when.minute:02d}" if when.minute else ""
    clock = f"{hour}{minutes}{'am' if when.hour < 12 else 'pm'}"
    return clock if at - now < 24 * 3600 else f"{when:%a} {clock}"


def describe(switch: Switch, now: float) -> str:
    if isinstance(switch, OnVertex):
        return (
            f"Sessions use Vertex AI until {clock(switch.until, now)} "
            f"(since {clock(switch.since, now)}, {switch.reason.value}).\n"
            "To move them back to the subscription now: cc-switch subscription"
        )
    return (
        "Sessions use the subscription.\n"
        "To move them to Vertex AI until the 5-hour limit resets: cc-switch vertex"
    )


def main(argv: list[str], paths: Paths, env: Mapping[str, str], now: float) -> int:
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
    change = (lambda s: choose_vertex(s, now)) if choice == "vertex" else choose_subscription
    try:
        state = _update(paths, env, change)
    except Busy:
        print("Another session is changing the switch; try again.", file=sys.stderr)
        return 1
    print(describe(state.switch, now))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:], Paths.under(Path.home()), os.environ, time.time()))
