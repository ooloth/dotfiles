#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic==2.14.1", "hypothesis", "beartype"]
# ///
"""Tests for tools/rex/saver.py, which saves Rex's sessions and restores them after a restart.

Run with: uv run tools/rex/tests/test_saver.py

The pure parts of the saver are called directly with JSON shaped like what `rex api call` returns,
recorded from a throwaway Rex server. Round trips go through `simulate_create`, which builds the
`session.view` that Rex would report after a `session.create`, so no test needs a Rex server. The
lock test starts a second Python process, because the lock is the operating system's. The zsh
check is run in a real zsh. The restart itself is checked by `live_restore.py`, run by hand.
"""

from __future__ import annotations

import json
import os
import plistlib
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

from beartype.claw import beartype_package
from hypothesis import given, settings
from hypothesis import strategies as st

REX_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REX_DIR))
beartype_package("saver")
import saver  # noqa: E402
from saver import Err, Ok  # noqa: E402

SHELL_ZSH = REX_DIR / "shell.zsh"
SHELL_FLAVOR = "com.superlogical.terminal.shell"
REX_ID = re.compile(r"(block|window|session|split):[0-9a-f]{8}-[0-9a-f]{4}-")
OSC7 = re.compile(r"\x1b\]7;[^\x1b]*\x1b\\")

# ----- Building Rex-shaped input ----------------------------------------------------------------

_ids = iter(range(10**9))


def new_id(kind: str) -> str:
    return f"{kind}:01a1759d-c604-7b62-911f-{next(_ids):012x}"


def simulate_create(request: dict[str, Any], session_id: str | None = None) -> tuple[dict, dict]:
    """The session.view Rex reports after creating `request`, and each new block's cwd.

    Rex labels an unlabelled window `Window <last 8 characters of its ID>` and an unlabelled block
    `shell`, and makes the last window active.
    """
    blocks: list[dict] = []
    cwds: dict[str, str] = {}

    def node(n: dict) -> dict:
        if "split" in n:
            s = n["split"]
            return {
                "split": {
                    "split_id": new_id("split"),
                    "direction": s["direction"],
                    "ratio": s["ratio"],
                    "before": node(s["before"]),
                    "after": node(s["after"]),
                }
            }
        block_id = new_id("block")
        b = n["block"]
        blocks.append(
            {
                "block_id": block_id,
                "label": b.get("label", "shell"),
                "creator_name": "com.superlogical.terminal",
                "flavor": b["flavor"],
                "owner": None,
            }
        )
        if "cwd" in b.get("options", {}):
            cwds[block_id] = b["options"]["cwd"]
        return {"rect": [0, 0, 1, 1], "block_id": block_id}

    windows = []
    for w in request.get("initial_windows", []):
        blocks.clear()
        window_id = new_id("window")
        layout = node(w["layout"])
        windows.append(
            {
                "window_id": window_id,
                "label": w.get("window_label", f"Window {window_id[-8:]}"),
                "layers": [{"kind": "tiled", "layout": layout, "blocks": list(blocks)}],
            }
        )
    view = {
        "revision": 1,
        "session_id": session_id or new_id("session"),
        "label": request["label"],
        "active_window_id": windows[-1]["window_id"] if windows else None,
        "windows": windows,
    }
    return view, cwds


def focus(view: dict, index: int | None) -> dict:
    """The view after `session.focus_window` makes the window at `index` (0-based) active."""
    if index is not None:
        view = {**view, "active_window_id": view["windows"][index]["window_id"]}
    return view


def two_pane_view() -> tuple[dict, dict]:
    request = {
        "label": "work",
        "initial_windows": [
            {
                "window_label": "edit",
                "layout": {
                    "split": {
                        "direction": "horizontal",
                        "ratio": 0.3,
                        "before": {
                            "block": {
                                "flavor": SHELL_FLAVOR,
                                "label": "left",
                                "options": {"cwd": "/tmp"},
                            }
                        },
                        "after": {"block": {"flavor": SHELL_FLAVOR, "options": {"cwd": "/usr"}}},
                    }
                },
            },
            {"layout": {"block": {"flavor": SHELL_FLAVOR, "options": {"cwd": "/etc"}}}},
        ],
    }
    return simulate_create(request)


labels = st.text(
    alphabet=st.characters(blacklist_categories=("Cs", "Cc")), min_size=1, max_size=12
).filter(lambda s: not s.startswith("Window "))
paths = st.lists(
    st.text(alphabet="abc é %-_.", min_size=1, max_size=6).filter(lambda s: s not in (".", "..")),
    max_size=3,
).map(lambda parts: "/" + "/".join(parts))
ratios = st.floats(min_value=0.01, max_value=0.99, allow_nan=False)


def layouts(depth: int = 3) -> st.SearchStrategy[dict]:
    pane = st.builds(
        lambda label, cwd: {
            "block": {
                "flavor": SHELL_FLAVOR,
                **({"label": label} if label is not None else {}),
                "options": {"cwd": cwd} if cwd is not None else {},
            }
        },
        st.none() | labels,
        st.none() | paths,
    )
    if depth == 0:
        return pane
    split = st.builds(
        lambda d, r, b, a: {"split": {"direction": d, "ratio": r, "before": b, "after": a}},
        st.sampled_from(["horizontal", "vertical"]),
        ratios,
        layouts(depth - 1),
        layouts(depth - 1),
    )
    return pane | split


session_requests = st.builds(
    lambda label, windows: {"label": label, "initial_windows": windows},
    labels,
    st.lists(
        st.builds(
            lambda label, layout: {
                **({"window_label": label} if label is not None else {}),
                "layout": layout,
            },
            st.none() | labels,
            layouts(),
        ),
        min_size=1,
        max_size=4,
    ),
)

json_values = st.recursive(
    st.none() | st.booleans() | st.floats(allow_nan=False) | st.text(max_size=8),
    lambda inner: st.lists(inner, max_size=3) | st.dictionaries(st.text(max_size=8), inner),
    max_leaves=12,
)


def pane(label: str) -> saver.PaneLabel:
    return saver.PaneLabel(label)


def parsed(view: dict, cwds: dict[str, str]) -> saver.SavedSession:
    result = saver.parse_session(view, cwds)
    assert isinstance(result, Ok), result
    return result.value


def snapshot_of(
    *sessions: saver.SavedSession,
    saved_at: str = "2026-10-25T00:00:00Z",
    focused_index: int | None = None,
):
    return saver.Snapshot(
        format=2,
        instance_id=saver.InstanceId("instance-1"),
        saved_at=saved_at,
        sessions=tuple(sessions),
        focused_index=focused_index,
    )


def named(label: str) -> saver.SavedSession:
    """A one-tab session called `label`."""
    request = {"label": label, "initial_windows": [{"layout": {"block": {"flavor": SHELL_FLAVOR}}}]}
    return parsed(*simulate_create(request))


# ----- Saving and restoring a layout ------------------------------------------------------------


class RoundTrip(unittest.TestCase):
    @settings(max_examples=150, deadline=None)
    @given(session_requests, st.integers(min_value=0, max_value=3))
    def test_a_restored_session_parses_back_to_the_layout_that_was_saved(
        self, request: dict, active: int
    ) -> None:
        active = min(active, len(request["initial_windows"]) - 1)
        original = parsed(*_focused(simulate_create(request), active))

        restore = saver.restore_request(original)
        view, cwds = simulate_create(restore.create)
        rebuilt = parsed(focus(view, restore.active_index), cwds)

        self.assertEqual(rebuilt, original)

    def test_a_saved_session_keeps_labels_ratios_directories_order_and_active_tab(self) -> None:
        view, cwds = two_pane_view()
        session = parsed(focus(view, 0), cwds)

        self.assertEqual(session.label, "work")
        self.assertEqual(session.active_index, 0)
        first, second = session.windows
        self.assertEqual(first.label, "edit")
        self.assertEqual(
            first.layout,
            saver.SavedSplit(
                direction="horizontal",
                ratio=saver.Ratio(0.3),
                before=saver.SavedPane(label=pane("left"), cwd=saver.AbsolutePath("/tmp")),
                after=saver.SavedPane(label=pane("shell"), cwd=saver.AbsolutePath("/usr")),
            ),
        )
        self.assertEqual(second.label, None, "a default window label is not kept")
        self.assertEqual(
            second.layout, saver.SavedPane(label=pane("shell"), cwd=saver.AbsolutePath("/etc"))
        )

    def test_a_pane_without_a_known_directory_restores_without_one(self) -> None:
        view, _ = two_pane_view()
        session = parsed(view, {})
        self.assertEqual(session.windows[1].layout, saver.SavedPane(label=pane("shell"), cwd=None))
        request = saver.restore_request(session).create
        self.assertEqual(request["initial_windows"][1]["layout"]["block"]["options"], {})


def _focused(view_and_cwds: tuple[dict, dict], index: int) -> tuple[dict, dict]:
    view, cwds = view_and_cwds
    return focus(view, index), cwds


class ParsingRexInput(unittest.TestCase):
    @settings(max_examples=300, deadline=None)
    @given(json_values)
    def test_any_json_returns_a_session_or_a_named_error_without_raising(self, value: Any) -> None:
        result = saver.parse_session(value, {})
        self.assertIsInstance(result, Ok | Err)
        if isinstance(result, Err):
            self.assertIsInstance(result.error, saver.SessionParseError)
            self.assertTrue(result.error.reason)

    @settings(max_examples=200, deadline=None)
    @given(json_values)
    def test_any_json_in_a_layout_node_returns_a_named_error_without_raising(
        self, value: Any
    ) -> None:
        view, cwds = two_pane_view()
        view["windows"][0]["layers"][0]["layout"]["split"]["after"] = value
        result = saver.parse_session(view, cwds)
        self.assertIsInstance(result, Ok | Err)

    def test_a_ratio_outside_zero_and_one_is_a_named_error(self) -> None:
        view, cwds = two_pane_view()
        view["windows"][0]["layers"][0]["layout"]["split"]["ratio"] = 1.5
        result = saver.parse_session(view, cwds)
        assert isinstance(result, Err), result
        self.assertIn("ratio", result.error.reason)
        self.assertEqual(result.error.session_id, view["session_id"])

    def test_a_relative_directory_is_dropped(self) -> None:
        view, cwds = two_pane_view()
        cwds = {block: "relative/dir" for block in cwds}
        session = parsed(view, cwds)
        self.assertEqual(session.windows[1].layout, saver.SavedPane(label=pane("shell"), cwd=None))

    def test_a_layout_deeper_than_rex_allows_is_a_named_error(self) -> None:
        node: dict = {"block": {"flavor": SHELL_FLAVOR}}
        for _ in range(70):
            leaf = {"block": {"flavor": SHELL_FLAVOR}}
            node = {"split": {"direction": "vertical", "ratio": 0.5, "before": leaf, "after": node}}
        view, cwds = simulate_create({"label": "deep", "initial_windows": [{"layout": node}]})
        result = saver.parse_session(view, cwds)
        assert isinstance(result, Err), result
        self.assertIn("deep", result.error.reason)

    def test_osc7_urls_decode_to_paths(self) -> None:
        cases = {
            "file://Air.local/tmp/a%20b": "/tmp/a b",
            "file:///Users/me/100%25": "/Users/me/100%",
            "file://host/caf%C3%A9": "/café",
            "/already/a/path": "/already/a/path",
        }
        for url, path in cases.items():
            with self.subTest(url=url):
                self.assertEqual(saver.decode_osc7(url), path)

    def test_an_osc7_url_that_is_not_a_path_decodes_to_nothing(self) -> None:
        self.assertIsNone(saver.decode_osc7("https://example.com/x"))
        self.assertIsNone(saver.decode_osc7(""))


class WhatReachesDisk(unittest.TestCase):
    @settings(max_examples=100, deadline=None)
    @given(session_requests)
    def test_a_written_snapshot_holds_no_rex_ids_commands_or_output(self, request: dict) -> None:
        view, cwds = simulate_create(request)
        text = saver.snapshot_json(snapshot_of(parsed(view, cwds)))

        self.assertIsNone(REX_ID.search(text), "a snapshot holds no Rex IDs")
        keys = _all_keys(json.loads(text))
        self.assertLessEqual(
            keys,
            {
                "format",
                "instance_id",
                "saved_at",
                "sessions",
                "focused_index",
                "label",
                "windows",
                "active_index",
                "layout",
                "pane",
                "split",
                "cwd",
                "direction",
                "ratio",
                "before",
                "after",
            },
        )

    def test_a_written_snapshot_loads_back_unchanged(self) -> None:
        view, cwds = two_pane_view()
        snap = snapshot_of(parsed(view, cwds))
        self.assertEqual(saver.load_snapshot(saver.snapshot_json(snap)), Ok(snap))

    def test_an_unreadable_snapshot_is_a_named_error(self) -> None:
        for text in ("", "{", '{"format": 2, "sessions": []}', '{"format": 1}'):
            with self.subTest(text=text):
                self.assertIsInstance(saver.load_snapshot(text), Err)

    @settings(max_examples=100, deadline=None)
    @given(st.lists(labels, min_size=1, max_size=5), st.data())
    def test_a_snapshot_with_any_focus_loads_back_unchanged(
        self, names: list[str], data: st.DataObject
    ) -> None:
        focused = data.draw(st.none() | st.integers(min_value=0, max_value=len(names) - 1))
        snap = snapshot_of(*(named(n) for n in names), focused_index=focused)
        self.assertEqual(saver.load_snapshot(saver.snapshot_json(snap)), Ok(snap))

    def test_a_snapshot_written_before_focus_was_saved_loads_with_no_focus(self) -> None:
        text = json.dumps(
            {
                "format": 1,
                "instance_id": "instance-1",
                "saved_at": "t",
                "sessions": [
                    {
                        "label": "work",
                        "windows": [
                            {"label": None, "layout": {"pane": {"label": None, "cwd": "/"}}}
                        ],
                        "active_index": 0,
                    }
                ],
            }
        )
        result = saver.load_snapshot(text)
        assert isinstance(result, Ok), result
        self.assertIsNone(result.value.focused_index)
        self.assertEqual([s.label for s in result.value.sessions], ["work"])

    def test_a_saved_focus_past_the_last_session_is_a_named_error(self) -> None:
        text = saver.snapshot_json(snapshot_of(named("a"), focused_index=0))
        data = json.loads(text)
        data["focused_index"] = 1
        result = saver.load_snapshot(json.dumps(data))
        assert isinstance(result, Err), result
        self.assertIn("focused_index", result.error)

    def test_a_snapshot_cannot_hold_a_focus_past_its_last_session(self) -> None:
        with self.assertRaises(AssertionError):
            snapshot_of(named("a"), focused_index=1)
        with self.assertRaises(AssertionError):
            snapshot_of(named("a"), focused_index=-1)


def _all_keys(value: Any) -> set[str]:
    if isinstance(value, dict):
        return set(value) | set().union(*(_all_keys(v) for v in value.values()))
    if isinstance(value, list):
        return set().union(*(_all_keys(v) for v in value))
    return set()


class BuildingASnapshot(unittest.TestCase):
    def test_a_session_that_fails_to_parse_keeps_its_last_good_copy(self) -> None:
        view, cwds = two_pane_view()
        good = parsed(view, cwds)
        error = saver.SessionParseError(view["session_id"], "windows", "changed shape")

        snap, errors = saver.build_snapshot(
            current={view["session_id"]: Err(error)},
            last_good={view["session_id"]: good},
            instance_id=saver.InstanceId("i"),
            saved_at="t",
        )

        self.assertEqual(snap.sessions, (good,))
        self.assertEqual(errors, (error,))

    def test_a_session_that_never_parsed_is_left_out(self) -> None:
        error = saver.SessionParseError("session:x", "", "bad")
        snap, errors = saver.build_snapshot(
            current={"session:x": Err(error)}, last_good={}, instance_id="i", saved_at="t"
        )
        self.assertEqual(snap.sessions, ())
        self.assertEqual(errors, (error,))

    def test_an_empty_server_saves_an_empty_snapshot(self) -> None:
        snap, errors = saver.build_snapshot(current={}, last_good={}, instance_id="i", saved_at="t")
        self.assertEqual(snap.sessions, ())
        self.assertEqual(errors, ())

    @settings(max_examples=200, deadline=None)
    @given(
        st.lists(st.sampled_from(["ok", "bad", "bad-with-last-good"]), min_size=1, max_size=6),
        st.data(),
    )
    def test_the_focused_session_is_saved_as_its_position_among_the_saved_sessions(
        self, kinds: list[str], data: st.DataObject
    ) -> None:
        ids = [f"session:{i}" for i in range(len(kinds))]
        current: dict[str, Any] = {}
        last_good: dict[str, saver.SavedSession] = {}
        for session_id, kind in zip(ids, kinds, strict=True):
            session = named(session_id)
            if kind == "ok":
                current[session_id] = Ok(session)
            else:
                current[session_id] = Err(saver.SessionParseError(session_id, "", "bad"))
                if kind == "bad-with-last-good":
                    last_good[session_id] = session
        focused = data.draw(st.sampled_from([*ids, "session:gone"]))

        snap, _ = saver.build_snapshot(current, last_good, "i", "t", focused=focused)

        saved_labels = [s.label for s in snap.sessions]
        if focused in saved_labels:
            assert snap.focused_index is not None
            self.assertEqual(snap.sessions[snap.focused_index].label, focused)
        else:
            self.assertIsNone(snap.focused_index)

    def test_with_no_focus_known_none_is_saved(self) -> None:
        snap, _ = saver.build_snapshot({"session:a": Ok(named("a"))}, {}, "i", "t", focused=None)
        self.assertIsNone(snap.focused_index)


class CheckingRexOffersWhatTheSaverNeeds(unittest.TestCase):
    # The shape `rex api list --json` returns: server methods, then each block type's methods.
    LISTING = {
        "methods": [{"name": m} for m in saver.REQUIRED_METHODS if "." in m and m.count(".") == 1],
        "block_types": [
            {
                "creator": "com.superlogical.terminal",
                "methods": [{"name": "process"}, {"name": "pwd"}],
            }
        ],
    }

    def test_a_listing_with_every_method_lacks_nothing(self) -> None:
        self.assertEqual(saver.missing_methods(json.dumps(self.LISTING)), Ok(()))

    def test_a_block_method_rex_dropped_is_named(self) -> None:
        listing = {
            **self.LISTING,
            "block_types": [{"creator": "com.superlogical.terminal", "methods": []}],
        }
        self.assertEqual(
            saver.missing_methods(json.dumps(listing)), Ok(("com.superlogical.terminal.process",))
        )

    def test_a_server_method_rex_dropped_is_named(self) -> None:
        listing = {
            **self.LISTING,
            "methods": [m for m in self.LISTING["methods"] if m["name"] != "session.view"],
        }
        self.assertEqual(saver.missing_methods(json.dumps(listing)), Ok(("session.view",)))

    def test_a_listing_of_another_shape_is_a_named_error(self) -> None:
        self.assertIsInstance(saver.missing_methods('{"methods": 3}'), Err)


# ----- Deciding what to do ----------------------------------------------------------------------


class PlanningARestore(unittest.TestCase):
    def setUp(self) -> None:
        view, cwds = two_pane_view()
        self.session = parsed(view, cwds)
        self.instance = saver.InstanceId("instance-2")

    def plan(self, marker: str | None, latest: Any) -> saver.RestorePlan:
        return saver.plan_restore(marker, self.instance, latest)

    def test_a_new_server_with_a_saved_layout_restores_it(self) -> None:
        self.assertEqual(
            self.plan("instance-1", Ok(snapshot_of(self.session))),
            saver.Restore(sessions=(self.session,)),
        )

    def test_a_first_ever_run_restores_too(self) -> None:
        self.assertIsInstance(self.plan(None, Ok(snapshot_of(self.session))), saver.Restore)

    def test_a_server_already_restored_into_is_not_restored_again(self) -> None:
        self.assertEqual(
            self.plan("instance-2", Ok(snapshot_of(self.session))), saver.AlreadyRestored()
        )

    def test_nothing_saved_restores_nothing(self) -> None:
        self.assertEqual(self.plan("instance-1", Ok(None)), saver.NothingSaved())
        self.assertEqual(self.plan("instance-1", Ok(snapshot_of())), saver.NothingSaved())

    def test_an_unreadable_snapshot_is_named_with_its_reason(self) -> None:
        self.assertEqual(
            self.plan("instance-1", Err("bad json")), saver.SnapshotUnreadable(reason="bad json")
        )

    def test_a_server_already_restored_into_ignores_an_unreadable_snapshot(self) -> None:
        self.assertEqual(self.plan("instance-2", Err("bad json")), saver.AlreadyRestored())


class KeepingHistory(unittest.TestCase):
    def setUp(self) -> None:
        view, cwds = two_pane_view()
        self.session = parsed(view, cwds)
        self.other = parsed(*simulate_create({"label": "other", "initial_windows": []}))

    def test_a_change_only_to_the_save_time_is_not_history(self) -> None:
        old = snapshot_of(self.session, saved_at="t1")
        new = snapshot_of(self.session, saved_at="t2")
        self.assertEqual(saver.record_history(old, new, existing=()), saver.Unchanged())

    def test_a_changed_layout_moves_the_old_one_into_history(self) -> None:
        old = snapshot_of(self.session, saved_at="t1")
        new = snapshot_of(self.other, saved_at="t2")
        self.assertEqual(saver.record_history(old, new, existing=()), saver.Changed(evict=()))

    def test_the_first_save_has_nothing_to_move(self) -> None:
        self.assertEqual(
            saver.record_history(None, snapshot_of(self.session), existing=()),
            saver.Changed(evict=()),
        )

    def test_history_keeps_20_and_evicts_the_oldest_first(self) -> None:
        existing = tuple(f"2026-10-25T00-00-{i:02d}Z.json" for i in range(20))
        decision = saver.record_history(
            snapshot_of(self.session), snapshot_of(self.other), existing=tuple(reversed(existing))
        )
        self.assertEqual(decision, saver.Changed(evict=(existing[0],)))

    def test_switching_sessions_rewrites_the_latest_but_adds_no_history(self) -> None:
        old = snapshot_of(self.session, self.other, saved_at="t1", focused_index=0)
        new = snapshot_of(self.session, self.other, saved_at="t2", focused_index=1)
        existing = tuple(f"2026-10-25T00-00-{i:02d}Z.json" for i in range(20))
        self.assertEqual(saver.record_history(old, new, existing=existing), saver.FocusOnly())

    def test_a_layout_change_with_a_focus_change_is_still_history(self) -> None:
        old = snapshot_of(self.session, self.other, focused_index=0)
        new = snapshot_of(self.other, self.session, focused_index=1)
        self.assertEqual(saver.record_history(old, new, existing=()), saver.Changed(evict=()))

    def test_history_that_somehow_grew_past_20_is_trimmed_back(self) -> None:
        existing = tuple(f"2026-10-25T00-00-{i:02d}Z.json" for i in range(25))
        decision = saver.record_history(
            snapshot_of(self.session), snapshot_of(self.other), existing=existing
        )
        self.assertEqual(decision, saver.Changed(evict=existing[:6]))


class CheckingEventsAgainstPolling(unittest.TestCase):
    def test_a_layout_change_no_event_explained_is_reported(self) -> None:
        view, cwds = two_pane_view()
        cached = parsed(view, cwds)
        view["windows"][0]["label"] = "renamed"
        fresh = parsed(view, cwds)
        self.assertEqual(
            saver.unexplained_changes({"s": cached}, {"s": fresh}, recently_changed=set()), ("s",)
        )

    def test_matching_layouts_report_nothing(self) -> None:
        view, cwds = two_pane_view()
        s = parsed(view, cwds)
        self.assertEqual(saver.unexplained_changes({"s": s}, {"s": s}, recently_changed=set()), ())

    def test_a_directory_change_alone_is_not_reported(self) -> None:
        view, cwds = two_pane_view()
        cached = parsed(view, cwds)
        fresh = parsed(view, {block: "/somewhere/else" for block in cwds})
        self.assertEqual(
            saver.unexplained_changes({"s": cached}, {"s": fresh}, recently_changed=set()), ()
        )

    def test_a_session_added_or_removed_without_an_event_is_reported(self) -> None:
        view, cwds = two_pane_view()
        s = parsed(view, cwds)
        self.assertEqual(
            saver.unexplained_changes({}, {"new": s}, recently_changed=set()), ("new",)
        )
        self.assertEqual(
            saver.unexplained_changes({"gone": s}, {}, recently_changed=set()), ("gone",)
        )

    def test_a_session_with_a_recent_event_is_not_reported(self) -> None:
        view, cwds = two_pane_view()
        cached = parsed(view, cwds)
        view["label"] = "renamed"
        fresh = parsed(view, cwds)
        self.assertEqual(
            saver.unexplained_changes({"s": cached}, {"s": fresh}, recently_changed={"s"}), ()
        )


times = st.floats(min_value=0, max_value=1e6, allow_nan=False)
waits = st.floats(min_value=0, max_value=60, allow_nan=False)


class JudgingASuspect(unittest.TestCase):
    """A poll's unexplained change waits `EVENT_GRACE` seconds for its event before it counts."""

    def suspect(self, raised_at: float) -> saver.Suspect:
        return saver.Suspect("s", raised_at, change="active tab 1→0")

    @given(times, waits, waits)
    def test_an_event_at_or_after_the_poll_explains_the_change(
        self, raised_at: float, event_after: float, judged_after: float
    ) -> None:
        verdict = saver.judge(
            self.suspect(raised_at),
            last_event_at=raised_at + event_after,
            now=raised_at + max(event_after, judged_after),
        )
        assert isinstance(verdict, saver.Explained), verdict
        self.assertAlmostEqual(verdict.after, event_after, places=6)

    @given(times, waits)
    def test_with_no_event_the_change_waits_then_counts_as_missed(
        self, raised_at: float, judged_after: float
    ) -> None:
        verdict = saver.judge(
            self.suspect(raised_at), last_event_at=None, now=raised_at + judged_after
        )
        if judged_after < saver.EVENT_GRACE:
            self.assertEqual(verdict, saver.Waiting())
        else:
            self.assertEqual(verdict, saver.Missed("s", change="active tab 1→0"))

    @given(times, st.floats(min_value=1e-3, max_value=60, allow_nan=False), waits)
    def test_an_event_before_the_poll_does_not_explain_the_change(
        self, raised_at: float, event_before: float, judged_after: float
    ) -> None:
        verdict = saver.judge(
            self.suspect(raised_at),
            last_event_at=raised_at - event_before,
            now=raised_at + judged_after,
        )
        self.assertNotIsInstance(verdict, saver.Explained)

    def test_a_clock_that_runs_backwards_stops_the_saver(self) -> None:
        with self.assertRaises(AssertionError):
            saver.judge(self.suspect(10.0), last_event_at=None, now=9.0)


class DescribingAChange(unittest.TestCase):
    def setUp(self) -> None:
        self.view, self.cwds = two_pane_view()
        self.before = parsed(self.view, self.cwds)

    def after(self, edit) -> saver.SavedSession:
        view = json.loads(json.dumps(self.view))
        edit(view)
        return parsed(view, self.cwds)

    def test_a_switch_of_tab_names_both_positions(self) -> None:
        first = self.view["windows"][0]["window_id"]
        after = self.after(lambda v: v.update(active_window_id=first))
        self.assertEqual(saver.describe_change(self.before, after), "active tab 1→0")

    def test_a_renamed_tab_is_named_as_tab_labels(self) -> None:
        after = self.after(lambda v: v["windows"][0].update(label="renamed"))
        self.assertEqual(saver.describe_change(self.before, after), "tab labels")

    def test_a_closed_tab_names_the_counts(self) -> None:
        after = self.after(lambda v: v.update(windows=v["windows"][:1]))
        self.assertIn("tabs 2→1", saver.describe_change(self.before, after))

    def test_a_session_that_appears_or_disappears_says_so(self) -> None:
        self.assertEqual(saver.describe_change(None, self.before), "session appeared")
        self.assertEqual(saver.describe_change(self.before, None), "session disappeared")


class RecordedRex(saver.Rex):
    """Answers `rex api call` from views recorded on a throwaway server, without a subprocess."""

    def __init__(self, views: dict[str, dict]) -> None:
        super().__init__(Path("/nonexistent/rex"), None)
        self.views = views

    def call(self, method: str, args: Any = None) -> Any:
        match method:
            case "session.list":
                return {"sessions": [{"session_id": s} for s in self.views]}
            case "session.view":
                return self.views[args["session_id"]]
        raise saver.RexError(f"{method}: not recorded")


class Clock:
    def __init__(self) -> None:
        self.now = 1000.0

    def __call__(self) -> float:
        return self.now


class PollRacingAnEvent(unittest.TestCase):
    """A tab switch the poll reads before the saver has handled the event that reports it."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        state = Path(self.tmp.name)
        self.view, cwds = two_pane_view()
        self.session_id = self.view["session_id"]
        self.rex = RecordedRex({self.session_id: self.view})
        self.clock = Clock()
        self.saver = saver.Saver(self.rex, state, saver.Log(state / "saver.log"), clock=self.clock)
        self.saver.cache = {self.session_id: parsed(self.view, cwds)}
        self.log = state / "saver.log"

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def switch_tab_during_the_poll(self) -> None:
        moved = json.loads(json.dumps(self.view))
        moved["active_window_id"] = moved["windows"][0]["window_id"]
        self.rex.views[self.session_id] = moved
        self.saver.poll()

    def tab_switch_event(self) -> str:
        return json.dumps(
            {
                "type": "session_event",
                "payload": {
                    "session_id": self.session_id,
                    "event": {"type": "active_window_changed", "payload": {}},
                },
            }
        )

    def test_an_event_just_after_the_poll_raises_no_problem_and_is_logged(self) -> None:
        self.switch_tab_during_the_poll()
        self.clock.now += 0.2
        self.saver.handle(self.tab_switch_event())
        self.clock.now += saver.EVENT_GRACE
        self.saver.judge_suspects()
        self.assertEqual(self.saver.problems, [])
        self.assertIn("explained by an event 0.2s after the poll", self.log.read_text())

    def test_no_event_counts_as_missed_only_after_the_grace(self) -> None:
        self.switch_tab_during_the_poll()
        self.clock.now += saver.EVENT_GRACE - 0.1
        self.saver.judge_suspects()
        self.assertEqual(self.saver.problems, [])
        self.clock.now += 0.1
        self.saver.judge_suspects()
        self.assertEqual(self.saver.problems, [saver.Problem("events_missed", self.session_id)])
        self.assertIn("active tab 1→0", self.log.read_text())

    def test_a_later_poll_keeps_the_first_stamp(self) -> None:
        self.switch_tab_during_the_poll()
        first = self.saver.suspects[self.session_id]
        self.clock.now += 1.0
        self.saver.cache = {}
        self.saver.poll()
        self.assertEqual(self.saver.suspects[self.session_id], first)


class WarningText(unittest.TestCase):
    def test_no_problems_means_no_warning(self) -> None:
        self.assertEqual(saver.warning_text(()), "")

    def test_a_missed_event_names_the_poll_and_stays_one_clause(self) -> None:
        text = saver.warning_text((saver.Problem("events_missed", "s1"),))
        self.assertIn("30-second poll", text)
        self.assertNotIn(";", text)

    def test_each_problem_is_named_once_with_its_detail(self) -> None:
        problem = saver.Problem("restore_failed", "work")
        text = saver.warning_text((problem, problem, saver.Problem("events_missed", "s1")))
        self.assertEqual(text.count("failed to restore"), 1)
        self.assertIn("(work)", text)
        self.assertIn("(s1)", text)


# Event lines as `rex events --all --json` printed them on a throwaway server.
SESSION = "session:01a1759d-c604-7b62-911f-3ee869c8cf38"
BLOCK = "block:01a1759d-c604-7e8a-82c3-ef0c14f7e87b"


def block_event(name: str, payload: dict) -> str:
    inner = {"block_id": BLOCK, "creator_name": "com.superlogical.terminal", "name": name}
    return json.dumps(
        {
            "type": "session_event",
            "payload": {
                "session_id": SESSION,
                "event": {"type": "block_event", "payload": {**inner, "payload": payload}},
            },
        }
    )


class FollowingEvents(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        state = Path(self.tmp.name)
        self.saver = saver.Saver(
            saver.Rex(Path("/nonexistent/rex"), None), state, saver.Log(state / "saver.log")
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_a_reported_directory_is_recorded_and_marks_the_session_changed(self) -> None:
        self.saver.handle(block_event("pwd_changed", {"pwd": "file://Air.local/tmp/a%20b"}))
        self.assertEqual(self.saver.cwds[BLOCK], "/tmp/a b")
        self.assertIn(SESSION, self.saver.dirty)

    def test_a_reported_directory_outranks_the_foreground_process(self) -> None:
        self.saver.handle(block_event("pwd_changed", {"pwd": "file://h/src"}))
        self.saver.handle(block_event("process_changed", {"foreground": {"cwd": "/elsewhere"}}))
        self.assertEqual(self.saver.cwds[BLOCK], "/src")

    def test_without_a_reported_directory_the_foreground_process_supplies_it(self) -> None:
        self.saver.handle(block_event("process_changed", {"foreground": {"cwd": "/var"}}))
        self.assertEqual(self.saver.cwds[BLOCK], "/var")

    def test_client_comings_and_goings_change_nothing(self) -> None:
        line = json.dumps(
            {
                "type": "session_event",
                "payload": {
                    "session_id": SESSION,
                    "event": {"type": "client_connected", "payload": {"client_id": "client:x"}},
                },
            }
        )
        self.saver.handle(line)
        self.assertEqual(self.saver.dirty, set())

    def test_a_layout_change_marks_the_session_changed(self) -> None:
        line = json.dumps(
            {
                "type": "session_event",
                "payload": {
                    "session_id": SESSION,
                    "event": {"type": "session_view_changed", "payload": {"revision": 3}},
                },
            }
        )
        self.saver.handle(line)
        self.assertEqual(self.saver.dirty, {SESSION})

    def test_a_destroyed_session_leaves_the_cache(self) -> None:
        view, cwds = two_pane_view()
        self.saver.cache[SESSION] = parsed(view, cwds)
        self.saver.handle(
            json.dumps({"type": "session_destroyed", "payload": {"session_id": SESSION}})
        )
        self.assertNotIn(SESSION, self.saver.cache)

    def test_a_resized_pane_asks_for_the_focus_to_be_read_again_and_changes_no_layout(
        self,
    ) -> None:
        self.saver.handle(block_event("size_changed", {"columns": 95, "rows": 44}))
        self.assertTrue(self.saver.focus_dirty)
        self.assertEqual(self.saver.dirty, set())

    def test_a_line_that_is_not_an_event_is_ignored(self) -> None:
        self.saver.handle("Error: interrupted")
        self.assertEqual(self.saver.dirty, set())


# ----- The session the app had in focus ---------------------------------------------------------


def app_preferences(**values: Any) -> bytes:
    """What `defaults export com.superlogical.rex -` prints: an XML plist."""
    return plistlib.dumps(values)


def focus_value(value: Any) -> bytes:
    return json.dumps(value).encode()


class ReadingTheAppsFocus(unittest.TestCase):
    def test_the_focused_session_is_read_from_the_apps_preferences(self) -> None:
        export = app_preferences(
            **{"Workspace.lastFocusedSession": focus_value({"sessionID": SESSION}), "other": 1}
        )
        self.assertEqual(saver.read_app_focus(export), Ok(saver.SessionId(SESSION)))

    def test_each_way_the_preference_can_break_is_a_named_error(self) -> None:
        cases = {
            "no key": app_preferences(other=1),
            "not data": app_preferences(**{"Workspace.lastFocusedSession": "text"}),
            "not json": app_preferences(**{"Workspace.lastFocusedSession": b"{nope"}),
            "no sessionID": app_preferences(
                **{"Workspace.lastFocusedSession": focus_value({"id": SESSION})}
            ),
            "not a session ID": app_preferences(
                **{"Workspace.lastFocusedSession": focus_value({"sessionID": "window:x"})}
            ),
            "not a plist": b"Domain com.superlogical.rex does not exist",
        }
        for name, export in cases.items():
            with self.subTest(name):
                result = saver.read_app_focus(export)
                assert isinstance(result, Err), result
                self.assertTrue(result.error)

    @settings(max_examples=300, deadline=None)
    @given(st.binary(max_size=200) | json_values.map(lambda v: focus_value(v)))
    def test_any_bytes_give_a_session_or_a_named_error_without_raising(self, raw: bytes) -> None:
        for export in (raw, app_preferences(**{"Workspace.lastFocusedSession": raw})):
            result = saver.read_app_focus(export)
            self.assertIsInstance(result, Ok | Err)


# Stands in for macOS's `defaults export <file> -` where it does not exist, such as in an Amp orb:
# it prints the plist file, which the tests write as XML, and nothing when the file is missing.
DEFAULTS_STUB = """#!/bin/sh
[ "$1" = export ] && [ "$3" = - ] && exec cat -- "$2" 2>/dev/null
exit 1
"""


class SavingTheFocus(unittest.TestCase):
    """The saver reads the app's preferences from a plist file, as `defaults export` allows."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.state = Path(self.tmp.name)
        # Only where the real command is missing, so on a Mac these tests still run Apple's defaults
        if shutil.which("defaults") is None:
            stub = self.state / "bin" / "defaults"
            stub.parent.mkdir()
            stub.write_text(DEFAULTS_STUB)
            stub.chmod(0o755)
            path = f"{stub.parent}{os.pathsep}{os.environ['PATH']}"
            self.enterContext(mock.patch.dict(os.environ, {"PATH": path}))
        self.first = app_session("first")
        self.second = app_session("second")
        self.rex = RecordedRex(
            {self.first["session_id"]: self.first, self.second["session_id"]: self.second}
        )
        self.preferences = self.state / "app.plist"
        self.saver = saver.Saver(
            self.rex,
            self.state,
            saver.Log(self.state / "saver.log"),
            app_preferences=str(self.preferences),
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def focus_on(self, session_id: str) -> None:
        value = focus_value({"sessionID": session_id})
        self.preferences.write_bytes(app_preferences(**{"Workspace.lastFocusedSession": value}))

    def latest(self) -> dict:
        return json.loads((self.state / "latest.json").read_text())

    def history(self) -> list[Path]:
        return list((self.state / "history").glob("*.json"))

    def test_the_session_the_app_shows_is_saved_with_the_layouts(self) -> None:
        self.focus_on(self.second["session_id"])
        self.saver.poll()
        self.assertEqual(self.latest()["focused_index"], 1)
        self.assertEqual(self.saver.problems, [])

    def test_switching_sessions_rewrites_the_latest_without_adding_history(self) -> None:
        self.focus_on(self.first["session_id"])
        self.saver.poll()
        before = self.history()
        self.focus_on(self.second["session_id"])
        self.saver.handle(block_event("size_changed", {"columns": 95, "rows": 44}))
        self.saver.flush()
        self.assertEqual(self.latest()["focused_index"], 1)
        self.assertEqual(self.history(), before)
        rotated = [json.loads(f.read_text()).get("focused_index") for f in self.history()]
        self.assertNotIn(0, rotated, "the snapshot before the switch must not enter history")

    def test_a_focused_session_the_server_lacks_warns_at_the_poll(self) -> None:
        self.focus_on("session:01a1759d-c604-7b62-911f-000000000000")
        self.saver.poll()
        self.assertEqual(
            self.saver.problems,
            [saver.Problem("focus_unknown", "session:01a1759d-c604-7b62-911f-000000000000")],
        )
        self.assertIsNone(self.latest()["focused_index"])

    def test_the_unknown_focus_warning_clears_once_the_app_shows_a_live_session(self) -> None:
        # After a restart, the app's preferences name the old server's session until it writes
        # the new one.
        self.focus_on("session:01a1759d-c604-7b62-911f-000000000000")
        self.saver.poll()
        self.assertTrue((self.state / "warning").exists())
        self.focus_on(self.second["session_id"])
        self.saver.poll()
        self.assertEqual(self.saver.problems, [])
        self.assertFalse((self.state / "warning").exists())
        self.assertIn("resolved: focus_unknown", (self.state / "saver.log").read_text())

    def test_an_unknown_focus_still_unknown_at_the_next_poll_stays_reported(self) -> None:
        self.focus_on("session:01a1759d-c604-7b62-911f-000000000000")
        self.saver.poll()
        self.saver.poll()
        self.assertEqual([p.kind for p in self.saver.problems], ["focus_unknown"])

    def test_a_live_focus_leaves_every_other_problem_reported(self) -> None:
        self.saver.problem("events_missed", self.first["session_id"])
        self.focus_on(self.second["session_id"])
        self.saver.poll()
        self.assertEqual(
            self.saver.problems, [saver.Problem("events_missed", self.first["session_id"])]
        )

    def test_a_problem_that_records_an_event_is_never_resolved(self) -> None:
        with self.assertRaises(AssertionError):
            self.saver.resolve("events_missed")

    def test_preferences_that_cannot_be_read_warn(self) -> None:
        self.saver.poll()
        self.assertEqual([p.kind for p in self.saver.problems], ["focus_unreadable"])


# ----- Rebuilding the focused session in the app's empty one ------------------------------------

# What `com.superlogical.terminal.process` returned on this Mac for an idle shell and a busy pane.
IDLE_SHELL = {
    "foreground": {"pid": 2306, "name": "zsh", "argv0": "-zsh", "cwd": "/Users/me"},
    "ancestors": [{"pid": 2304, "name": "login"}],
}
BUSY_PANE = {
    "foreground": {"pid": 79294, "name": "claude", "argv0": "claude", "cwd": "/Users/me"},
    "ancestors": [{"pid": 42752, "name": "zsh"}, {"pid": 42751, "name": "login"}],
}
SHELL_STARTING: dict = {}


def app_session(label: str = "polished-hollow") -> dict:
    """The session the app creates when it finds none: one tab with one shell."""
    view, _ = simulate_create(
        {"label": label, "initial_windows": [{"layout": {"block": {"flavor": SHELL_FLAVOR}}}]}
    )
    return view


class JudgingACandidate(unittest.TestCase):
    def test_one_tab_with_an_idle_shell_is_unused(self) -> None:
        view = app_session()
        self.assertEqual(
            saver.judge_candidate(view, IDLE_SHELL),
            saver.Unused(
                saver.SessionId(view["session_id"]), saver.WindowId(view["windows"][0]["window_id"])
            ),
        )

    def test_a_running_program_keeps_the_session(self) -> None:
        self.assertIsInstance(saver.judge_candidate(app_session(), BUSY_PANE), saver.InUse)

    def test_a_second_tab_keeps_the_session(self) -> None:
        view, _ = simulate_create(
            {
                "label": "two",
                "initial_windows": [
                    {"layout": {"block": {"flavor": SHELL_FLAVOR}}},
                    {"layout": {"block": {"flavor": SHELL_FLAVOR}}},
                ],
            }
        )
        self.assertIsInstance(saver.judge_candidate(view, IDLE_SHELL), saver.InUse)

    def test_a_split_keeps_the_session(self) -> None:
        view, _ = two_pane_view()
        view["windows"] = view["windows"][:1]
        self.assertIsInstance(saver.judge_candidate(view, IDLE_SHELL), saver.InUse)

    def test_a_floating_pane_keeps_the_session(self) -> None:
        view = app_session()
        view["windows"][0]["layers"].append(
            {"kind": "floating", "blocks": [{"block_id": new_id("block"), "label": "shell"}]}
        )
        self.assertIsInstance(saver.judge_candidate(view, IDLE_SHELL), saver.InUse)

    def test_a_shell_that_has_not_started_cannot_be_judged_yet(self) -> None:
        self.assertIsInstance(
            saver.judge_candidate(app_session(), SHELL_STARTING), saver.Unjudgeable
        )

    @settings(max_examples=200, deadline=None)
    @given(json_values, json_values)
    def test_any_json_gives_a_verdict_without_raising_and_is_never_unused(
        self, view: Any, process: Any
    ) -> None:
        self.assertNotIsInstance(saver.judge_candidate(view, process), saver.Unused)


def unused(n: int) -> saver.Unused:
    return saver.Unused(saver.SessionId(f"session:app{n}"), saver.WindowId(f"window:app{n}"))


verdicts = st.lists(
    st.integers(min_value=0, max_value=3).map(
        lambda n: (
            unused(n) if n % 2 == 0 else saver.InUse(saver.SessionId(f"session:busy{n}"), "busy")
        )
    ),
    max_size=3,
)


class PlanningAnAdoption(unittest.TestCase):
    @settings(max_examples=300, deadline=None)
    @given(st.lists(labels, min_size=1, max_size=5, unique=True), verdicts, st.data())
    def test_the_focused_session_is_built_into_the_first_unused_one_and_none_is_lost(
        self, names: list[str], found: list[saver.CandidateVerdict], data: st.DataObject
    ) -> None:
        sessions = tuple(named(n) for n in names)
        focused = data.draw(st.none() | st.integers(min_value=0, max_value=len(names) - 1))

        plan = saver.plan_adoption(sessions, focused, tuple(found))

        first_unused = next((v for v in found if isinstance(v, saver.Unused)), None)
        match plan:
            case saver.Adopt(
                into=into, original_window=window, target=target, position=pos, rest=rest
            ):
                assert first_unused is not None
                self.assertEqual((into, window), (first_unused.session_id, first_unused.window_id))
                self.assertEqual(target, sessions[focused if focused is not None else 0])
                self.assertEqual(sessions[pos], target)
                self.assertEqual(rest, sessions[:pos] + sessions[pos + 1 :])
            case saver.CreateEach(sessions=created):
                self.assertIsNone(first_unused)
                self.assertEqual(created, sessions)
            case _:
                self.fail(f"unexpected plan {plan!r}")


class RestoringRex(RecordedRex):
    """Answers the calls a restore makes, and records what it builds."""

    def __init__(self, views: dict[str, dict], processes: list[dict]) -> None:
        super().__init__(views)
        self.processes = processes
        self.adopted: list[tuple[str, str]] = []
        self.created: list[str] = []
        self.moves: list[dict] = []
        self.adopt_error: str | None = None

    def call(self, method: str, args: Any = None) -> Any:
        match method:
            case "com.superlogical.terminal.process":
                return self.processes.pop(0) if len(self.processes) > 1 else self.processes[0]
        return super().call(method, args)

    def move(self, session_id: str, before: str | None) -> None:
        self.moves.append({"session_id": session_id, "before": before})

    def adopt(self, adopt: saver.Adopt, scratch: Path) -> str:
        if self.adopt_error is not None:
            raise saver.RexError(self.adopt_error)
        self.adopted.append((adopt.into, adopt.target.label))
        return adopt.into

    def restore(self, request: saver.RestoreRequest, scratch: Path) -> str:
        self.created.append(request.create["label"])
        session_id = new_id("session")
        return session_id


class AdoptingTheAppsSession(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.state = Path(self.tmp.name)
        snap = snapshot_of(named("work"), named("notes"), focused_index=1)
        (self.state / "latest.json").write_text(saver.snapshot_json(snap))
        self.app = app_session()
        self.clock = Clock()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def restore(self, processes: list[dict]) -> tuple[saver.Saver, RestoringRex]:
        rex = RestoringRex({self.app["session_id"]: self.app}, processes)

        def sleep(seconds: float) -> None:
            self.clock.now += seconds

        restorer = saver.Saver(
            rex, self.state, saver.Log(self.state / "saver.log"), clock=self.clock, sleep=sleep
        )
        restorer.instance_id = saver.InstanceId("instance-2")
        restorer.restore_once()
        return restorer, rex

    def test_the_focused_session_is_built_into_the_apps_session(self) -> None:
        restorer, rex = self.restore([IDLE_SHELL])
        self.assertEqual(rex.adopted, [(self.app["session_id"], "notes")])
        self.assertEqual(rex.created, ["work"])
        self.assertEqual(restorer.problems, [])

    def test_a_shell_still_starting_is_checked_again_and_then_used(self) -> None:
        _, rex = self.restore([SHELL_STARTING, SHELL_STARTING, IDLE_SHELL])
        self.assertEqual(rex.adopted, [(self.app["session_id"], "notes")])
        self.assertEqual(rex.created, ["work"])

    def test_a_shell_that_never_starts_leaves_the_apps_session_alone(self) -> None:
        restorer, rex = self.restore([SHELL_STARTING])
        self.assertEqual(rex.adopted, [])
        self.assertEqual(rex.created, ["work", "notes"])
        self.assertLessEqual(self.clock.now - 1000.0, saver.CANDIDATE_WAIT + 1)

    def test_a_busy_session_is_left_alone_and_everything_is_created(self) -> None:
        _, rex = self.restore([BUSY_PANE])
        self.assertEqual(rex.adopted, [])
        self.assertEqual(rex.created, ["work", "notes"])

    def test_a_failed_adoption_creates_the_session_instead_and_warns(self) -> None:
        rex = RestoringRex({self.app["session_id"]: self.app}, [IDLE_SHELL])
        rex.adopt_error = "boom"
        restorer = saver.Saver(
            rex,
            self.state,
            saver.Log(self.state / "saver.log"),
            clock=self.clock,
            sleep=lambda s: None,
        )
        restorer.instance_id = saver.InstanceId("instance-2")
        restorer.restore_once()
        self.assertEqual(sorted(rex.created), ["notes", "work"])
        self.assertEqual(restorer.problems, [saver.Problem("adopt_failed", "notes")])

    def test_the_adopted_session_is_moved_to_its_saved_place(self) -> None:
        _, rex = self.restore([IDLE_SHELL])
        self.assertEqual(len(rex.moves), 1)
        self.assertEqual(rex.moves[0]["session_id"], self.app["session_id"])

    def test_the_log_says_what_was_judged_and_chosen(self) -> None:
        self.restore([IDLE_SHELL])
        log = (self.state / "saver.log").read_text()
        self.assertIn("unused", log)
        self.assertIn("notes", log)


class CheckingTheMethodsAdoptionNeeds(unittest.TestCase):
    def test_every_method_adoption_calls_is_checked_at_startup(self) -> None:
        for method in (
            "session.new_window",
            "session.close_window",
            "session.set_label",
            "session.move",
        ):
            with self.subTest(method):
                self.assertIn(method, saver.REQUIRED_METHODS)


# ----- One saver at a time ----------------------------------------------------------------------

HOLD_LOCK = """
import sys, time
sys.path.insert(0, sys.argv[1])
import saver
from pathlib import Path
lock = saver.acquire_lock(Path(sys.argv[2]), timeout=0.0)
print("held" if lock else "busy", flush=True)
time.sleep(float(sys.argv[3]))
"""


class OneSaverAtATime(unittest.TestCase):
    def test_a_second_saver_cannot_take_the_lock_while_the_first_holds_it(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            lock_path = Path(tmp) / "saver.lock"
            first = subprocess.Popen(
                [sys.executable, "-c", HOLD_LOCK, str(REX_DIR), str(lock_path), "3"],
                stdout=subprocess.PIPE,
                text=True,
            )
            try:
                assert first.stdout is not None
                self.assertEqual(first.stdout.readline().strip(), "held")
                self.assertIsNone(saver.acquire_lock(lock_path, timeout=0.0))
            finally:
                first.kill()
                first.wait()
                if first.stdout is not None:
                    first.stdout.close()

    def test_a_waiting_saver_takes_the_lock_once_the_first_exits(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            lock_path = Path(tmp) / "saver.lock"
            first = subprocess.Popen(
                [sys.executable, "-c", HOLD_LOCK, str(REX_DIR), str(lock_path), "1"],
                stdout=subprocess.PIPE,
                text=True,
            )
            assert first.stdout is not None
            self.assertEqual(first.stdout.readline().strip(), "held")
            started = time.monotonic()
            lock = saver.acquire_lock(lock_path, timeout=10.0)
            first.wait()
            first.stdout.close()
            self.assertIsNotNone(lock)
            self.assertLess(time.monotonic() - started, 10)
            if lock is not None:
                lock.close()


# ----- The warning in Rex panes -----------------------------------------------------------------


def run_zsh(script: str, state_dir: Path, *, in_rex: bool = True) -> str:
    env = {
        "HOME": os.environ["HOME"],
        "PATH": "/usr/bin:/bin",
        "REX_RESTORE_STATE_DIR": str(state_dir),
        "TERM": "xterm",
    }
    if in_rex:
        env["REX_BLOCK"] = "block:test"
    return subprocess.run(
        ["/bin/zsh", "-fc", f"source {SHELL_ZSH}; {script}"],
        env=env,
        capture_output=True,
        text=True,
        check=True,
        cwd=state_dir,
    ).stdout


def warnings_from(script: str, state_dir: Path) -> str:
    """What the zsh check prints, without the OSC 7 sequences that report the directory."""
    return OSC7.sub("", run_zsh(script, state_dir))


class WarningInRexPanes(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.state = Path(self.tmp.name)
        self.status = self.state / "status.json"
        self.status.write_text("{}")
        self.log = self.state / "saver.log"
        self.log.write_text("")

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_a_fresh_heartbeat_with_no_problems_prints_nothing(self) -> None:
        self.assertEqual(warnings_from("_rex_restore_check", self.state), "")

    def test_a_stale_heartbeat_warns(self) -> None:
        old = time.time() - 300
        os.utime(self.status, (old, old))
        self.assertIn("not running", warnings_from("_rex_restore_check", self.state))

    def test_a_missing_status_file_warns(self) -> None:
        self.status.unlink()
        out = warnings_from("_rex_restore_check", self.state)
        self.assertIn("not running", out)
        self.assertIn("saver.log", out)

    def test_a_stale_heartbeat_points_to_the_log(self) -> None:
        old = time.time() - 300
        os.utime(self.status, (old, old))
        self.assertIn("saver.log", warnings_from("_rex_restore_check", self.state))

    def test_a_saver_that_never_started_says_how_to_start_it(self) -> None:
        self.status.unlink()
        self.log.unlink()
        out = warnings_from("_rex_restore_check", self.state)
        self.assertIn("never started", out)
        self.assertIn("rex config reload", out)

    def test_a_saver_that_never_started_does_not_point_to_a_missing_log(self) -> None:
        self.status.unlink()
        self.log.unlink()
        self.assertNotIn("saver.log", warnings_from("_rex_restore_check", self.state))

    def test_a_running_saver_without_a_log_prints_nothing(self) -> None:
        self.log.unlink()
        self.assertEqual(warnings_from("_rex_restore_check", self.state), "")

    def test_the_never_started_warning_is_printed_once(self) -> None:
        self.status.unlink()
        self.log.unlink()
        out = warnings_from("_rex_restore_check; _rex_restore_check", self.state)
        self.assertEqual(out.count("never started"), 1)

    def test_a_listed_problem_warns_with_its_text(self) -> None:
        (self.state / "warning").write_text("1 session failed to restore: work\n")
        out = warnings_from("_rex_restore_check", self.state)
        self.assertIn("1 session failed to restore: work", out)
        self.assertIn("saver.log", out)

    def test_the_same_warning_is_printed_once_until_it_changes(self) -> None:
        self.status.unlink()
        out = warnings_from("_rex_restore_check; _rex_restore_check", self.state)
        self.assertEqual(out.count("not running"), 1)

    def test_outside_rex_nothing_is_checked(self) -> None:
        self.status.unlink()
        self.assertEqual(
            run_zsh("whence _rex_restore_check || true", self.state, in_rex=False).strip(), ""
        )

    def test_the_directory_reported_on_cd_decodes_back_to_the_directory(self) -> None:
        odd = self.state / "a b%é"
        odd.mkdir()
        out = run_zsh(f"cd {shlex.quote(str(odd))}", self.state)
        url = out.split("\x1b]7;")[-1].split("\x1b\\")[0]
        self.assertEqual(saver.decode_osc7(url), str(odd))


if __name__ == "__main__":
    unittest.main()
