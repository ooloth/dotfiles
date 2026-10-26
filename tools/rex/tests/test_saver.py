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
import re
import shlex
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from typing import Any

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


def snapshot_of(*sessions: saver.SavedSession, saved_at: str = "2026-10-25T00:00:00Z"):
    return saver.Snapshot(
        format=1,
        instance_id=saver.InstanceId("instance-1"),
        saved_at=saved_at,
        sessions=tuple(sessions),
    )


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


class WarningText(unittest.TestCase):
    def test_no_problems_means_no_warning(self) -> None:
        self.assertEqual(saver.warning_text(()), "")

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

    def test_a_line_that_is_not_an_event_is_ignored(self) -> None:
        self.saver.handle("Error: interrupted")
        self.assertEqual(self.saver.dirty, set())


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
