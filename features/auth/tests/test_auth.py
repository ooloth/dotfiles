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
argocd commands on PATH that record their arguments.
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
from unittest import mock

from hypothesis import given
from hypothesis import strategies as st

SCRIPT = Path(__file__).resolve().parent.parent / "auth.py"

_spec = importlib.util.spec_from_file_location("auth", SCRIPT)
assert _spec is not None and _spec.loader is not None, f"cannot load {SCRIPT}"
auth = importlib.util.module_from_spec(_spec)
sys.modules["auth"] = auth
_spec.loader.exec_module(auth)

SERVER = auth.ArgoServer("cd.example.com")
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
            return auth.TimedOut(command)
        return ANSWERS[command[0]][self.states[login.name]]

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


login_state = st.sampled_from(["valid", "expired", "unreachable"])


class OnlyExpiredLoginsRun(unittest.TestCase):
    @given(
        google_internal=login_state,
        google_external=login_state,
        spacelift=login_state,
        argocd=st.sampled_from(["valid", "expired", "unreachable", "revoked"]),
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
        expired = [item for item in installed if states[item.name] in ("expired", "revoked")]
        self.assertEqual(shell.attached, [item.login for item in expired])
        ends_valid = len(installed) == len(items) and all(
            states[item.name] == "valid"
            or (states[item.name] in ("expired", "revoked") and login_works[item.name])
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
        shell.states["Argo CD"] = "revoked"

        outcomes = auth.run(auth.Mode.REFRESH, items, shell)

        self.assertEqual(shell.attached, [items[3].login])
        self.assertEqual(outcomes[3].after, auth.Valid())

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

        outcomes = auth.run(auth.Mode.REFRESH, items, shell)

        self.assertEqual(shell.attached, [])
        for outcome in outcomes:
            self.assertIsInstance(outcome.before, auth.Unchecked)


class SubprocessShellLimits(unittest.TestCase):
    def test_a_check_slower_than_the_timeout_is_reported_as_timed_out(self) -> None:
        with mock.patch.object(auth, "CHECK_TIMEOUT_SECONDS", 0.2):
            result = auth.SubprocessShell().capture(("sleep", "5"))

        self.assertEqual(result, auth.TimedOut(("sleep", "5")))


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
                "PRIVATE_ARGOCD_SERVER": SERVER,
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
                " --endpoint https://recursion.app.spacelift.io/ recursion",
                "argocd login --sso --grpc-web cd.example.com",
            ],
            result.stderr,
        )

    def test_each_check_gets_exactly_its_arguments(self) -> None:
        _, calls = self.run_auth("--check")

        self.assertEqual(
            sorted(calls),
            [
                "argocd account get-user-info --grpc-web --output json --server cd.example.com",
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
        self.assertEqual(result.stdout.count("still expired"), 4, result.stdout)

    def test_ctrl_c_during_a_login_moves_on_to_the_next_and_still_prints_the_summary(
        self,
    ) -> None:
        result, calls = self.run_auth(extra_env={"STUB_LOGIN_SENDS_CTRL_C": "1"})

        self.assertNotIn("Traceback", result.stderr)
        self.assertEqual(len([call for call in calls if "login" in call.split()]), 4)
        self.assertEqual(result.stdout.count("still expired"), 4, result.stdout + result.stderr)
        self.assertEqual(result.returncode, 1)

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
