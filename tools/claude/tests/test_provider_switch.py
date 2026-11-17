#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/claude/provider_switch.py, which moves every Claude Code session on the work
laptop between the subscription and Vertex AI.

Run with: uv run tools/claude/tests/test_provider_switch.py

The rules for when sessions move are pure functions, tested with generated times. The file writes
run against a temporary HOME whose ~/.claude/settings.json is a symlink into a separate folder, as
it is into this repo on a real machine.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import ModuleType

from hypothesis import given, settings
from hypothesis import strategies as st

SCRIPT = Path(__file__).resolve().parent.parent / "provider_switch.py"
SETTINGS = Path(__file__).resolve().parent.parent / "config" / "settings.json"
ENV = {"ANTHROPIC_VERTEX_PROJECT_ID": "example-vertex-1234"}
NOW = 1_800_000_000.0


def load_script() -> ModuleType:
    spec = importlib.util.spec_from_file_location("provider_switch", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["provider_switch"] = module  # dataclasses look their module up here
    spec.loader.exec_module(module)
    return module


PS = load_script()

times = st.floats(min_value=0, max_value=4_000_000_000, allow_nan=False)


class Home:
    """A temporary HOME holding a copy of the real settings file behind a symlink."""

    def __init__(self, root: Path) -> None:
        self.home = root / "home"
        (self.home / ".claude").mkdir(parents=True)
        self.target = root / "repo" / "settings.json"
        self.target.parent.mkdir()
        self.target.write_text(SETTINGS.read_text())
        self.write_switch("")
        (self.home / ".claude" / "settings.json").symlink_to(self.target)
        self.paths = PS.Paths.under(self.home)

    def write_switch(self, value: str) -> None:
        data = json.loads(self.target.read_text())
        data["env"]["CLAUDE_CODE_USE_VERTEX"] = value
        self.target.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")

    def switch(self) -> str:
        return json.loads(self.target.read_text())["env"]["CLAUDE_CODE_USE_VERTEX"]

    def saved_state(self):
        return PS.parse_state(self.paths.state.read_text())


class WhenSessionsMoveBack(unittest.TestCase):
    @given(since=times, length=st.floats(min_value=1, max_value=8 * 24 * 3600), now=times)
    def test_back_on_the_subscription_exactly_when_the_vertex_time_is_up(
        self, since: float, length: float, now: float
    ) -> None:
        on_vertex = PS.OnVertex(since, since + length, PS.Reason.MANUAL)
        after = PS.after_tick(PS.State(on_vertex), now, {})
        if now >= since + length:
            self.assertEqual(after.switch, PS.OnSubscription())
        else:
            self.assertEqual(after.switch, on_vertex)

    @given(now=times)
    def test_the_subscription_stays_the_subscription(self, now: float) -> None:
        self.assertEqual(PS.after_tick(PS.State(), now, {}).switch, PS.OnSubscription())

    def test_the_latest_reset_times_are_kept(self) -> None:
        state = PS.State(resets_at={"five_hour": 1.0, "seven_day": 2.0})
        after = PS.after_tick(state, NOW, {"five_hour": 3.0})
        self.assertEqual(dict(after.resets_at), {"five_hour": 3.0, "seven_day": 2.0})


class Command(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.home = Home(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def run_command(self, *args: str, env: dict[str, str] = ENV) -> int:
        return PS.main(list(args), self.home.paths, env, NOW)

    def test_vertex_lasts_until_the_recorded_five_hour_reset(self) -> None:
        resets = NOW + 3600
        self.home.paths.state.parent.mkdir(parents=True)
        self.home.paths.state.write_text(PS.dump_state(PS.State(resets_at={"five_hour": resets})))

        self.assertEqual(self.run_command("vertex"), 0)
        self.assertEqual(self.home.saved_state().switch, PS.OnVertex(NOW, resets, PS.Reason.MANUAL))
        self.assertEqual(self.home.switch(), "1")

    def test_vertex_lasts_five_hours_when_no_reset_is_ahead(self) -> None:
        for state in (PS.State(), PS.State(resets_at={"five_hour": NOW - 60})):
            with self.subTest(state=state):
                self.home.paths.state.parent.mkdir(parents=True, exist_ok=True)
                self.home.paths.state.write_text(PS.dump_state(state))

                self.assertEqual(self.run_command("vertex"), 0)
                self.assertEqual(self.home.saved_state().switch.until, NOW + 5 * 3600)

    def test_subscription_moves_sessions_back(self) -> None:
        self.run_command("vertex")

        self.assertEqual(self.run_command("subscription"), 0)
        self.assertEqual(self.home.saved_state().switch, PS.OnSubscription())
        self.assertEqual(self.home.switch(), "")

    def test_without_a_vertex_project_nothing_moves(self) -> None:
        before = self.home.target.read_text()

        on_vertex = PS.OnVertex(NOW, NOW + 60, PS.Reason.MANUAL)

        self.assertEqual(self.run_command("vertex", env={}), 1)
        self.assertEqual(PS.tick(NOW, {}, self.home.paths, {}), PS.OnSubscription())
        self.assertIsInstance(PS.sync_settings(self.home.paths.settings, on_vertex, {}), PS.Skipped)
        self.assertEqual(self.home.target.read_text(), before)
        self.assertFalse(self.home.paths.state.exists())


class SettingsSync(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.home = Home(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()

    @settings(deadline=None, max_examples=25)
    @given(on_vertex=st.booleans(), extra=st.dictionaries(st.text(), st.text(), max_size=5))
    def test_only_the_switch_line_changes_and_the_symlink_stays(
        self, on_vertex: bool, extra: dict[str, str]
    ) -> None:
        data = json.loads(self.home.target.read_text())
        data["extra"] = extra
        data["env"]["CLAUDE_CODE_USE_VERTEX"] = "" if on_vertex else "1"
        self.home.target.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
        before = self.home.target.read_text().splitlines()
        switch = PS.OnVertex(NOW, NOW + 60, PS.Reason.MANUAL) if on_vertex else PS.OnSubscription()

        result = PS.sync_settings(self.home.paths.settings, switch, ENV)

        after = self.home.target.read_text().splitlines()
        self.assertEqual(result, PS.Wrote("1" if on_vertex else ""))
        self.assertEqual(len(after), len(before))
        changed = [b for b, a in zip(before, after, strict=True) if b != a]
        self.assertEqual(len(changed), 1)
        self.assertIn('"CLAUDE_CODE_USE_VERTEX"', changed[0])
        self.assertTrue(self.home.paths.settings.is_symlink())

    def test_an_unreadable_settings_file_is_left_alone(self) -> None:
        self.home.target.write_text('{"env": ')
        switch = PS.OnVertex(NOW, NOW + 60, PS.Reason.MANUAL)

        self.assertIsInstance(PS.sync_settings(self.home.paths.settings, switch, ENV), PS.Skipped)
        self.assertEqual(self.home.target.read_text(), '{"env": ')

    def test_sessions_switching_at_once_leave_the_files_agreeing(self) -> None:
        # Many status lines and a cc-switch can write at the same moment
        program = (
            "import sys, time; sys.path.insert(0, sys.argv[1]); import provider_switch as p; "
            "from pathlib import Path; "
            "raise SystemExit(p.main([sys.argv[2]], p.Paths.under(Path(sys.argv[3])), "
            "{'ANTHROPIC_VERTEX_PROJECT_ID': 'x'}, time.time()))"
        )
        processes = [
            subprocess.Popen(
                [sys.executable, "-c", program, str(SCRIPT.parent), choice, str(self.home.home)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            for choice in ["vertex", "subscription"] * 10
        ]
        for process in processes:
            process.wait(timeout=30)

        state = self.home.saved_state()
        self.assertEqual(self.home.switch(), PS.switch_value(state.switch))


if __name__ == "__main__":
    unittest.main()
