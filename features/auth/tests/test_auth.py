#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for features/auth/auth.py, which logs in to the work tools whose credentials have expired.

Run with: uv run features/auth/tests/test_auth.py

Most tests load the script in-process and hand `run` a FakeShell. It answers each check the way the
real tool answered when its credential was valid or expired, when the server could not be reached,
or, for argocd, when the server had revoked the refresh token, and it records each login it is
asked to run. The end-to-end tests run the script as a subprocess with stub gcloud, spacectl and
argocd commands on PATH that record their arguments. The lock tests run real processes under one
HOME, with stubs that remember a login, so one run's login is seen by another.
"""

from __future__ import annotations

import contextlib
import errno
import fcntl
import importlib.util
import io
import select
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from dataclasses import dataclass, field
from pathlib import Path
from typing import IO, Literal
from unittest import mock

from hypothesis import given
from hypothesis import strategies as st

SCRIPT = Path(__file__).resolve().parent.parent / "auth.py"
# Running as a script puts its folder on the import path, where it finds login_lock.py
sys.path.insert(0, str(SCRIPT.parent))

_spec = importlib.util.spec_from_file_location("auth", SCRIPT)
assert _spec is not None and _spec.loader is not None, f"cannot load {SCRIPT}"
auth = importlib.util.module_from_spec(_spec)
sys.modules["auth"] = auth
_spec.loader.exec_module(auth)

import login_lock  # noqa: E402  (from the folder the loader put on the path)

PROD = auth.ArgoServer("cd-prod.example.com")
DEV = auth.ArgoServer("cd-dev.example.com")
# The first is the default context, as in private.env
SERVERS = (PROD, DEV)
ACCOUNT = auth.SpaceliftAccount("example")
State = Literal["valid", "expired", "unreachable", "revoked"]

# What each tool prints in each state, shortened. The gcloud and spacectl unreachable answers, and
# the argocd ones, are what the real commands printed on this laptop, the first through a proxy that
# refuses connections. The gcloud expired answer is a message in the SDK's source, and the spacectl
# one is a message in its binary.
ANSWERS = {
    "argocd": {
        "valid": auth.CheckResult(0, '{"loggedIn": true, "username": "alice"}', ""),
        "expired": auth.CheckResult(0, "{}", ""),
        "unreachable": auth.CheckResult(
            20, "", '{"level":"fatal","msg":"dial tcp: lookup cd.example.com: no such host"}\n'
        ),
        "revoked": auth.CheckResult(
            1, "", '{"level":"fatal","msg":"oauth2: \\"invalid_grant\\""}\n'
        ),
    },
    "gcloud": {
        "valid": auth.CheckResult(0, "token", ""),
        "expired": auth.CheckResult(1, "", "Reauthentication required.\n"),
        "unreachable": auth.CheckResult(
            1,
            "",
            "ERROR: (gcloud.auth.print-access-token) HTTPSConnectionPool(host='oauth2.googleapis.com',"
            " port=443): Max retries exceeded with url: /token\n",
        ),
    },
    "spacectl": {
        "valid": auth.CheckResult(0, "alice", ""),
        "expired": auth.CheckResult(
            1, "", "2026/11/05 19:13:46 failed to query user information: unauthorized\n"
        ),
        "unreachable": auth.CheckResult(
            1,
            "",
            "2026/11/05 19:13:46 Warning: Unable to determine Spacelift instance type.\n"
            '2026/11/05 19:13:46 failed to query user information: Post "https://example.app.'
            'spacelift.io/graphql": dial tcp: connect: connection refused\n',
        ),
    },
}


@dataclass
class FakeShell:
    """Answers checks from `states`, keyed by login name, and records each login it runs."""

    items: tuple
    states: dict[str, State]
    login_works: dict[str, bool]
    missing: frozenset[str] = frozenset()
    timed_out: frozenset[str] = frozenset()
    attached: list[tuple[str, ...]] = field(default_factory=list)

    def _logins(self) -> list:
        return [item for item in self.items if isinstance(item, auth.Login)]

    def has(self, command: str) -> bool:
        return command not in self.missing

    def capture(self, command: tuple[str, ...]):
        (login,) = [item for item in self._logins() if item.check == command]
        if login.name in self.timed_out:
            return auth.TimedOut()
        return ANSWERS[command[0]][self.states[login.name]]

    def attach(self, command: tuple[str, ...]) -> int:
        self.attached.append(command)
        (login,) = [item for item in self._logins() if item.login == command]
        if self.login_works[login.name]:
            self.states[login.name] = "valid"
            return 0
        return 1


class FreeLock:
    """A login lock no other run holds, for the in-process tests."""

    def __enter__(self):
        return login_lock.HeldLoginLock()

    def __exit__(self, *_exc: object) -> None:
        return None


@dataclass
class LockAnotherRunReleasedAfterLoggingIn:
    """A login lock that another run held while it logged in to every login, so they are all
    valid by the time this run holds it."""

    shell: FakeShell

    def __enter__(self):
        for name in self.shell.states:
            self.shell.states[name] = "valid"
        return login_lock.HeldLoginLock()

    def __exit__(self, *_exc: object) -> None:
        return None


@dataclass
class SharedCredentialShell(FakeShell):
    """A login that also makes every other login to its tool valid, as one SSO session can."""

    def attach(self, command: tuple[str, ...]) -> int:
        exit_code = super().attach(command)
        (login,) = [item for item in self._logins() if item.login == command]
        for other in self._logins():
            if other.check[0] == login.check[0]:
                self.states[other.name] = self.states[login.name]
        return exit_code


@dataclass
class RecordingLock:
    """A login lock that says whether it is held."""

    held: bool = False

    def __enter__(self):
        self.held = True
        return login_lock.HeldLoginLock()

    def __exit__(self, *_exc: object) -> None:
        self.held = False


@dataclass
class LockWhoseCheckAgainSays:
    """A login lock that, once held, makes every check say `again`: one of ANSWERS' states,
    "missing" for a tool gone from PATH, or "timed out"."""

    shell: FakeShell
    again: State | Literal["missing", "timed out"]

    def __enter__(self):
        names = frozenset(self.shell.states)
        match self.again:
            case "missing":
                self.shell.missing = frozenset(TOOLS)
            case "timed out":
                self.shell.timed_out = names
            case state:
                for name in names:
                    self.shell.states[name] = state
        return login_lock.HeldLoginLock()

    def __exit__(self, *_exc: object) -> None:
        return None


def configured_logins() -> tuple:
    return auth.logins(auth.Settings(argocd_servers=SERVERS, spacelift_account=ACCOUNT))


def names(items: tuple) -> list[str]:
    return [item.name for item in items]


def tool(item) -> str:
    return item.check[0]


def ignore(_outcome) -> None:
    return None


login_state = st.sampled_from(["valid", "expired", "unreachable"])


@dataclass
class BlockingShell(FakeShell):
    """A FakeShell whose check for `blocked` waits until every other login has been reported."""

    blocked: str = ""
    others_reported: threading.Event = field(default_factory=threading.Event)

    def capture(self, command: tuple[str, ...]):
        (login,) = [item for item in self._logins() if item.check == command]
        if login.name == self.blocked and not self.others_reported.wait(timeout=5):
            return auth.TimedOut()
        return super().capture(command)


class ResultsAppearAsChecksFinish(unittest.TestCase):
    def test_a_slow_check_does_not_hold_back_the_results_of_the_others(self) -> None:
        items = configured_logins()
        argocd = items[3]
        shell = BlockingShell(
            items, dict.fromkeys(names(items), "valid"), dict.fromkeys(names(items), True)
        )
        shell.blocked = argocd.name
        reported: list = []

        def report(outcome) -> None:
            reported.append(outcome)
            if len(reported) == len(items) - 1:
                shell.others_reported.set()

        outcomes = auth.run(auth.Mode.REFRESH, items, shell, report, FreeLock())

        self.assertEqual(outcomes[3].before, auth.Valid(), "argocd's check gave up waiting")
        self.assertEqual(reported[-1].name, argocd.name)

    def test_an_expired_login_is_reported_after_its_login_runs(self) -> None:
        items = configured_logins()
        spacelift = items[2]
        states: dict[str, State] = dict.fromkeys(names(items), "valid")
        states[spacelift.name] = "expired"
        shell = FakeShell(items, states, dict.fromkeys(names(items), True))
        reported: list = []

        auth.run(auth.Mode.REFRESH, items, shell, reported.append, FreeLock())

        (spacelift_outcome,) = [o for o in reported if o.name == spacelift.name]
        self.assertEqual(spacelift_outcome.before, auth.Expired())
        self.assertEqual(spacelift_outcome.after, auth.Valid())


class OnlyExpiredLoginsRun(unittest.TestCase):
    @given(
        google_internal=login_state,
        google_external=login_state,
        spacelift=login_state,
        argocd_prod=st.sampled_from(["valid", "expired", "unreachable", "revoked"]),
        argocd_dev=st.sampled_from(["valid", "expired", "unreachable", "revoked"]),
        missing=st.frozensets(st.sampled_from(["gcloud", "spacectl", "argocd"])),
        works=st.lists(st.booleans(), min_size=5, max_size=5),
    )
    def test_logins_run_for_exactly_the_expired_ones_and_exit_follows_the_final_statuses(
        self,
        google_internal: State,
        google_external: State,
        spacelift: State,
        argocd_prod: State,
        argocd_dev: State,
        missing: frozenset[str],
        works: list[bool],
    ) -> None:
        items = configured_logins()
        states = dict(
            zip(
                names(items),
                [google_internal, google_external, spacelift, argocd_prod, argocd_dev],
                strict=True,
            )
        )
        login_works = dict(zip(names(items), works, strict=True))
        shell = FakeShell(items, dict(states), login_works, missing)
        reported: list = []

        outcomes = auth.run(auth.Mode.REFRESH, items, shell, reported.append, FreeLock())

        self.assertCountEqual(reported, outcomes)
        installed = [item for item in items if tool(item) not in missing]
        expired = [item for item in installed if states[item.name] in ("expired", "revoked")]
        self.assertEqual(shell.attached, [item.login for item in expired])
        ends_valid = len(installed) == len(items) and all(
            states[item.name] == "valid"
            or (states[item.name] in ("expired", "revoked") and login_works[item.name])
            for item in installed
        )
        self.assertEqual(auth.all_valid(outcomes), ends_valid)


class LockThatCantBeSetUp(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.lock_path = Path(self._tmp.name) / "auth" / "logins.lock"

    def test_a_file_system_that_refuses_the_lock_still_runs_every_login(self) -> None:
        items = configured_logins()
        shell = FakeShell(
            items, dict.fromkeys(names(items), "expired"), dict.fromkeys(names(items), True)
        )
        refused = OSError(errno.ENOLCK, "No locks available")
        stderr = io.StringIO()

        with (
            mock.patch.object(login_lock.fcntl, "flock", side_effect=refused),
            contextlib.redirect_stderr(stderr),
        ):
            outcomes = auth.run(
                auth.Mode.REFRESH, items, shell, ignore, login_lock.file_login_lock(self.lock_path)
            )

        self.assertIn("won't share logins", stderr.getvalue())
        self.assertIn("No locks available", stderr.getvalue())
        self.assertTrue(all(outcome.login_ran for outcome in outcomes))
        self.assertTrue(auth.all_valid(outcomes))

    def test_an_error_in_an_unshared_run_carries_no_lock_error(self) -> None:
        # A file where the lock's folder goes, so the lock can't be created
        self.lock_path.parent.write_text("")

        with (
            contextlib.redirect_stderr(io.StringIO()),
            self.assertRaises(ValueError) as raised,
            login_lock.file_login_lock(self.lock_path) as permit,
        ):
            self.assertEqual(permit, login_lock.UnsharedLogins())
            raise ValueError("a bug in a login")

        self.assertIsNone(raised.exception.__context__)


class SharedLogins(unittest.TestCase):
    def test_a_login_another_run_completed_while_this_one_waited_is_not_run_again(self) -> None:
        items = configured_logins()
        shell = FakeShell(
            items, dict.fromkeys(names(items), "expired"), dict.fromkeys(names(items), True)
        )

        outcomes = auth.run(
            auth.Mode.REFRESH, items, shell, ignore, LockAnotherRunReleasedAfterLoggingIn(shell)
        )

        self.assertEqual(shell.attached, [])
        self.assertTrue(auth.all_valid(outcomes))
        self.assertTrue(all(outcome.before == auth.Expired() for outcome in outcomes))
        self.assertFalse(any(outcome.login_ran for outcome in outcomes))

    def test_a_run_that_waited_out_another_runs_argo_cd_login_leaves_its_context_alone(
        self,
    ) -> None:
        items = configured_logins()
        settings = auth.Settings(argocd_servers=SERVERS, spacelift_account=ACCOUNT)
        shell = FakeShell(
            items, dict.fromkeys(names(items), "expired"), dict.fromkeys(names(items), True)
        )

        outcomes = auth.run(
            auth.Mode.REFRESH, items, shell, ignore, LockAnotherRunReleasedAfterLoggingIn(shell)
        )

        self.assertIsNone(auth.default_context_command(settings, outcomes))

    def test_a_login_this_run_made_valid_is_not_opened(self) -> None:
        items = configured_logins()
        shell = SharedCredentialShell(
            items, dict.fromkeys(names(items), "expired"), dict.fromkeys(names(items), True)
        )

        auth.run(auth.Mode.REFRESH, items, shell, ignore, FreeLock())

        self.assertEqual([command[0] for command in shell.attached], list(TOOLS))

    def test_the_context_reset_runs_inside_the_lock_once_the_logins_are_done(self) -> None:
        items = configured_logins()
        shell = FakeShell(
            items, dict.fromkeys(names(items), "expired"), dict.fromkeys(names(items), True)
        )
        lock = RecordingLock()
        calls: list[tuple[bool, tuple]] = []

        outcomes = auth.run(
            auth.Mode.REFRESH,
            items,
            shell,
            ignore,
            lock,
            after_logins=lambda done: calls.append((lock.held, done)),
        )

        self.assertEqual(calls, [(True, outcomes)])

    def test_with_nothing_expired_the_context_reset_never_runs(self) -> None:
        items = configured_logins()
        shell = FakeShell(
            items, dict.fromkeys(names(items), "valid"), dict.fromkeys(names(items), True)
        )
        calls: list[tuple] = []

        auth.run(auth.Mode.REFRESH, items, shell, ignore, FreeLock(), after_logins=calls.append)

        self.assertEqual(calls, [])

    def test_only_a_valid_or_missing_tool_under_the_lock_skips_a_login(self) -> None:
        # A check that can't tell runs the login: a second browser login shows, while a session
        # that starts with an expired login says nothing
        for again, logs_in in (
            ("valid", False),
            ("missing", False),
            ("expired", True),
            ("unreachable", True),
            ("timed out", True),
        ):
            with self.subTest(again=again):
                items = configured_logins()
                shell = FakeShell(
                    items, dict.fromkeys(names(items), "expired"), dict.fromkeys(names(items), True)
                )

                outcomes = auth.run(
                    auth.Mode.REFRESH, items, shell, ignore, LockWhoseCheckAgainSays(shell, again)
                )

                self.assertEqual(bool(shell.attached), logs_in)
                self.assertEqual(all(outcome.login_ran for outcome in outcomes), logs_in)


class CheckMode(unittest.TestCase):
    def test_check_runs_no_login_even_when_every_login_has_expired(self) -> None:
        items = configured_logins()
        shell = FakeShell(
            items,
            dict.fromkeys(names(items), "expired"),
            dict.fromkeys(names(items), True),
        )

        outcomes = auth.run(auth.Mode.CHECK, items, shell, ignore, FreeLock())

        self.assertEqual(shell.attached, [])
        self.assertEqual([outcome.before for outcome in outcomes], [auth.Expired()] * 5)
        self.assertFalse(auth.all_valid(outcomes))


class ArgoCdStatus(unittest.TestCase):
    def test_logged_in_user_info_is_valid(self) -> None:
        self.assertEqual(auth.read_argocd_user_info(ANSWERS["argocd"]["valid"]), auth.Valid())

    def test_empty_user_info_with_exit_zero_is_expired(self) -> None:
        self.assertEqual(auth.read_argocd_user_info(ANSWERS["argocd"]["expired"]), auth.Expired())

    def test_failed_call_is_unchecked_with_its_last_error_line(self) -> None:
        self.assertEqual(
            auth.read_argocd_user_info(ANSWERS["argocd"]["unreachable"]),
            auth.Unchecked(
                '{"level":"fatal","msg":"dial tcp: lookup cd.example.com: no such host"}'
            ),
        )

    def test_a_failure_naming_the_session_or_token_is_expired(self) -> None:
        # What argocd printed on this laptop for a revoked refresh token and an expired session
        for stderr in (
            '{"level":"fatal","msg":"oauth2: \\"invalid_grant\\" \\"Refresh token is invalid or'
            ' has already been claimed by another client.\\""}\n',
            '{"level":"fatal","msg":"rpc error: code = Unauthenticated desc = invalid session:'
            ' failed to verify the token"}\n',
        ):
            with self.subTest(stderr=stderr):
                status = auth.read_argocd_user_info(auth.CheckResult(1, "", stderr))
                self.assertEqual(status, auth.Expired())

    def test_a_revoked_token_gets_its_login_run(self) -> None:
        items = configured_logins()
        shell = FakeShell(
            items,
            dict.fromkeys(names(items), "valid"),
            dict.fromkeys(names(items), True),
        )
        shell.states[items[4].name] = "revoked"

        outcomes = auth.run(auth.Mode.REFRESH, items, shell, ignore, FreeLock())

        self.assertEqual(shell.attached, [items[4].login])
        self.assertEqual(outcomes[4].after, auth.Valid())

    def test_each_server_is_its_own_login_named_after_it(self) -> None:
        argocd = configured_logins()[3:]

        self.assertEqual(names(argocd), [f"Argo CD ({PROD})", f"Argo CD ({DEV})"])
        self.assertEqual([item.login[-1] for item in argocd], list(SERVERS))
        self.assertEqual([item.check[-1] for item in argocd], list(SERVERS))


class ArgoCdDefaultContext(unittest.TestCase):
    def outcome(self, item, after) -> object:
        return auth.Outcome(
            item.name, auth.Expired() if after else auth.Valid(), after, bool(after)
        )

    def test_an_argo_cd_login_makes_the_first_server_the_default_again(self) -> None:
        items = configured_logins()
        settings = auth.Settings(argocd_servers=SERVERS, spacelift_account=ACCOUNT)
        # Only the second server logged in, which made it argocd's current context
        outcomes = tuple(
            self.outcome(item, auth.Valid() if item is items[4] else None) for item in items
        )

        self.assertEqual(
            auth.default_context_command(settings, outcomes), ("argocd", "context", PROD)
        )

    def test_no_argo_cd_login_leaves_the_context_alone(self) -> None:
        items = configured_logins()
        settings = auth.Settings(argocd_servers=SERVERS, spacelift_account=ACCOUNT)
        # Spacelift logged in, but no Argo CD login ran
        outcomes = tuple(
            self.outcome(item, auth.Valid() if item is items[2] else None) for item in items
        )

        self.assertIsNone(auth.default_context_command(settings, outcomes))

    def test_without_servers_there_is_no_context_to_set(self) -> None:
        settings = auth.Settings(argocd_servers=(), spacelift_account=ACCOUNT)
        outcomes = (auth.Outcome(auth.LoginName("Argo CD"), auth.NotConfigured("x"), None, False),)

        self.assertIsNone(auth.default_context_command(settings, outcomes))

    def test_output_that_is_not_json_is_unchecked(self) -> None:
        status = auth.read_argocd_user_info(auth.CheckResult(0, "Logged In: false\n", ""))
        self.assertIsInstance(status, auth.Unchecked)


class GcloudAndSpacectlStatus(unittest.TestCase):
    def test_a_failure_naming_the_credentials_is_expired(self) -> None:
        # From the SDK's own messages and from runs on this laptop with no credentials
        for stderr in (
            "Reauthentication required.\n",
            "ERROR: (gcloud.auth.print-access-token) There was a problem refreshing your current auth"
            " tokens: ('invalid_grant: Token has been expired or revoked.')\n",
            "ERROR: (gcloud.auth.print-access-token) There was a problem reauthenticating while"
            " refreshing your current auth tokens: Reauthentication failed. cannot prompt during"
            " non-interactive execution.\n",
            "ERROR: (gcloud.auth.print-access-token) Your current active account [alice@example.com]"
            " does not have any valid credentials\nPlease run:\n\n  $ gcloud auth login\n",
            "ERROR: (gcloud.auth.application-default.print-access-token) Your default credentials"
            " were not found. To set up Application Default Credentials, see …\n",
        ):
            with self.subTest(stderr=stderr):
                status = auth.read_gcloud_token(auth.CheckResult(1, "", stderr))
                self.assertEqual(status, auth.Expired())

    def test_spacectl_without_a_profile_is_expired(self) -> None:
        stderr = (
            "2026/11/05 19:13:46 could not build the session from the environment"
            " (SPACELIFT_API_TOKEN not set in environment) or file (no current profile is set -"
            " please login first)\n"
        )
        status = auth.read_spacectl_whoami(auth.CheckResult(1, "", stderr))
        self.assertEqual(status, auth.Expired())

    def test_an_unreachable_server_is_unchecked_with_the_error_line(self) -> None:
        gcloud = ANSWERS["gcloud"]["unreachable"]
        spacectl = ANSWERS["spacectl"]["unreachable"]

        self.assertEqual(
            auth.read_gcloud_token(gcloud), auth.Unchecked(gcloud.stderr.splitlines()[0])
        )
        self.assertEqual(
            auth.read_spacectl_whoami(spacectl), auth.Unchecked(spacectl.stderr.splitlines()[-1])
        )

    def test_a_failure_with_no_output_is_unchecked_and_names_the_exit_code(self) -> None:
        status = auth.read_gcloud_token(auth.CheckResult(2, "", ""))
        self.assertEqual(status, auth.Unchecked("the check exited 2"))

    def test_no_login_runs_while_the_network_is_down(self) -> None:
        items = configured_logins()
        shell = FakeShell(
            items,
            dict.fromkeys(names(items), "unreachable"),
            dict.fromkeys(names(items), True),
        )

        outcomes = auth.run(auth.Mode.REFRESH, items, shell, ignore, FreeLock())

        self.assertEqual(shell.attached, [])
        for outcome in outcomes:
            self.assertIsInstance(outcome.before, auth.Unchecked)


class SubprocessShellLimits(unittest.TestCase):
    def test_a_check_slower_than_the_timeout_is_reported_as_timed_out(self) -> None:
        with mock.patch.object(auth, "CHECK_TIMEOUT_SECONDS", 0.2):
            result = auth.SubprocessShell().capture(("sleep", "5"))

        self.assertEqual(result, auth.TimedOut())


class TimedOutCheck(unittest.TestCase):
    def test_a_check_that_times_out_is_unchecked_and_its_login_does_not_run(self) -> None:
        items = configured_logins()
        spacelift = items[2]
        shell = FakeShell(
            items,
            dict.fromkeys(names(items), "valid"),
            dict.fromkeys(names(items), True),
            timed_out=frozenset({spacelift.name}),
        )

        outcomes = auth.run(auth.Mode.REFRESH, items, shell, ignore, FreeLock())

        self.assertIsInstance(outcomes[2].before, auth.Unchecked)
        self.assertEqual(shell.attached, [])


class PrivateSettings(unittest.TestCase):
    def test_unset_or_blank_values_are_not_configured(self) -> None:
        for value in (None, "", "  "):
            environ = (
                {}
                if value is None
                else {"PRIVATE_ARGOCD_SERVERS": value, "PRIVATE_SPACELIFT_ACCOUNT": value}
            )
            with self.subTest(environ=environ):
                self.assertEqual(
                    auth.read_settings(environ),
                    auth.Settings(argocd_servers=(), spacelift_account=None),
                )

    def test_set_values_are_read(self) -> None:
        settings = auth.read_settings(
            {"PRIVATE_ARGOCD_SERVERS": f" {PROD}  {DEV} ", "PRIVATE_SPACELIFT_ACCOUNT": " example "}
        )
        self.assertEqual(settings, auth.Settings(argocd_servers=SERVERS, spacelift_account=ACCOUNT))

    def test_a_server_listed_twice_is_checked_once_in_its_first_place(self) -> None:
        settings = auth.read_settings({"PRIVATE_ARGOCD_SERVERS": f"{PROD} {DEV} {PROD}"})
        self.assertEqual(settings.argocd_servers, SERVERS)

    def test_without_a_server_argocd_names_the_key_and_the_other_logins_still_run(self) -> None:
        items = auth.logins(auth.Settings(argocd_servers=(), spacelift_account=ACCOUNT))
        shell = FakeShell(
            items,
            dict.fromkeys(names(items), "expired"),
            dict.fromkeys(names(items), True),
        )

        outcomes = auth.run(auth.Mode.REFRESH, items, shell, ignore, FreeLock())

        self.assertEqual(len(outcomes), 4)
        self.assertEqual(outcomes[3].before, auth.NotConfigured("PRIVATE_ARGOCD_SERVERS"))
        self.assertIn("PRIVATE_ARGOCD_SERVERS", auth.describe(outcomes[3]))
        self.assertEqual(len(shell.attached), 3)

    def test_without_an_account_spacelift_names_the_key_and_the_other_logins_still_run(
        self,
    ) -> None:
        items = auth.logins(auth.Settings(argocd_servers=SERVERS, spacelift_account=None))
        shell = FakeShell(
            items,
            dict.fromkeys(names(items), "expired"),
            dict.fromkeys(names(items), True),
        )

        outcomes = auth.run(auth.Mode.REFRESH, items, shell, ignore, FreeLock())

        self.assertEqual(outcomes[2].before, auth.NotConfigured("PRIVATE_SPACELIFT_ACCOUNT"))
        self.assertIn("PRIVATE_SPACELIFT_ACCOUNT", auth.describe(outcomes[2]))
        self.assertEqual(len(shell.attached), 4)


STUB = """#!/bin/bash
printf '%s\\n' "${0##*/} $*" >> "${STUB_LOG}"
for arg in "$@"; do
  if [[ "${arg}" == login ]]; then
    # Ctrl-C reaches the script as well as the login, so the stub sends the script a SIGINT
    [[ -n "${STUB_LOGIN_SENDS_CTRL_C:-}" ]] && kill -INT "${PPID}" && sleep 2
    exit 0
  fi
done
case "${0##*/}" in
  argocd) echo '{}'; exit 0 ;;
  spacectl) echo 'failed to query user information: unauthorized' >&2; exit 1 ;;
  *) echo 'Reauthentication required.' >&2; exit 1 ;;
esac
"""


# Like STUB, except that a login makes its tool's checks valid, through a file under STUB_STATE, so
# a login one run completes is seen by another
STATEFUL_STUB = """#!/bin/bash
printf '%s\\n' "${0##*/} $*" >> "${STUB_LOG}"
valid="${STUB_STATE}/${0##*/}-valid"
for arg in "$@"; do
  if [[ "${arg}" == login ]]; then
    # Long enough that a run started at the same moment finishes its checks and meets the lock
    sleep "${STUB_LOGIN_SECONDS:-0}"
    # Or held until the test has seen the other run wait, however slow the machine
    while [[ -n "${STUB_GATE:-}" && ! -e "${STUB_GATE}" ]]; do sleep 0.05; done
    : > "${valid}"
    exit 0
  fi
done
# Each check's start and end, so a test can see which checks ran at the same time
if [[ -n "${STUB_CHECKS:-}" ]]; then
  echo start >> "${STUB_CHECKS}"
  sleep "${STUB_CHECK_SECONDS:-0}"
  echo end >> "${STUB_CHECKS}"
fi
if [[ -e "${valid}" ]]; then
  case "${0##*/}" in
    argocd) echo '{"loggedIn": true, "username": "alice"}' ;;
    spacectl) echo alice ;;
    *) echo token ;;
  esac
  exit 0
fi
case "${0##*/}" in
  argocd) echo '{}'; exit 0 ;;
  spacectl) echo 'failed to query user information: unauthorized' >&2; exit 1 ;;
  *) echo 'Reauthentication required.' >&2; exit 1 ;;
esac
"""
TOOLS = ("gcloud", "spacectl", "argocd")
# The stubs keep one credential per tool, so the first login to each tool makes that tool's other
# check valid too, and the check under the lock skips its login: one login per tool
FIRST_LOGIN_TO_EACH_TOOL = [
    "gcloud auth login --update-adc michael.uloth@recursion.com",
    "spacectl profile login --method browser --endpoint https://example.app.spacelift.io/ example",
    "argocd login --sso --grpc-web cd-prod.example.com",
]
WAITING = "Another run of auth is logging in"


class LoginLockBetweenRuns(unittest.TestCase):
    """Real auth.py processes sharing the lock under one HOME, with stubs that remember logins."""

    stubs: Path
    _folder: tempfile.TemporaryDirectory

    @classmethod
    def setUpClass(cls) -> None:
        cls._folder = tempfile.TemporaryDirectory()
        cls.stubs = Path(cls._folder.name) / "stubs"
        cls.stubs.mkdir()
        for name in TOOLS:
            stub = cls.stubs / name
            stub.write_text(STATEFUL_STUB)
            stub.chmod(0o755)
        cls.stubs.chmod(0o555)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.stubs.chmod(0o755)
        cls._folder.cleanup()

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.home = Path(self._tmp.name) / "home"
        self.state = Path(self._tmp.name) / "state"
        self.home.mkdir()
        self.state.mkdir()
        self.log = Path(self._tmp.name) / "stub.log"
        self.lock_path = self.home / ".local" / "state" / "auth" / "logins.lock"

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def start(self, **extra_env: str) -> subprocess.Popen:
        env = {
            "HOME": str(self.home),
            # /bin for the stubs' sleep; no real gcloud, spacectl or argocd lives there
            "PATH": f"{self.stubs}:/bin",
            "STUB_LOG": str(self.log),
            "STUB_STATE": str(self.state),
            "STUB_LOGIN_SECONDS": "1",
            "PRIVATE_ARGOCD_SERVERS": " ".join(SERVERS),
            "PRIVATE_SPACELIFT_ACCOUNT": ACCOUNT,
            **extra_env,
        }
        return subprocess.Popen(
            [sys.executable, str(SCRIPT)],
            env=env,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

    @contextlib.contextmanager
    def held_by_another_run(self):
        self.lock_path.parent.mkdir(parents=True, exist_ok=True)
        with self.lock_path.open("a") as handle:
            fcntl.flock(handle, fcntl.LOCK_EX)
            yield
            fcntl.flock(handle, fcntl.LOCK_UN)

    def wait_for_waiting_line(self, process: subprocess.Popen) -> None:
        assert process.stderr is not None
        deadline = time.monotonic() + 10
        seen = ""
        while time.monotonic() < deadline:
            ready, _, _ = select.select([process.stderr], [], [], 0.1)
            if ready:
                line = process.stderr.readline()
                seen += line
                if WAITING in line:
                    return
        self.fail(f"auth.py never said it was waiting; it printed:\n{seen}")

    def wait_for_either_to_wait(self, processes: list[subprocess.Popen]) -> subprocess.Popen:
        """The run that says it is waiting, once one does. What it read stays read."""
        streams: dict[IO[str], subprocess.Popen] = {}
        for process in processes:
            assert process.stderr is not None
            streams[process.stderr] = process
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            ready, _, _ = select.select(list(streams), [], [], 0.1)
            for stream in ready:
                if WAITING in stream.readline():
                    return streams[stream]
        self.fail("neither run said it was waiting")

    def logins_run(self) -> list[str]:
        calls = self.log.read_text().splitlines() if self.log.exists() else []
        return [call for call in calls if "login" in call.split()]

    def make_all_valid(self) -> None:
        for name in TOOLS:
            (self.state / f"{name}-valid").touch()

    def test_a_run_that_waited_runs_no_login_another_run_completed(self) -> None:
        with self.held_by_another_run():
            process = self.start()
            self.wait_for_waiting_line(process)
            self.make_all_valid()

        out, err = process.communicate(timeout=30)

        self.assertEqual(process.returncode, 0, out + err)
        self.assertEqual(self.logins_run(), [])

    def test_a_run_that_waited_logs_in_itself_when_the_login_is_still_expired(self) -> None:
        with self.held_by_another_run():
            process = self.start()
            self.wait_for_waiting_line(process)

        out, err = process.communicate(timeout=30)

        self.assertEqual(process.returncode, 0, out + err)
        self.assertEqual(self.logins_run(), FIRST_LOGIN_TO_EACH_TOOL)

    def test_ctrl_c_while_waiting_stops_the_run_without_a_login(self) -> None:
        with self.held_by_another_run():
            process = self.start()
            self.wait_for_waiting_line(process)
            process.send_signal(signal.SIGINT)
            out, err = process.communicate(timeout=30)

        self.assertEqual(process.returncode, 130, out + err)
        self.assertIn("Stopped.", err)
        self.assertEqual(self.logins_run(), [])

    def test_with_every_login_valid_a_run_never_waits_for_the_lock(self) -> None:
        self.make_all_valid()
        with self.held_by_another_run():
            process = self.start()
            out, err = process.communicate(timeout=30)

        self.assertEqual(process.returncode, 0, out + err)
        self.assertNotIn(WAITING, err)

    def test_a_run_that_waited_checks_again_all_at_once(self) -> None:
        checks = Path(self._tmp.name) / "checks"
        with self.held_by_another_run():
            process = self.start(STUB_CHECKS=str(checks), STUB_CHECK_SECONDS="0.5")
            self.wait_for_waiting_line(process)
            self.make_all_valid()
            first_pass = len(checks.read_text().splitlines())

        out, err = process.communicate(timeout=30)

        self.assertEqual(process.returncode, 0, out + err)
        under_the_lock = checks.read_text().splitlines()[first_pass:]
        # Every check under the lock started before any of them ended
        self.assertEqual(under_the_lock, ["start"] * 5 + ["end"] * 5)

    def test_a_lock_that_cant_be_set_up_still_runs_every_login(self) -> None:
        # A file where the lock's folder goes, so the lock can't be created
        self.lock_path.parent.parent.mkdir(parents=True)
        self.lock_path.parent.write_text("")

        out, err = self.start().communicate(timeout=30)

        self.assertIn("won't share logins", err)
        self.assertEqual(self.logins_run(), FIRST_LOGIN_TO_EACH_TOOL, out + err)

    def test_two_runs_started_together_log_in_to_each_tool_once(self) -> None:
        gate = Path(self._tmp.name) / "gate"
        processes = [self.start(STUB_GATE=str(gate)), self.start(STUB_GATE=str(gate))]
        waited = self.wait_for_either_to_wait(processes)
        gate.touch()
        results = {process: process.communicate(timeout=60) for process in processes}

        for process, (out, err) in results.items():
            self.assertEqual(process.returncode, 0, out + err)
            # Only the run that already said so waited
            self.assertNotIn(WAITING, err)
        self.assertEqual(self.logins_run(), FIRST_LOGIN_TO_EACH_TOOL)
        self.assertIn("(checked again, no login run)", results[waited][0])


class EndToEnd(unittest.TestCase):
    """Runs the script with stubs whose checks always report expired and whose logins exit 0."""

    stubs: Path
    _folder: tempfile.TemporaryDirectory

    @classmethod
    def setUpClass(cls) -> None:
        cls._folder = tempfile.TemporaryDirectory()
        cls.stubs = Path(cls._folder.name) / "stubs"
        cls.stubs.mkdir()
        for name in ("gcloud", "spacectl", "argocd"):
            stub = cls.stubs / name
            stub.write_text(STUB)
            stub.chmod(0o755)
        cls.stubs.chmod(0o555)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.stubs.chmod(0o755)
        cls._folder.cleanup()

    def run_auth(
        self, *args: str, path: Path | None = None, extra_env: dict[str, str] | None = None
    ) -> tuple[subprocess.CompletedProcess, list[str]]:
        with tempfile.TemporaryDirectory() as home:
            log = Path(home) / "stub.log"
            env = {
                "HOME": home,
                "PATH": str(path or self.stubs),
                "STUB_LOG": str(log),
                "PRIVATE_ARGOCD_SERVERS": " ".join(SERVERS),
                "PRIVATE_SPACELIFT_ACCOUNT": ACCOUNT,
                **(extra_env or {}),
            }
            result = subprocess.run(
                [sys.executable, str(SCRIPT), *args],
                capture_output=True,
                text=True,
                env=env,
                check=False,
                stdin=subprocess.DEVNULL,
            )
            calls = log.read_text().splitlines() if log.exists() else []
        return result, calls

    def test_each_login_gets_exactly_its_arguments(self) -> None:
        result, calls = self.run_auth()

        logins = [call for call in calls if "login" in call.split()]
        self.assertEqual(
            logins,
            [
                "gcloud auth login --update-adc michael.uloth@recursion.com",
                "gcloud auth login --no-activate michael.uloth@rxrx.tech",
                "spacectl profile login --method browser"
                " --endpoint https://example.app.spacelift.io/ example",
                "argocd login --sso --grpc-web cd-prod.example.com",
                "argocd login --sso --grpc-web cd-dev.example.com",
            ],
            result.stderr,
        )

    def test_each_check_gets_exactly_its_arguments(self) -> None:
        _, calls = self.run_auth("--check")

        self.assertEqual(
            sorted(calls),
            [
                "argocd account get-user-info --grpc-web --output json --server cd-dev.example.com",
                "argocd account get-user-info --grpc-web --output json --server cd-prod.example.com",
                "gcloud auth application-default print-access-token",
                "gcloud auth print-access-token --account=michael.uloth@rxrx.tech",
                "spacectl whoami",
            ],
        )

    def test_a_login_that_exits_zero_but_still_fails_its_check_is_reported_and_fails_the_run(
        self,
    ) -> None:
        result, _ = self.run_auth()

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(result.stdout.count("still expired"), 5, result.stdout)

    def test_ctrl_c_during_a_login_moves_on_to_the_next_and_still_reports_every_login(
        self,
    ) -> None:
        result, calls = self.run_auth(extra_env={"STUB_LOGIN_SENDS_CTRL_C": "1"})

        self.assertNotIn("Traceback", result.stderr)
        self.assertEqual(len([call for call in calls if "login" in call.split()]), 5)
        self.assertEqual(result.stdout.count("still expired"), 5, result.stdout + result.stderr)
        self.assertEqual(result.returncode, 1)

    def test_after_the_logins_the_first_server_is_argocds_default_context(self) -> None:
        result, calls = self.run_auth()

        self.assertEqual(calls[-1], "argocd context cd-prod.example.com", result.stderr)

    def test_check_mode_leaves_argocds_context_alone(self) -> None:
        _, calls = self.run_auth("--check")

        self.assertEqual([call for call in calls if " context " in call], [])

    def test_check_mode_runs_no_login(self) -> None:
        result, calls = self.run_auth("--check")

        self.assertEqual([call for call in calls if "login" in call.split()], [])
        self.assertEqual(result.stdout.count(": expired"), 5, result.stdout + result.stderr)
        self.assertEqual(result.returncode, 1, result.stderr)

    def test_missing_tools_are_reported_without_a_traceback(self) -> None:
        with tempfile.TemporaryDirectory() as empty:
            result, _ = self.run_auth(path=Path(empty))

        self.assertEqual(result.returncode, 1)
        self.assertNotIn("Traceback", result.stderr)
        for command in ("gcloud", "spacectl", "argocd"):
            self.assertIn(f"{command} is not installed", result.stdout)

    def test_help_runs_nothing(self) -> None:
        result, calls = self.run_auth("--help")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main()
