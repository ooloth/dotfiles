#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for features/auth/auth.py, which logs in to the work tools whose credentials have expired.

Run with: uv run features/auth/tests/test_auth.py

Most tests load the script in-process and hand `run` a FakeShell. It answers each check the way the
real tool answered when its credential was valid or expired, or, for argocd, when the server could
not be reached, and it records each login it is asked to run. The end-to-end tests run the script as
a subprocess with stub gcloud, spacectl and argocd commands on PATH that record their arguments.
"""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal

from hypothesis import given
from hypothesis import strategies as st

SCRIPT = Path(__file__).resolve().parent.parent / "auth.py"

_spec = importlib.util.spec_from_file_location("auth", SCRIPT)
assert _spec is not None and _spec.loader is not None, f"cannot load {SCRIPT}"
auth = importlib.util.module_from_spec(_spec)
sys.modules["auth"] = auth
_spec.loader.exec_module(auth)

SERVER = auth.ArgoServer("cd.example.com")
State = Literal["valid", "expired", "unreachable"]

# What each tool printed on this laptop in each state, checked against the real commands
ARGOCD_ANSWERS = {
    "valid": auth.CheckResult(0, '{"loggedIn": true, "username": "alice"}', ""),
    "expired": auth.CheckResult(0, "{}", ""),
    "unreachable": auth.CheckResult(
        20, "", '{"level":"fatal","msg":"dial tcp: lookup cd.example.com: no such host"}\n'
    ),
}
EXIT_CODE_ANSWERS = {
    "valid": auth.CheckResult(0, "token", ""),
    "expired": auth.CheckResult(1, "", "Reauthentication required.\n"),
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
            return auth.TimedOut(command)
        answers = ARGOCD_ANSWERS if command[0] == "argocd" else EXIT_CODE_ANSWERS
        return answers[self.states[login.name]]

    def attach(self, command: tuple[str, ...]) -> int:
        self.attached.append(command)
        (login,) = [item for item in self._logins() if item.login == command]
        if self.login_works[login.name]:
            self.states[login.name] = "valid"
            return 0
        return 1


def configured_logins() -> tuple:
    return auth.logins(auth.Settings(argocd_server=SERVER))


def names(items: tuple) -> list[str]:
    return [item.name for item in items]


def tool(item) -> str:
    return item.check[0]


login_state = st.sampled_from(["valid", "expired"])


class OnlyExpiredLoginsRun(unittest.TestCase):
    @given(
        google_internal=login_state,
        google_external=login_state,
        spacelift=login_state,
        argocd=st.sampled_from(["valid", "expired", "unreachable"]),
        missing=st.frozensets(st.sampled_from(["gcloud", "spacectl", "argocd"])),
        works=st.lists(st.booleans(), min_size=4, max_size=4),
    )
    def test_logins_run_for_exactly_the_expired_ones_and_exit_follows_the_final_statuses(
        self,
        google_internal: State,
        google_external: State,
        spacelift: State,
        argocd: State,
        missing: frozenset[str],
        works: list[bool],
    ) -> None:
        items = configured_logins()
        states = dict(
            zip(names(items), [google_internal, google_external, spacelift, argocd], strict=True)
        )
        login_works = dict(zip(names(items), works, strict=True))
        shell = FakeShell(items, dict(states), login_works, missing)

        outcomes = auth.run(auth.Mode.REFRESH, items, shell)

        installed = [item for item in items if tool(item) not in missing]
        expired = [item for item in installed if states[item.name] == "expired"]
        self.assertEqual(shell.attached, [item.login for item in expired])
        ends_valid = len(installed) == len(items) and all(
            states[item.name] == "valid"
            or (states[item.name] == "expired" and login_works[item.name])
            for item in installed
        )
        self.assertEqual(auth.all_valid(outcomes), ends_valid)


class CheckMode(unittest.TestCase):
    def test_check_runs_no_login_even_when_every_login_has_expired(self) -> None:
        items = configured_logins()
        shell = FakeShell(
            items,
            dict.fromkeys(names(items), "expired"),
            dict.fromkeys(names(items), True),
        )

        outcomes = auth.run(auth.Mode.CHECK, items, shell)

        self.assertEqual(shell.attached, [])
        self.assertEqual([outcome.before for outcome in outcomes], [auth.Expired()] * 4)
        self.assertFalse(auth.all_valid(outcomes))


class ArgoCdStatus(unittest.TestCase):
    def test_logged_in_user_info_is_valid(self) -> None:
        self.assertEqual(auth.read_argocd_user_info(ARGOCD_ANSWERS["valid"]), auth.Valid())

    def test_empty_user_info_with_exit_zero_is_expired(self) -> None:
        self.assertEqual(auth.read_argocd_user_info(ARGOCD_ANSWERS["expired"]), auth.Expired())

    def test_failed_call_is_unchecked_with_its_last_error_line(self) -> None:
        self.assertEqual(
            auth.read_argocd_user_info(ARGOCD_ANSWERS["unreachable"]),
            auth.Unchecked(
                '{"level":"fatal","msg":"dial tcp: lookup cd.example.com: no such host"}'
            ),
        )

    def test_output_that_is_not_json_is_unchecked(self) -> None:
        status = auth.read_argocd_user_info(auth.CheckResult(0, "Logged In: false\n", ""))
        self.assertIsInstance(status, auth.Unchecked)


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

        outcomes = auth.run(auth.Mode.REFRESH, items, shell)

        self.assertIsInstance(outcomes[2].before, auth.Unchecked)
        self.assertEqual(shell.attached, [])


class ArgoCdServerSetting(unittest.TestCase):
    def test_unset_or_blank_server_is_not_configured(self) -> None:
        for environ in ({}, {"PRIVATE_ARGOCD_SERVER": ""}, {"PRIVATE_ARGOCD_SERVER": "  "}):
            with self.subTest(environ=environ):
                self.assertEqual(auth.read_settings(environ), auth.Settings(argocd_server=None))

    def test_set_server_is_read(self) -> None:
        settings = auth.read_settings({"PRIVATE_ARGOCD_SERVER": " cd.example.com "})
        self.assertEqual(settings, auth.Settings(argocd_server=SERVER))

    def test_without_a_server_argocd_names_the_key_and_the_other_logins_still_run(self) -> None:
        items = auth.logins(auth.Settings(argocd_server=None))
        shell = FakeShell(
            items,
            dict.fromkeys(names(items), "expired"),
            dict.fromkeys(names(items), True),
        )

        outcomes = auth.run(auth.Mode.REFRESH, items, shell)

        self.assertEqual(outcomes[3].before, auth.NotConfigured("PRIVATE_ARGOCD_SERVER"))
        self.assertIn("PRIVATE_ARGOCD_SERVER", auth.describe(outcomes[3]))
        self.assertEqual(len(shell.attached), 3)


STUB = """#!/bin/bash
printf '%s\\n' "${0##*/} $*" >> "${STUB_LOG}"
for arg in "$@"; do
  [[ "${arg}" == login ]] && exit 0
done
if [[ "${0##*/}" == argocd ]]; then
  echo '{}'
  exit 0
fi
echo 'Reauthentication required.' >&2
exit 1
"""


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
        self, *args: str, path: Path | None = None
    ) -> tuple[subprocess.CompletedProcess, list[str]]:
        with tempfile.TemporaryDirectory() as home:
            log = Path(home) / "stub.log"
            env = {
                "HOME": home,
                "PATH": str(path or self.stubs),
                "STUB_LOG": str(log),
                "PRIVATE_ARGOCD_SERVER": SERVER,
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
                "gcloud auth login --quiet --update-adc michael.uloth@recursion.com",
                "gcloud auth login --quiet --no-activate michael.uloth@rxrx.tech",
                "spacectl profile login --method browser recursion",
                "argocd login --sso --grpc-web cd.example.com",
            ],
            result.stderr,
        )

    def test_a_login_that_exits_zero_but_still_fails_its_check_is_reported_and_fails_the_run(
        self,
    ) -> None:
        result, _ = self.run_auth()

        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(result.stdout.count("still expired"), 4, result.stdout)

    def test_check_mode_runs_no_login(self) -> None:
        result, calls = self.run_auth("--check")

        self.assertEqual([call for call in calls if "login" in call.split()], [])
        self.assertEqual(result.stdout.count(": expired"), 4, result.stdout + result.stderr)
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
