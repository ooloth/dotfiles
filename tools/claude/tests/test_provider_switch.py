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
        state = PS.State(usage={"five_hour": seen(5, 1.0), "seven_day": seen(50, 2.0)})
        after = PS.after_tick(state, NOW, {"five_hour": seen(10, 3.0)})
        self.assertEqual(
            dict(after.usage), {"five_hour": seen(10, 3.0), "seven_day": seen(50, 2.0)}
        )


def seen(used: float, resets_at: float | None):
    return PS.UsageSeen(used, resets_at)


class WhenSessionsMoveToVertex(unittest.TestCase):
    @given(
        five=st.floats(min_value=0, max_value=150),
        seven=st.floats(min_value=0, max_value=150),
        five_left=st.floats(min_value=1, max_value=5 * 3600),
        seven_left=st.floats(min_value=1, max_value=7 * 24 * 3600),
    )
    def test_to_vertex_exactly_when_a_window_is_used_up_until_the_latest_reset(
        self, five: float, seven: float, five_left: float, seven_left: float
    ) -> None:
        windows = {
            "five_hour": seen(five, NOW + five_left),
            "seven_day": seen(seven, NOW + seven_left),
        }
        after = PS.after_tick(PS.State(), NOW, windows)
        used_up = [NOW + five_left] * (five >= 100) + [NOW + seven_left] * (seven >= 100)
        if used_up:
            self.assertEqual(after.switch, PS.OnVertex(NOW, max(used_up), PS.Reason.USAGE_LIMIT))
        else:
            self.assertEqual(after.switch, PS.OnSubscription())

    def test_a_used_up_window_with_no_reset_time_lasts_its_full_length(self) -> None:
        after = PS.after_tick(PS.State(), NOW, {"five_hour": seen(100, None)})
        self.assertEqual(after.switch.until, NOW + 5 * 3600)

    def test_a_window_whose_reset_has_passed_moves_nothing(self) -> None:
        # The payload can still say 100% for a moment after the reset that moved sessions back
        after = PS.after_tick(PS.State(), NOW, {"five_hour": seen(100, NOW)})
        self.assertEqual(after.switch, PS.OnSubscription())


class WhileOnVertex(unittest.TestCase):
    """A stay on Vertex AI lasts as long as a used-up window the status line reports, so sessions
    never move back while it is still used up, whatever set the stay's end."""

    @given(
        until_left=st.floats(min_value=-3600, max_value=7 * 24 * 3600),
        used=st.floats(min_value=0, max_value=150),
        reset_left=st.one_of(st.none(), st.floats(min_value=-3600, max_value=8 * 24 * 3600)),
        reason=st.sampled_from(list(PS.Reason)),
    )
    def test_a_stay_lasts_until_its_end_or_a_later_reset_of_a_used_up_window(
        self, until_left: float, used: float, reset_left: float | None, reason
    ) -> None:
        since = NOW - 7200
        on_vertex = PS.OnVertex(since, NOW + until_left, reason)
        resets_at = None if reset_left is None else NOW + reset_left

        after = PS.after_tick(PS.State(on_vertex), NOW, {"five_hour": seen(used, resets_at)})

        extends = (
            used >= 100
            and resets_at is not None
            and resets_at > NOW
            and resets_at > on_vertex.until
        )
        if extends:
            self.assertEqual(after.switch, PS.OnVertex(since, resets_at, reason))
        elif on_vertex.until > NOW:
            self.assertEqual(after.switch, on_vertex)
        else:
            # An ended stay is the subscription, which the usual rule may move straight back
            from_subscription = PS.after_tick(PS.State(), NOW, {"five_hour": seen(used, resets_at)})
            self.assertEqual(after.switch, from_subscription.switch)

    def test_a_used_up_window_with_no_reset_time_leaves_the_stay_alone(self) -> None:
        # Its end would move with every tick, so the stay would never end
        on_vertex = PS.OnVertex(NOW - 60, NOW + 60, PS.Reason.MANUAL)
        after = PS.after_tick(PS.State(on_vertex), NOW, {"five_hour": seen(100, None)})
        self.assertEqual(after.switch, on_vertex)


class HoldOnTheSubscription(unittest.TestCase):
    """Moving sessions back by hand while a window is used up keeps them on the subscription until
    it resets, for someone who would rather wait than pay for Vertex AI."""

    @given(
        five=st.floats(min_value=0, max_value=150),
        five_left=st.floats(min_value=-3600, max_value=5 * 3600),
        seven=st.floats(min_value=0, max_value=150),
        seven_left=st.floats(min_value=-3600, max_value=7 * 24 * 3600),
    )
    def test_the_hold_lasts_until_the_latest_used_up_window_resets(
        self, five: float, five_left: float, seven: float, seven_left: float
    ) -> None:
        usage = {
            "five_hour": seen(five, NOW + five_left),
            "seven_day": seen(seven, NOW + seven_left),
        }
        held = PS.choose_subscription(
            PS.State(PS.OnVertex(NOW - 1, NOW + 1, PS.Reason.MANUAL), usage), NOW
        )
        used_up = [
            NOW + left
            for used, left in ((five, five_left), (seven, seven_left))
            if used >= 100 and NOW + left > NOW
        ]
        self.assertEqual(held.switch, PS.OnSubscription(max(used_up) if used_up else None))

    @given(at=st.floats(min_value=0, max_value=2 * 3600))
    def test_no_trigger_moves_sessions_until_the_hold_ends(self, at: float) -> None:
        held_until = NOW + 3600
        state = PS.State(PS.OnSubscription(held_until))
        used_up = {"five_hour": seen(100, NOW + 3 * 3600)}

        by_status_line = PS.after_tick(state, NOW + at, used_up).switch
        failure = PS.KnownLimit("five_hour")
        by_limit_failure = PS.after_limit_failure(state, NOW + at, failure).switch

        if NOW + at < held_until:
            self.assertEqual(by_status_line, PS.OnSubscription(held_until))
            self.assertEqual(by_limit_failure, PS.OnSubscription(held_until))
        else:
            self.assertIsInstance(by_status_line, PS.OnVertex)
            self.assertIsInstance(by_limit_failure, PS.OnVertex)

    def test_moving_to_vertex_by_hand_ends_the_hold(self) -> None:
        state = PS.State(PS.OnSubscription(NOW + 3600))
        self.assertIsInstance(PS.choose_vertex(state, NOW).switch, PS.OnVertex)

    def test_a_hold_survives_the_state_file(self) -> None:
        state = PS.State(PS.OnSubscription(NOW + 3600), {"five_hour": seen(100, NOW + 3600)})
        self.assertEqual(PS.parse_state(PS.dump_state(state)), state)


# Every error type Claude Code's hook reference lists for StopFailure besides rate_limit
# See: https://code.claude.com/docs/en/hooks#stopfailure-input
OTHER_ERRORS = [
    "authentication_failed",
    "oauth_org_not_allowed",
    "account_on_hold",
    "billing_error",
    "invalid_request",
    "model_not_found",
    "server_error",
    "max_output_tokens",
    "cloud_credential_error",
    "unknown",
]
# How much of a failure's wording the state file keeps
MESSAGE_CAP = 200
KNOWN_WORDINGS = ["session limit", "5-hour limit", "weekly limit"]


def unknown_wording(text: str) -> bool:
    lowered = text.replace("\u2019", "'").lower()
    return not any(wording in lowered for wording in KNOWN_WORDINGS)


# The error_details value in the StopFailure input example of Claude Code's hooks reference, which
# calls the field optional. See: https://code.claude.com/docs/en/hooks
DETAILS = "429 Too Many Requests"


def limit_payload(error: str, message: str, details: str | None = DETAILS) -> dict[str, str]:
    payload = {"hook_event_name": "StopFailure", "error": error, "last_assistant_message": message}
    return payload if details is None else {**payload, "error_details": details}


class LimitFailures(unittest.TestCase):
    """Any turn that ends on a rate limit is a limit failure. Its wording only names the window."""

    def test_each_known_wording_names_its_window(self) -> None:
        for message, window in (
            ("You've hit your session limit · resets 3pm", "five_hour"),
            ("You've hit your 5-hour limit · resets 11:50am (America/Toronto)", "five_hour"),
            ("You\u2019ve hit your 5-hour limit · resets 11:50am", "five_hour"),
            ("You've hit your weekly limit · resets Mon 8am", "seven_day"),
        ):
            with self.subTest(message=message):
                failure = PS.parse_limit_failure(limit_payload("rate_limit", message))
                self.assertEqual(failure, PS.KnownLimit(window))

    def test_a_known_wording_in_error_details_alone_names_its_window(self) -> None:
        payload = limit_payload("rate_limit", "", details="You've hit your weekly limit")

        self.assertEqual(PS.parse_limit_failure(payload), PS.KnownLimit("seven_day"))

    # Half the cases run past the cap, which plain generated text almost never does
    @given(
        message=st.one_of(
            st.text(max_size=MESSAGE_CAP), st.text(min_size=MESSAGE_CAP - 10, max_size=1000)
        ).filter(unknown_wording),
        details=st.sampled_from([DETAILS, None]),
    )
    def test_a_rate_limit_in_any_other_wording_is_a_limit_failure_with_no_window(
        self, message: str, details: str | None
    ) -> None:
        failure = PS.parse_limit_failure(limit_payload("rate_limit", message, details))
        expected = " ".join(part for part in (message, details) if part)
        self.assertEqual(failure, PS.UnknownLimit(expected[:MESSAGE_CAP]))

    def test_no_other_error_is_a_limit_failure_whatever_its_wording(self) -> None:
        for error in OTHER_ERRORS:
            for message in ("You've hit your 5-hour limit · resets 3pm", "Request rejected (429)"):
                with self.subTest(error=error, message=message):
                    self.assertIsNone(PS.parse_limit_failure(limit_payload(error, message)))


class WhenALimitFailureMovesSessions(unittest.TestCase):
    @given(
        five=st.floats(min_value=0, max_value=150),
        five_left=st.floats(min_value=-3600, max_value=5 * 3600),
        seven=st.floats(min_value=0, max_value=150),
        seven_left=st.floats(min_value=-3600, max_value=7 * 24 * 3600),
    )
    def test_unknown_wording_lasts_until_the_latest_used_up_reset_or_thirty_minutes(
        self, five: float, five_left: float, seven: float, seven_left: float
    ) -> None:
        usage = {
            "five_hour": seen(five, NOW + five_left),
            "seven_day": seen(seven, NOW + seven_left),
        }
        failure = PS.UnknownLimit("Request rejected (429)")

        after = PS.after_limit_failure(PS.State(usage=usage), NOW, failure)

        used_up = [
            NOW + left
            for used, left in ((five, five_left), (seven, seven_left))
            if used >= 100 and NOW + left > NOW
        ]
        until = max(used_up) if used_up else NOW + 30 * 60
        self.assertEqual(after.switch, PS.OnVertex(NOW, until, PS.Reason.UNRECOGNISED_WORDING))
        self.assertEqual(after.unknown_wording, PS.UnknownWording(NOW, "Request rejected (429)"))

    @given(reset_left=st.one_of(st.none(), st.floats(min_value=-3600, max_value=5 * 3600)))
    def test_a_known_wording_lasts_until_its_window_resets_or_its_full_length(
        self, reset_left: float | None
    ) -> None:
        resets_at = None if reset_left is None else NOW + reset_left
        state = PS.State(usage={"five_hour": seen(40, resets_at)})
        failure = PS.KnownLimit("five_hour")

        after = PS.after_limit_failure(state, NOW, failure)

        until = resets_at if resets_at is not None and resets_at > NOW else NOW + 5 * 3600
        self.assertEqual(after.switch, PS.OnVertex(NOW, until, PS.Reason.LIMIT_ERROR))

    def test_a_known_wording_leaves_the_unknown_wording_seen_before(self) -> None:
        earlier = PS.UnknownWording(NOW - 3600, "Request rejected (429)")
        failure = PS.KnownLimit("five_hour")
        after = PS.after_limit_failure(PS.State(unknown_wording=earlier), NOW, failure)
        self.assertEqual(after.unknown_wording, earlier)

    def test_sessions_already_on_vertex_keep_their_time_and_the_wording_is_kept(self) -> None:
        on_vertex = PS.OnVertex(NOW - 60, NOW + 60, PS.Reason.MANUAL)
        failure = PS.UnknownLimit("Request rejected (429)")
        after = PS.after_limit_failure(PS.State(on_vertex), NOW, failure)
        self.assertEqual(after.switch, on_vertex)
        self.assertEqual(after.unknown_wording, PS.UnknownWording(NOW, "Request rejected (429)"))

    def test_held_sessions_stay_held_and_the_wording_is_kept(self) -> None:
        held = PS.OnSubscription(NOW + 3600)
        failure = PS.UnknownLimit("Request rejected (429)")
        after = PS.after_limit_failure(PS.State(held), NOW, failure)
        self.assertEqual(after.switch, held)
        self.assertEqual(after.unknown_wording, PS.UnknownWording(NOW, "Request rejected (429)"))


switches = st.one_of(
    st.builds(PS.OnSubscription, st.one_of(st.none(), times)),
    st.builds(
        lambda since, length, reason: PS.OnVertex(since, since + length, reason),
        times,
        st.floats(min_value=1, max_value=8 * 24 * 3600),
        st.sampled_from(list(PS.Reason)),
    ),
)
unknown_wordings = st.one_of(
    st.none(), st.builds(PS.UnknownWording, times, st.text(max_size=MESSAGE_CAP))
)


class UnknownWordingKept(unittest.TestCase):
    """Rate-limit wording the switch doesn't know stays readable in cc-switch after the stay it
    caused, until newer unknown wording replaces it or LIMIT_MESSAGES gains it."""

    @given(switch=switches, wording=unknown_wordings, now=times)
    def test_no_tick_or_choice_drops_it(self, switch, wording, now: float) -> None:
        state = PS.State(switch, unknown_wording=wording)
        for after in (
            PS.after_tick(state, now, {"five_hour": seen(100, now + 60)}),
            PS.after_tick(state, now, {}),
            PS.choose_vertex(state, now),
            PS.choose_subscription(state, now),
        ):
            self.assertEqual(after.unknown_wording, wording)

    @given(switch=switches, wording=unknown_wordings)
    def test_it_survives_the_state_file(self, switch, wording) -> None:
        state = PS.State(switch, unknown_wording=wording)
        self.assertEqual(PS.parse_state(PS.dump_state(state)), state)

    def test_a_malformed_one_reads_as_none_and_keeps_the_rest(self) -> None:
        state = PS.State(PS.OnVertex(NOW, NOW + 60, PS.Reason.MANUAL))
        for bad in ("text", {"at": "soon"}, {"message": "x"}, [1, 2]):
            with self.subTest(bad=bad):
                data = json.loads(PS.dump_state(state))
                data["unknown_wording"] = bad
                self.assertEqual(PS.parse_state(json.dumps(data)), state)

    def test_a_hand_edited_wording_longer_than_the_cap_is_cut_to_it(self) -> None:
        state = PS.State(unknown_wording=PS.UnknownWording(NOW, "x"))
        data = json.loads(PS.dump_state(state))
        data["unknown_wording"]["message"] = "x" * 5000
        wording = PS.parse_state(json.dumps(data)).unknown_wording
        self.assertEqual(wording, PS.UnknownWording(NOW, "x" * MESSAGE_CAP))

    def test_a_stay_with_its_wording_beside_the_reason_reads_and_drops_the_wording(self) -> None:
        # As some state files on disk hold it. parse_state ignores the extra key
        text = json.dumps(
            {
                "provider": "vertex",
                "since": NOW,
                "until": NOW + 60,
                "reason": "a turn failed on a rate limit in wording the switch doesn't know",
                "message": "Request rejected (429)",
                "usage": {},
            }
        )
        expected = PS.OnVertex(NOW, NOW + 60, PS.Reason.UNRECOGNISED_WORDING)
        self.assertEqual(PS.parse_state(text).switch, expected)

    def test_cc_switch_still_names_it_after_the_stay_ends(self) -> None:
        message = "API Error: Request rejected (429)"
        stay = PS.after_limit_failure(PS.State(), NOW, PS.UnknownLimit(message))
        ended = PS.after_tick(stay, NOW + 3600, {})

        self.assertEqual(ended.switch, PS.OnSubscription())
        self.assertIn(f'"{message}"', PS.describe(ended, NOW + 3600))

    def test_cc_switch_stops_naming_it_once_limit_messages_knows_it(self) -> None:
        wording = PS.UnknownWording(NOW, "You've hit your 5-hour limit · resets 3pm")
        self.assertNotIn("resets 3pm", PS.describe(PS.State(unknown_wording=wording), NOW))

    def test_a_wording_seen_days_ago_names_its_day(self) -> None:
        self.assertRegex(PS.clock(NOW - 3 * 24 * 3600, NOW), r"^(Mon|Tue|Wed|Thu|Fri|Sat|Sun) ")


class StateFile(unittest.TestCase):
    def test_each_reason_reads_back_from_the_text_the_state_file_stores(self) -> None:
        # The stored text, written out, so rewording a Reason fails here rather than silently
        # turning saved stays into the subscription
        for stored, reason in (
            ("chosen with cc-switch", PS.Reason.MANUAL),
            ("the status line saw a usage limit reached", PS.Reason.USAGE_LIMIT),
            ("a turn failed on a usage limit", PS.Reason.LIMIT_ERROR),
            (
                "a turn failed on a rate limit in wording the switch doesn't know",
                PS.Reason.UNRECOGNISED_WORDING,
            ),
        ):
            with self.subTest(reason=reason.name):
                text = json.dumps(
                    {
                        "provider": "vertex",
                        "since": NOW,
                        "until": NOW + 60,
                        "reason": stored,
                        "usage": {},
                    }
                )
                expected = PS.OnVertex(NOW, NOW + 60, reason)
                self.assertEqual(PS.parse_state(text).switch, expected)


class StopFailureHook(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.home = Home(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def run_hook(
        self,
        message: str,
        error: str = "rate_limit",
        env: dict[str, str] = ENV,
        details: str | None = DETAILS,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--stop-failure"],
            input=json.dumps(limit_payload(error, message, details)),
            env={"HOME": str(self.home.home), "PATH": "/usr/bin:/bin", **env},
            capture_output=True,
            text=True,
            check=False,
        )

    def test_the_5_hour_wording_moves_sessions_until_the_recorded_reset(self) -> None:
        resets = 4_000_000_000.0
        self.home.paths.state.parent.mkdir(parents=True)
        self.home.paths.state.write_text(
            PS.dump_state(PS.State(usage={"five_hour": seen(40, resets)}))
        )

        # The text Claude Code showed when the 5-hour limit was hit on 2026-11-18
        result = self.run_hook("You've hit your 5-hour limit · resets 11:50am (America/Toronto)")

        self.assertEqual(result.returncode, 0, result.stderr)
        switch = self.home.saved_state().switch
        self.assertEqual((switch.until, switch.reason), (resets, PS.Reason.LIMIT_ERROR))
        self.assertEqual(self.home.switch(), "1")

    def test_unknown_wording_moves_sessions_for_thirty_minutes_and_keeps_the_wording(self) -> None:
        message = "API Error: Request rejected (429) · Too Many Requests"

        result = self.run_hook(message)

        self.assertEqual(result.returncode, 0, result.stderr)
        saved = self.home.saved_state()
        self.assertEqual(saved.switch.until - saved.switch.since, 30 * 60)
        self.assertEqual(saved.switch.reason, PS.Reason.UNRECOGNISED_WORDING)
        assert saved.unknown_wording is not None
        self.assertEqual(saved.unknown_wording.message, f"{message} {DETAILS}")
        self.assertEqual(self.home.switch(), "1")

    def test_a_failure_with_no_error_details_keeps_the_message_alone(self) -> None:
        message = "API Error: Request rejected (429) · Too Many Requests"

        result = self.run_hook(message, details=None)

        self.assertEqual(result.returncode, 0, result.stderr)
        saved = self.home.saved_state()
        assert saved.unknown_wording is not None
        self.assertEqual(saved.unknown_wording.message, message)
        self.assertEqual(self.home.switch(), "1")

    def test_a_session_already_on_vertex_moves_nothing_and_records_nothing(self) -> None:
        # A cc-vertex session's own 429 would otherwise put every session on the throttled project
        result = self.run_hook(
            "API Error: Request rejected (429)", env={**ENV, "CLAUDE_CODE_USE_VERTEX": "1"}
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.home.switch(), "")
        self.assertFalse(self.home.paths.state.exists())

    def test_another_failure_moves_nothing(self) -> None:
        result = self.run_hook("You've hit your 5-hour limit", error="server_error")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.home.switch(), "")

    def test_without_a_vertex_project_nothing_moves(self) -> None:
        result = self.run_hook("You've hit your 5-hour limit", env={})

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.home.switch(), "")


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
        self.home.paths.state.write_text(
            PS.dump_state(PS.State(usage={"five_hour": seen(40, resets)}))
        )

        self.assertEqual(self.run_command("vertex"), 0)
        self.assertEqual(self.home.saved_state().switch, PS.OnVertex(NOW, resets, PS.Reason.MANUAL))
        self.assertEqual(self.home.switch(), "1")

    def test_vertex_lasts_five_hours_when_no_reset_is_ahead(self) -> None:
        for state in (PS.State(), PS.State(usage={"five_hour": seen(40, NOW - 60)})):
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

    def test_a_settings_file_that_cannot_take_the_switch_is_reported(self) -> None:
        # The state would say Vertex AI while sessions stay on the subscription
        self.home.target.write_text('{"env": ')

        self.assertEqual(self.run_command("vertex"), 1)
        with self.assertRaises(PS.NotWritten):
            PS.tick(NOW, {}, self.home.paths, ENV)

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
        # Many cc-switch runs can write at the same moment
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
