#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic==2.14.1"]
# ///
"""Save every Rex session's layout, and rebuild the sessions after the Rex server restarts.

Rex keeps sessions only in the server's memory, so a reboot or a server restart loses every
session, tab and split. `tools/rex/config/init.lua` starts this script each time the server loads
its config:

    uv run --offline --script tools/rex/saver.py run --state-dir ~/.local/state/rex-restore

One copy runs per server, held by a lock in the state directory. On a server it has not restored
into yet, it rebuilds the sessions in `latest.json` first. The session Rex.app last showed is
rebuilt inside the empty session the app opens when it finds the server empty, so the app shows it
again. It then follows `rex events`, writes
each change to `latest.json` within about a second, keeps the last 20 distinct layouts in
`history/`, and writes `status.json` every 30 seconds. `tools/rex/shell.zsh` reads that file and
prints a warning in Rex panes when the saver stops or something fails. `saver.log` says why.

Only layouts, working directories and the position of the session the app showed are written:
never terminal output or commands.

The file is three sections, marked below, that become modules when the script moves into the
repo's Python project (#203): pure domain logic, the Pydantic models at the boundary, and the I/O.
"""

from __future__ import annotations

import argparse
import contextlib
import fcntl
import json
import os
import plistlib
import selectors
import subprocess
import sys
import tempfile
import time
from collections.abc import Callable, Iterator, Mapping, Sequence
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import IO, Any, Generic, Literal, NewType, TypeVar, assert_never
from urllib.parse import unquote, urlsplit

from pydantic import BaseModel, ConfigDict, ValidationError, model_validator

# ================================================================================================
# DOMAIN: pure logic, no I/O. Becomes `domain.py` when this moves into the repo's project (#203).
# ================================================================================================

# Covariant: a frozen dataclass is read-only, so an Ok[Snapshot] is an Ok[Snapshot | None].
T = TypeVar("T", covariant=True)
E = TypeVar("E", covariant=True)


@dataclass(frozen=True)
class Ok(Generic[T]):
    value: T


@dataclass(frozen=True)
class Err(Generic[E]):
    error: E


# An expected failure is returned as `Err`, never raised.
Result = Ok[T] | Err[E]

SessionLabel = NewType("SessionLabel", str)
WindowLabel = NewType("WindowLabel", str)
PaneLabel = NewType("PaneLabel", str)
AbsolutePath = NewType("AbsolutePath", str)
InstanceId = NewType("InstanceId", str)
SessionId = NewType("SessionId", str)
WindowId = NewType("WindowId", str)
Ratio = NewType("Ratio", float)
Direction = Literal["horizontal", "vertical"]

SHELL_FLAVOR = "com.superlogical.terminal.shell"
HISTORY_KEEP = 20
# Rex refuses a window with more than 64 panes, and a split tree of 64 panes is at most 64 deep.
MAX_LAYOUT_DEPTH = 64


def make_ratio(value: float) -> Ratio:
    assert 0 < value < 1, f"a split ratio must be strictly between 0 and 1, got {value}"
    return Ratio(value)


@dataclass(frozen=True)
class SavedPane:
    label: PaneLabel | None
    cwd: AbsolutePath | None


@dataclass(frozen=True)
class SavedSplit:
    direction: Direction
    ratio: Ratio
    before: Layout
    after: Layout


Layout = SavedPane | SavedSplit


@dataclass(frozen=True)
class SavedWindow:
    label: WindowLabel | None
    layout: Layout


@dataclass(frozen=True)
class SavedSession:
    """One session as it will be rebuilt. It holds no Rex IDs, commands or terminal output."""

    label: SessionLabel
    windows: tuple[SavedWindow, ...]
    active_index: int | None


@dataclass(frozen=True)
class Snapshot:
    format: Literal[2]
    instance_id: InstanceId
    saved_at: str
    sessions: tuple[SavedSession, ...]
    # The position in `sessions` of the session the app showed, from its preferences.
    focused_index: int | None = None

    def __post_init__(self) -> None:
        if self.focused_index is not None:
            assert self.focused_index >= 0, f"focused_index {self.focused_index} is negative"
            assert self.focused_index < len(self.sessions), (
                f"focused_index {self.focused_index} is past the last of "
                f"{len(self.sessions)} session(s)"
            )


@dataclass(frozen=True)
class SessionParseError:
    session_id: str
    path_in_view: str
    reason: str


@dataclass(frozen=True)
class RestoreRequest:
    """The `session.create` arguments for one session, and which window to focus after."""

    create: dict[str, Any]
    active_index: int | None


@dataclass(frozen=True)
class AlreadyRestored:
    pass


@dataclass(frozen=True)
class NothingSaved:
    pass


@dataclass(frozen=True)
class SnapshotUnreadable:
    reason: str


@dataclass(frozen=True)
class Restore:
    sessions: tuple[SavedSession, ...]
    focused_index: int | None = None


RestorePlan = AlreadyRestored | NothingSaved | SnapshotUnreadable | Restore


@dataclass(frozen=True)
class Unchanged:
    pass


@dataclass(frozen=True)
class Changed:
    """The layout changed: the old `latest.json` moves into history, and these files leave it."""

    evict: tuple[str, ...]


@dataclass(frozen=True)
class FocusOnly:
    pass


HistoryDecision = Unchanged | FocusOnly | Changed


@dataclass(frozen=True)
class Unused:
    """A session nobody has used: one tab, one pane, an idle shell. The app makes one at startup."""

    session_id: SessionId
    window_id: WindowId


@dataclass(frozen=True)
class InUse:
    session_id: SessionId
    reason: str


@dataclass(frozen=True)
class Unjudgeable:
    session_id: str
    reason: str


CandidateVerdict = Unused | InUse | Unjudgeable


@dataclass(frozen=True)
class Adopt:
    """Build `target` into the unused session `into`, which the app is showing, in place of its tab.

    `position` is where `target` sits among the saved sessions, and `rest` is every other one.
    """

    into: SessionId
    original_window: WindowId
    target: SavedSession
    position: int
    rest: tuple[SavedSession, ...]


@dataclass(frozen=True)
class CreateEach:
    sessions: tuple[SavedSession, ...]


Adoption = Adopt | CreateEach

ProblemKind = Literal[
    "rex_methods_missing",
    "session_unreadable",
    "snapshot_unreadable",
    "restore_failed",
    "events_missed",
    "saver_crashed",
    "adopt_failed",
    "focus_unreadable",
    "focus_unknown",
]

# The kinds that describe a state the saver checks again on every poll, rather than an event.
RESOLVABLE: frozenset[ProblemKind] = frozenset({"focus_unknown"})


@dataclass(frozen=True)
class Problem:
    kind: ProblemKind
    detail: str


# An event this close to a poll, before or after it, explains a change the poll found. Rex sends an
# event within a second of the change, but the poll may read the change before the saver has
# handled the event that reports it.
EVENT_GRACE = 5.0


@dataclass(frozen=True)
class Suspect:
    """A session whose layout a poll found changed, waiting for an event to explain it."""

    session_id: str
    raised_at: float
    change: str


@dataclass(frozen=True)
class Explained:
    session_id: str
    after: float


@dataclass(frozen=True)
class Missed:
    session_id: str
    change: str


@dataclass(frozen=True)
class Waiting:
    pass


Verdict = Explained | Missed | Waiting


def restore_request(session: SavedSession) -> RestoreRequest:
    windows = []
    for window in session.windows:
        entry: dict[str, Any] = {"layout": _layout_request(window.layout)}
        if window.label is not None:
            entry["window_label"] = window.label
        windows.append(entry)
    create: dict[str, Any] = {"label": session.label}
    if windows:
        create["initial_windows"] = windows
    return RestoreRequest(create=create, active_index=session.active_index)


def _layout_request(layout: Layout) -> dict[str, Any]:
    match layout:
        case SavedPane(label=label, cwd=cwd):
            block: dict[str, Any] = {
                "flavor": SHELL_FLAVOR,
                "options": {"cwd": cwd} if cwd is not None else {},
            }
            if label is not None:
                block["label"] = label
            return {"block": block}
        case SavedSplit(direction=direction, ratio=ratio, before=before, after=after):
            return {
                "split": {
                    "direction": direction,
                    "ratio": ratio,
                    "before": _layout_request(before),
                    "after": _layout_request(after),
                }
            }


def build_snapshot(
    current: Mapping[str, Result[SavedSession, SessionParseError]],
    last_good: Mapping[str, SavedSession],
    instance_id: str,
    saved_at: str,
    focused: str | None = None,
) -> tuple[Snapshot, tuple[SessionParseError, ...]]:
    """Every live session in order, using a session's last good copy when it fails to parse.

    Keeping the last good copy means a Rex change that breaks parsing cannot drop a session from
    `latest.json` before the next reboot. A session that never parsed is left out. `focused` is the
    session the app showed, saved as its position, or as no focus when it isn't saved.
    """
    sessions: list[SavedSession] = []
    errors: list[SessionParseError] = []
    focused_index: int | None = None
    for session_id, result in current.items():
        saved: SavedSession | None = None
        match result:
            case Ok(session):
                saved = session
            case Err(error):
                errors.append(error)
                saved = last_good.get(session_id)
        if saved is None:
            continue
        if session_id == focused:
            focused_index = len(sessions)
        sessions.append(saved)
    snapshot = Snapshot(
        format=2,
        instance_id=InstanceId(instance_id),
        saved_at=saved_at,
        sessions=tuple(sessions),
        focused_index=focused_index,
    )
    return snapshot, tuple(errors)


def plan_restore(
    marker: str | None, instance_id: InstanceId, latest: Result[Snapshot | None, str]
) -> RestorePlan:
    """What to do when a saver starts. `marker` names the server last restored into."""
    if marker == instance_id:
        return AlreadyRestored()
    match latest:
        case Err(reason):
            return SnapshotUnreadable(reason=reason)
        case Ok(None):
            return NothingSaved()
        case Ok(Snapshot(sessions=())):
            return NothingSaved()
        case Ok(Snapshot(sessions=sessions, focused_index=focused_index)):
            return Restore(sessions=sessions, focused_index=focused_index)
    raise AssertionError(f"unexpected snapshot result: {latest!r}")


def record_history(
    previous: Snapshot | None, new: Snapshot, existing: Sequence[str]
) -> HistoryDecision:
    """Whether a new snapshot changes the layout, and which history files make room for it.

    History file names sort oldest first, and the old `latest.json` is about to join them.
    """
    if previous is not None and previous.sessions == new.sessions:
        # Switching sessions changes only the focus, which is not worth one of the 20 layouts.
        return Unchanged() if previous.focused_index == new.focused_index else FocusOnly()
    joining = 1 if previous is not None else 0
    oldest_first = sorted(existing)
    overflow = max(0, len(oldest_first) + joining - HISTORY_KEEP)
    return Changed(evict=tuple(oldest_first[:overflow]))


def unexplained_changes(
    cached: Mapping[str, SavedSession],
    fresh: Mapping[str, SavedSession],
    recently_changed: set[str],
) -> tuple[str, ...]:
    """Sessions whose layout changed with no event to say so, ignoring working directories.

    A plain `cd` sends no event unless the shell reports OSC 7, so directories are left out.
    Sessions with a recent event are left out too, because the cache may not have caught up yet.
    """
    ids = [*cached, *(i for i in fresh if i not in cached)]
    return tuple(
        i
        for i in ids
        if i not in recently_changed and _structure(cached.get(i)) != _structure(fresh.get(i))
    )


def _structure(session: SavedSession | None) -> object:
    if session is None:
        return None
    windows = tuple((w.label, _layout_structure(w.layout)) for w in session.windows)
    return (session.label, windows, session.active_index)


def _layout_structure(node: Layout) -> object:
    match node:
        case SavedPane(label=label):
            return ("pane", label)
        case SavedSplit(direction=d, ratio=r, before=b, after=a):
            return ("split", d, r, _layout_structure(b), _layout_structure(a))


def describe_change(cached: SavedSession | None, fresh: SavedSession | None) -> str:
    """Which parts of a session's layout differ, ignoring working directories, for `saver.log`."""
    if cached is None:
        return "session appeared"
    if fresh is None:
        return "session disappeared"
    parts: list[str] = []
    if cached.label != fresh.label:
        parts.append("session label")
    if len(cached.windows) != len(fresh.windows):
        parts.append(f"tabs {len(cached.windows)}→{len(fresh.windows)}")
    else:
        if [w.label for w in cached.windows] != [w.label for w in fresh.windows]:
            parts.append("tab labels")
        if [_layout_structure(w.layout) for w in cached.windows] != [
            _layout_structure(w.layout) for w in fresh.windows
        ]:
            parts.append("split layout")
    if cached.active_index != fresh.active_index:
        parts.append(f"active tab {cached.active_index}→{fresh.active_index}")
    return ", ".join(parts) or "nothing the saver compares"


def plan_adoption(
    sessions: tuple[SavedSession, ...],
    focused_index: int | None,
    verdicts: tuple[CandidateVerdict, ...],
) -> Adoption:
    """Which saved session to build into the app's unused session, if there is one.

    The app shows the session it made when it found the new server empty. Building the focused
    session into it brings that session back into view without asking the app, which refuses
    actions from scripts. With no focus saved, the first session takes its place.
    """
    into = next((v for v in verdicts if isinstance(v, Unused)), None)
    if into is None or not sessions:
        return CreateEach(sessions)
    position = focused_index if focused_index is not None else 0
    assert 0 <= position < len(sessions), f"focus {position} is outside {len(sessions)} sessions"
    adoption = Adopt(
        into=into.session_id,
        original_window=into.window_id,
        target=sessions[position],
        position=position,
        rest=sessions[:position] + sessions[position + 1 :],
    )
    rebuilt = adoption.rest[:position] + (adoption.target,) + adoption.rest[position:]
    assert rebuilt == sessions, "building into the app's session must keep every saved session"
    return adoption


def judge(suspect: Suspect, last_event_at: float | None, now: float) -> Verdict:
    """Whether an event since the poll explains the suspect's change, or the grace has run out."""
    assert now >= suspect.raised_at, f"the clock ran backwards: {now} < {suspect.raised_at}"
    if last_event_at is not None and last_event_at >= suspect.raised_at:
        return Explained(suspect.session_id, after=last_event_at - suspect.raised_at)
    if now - suspect.raised_at >= EVENT_GRACE:
        return Missed(suspect.session_id, suspect.change)
    return Waiting()


def warning_text(problems: Sequence[Problem]) -> str:
    """The one line `shell.zsh` prints in Rex panes, or nothing when all is well."""
    if not problems:
        return ""
    kinds = {
        "rex_methods_missing": "Rex no longer offers a method the saver needs",
        "session_unreadable": "a session could not be read, so its last good copy is kept",
        "snapshot_unreadable": "the saved layout could not be read, so nothing was restored",
        "restore_failed": "a session failed to restore",
        "events_missed": (
            "Rex changed a layout without sending an event, "
            "so changes like it are saved only by the 30-second poll"
        ),
        "saver_crashed": "the saver stopped on an unexpected error",
        "adopt_failed": (
            "the focused session could not be built into the app's empty session, "
            "so it was restored on its own"
        ),
        "focus_unreadable": "the app's focused session could not be read",
        "focus_unknown": "the app's focused session is not one the server has",
    }
    seen: list[str] = []
    for problem in problems:
        text = f"{kinds[problem.kind]} ({problem.detail})"
        if text not in seen:
            seen.append(text)
    return "; ".join(seen)


# ================================================================================================
# BOUNDARY: Pydantic models for what Rex and the state files send, and their conversion to the
# domain. Becomes `boundary.py` when this moves into the repo's project (#203).
# ================================================================================================


# Every Rex method the saver calls, checked when it starts.
REQUIRED_METHODS = (
    "server.status",
    "session.list",
    "session.view",
    "session.create",
    "session.attach",
    "session.disown_block",
    "session.focus_window",
    "session.new_window",
    "session.close_window",
    "session.set_label",
    "session.move",
    "com.superlogical.terminal.process",
)


class _RexModel(BaseModel):
    # Rex adds fields over time; anything not named here is ignored.
    model_config = ConfigDict(extra="ignore", frozen=True)


class ViewSplit(_RexModel):
    direction: Direction
    ratio: float
    before: ViewNode
    after: ViewNode


class ViewNode(_RexModel):
    block_id: str | None = None
    split: ViewSplit | None = None

    @model_validator(mode="after")
    def _one_kind(self) -> ViewNode:
        if (self.block_id is None) == (self.split is None):
            raise ValueError("a layout node needs exactly one of block_id and split")
        return self


class ViewBlock(_RexModel):
    block_id: str
    label: str | None = None


class ViewLayer(_RexModel):
    kind: str
    layout: ViewNode | None = None
    blocks: list[ViewBlock] = []


class ViewWindow(_RexModel):
    window_id: str
    label: str | None = None
    layers: list[ViewLayer] = []


class SessionView(_RexModel):
    session_id: str
    label: str
    active_window_id: str | None = None
    windows: list[ViewWindow] = []


class ServerStatus(_RexModel):
    instance_id: str


class SessionSummary(_RexModel):
    session_id: str


class SessionList(_RexModel):
    sessions: list[SessionSummary] = []


class MethodSummary(_RexModel):
    name: str


class BlockTypeSummary(_RexModel):
    creator: str
    methods: list[MethodSummary] = []


class MethodList(_RexModel):
    methods: list[MethodSummary]
    block_types: list[BlockTypeSummary] = []


def missing_methods(listing: str) -> Result[tuple[str, ...], str]:
    """Which of the methods the saver calls a `rex api list --json` result lacks.

    Rex lists a block type's methods under that type, so `process` on a terminal appears as
    `com.superlogical.terminal.process` here.
    """
    try:
        model = MethodList.model_validate_json(listing)
    except ValidationError as error:
        return Err(f"rex api list: {error.errors()[0]['msg']}")
    offered = {m.name for m in model.methods} | {
        f"{b.creator}.{m.name}" for b in model.block_types for m in b.methods
    }
    return Ok(tuple(m for m in REQUIRED_METHODS if m not in offered))


class ProcessForeground(_RexModel):
    cwd: str | None = None


class ProcessAncestor(_RexModel):
    name: str


class TerminalProcess(_RexModel):
    foreground: ProcessForeground | None = None
    ancestors: list[ProcessAncestor] = []


class AppFocus(BaseModel):
    model_config = ConfigDict(extra="ignore", frozen=True)
    sessionID: str


class RexEvent(_RexModel):
    type: str
    payload: dict[str, Any] = {}


class _StateModel(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)


class PaneFile(_StateModel):
    label: str | None
    cwd: str | None


class SplitFile(_StateModel):
    direction: Direction
    ratio: float
    before: NodeFile
    after: NodeFile


class NodeFile(_StateModel):
    pane: PaneFile | None = None
    split: SplitFile | None = None


class WindowFile(_StateModel):
    label: str | None
    layout: NodeFile


class SessionFile(_StateModel):
    label: str
    windows: list[WindowFile]
    active_index: int | None


class SnapshotFile(_StateModel):
    # Format 1 was written before the focused session was saved.
    format: Literal[1, 2]
    instance_id: str
    saved_at: str
    sessions: list[SessionFile]
    focused_index: int | None = None


def parse_session(view: object, cwds: Mapping[str, str]) -> Result[SavedSession, SessionParseError]:
    """One `session.view` result as a saved session, or the reason it can't be read.

    `cwds` maps block IDs to each pane's working directory, from OSC 7 or the foreground process.
    """
    session_id = view.get("session_id", "?") if isinstance(view, dict) else "?"
    try:
        model = SessionView.model_validate(view)
    except ValidationError as error:
        first = error.errors()[0]
        where = ".".join(str(part) for part in first["loc"])
        return Err(SessionParseError(str(session_id), where, first["msg"]))
    try:
        windows: list[SavedWindow] = []
        active_index: int | None = None
        for index, window in enumerate(model.windows):
            tiled = next((x for x in window.layers if x.kind == "tiled" and x.layout), None)
            if tiled is None or tiled.layout is None:
                # Only floating panes: nothing tiled to rebuild.
                continue
            labels = {b.block_id: b.label for b in tiled.blocks}
            layout = _layout(tiled.layout, labels, cwds, f"windows.{index}.layout", 0)
            if window.window_id == model.active_window_id:
                active_index = len(windows)
            windows.append(SavedWindow(label=_window_label(window), layout=layout))
    except _Unreadable as error:
        return Err(SessionParseError(model.session_id, error.path, error.reason))
    return Ok(SavedSession(SessionLabel(model.label), tuple(windows), active_index))


class _Unreadable(Exception):
    def __init__(self, path: str, reason: str) -> None:
        super().__init__(reason)
        self.path = path
        self.reason = reason


def _layout(
    node: ViewNode, labels: Mapping[str, str | None], cwds: Mapping[str, str], path: str, depth: int
) -> Layout:
    if depth > MAX_LAYOUT_DEPTH:
        raise _Unreadable(path, f"layout is more than {MAX_LAYOUT_DEPTH} splits deep")
    if node.split is not None:
        s = node.split
        if not 0 < s.ratio < 1:
            raise _Unreadable(path, f"split ratio {s.ratio} is not between 0 and 1")
        return SavedSplit(
            direction=s.direction,
            ratio=make_ratio(s.ratio),
            before=_layout(s.before, labels, cwds, f"{path}.before", depth + 1),
            after=_layout(s.after, labels, cwds, f"{path}.after", depth + 1),
        )
    assert node.block_id is not None, "the model allows only a block or a split"
    label = labels.get(node.block_id)
    cwd = cwds.get(node.block_id)
    return SavedPane(
        label=PaneLabel(label) if label is not None else None,
        cwd=AbsolutePath(cwd) if cwd is not None and cwd.startswith("/") else None,
    )


def _window_label(window: ViewWindow) -> WindowLabel | None:
    # Rex names an unlabelled window after the end of its ID. A restored window gets a new ID, so
    # the old name would be stale; leaving it out lets Rex name the new window the same way.
    if window.label is None or window.label == f"Window {window.window_id[-8:]}":
        return None
    return WindowLabel(window.label)


def judge_candidate(view: object, process: object) -> CandidateVerdict:
    """Whether a session the saver didn't make is one nobody has used.

    `process` is `com.superlogical.terminal.process` for its first pane. A shell with nothing
    running in it is the foreground program and has only `login` above it.
    """
    session_id = view.get("session_id", "?") if isinstance(view, dict) else "?"
    try:
        model = SessionView.model_validate(view)
        running = TerminalProcess.model_validate(process)
    except ValidationError as error:
        first = error.errors()[0]
        where = ".".join(str(part) for part in first["loc"])
        return Unjudgeable(str(session_id), f"{where}: {first['msg']}")
    sid = SessionId(model.session_id)
    if len(model.windows) != 1:
        return InUse(sid, f"{len(model.windows)} tabs")
    window = model.windows[0]
    blocks = [b for layer in window.layers for b in layer.blocks]
    if len(blocks) != 1:
        return InUse(sid, f"{len(blocks)} panes")
    if running.foreground is None:
        return Unjudgeable(model.session_id, "its shell has not started")
    parents = [a.name for a in running.ancestors]
    if parents != ["login"]:
        return InUse(sid, f"a program is running under {' > '.join(reversed(parents))}")
    return Unused(sid, WindowId(window.window_id))


FOCUS_KEY = "Workspace.lastFocusedSession"


def read_app_focus(export: bytes) -> Result[SessionId, str]:
    """The session the Rex app last showed, from `defaults export com.superlogical.rex -`.

    The app keeps it as JSON bytes, `{"sessionID": "session:…"}`, under `Workspace.lastFocusedSession`.
    It is the app's private setting, so each way it can change is a named error, not a guess.
    """
    try:
        preferences = plistlib.loads(export)
    except Exception as error:  # plistlib raises several unrelated types for bad input
        return Err(f"the preferences are not a plist ({type(error).__name__})")
    if not isinstance(preferences, dict) or FOCUS_KEY not in preferences:
        return Err(f"{FOCUS_KEY} is missing")
    raw = preferences[FOCUS_KEY]
    if not isinstance(raw, bytes):
        return Err(f"{FOCUS_KEY} is {type(raw).__name__}, not data")
    try:
        focus = AppFocus.model_validate_json(raw)
    except ValidationError as error:
        return Err(f"{FOCUS_KEY} ({len(raw)} bytes): {error.errors()[0]['msg']}")
    if not focus.sessionID.startswith("session:"):
        return Err(f"{FOCUS_KEY} holds {len(focus.sessionID)} characters that are not a session ID")
    return Ok(SessionId(focus.sessionID))


def decode_osc7(url: str) -> AbsolutePath | None:
    """The path in a `file://host/path` URL that a shell reports with OSC 7."""
    if url.startswith("/"):
        return AbsolutePath(url)
    parts = urlsplit(url)
    if parts.scheme != "file" or not parts.path.startswith("/"):
        return None
    return AbsolutePath(unquote(parts.path))


def snapshot_json(snapshot: Snapshot) -> str:
    def layout(node: Layout) -> dict[str, Any]:
        match node:
            case SavedPane(label=label, cwd=cwd):
                return {"pane": {"label": label, "cwd": cwd}}
            case SavedSplit(direction=d, ratio=r, before=b, after=a):
                return {
                    "split": {"direction": d, "ratio": r, "before": layout(b), "after": layout(a)}
                }

    data = {
        "format": snapshot.format,
        "instance_id": snapshot.instance_id,
        "saved_at": snapshot.saved_at,
        "sessions": [
            {
                "label": s.label,
                "windows": [{"label": w.label, "layout": layout(w.layout)} for w in s.windows],
                "active_index": s.active_index,
            }
            for s in snapshot.sessions
        ],
        "focused_index": snapshot.focused_index,
    }
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def load_snapshot(text: str) -> Result[Snapshot, str]:
    try:
        model = SnapshotFile.model_validate_json(text)
    except ValidationError as error:
        first = error.errors()[0]
        return Err(f"{'.'.join(str(p) for p in first['loc']) or 'file'}: {first['msg']}")
    try:
        sessions = tuple(
            SavedSession(
                label=SessionLabel(s.label),
                windows=tuple(
                    SavedWindow(
                        label=WindowLabel(w.label) if w.label is not None else None,
                        layout=_layout_from_file(w.layout, 0),
                    )
                    for w in s.windows
                ),
                active_index=s.active_index,
            )
            for s in model.sessions
        )
    except _Unreadable as error:
        return Err(f"{error.path}: {error.reason}")
    focused = model.focused_index
    if focused is not None and not 0 <= focused < len(sessions):
        return Err(f"focused_index: {focused} is not one of the {len(sessions)} saved sessions")
    return Ok(Snapshot(2, InstanceId(model.instance_id), model.saved_at, sessions, focused))


def _layout_from_file(node: NodeFile, depth: int) -> Layout:
    if depth > MAX_LAYOUT_DEPTH:
        raise _Unreadable("layout", f"more than {MAX_LAYOUT_DEPTH} splits deep")
    if node.pane is not None and node.split is None:
        p = node.pane
        cwd = p.cwd if p.cwd is not None and p.cwd.startswith("/") else None
        return SavedPane(
            label=PaneLabel(p.label) if p.label is not None else None,
            cwd=AbsolutePath(cwd) if cwd is not None else None,
        )
    if node.split is not None and node.pane is None:
        s = node.split
        if not 0 < s.ratio < 1:
            raise _Unreadable("layout", f"split ratio {s.ratio} is not between 0 and 1")
        return SavedSplit(
            direction=s.direction,
            ratio=make_ratio(s.ratio),
            before=_layout_from_file(s.before, depth + 1),
            after=_layout_from_file(s.after, depth + 1),
        )
    raise _Unreadable("layout", "a layout node needs exactly one of pane and split")


# ================================================================================================
# I/O: the rex CLI, the state files, the event stream and the lock. Becomes `saver.py` when this
# moves into the repo's project (#203).
# ================================================================================================

FLUSH_EVERY = 1.0
POLL_EVERY = 30.0
# How long a session's shell may take to start before the session counts as not unused.
CANDIDATE_WAIT = 2.0
CANDIDATE_TRIES = 9
LOG_MAX_BYTES = 1_000_000
REX_SERVER_APP = Path.home() / "Library/Application Support/com.superlogical.rex/RexServer/Versions"
REX_IN_APP = "Rex Server.app/Contents/MacOS/rex"

# Run with `rex do -`: rebuild one session and release its panes over one connection. Rex gives a
# new pane to the client that created it, and only that client can release it, so creating it with
# `rex api call` would leave it held by a client that has already exited, and the app could not
# size it.
RESTORE_LUA = """
local f = assert(io.open(rex.args.request))
local request = rex.json.decode(f:read("*a"))
f:close()
local created, err = rex.call("session.create", request.create)
if not created then return { error = tostring(err) } end
rex.call("session.attach", { session_id = created.session_id })
rex.call("session.disown_block", { session_id = created.session_id })
local index = request.active_index
if index ~= nil and index ~= rex.json.null then
  local window = created.initial_windows[index + 1]
  if window then
    rex.call("session.focus_window", { session_id = created.session_id, window_id = window.window_id })
  end
end
return { session_id = created.session_id }
"""

# Run with `rex do -`: build a saved session's tabs into the app's unused session, which the app is
# showing. The original tab closes only once a saved tab exists beside it, because Rex can close
# its macOS window when the session it shows loses its last tab.
ADOPT_LUA = """
local f = assert(io.open(rex.args.request))
local request = rex.json.decode(f:read("*a"))
f:close()
local sid = request.into
rex.call("session.attach", { session_id = sid })
local made = {}
for _, window in ipairs(request.windows) do
  local args = { session_id = sid, layout = window.layout, focus = false }
  if window.window_label then args.window_label = window.window_label end
  local created, err = rex.call("session.new_window", args)
  if not created then
    return { error = "building tab " .. (#made + 1) .. ": " .. tostring(err) }
  end
  table.insert(made, created.window_id)
end
if #made == 0 then return { error = "no saved tab was built, so the original tab was kept" } end
rex.call("session.disown_block", { session_id = sid })
local active = made[1]
local index = request.active_index
if index ~= nil and index ~= rex.json.null and made[index + 1] then active = made[index + 1] end
rex.call("session.focus_window", { session_id = sid, window_id = active })
local closed, close_err = rex.call("session.close_window", { session_id = sid, window_id = request.original_window })
if close_err then return { error = "closing the original tab: " .. tostring(close_err) } end
local labelled, label_err = rex.call("session.set_label", { session_id = sid, label = request.label })
if label_err then return { error = "setting the label: " .. tostring(label_err) } end
return { session_id = sid }
"""

# Run with `rex do -`: Rex moves only a session the connection is attached to.
MOVE_LUA = """
rex.call("session.attach", { session_id = rex.args.session })
local args = { session_id = rex.args.session }
if rex.args.before ~= "" then args.before_session_id = rex.args.before end
local moved, err = rex.call("session.move", args)
if err then return { error = tostring(err) } end
return {}
"""


def now_iso() -> str:
    return datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


def acquire_lock(path: Path, timeout: float) -> IO[str] | None:
    """Hold an exclusive lock on `path` for the life of the process, waiting up to `timeout`.

    The operating system releases it when the process exits, however it exits.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = path.open("a")
    deadline = time.monotonic() + timeout
    while True:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return handle
        except BlockingIOError:
            if time.monotonic() >= deadline:
                handle.close()
                return None
            time.sleep(0.2)


def write_atomic(path: Path, text: str) -> None:
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    with os.fdopen(fd, "w") as handle:
        handle.write(text)
    os.replace(tmp, path)


class Log:
    def __init__(self, path: Path) -> None:
        if path.exists() and path.stat().st_size > LOG_MAX_BYTES:
            path.replace(path.with_suffix(".log.1"))
        self.path = path

    def __call__(self, message: str) -> None:
        with self.path.open("a") as handle:
            handle.write(f"{now_iso()} [{os.getpid()}] {message}\n")


class RexError(Exception):
    pass


@dataclass
class Rex:
    binary: Path
    server: str | None

    def _base(self) -> list[str]:
        base = [str(self.binary), "--autostart=false"]
        return [*base, "-S", self.server] if self.server else base

    def call(self, method: str, args: Mapping[str, Any] | None = None) -> Any:
        command = [*self._base(), "api", "call", method, json.dumps(dict(args or {}))]
        done = subprocess.run(command, capture_output=True, text=True, timeout=20)
        if done.returncode != 0:
            raise RexError(f"{method}: {done.stderr.strip() or done.returncode}")
        return json.loads(done.stdout)

    def method_listing(self) -> str:
        done = subprocess.run(
            [*self._base(), "api", "list", "--json"], capture_output=True, text=True, timeout=20
        )
        if done.returncode != 0:
            raise RexError(f"api list: {done.stderr.strip()}")
        return done.stdout

    def _do(self, script: str, *pairs: str) -> dict[str, Any]:
        done = subprocess.run(
            [*self._base(), "do", "-", *pairs, "--json"],
            input=script,
            capture_output=True,
            text=True,
            timeout=60,
        )
        if done.returncode != 0:
            raise RexError(done.stderr.strip() or f"rex do exited {done.returncode}")
        result = json.loads(done.stdout or "{}")
        if not isinstance(result, dict):
            raise RexError(f"rex do returned {type(result).__name__}, not an object")
        if "error" in result:
            raise RexError(str(result["error"]))
        return result

    def restore(self, request: RestoreRequest, scratch: Path) -> str:
        path = scratch / "request.json"
        payload = {"create": request.create, "active_index": request.active_index}
        path.write_text(json.dumps(payload))
        return str(self._do(RESTORE_LUA, f"request={path}").get("session_id", "?"))

    def adopt(self, adopt: Adopt, scratch: Path) -> str:
        request = restore_request(adopt.target)
        path = scratch / "adopt.json"
        payload = {
            "into": adopt.into,
            "original_window": adopt.original_window,
            "label": request.create["label"],
            "windows": request.create.get("initial_windows", []),
            "active_index": request.active_index,
        }
        path.write_text(json.dumps(payload))
        return str(self._do(ADOPT_LUA, f"request={path}").get("session_id", "?"))

    def move(self, session_id: str, before: str | None) -> None:
        self._do(MOVE_LUA, f"session={session_id}", f"before={before or ''}")

    def events(self) -> subprocess.Popen[str]:
        return subprocess.Popen(
            [*self._base(), "events", "--all", "--json"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )


def find_rex(explicit: str | None) -> Path:
    if explicit:
        return Path(explicit)
    current = REX_SERVER_APP / "Current" / REX_IN_APP
    if current.exists():
        return current
    numbered = sorted(
        (p for p in REX_SERVER_APP.glob(f"*/{REX_IN_APP}") if p.parts[-5].isdigit()),
        key=lambda p: int(p.parts[-5]),
    )
    if numbered:
        return numbered[-1]
    raise RexError(f"no rex binary under {REX_SERVER_APP}")


@dataclass
class Saver:
    rex: Rex
    state: Path
    log: Log
    instance_id: InstanceId = InstanceId("")
    problems: list[Problem] = field(default_factory=list)
    cache: dict[str, SavedSession] = field(default_factory=dict)
    cwds: dict[str, str] = field(default_factory=dict)
    osc7_blocks: set[str] = field(default_factory=set)
    dirty: set[str] = field(default_factory=set)
    last_event: dict[str, float] = field(default_factory=dict)
    suspects: dict[str, Suspect] = field(default_factory=dict)
    clock: Callable[[], float] = time.monotonic
    sleep: Callable[[float], None] = time.sleep
    session_order: list[str] = field(default_factory=list)
    last_written: Snapshot | None = None
    # A domain or plist path for `defaults export`, or None to save no focus.
    app_preferences: str | None = None
    focused: SessionId | None = None
    focus_dirty: bool = False

    # ----- startup -----

    def start(self) -> None:
        match missing_methods(self.rex.method_listing()):
            case Err(reason):
                self.problem("rex_methods_missing", reason)
                raise SystemExit(reason)
            case Ok(missing) if missing:
                self.problem("rex_methods_missing", ", ".join(missing))
                raise SystemExit(f"Rex is missing methods the saver needs: {', '.join(missing)}")
        status = ServerStatus.model_validate(self.rex.call("server.status"))
        self.instance_id = InstanceId(status.instance_id)
        self.log(f"saver started for server {self.instance_id}")
        self.restore_once()
        self.write_status()

    def restore_once(self) -> None:
        marker_path = self.state / "restored-instance"
        marker = marker_path.read_text().strip() if marker_path.exists() else None
        latest_path = self.state / "latest.json"
        latest: Result[Snapshot | None, str] = (
            load_snapshot(latest_path.read_text()) if latest_path.exists() else Ok(None)
        )
        plan = plan_restore(marker, self.instance_id, latest)
        match plan:
            case AlreadyRestored():
                self.log("restore skipped: this server was already restored into")
                if isinstance(latest, Ok):
                    self.last_written = latest.value
                return
            case NothingSaved():
                self.log("restore skipped: nothing saved")
            case SnapshotUnreadable(reason=reason):
                self.log(f"restore skipped: latest.json is unreadable: {reason}")
                self.problem("snapshot_unreadable", reason)
            case Restore(sessions=sessions, focused_index=focused_index):
                assert marker != self.instance_id, "never restore into a server twice"
                saved_at = latest.value.saved_at if isinstance(latest, Ok) and latest.value else "?"
                self.log(
                    f"restoring {len(sessions)} session(s) saved at {saved_at}, "
                    f"focus {focused_index}"
                )
                self.restore_sessions(sessions, focused_index)
        if isinstance(latest, Ok):
            self.last_written = latest.value
        write_atomic(marker_path, f"{self.instance_id}\n")

    def restore_sessions(self, sessions: Sequence[SavedSession], focused_index: int | None) -> None:
        plan = plan_adoption(tuple(sessions), focused_index, self.find_candidates())
        failed: list[str] = []
        with tempfile.TemporaryDirectory() as tmp:
            scratch = Path(tmp)
            match plan:
                case CreateEach(sessions=each):
                    self.log("no unused session to build into, so each session is created")
                    self.create_each(each, scratch, failed)
                case Adopt(into=into, target=target, position=position, rest=rest):
                    self.log(f"building {target.label!r} into the unused session {into}")
                    try:
                        self.rex.adopt(plan, scratch)
                    except (RexError, subprocess.TimeoutExpired, json.JSONDecodeError) as error:
                        self.log(f"failed to build {target.label!r} into {into}: {error}")
                        self.problem("adopt_failed", target.label)
                        self.create_each(
                            rest[:position] + (target,) + rest[position:], scratch, failed
                        )
                    else:
                        self.log(f"restored {target.label!r} into {into}")
                        created = self.create_each(rest, scratch, failed)
                        self.move_into_place(into, created[position:])
                case unreachable:
                    assert_never(unreachable)
        if failed:
            self.problem("restore_failed", ", ".join(failed))

    def create_each(
        self, sessions: Sequence[SavedSession], scratch: Path, failed: list[str]
    ) -> list[str | None]:
        """Create each session, returning its new ID, or None for one that failed."""
        created: list[str | None] = []
        for session in sessions:
            try:
                session_id = self.rex.restore(restore_request(session), scratch)
                self.log(f"restored {session.label!r} as {session_id}")
                created.append(session_id)
            except (RexError, subprocess.TimeoutExpired, json.JSONDecodeError) as error:
                self.log(f"failed to restore {session.label!r}: {error}")
                failed.append(session.label)
                created.append(None)
        return created

    def move_into_place(self, session_id: str, following: Sequence[str | None]) -> None:
        """Move the adopted session before the first restored session that followed it."""
        before = next((s for s in following if s is not None), None)
        try:
            self.rex.move(session_id, before)
        except (RexError, subprocess.TimeoutExpired, json.JSONDecodeError) as error:
            self.log(f"could not move {session_id} to its saved place: {error}")

    def find_candidates(self) -> tuple[CandidateVerdict, ...]:
        """Judge every session on the new server, waiting briefly for shells still starting.

        The saver has created nothing yet, so each one was made by the app or by someone else.
        """
        verdicts: tuple[CandidateVerdict, ...] = ()
        for attempt in range(CANDIDATE_TRIES):
            verdicts = tuple(self.judge_session(s) for s in self.list_sessions())
            if not any(isinstance(v, Unjudgeable) for v in verdicts):
                break
            if attempt < CANDIDATE_TRIES - 1:
                self.sleep(CANDIDATE_WAIT / (CANDIDATE_TRIES - 1))
        for verdict in verdicts:
            match verdict:
                case Unused(session_id=session_id):
                    self.log(f"candidate {session_id}: unused")
                case InUse(session_id=session_id, reason=reason):
                    self.log(f"candidate {session_id}: in use, {reason}")
                case Unjudgeable(session_id=session_id, reason=reason):
                    self.log(f"candidate {session_id}: not judged, {reason}")
                case unreachable:
                    assert_never(unreachable)
        return verdicts

    def judge_session(self, session_id: str) -> CandidateVerdict:
        try:
            view = self.rex.call("session.view", {"session_id": session_id})
        except RexError as error:
            return Unjudgeable(session_id, str(error))
        blocks = _block_ids(view) if isinstance(view, dict) else []
        process: object = {}
        if blocks:
            with contextlib.suppress(RexError):
                process = self.rex.call(
                    "com.superlogical.terminal.process",
                    {"session_id": session_id, "block_id": blocks[0]},
                )
        return judge_candidate(view, process)

    # ----- saving -----

    def read_session(
        self, session_id: str, poll_cwds: bool
    ) -> Result[SavedSession, SessionParseError]:
        view = self.rex.call("session.view", {"session_id": session_id})
        if isinstance(view, dict):
            for block_id in _block_ids(view):
                if block_id in self.osc7_blocks:
                    continue
                if poll_cwds or block_id not in self.cwds:
                    self.poll_cwd(session_id, block_id)
        return parse_session(view, self.cwds)

    def poll_cwd(self, session_id: str, block_id: str) -> None:
        try:
            raw = self.rex.call(
                "com.superlogical.terminal.process",
                {"session_id": session_id, "block_id": block_id},
            )
            process = TerminalProcess.model_validate(raw)
        except (RexError, ValidationError):
            return
        if process.foreground and process.foreground.cwd:
            self.cwds[block_id] = process.foreground.cwd

    def refresh(self, session_ids: Sequence[str], poll_cwds: bool) -> dict[str, SavedSession]:
        """Read sessions from Rex, recording a problem for any that cannot be parsed."""
        fresh: dict[str, SavedSession] = {}
        for session_id in session_ids:
            try:
                result = self.read_session(session_id, poll_cwds)
            except RexError as error:
                # The session may have closed between the event and the read.
                self.log(f"could not read {session_id}: {error}")
                continue
            match result:
                case Ok(session):
                    fresh[session_id] = session
                case Err(error):
                    self.problem("session_unreadable", f"{error.path_in_view}: {error.reason}")
        return fresh

    def list_sessions(self) -> list[str]:
        listing = SessionList.model_validate(self.rex.call("session.list"))
        return [s.session_id for s in listing.sessions]

    def read_focus(self) -> None:
        """Read which session the app shows, from its preferences."""
        if self.app_preferences is None:
            return
        try:
            done = subprocess.run(
                ["defaults", "export", self.app_preferences, "-"], capture_output=True, timeout=10
            )
        except subprocess.TimeoutExpired:
            self.problem("focus_unreadable", "defaults export timed out")
            return
        match read_app_focus(done.stdout):
            case Ok(session_id):
                self.focused = session_id
            case Err(reason):
                self.problem("focus_unreadable", reason)

    def flush(self) -> None:
        if self.focus_dirty:
            self.focus_dirty = False
            self.read_focus()
        if self.dirty:
            live = self.list_sessions()
            self.session_order = live
            targets = [s for s in live if s in self.dirty]
            self.dirty.clear()
            self.cache.update(self.refresh(targets, poll_cwds=False))
            for gone in set(self.cache) - set(live):
                del self.cache[gone]
        self.save()

    def save(self) -> None:
        current: dict[str, Result[SavedSession, SessionParseError]] = {
            s: Ok(self.cache[s]) for s in self.session_order if s in self.cache
        }
        snapshot, _ = build_snapshot(
            current, self.cache, self.instance_id, now_iso(), focused=self.focused
        )
        decision = record_history(self.last_written, snapshot, self._history_files())
        match decision:
            case Unchanged():
                return
            case FocusOnly():
                write_atomic(self.state / "latest.json", snapshot_json(snapshot))
                self.last_written = snapshot
            case Changed(evict=evict):
                history = self.state / "history"
                history.mkdir(exist_ok=True)
                latest = self.state / "latest.json"
                if self.last_written is not None and latest.exists():
                    stamp = self.last_written.saved_at.replace(":", "-")
                    latest.replace(history / f"{stamp}.json")
                for name in evict:
                    (history / name).unlink(missing_ok=True)
                write_atomic(latest, snapshot_json(snapshot))
                self.last_written = snapshot
            case unreachable:
                assert_never(unreachable)

    def _history_files(self) -> list[str]:
        history = self.state / "history"
        return [p.name for p in history.glob("*.json")] if history.exists() else []

    def poll(self) -> None:
        """Re-read everything, and suspect each change no event has explained yet."""
        started = self.clock()
        self.read_focus()
        self.flush()
        live = self.list_sessions()
        self.session_order = live
        match self.focused:
            case None:
                pass
            case focused if focused in live:
                self.resolve("focus_unknown")
            case focused:
                self.problem("focus_unknown", focused)
        fresh = self.refresh(live, poll_cwds=True)
        recent = {s for s, t in self.last_event.items() if t > started - EVENT_GRACE}
        for session_id in unexplained_changes(self.cache, fresh, recent):
            change = describe_change(self.cache.get(session_id), fresh.get(session_id))
            self.suspects.setdefault(session_id, Suspect(session_id, started, change))
        self.cache = fresh
        self.save()
        self.write_status()

    def judge_suspects(self) -> None:
        """Drop each suspect an event has explained, and report each the grace ran out on."""
        now = self.clock()
        for suspect in list(self.suspects.values()):
            match judge(suspect, self.last_event.get(suspect.session_id), now):
                case Explained(session_id=session_id, after=after):
                    self.log(
                        f"change to {session_id} explained by an event {after:.1f}s after the poll"
                    )
                    del self.suspects[session_id]
                case Missed(session_id=session_id, change=change):
                    self.log(f"no event explained a change to {session_id}: {change}")
                    del self.suspects[session_id]
                    self.problem("events_missed", session_id)
                case Waiting():
                    pass
                case unreachable:
                    assert_never(unreachable)
        for suspect in self.suspects.values():
            assert now - suspect.raised_at < EVENT_GRACE, f"{suspect} outlived the grace"

    # ----- events -----

    def handle(self, line: str) -> None:
        try:
            event = RexEvent.model_validate_json(line)
        except ValidationError:
            return
        if event.type == "session_created":
            session_id = str(event.payload.get("session", {}).get("session_id", ""))
            self.mark(session_id)
        elif event.type == "session_destroyed":
            session_id = str(event.payload.get("session_id", ""))
            self.cache.pop(session_id, None)
            self.mark(session_id)
        elif event.type == "session_event":
            self.handle_session_event(event.payload)

    def handle_session_event(self, payload: Mapping[str, Any]) -> None:
        session_id = str(payload.get("session_id", ""))
        inner = payload.get("event") or {}
        kind = inner.get("type")
        if kind in ("client_connected", "client_disconnected", "block_owner_changed"):
            return
        if kind == "block_event":
            block = inner.get("payload") or {}
            block_id, name = str(block.get("block_id", "")), block.get("name")
            data = block.get("payload") or {}
            if name == "pwd_changed" and (path := decode_osc7(str(data.get("pwd", "")))):
                self.cwds[block_id] = path
                self.osc7_blocks.add(block_id)
            elif name == "size_changed":
                # The app resizes a session's panes when it shows them, so focus may have moved.
                self.focus_dirty = True
                return
            elif name == "process_changed" and block_id not in self.osc7_blocks:
                cwd = (data.get("foreground") or {}).get("cwd")
                if isinstance(cwd, str):
                    self.cwds[block_id] = cwd
            else:
                return
        self.mark(session_id)

    def mark(self, session_id: str) -> None:
        if session_id:
            self.dirty.add(session_id)
            self.last_event[session_id] = self.clock()

    # ----- status -----

    def problem(self, kind: ProblemKind, detail: str) -> None:
        problem = Problem(kind, detail)
        if problem not in self.problems:
            self.problems.append(problem)
            self.log(f"problem: {kind}: {detail}")
            self.write_status()

    def resolve(self, kind: ProblemKind) -> None:
        """Stop reporting a problem that describes a state, once that state has passed.

        Every other kind records something that happened, so it stays reported until the saver
        restarts. After a restart, the app's preferences name the old server's session until the
        app writes the new one.
        """
        assert kind in RESOLVABLE, f"{kind} records an event, so it is never resolved"
        kept = [p for p in self.problems if p.kind != kind]
        if len(kept) < len(self.problems):
            self.problems = kept
            self.log(f"resolved: {kind}")
            self.write_status()

    def write_status(self) -> None:
        status = {
            "instance_id": self.instance_id,
            "pid": os.getpid(),
            "heartbeat_at": now_iso(),
            "problems": [{"kind": p.kind, "detail": p.detail} for p in self.problems],
        }
        write_atomic(self.state / "status.json", json.dumps(status, indent=2) + "\n")
        warning = self.state / "warning"
        text = warning_text(self.problems)
        if text:
            write_atomic(warning, text + "\n")
        else:
            warning.unlink(missing_ok=True)

    # ----- main loop -----

    def run(self) -> None:
        events = self.rex.events()
        assert events.stdout is not None
        self.session_order = self.list_sessions()
        self.cache = self.refresh(self.session_order, poll_cwds=True)
        self.read_focus()
        self.save()
        selector = selectors.DefaultSelector()
        selector.register(events.stdout, selectors.EVENT_READ)
        next_flush = time.monotonic() + FLUSH_EVERY
        next_poll = time.monotonic() + POLL_EVERY
        for line in _lines(events.stdout, selector, timeout=FLUSH_EVERY / 4):
            if line is not None:
                self.handle(line)
            now = time.monotonic()
            if now >= next_flush:
                self.flush()
                next_flush = now + FLUSH_EVERY
            if now >= next_poll:
                self.poll()
                next_poll = now + POLL_EVERY
            self.judge_suspects()
        events.wait()
        self.log("event stream ended: the Rex server stopped")


def _lines(
    stream: IO[str], selector: selectors.BaseSelector, timeout: float
) -> Iterator[str | None]:
    """Each line from `stream`, or None after `timeout` seconds with none. Ends at EOF."""
    buffer = ""
    fd = stream.fileno()
    while True:
        if not selector.select(timeout=timeout):
            yield None
            continue
        chunk = os.read(fd, 65536)
        if not chunk:
            return
        buffer += chunk.decode(errors="replace")
        *complete, buffer = buffer.split("\n")
        for line in complete:
            if line.strip():
                yield line


def _block_ids(view: Mapping[str, Any]) -> list[str]:
    ids: list[str] = []
    for window in view.get("windows") or []:
        for layer in (window or {}).get("layers") or []:
            for block in (layer or {}).get("blocks") or []:
                if isinstance(block, dict) and isinstance(block.get("block_id"), str):
                    ids.append(block["block_id"])
    return ids


def main(argv: Sequence[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    run = sub.add_parser("run", help="save and restore the sessions of one Rex server")
    run.add_argument("--state-dir", required=True, type=Path)
    run.add_argument("--rex", help="the rex binary (default: the one inside the Rex app)")
    run.add_argument("--server", help="the server address (default: rex's own default)")
    run.add_argument(
        "--app-preferences",
        default="com.superlogical.rex",
        help="the Rex app's preferences domain or plist path, read for its focused session",
    )
    args = parser.parse_args(argv)

    state: Path = args.state_dir.expanduser()
    state.mkdir(parents=True, exist_ok=True)
    state.chmod(0o700)
    log = Log(state / "saver.log")
    lock = acquire_lock(state / "saver.lock", timeout=10)
    if lock is None:
        log("another saver holds the lock; exiting")
        return
    saver: Saver | None = None
    try:
        saver = Saver(
            Rex(find_rex(args.rex), args.server), state, log, app_preferences=args.app_preferences
        )
        saver.start()
        saver.run()
    except SystemExit:
        raise
    except Exception as error:
        log(f"saver crashed: {error!r}")
        if saver is not None:
            with contextlib.suppress(Exception):
                saver.problem("saver_crashed", type(error).__name__)
        raise SystemExit(1) from error
    finally:
        lock.close()


if __name__ == "__main__":
    sys.exit(main())
