#!/usr/bin/env -S uv run --offline --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Log in to each work tool whose credentials have expired.

Checks the internal and external Google accounts, Spacelift and Argo CD, then runs the browser login
for each one that has expired, one at a time, and checks it again. Exits 0 only when every login
ends up valid.

Run with: auth            (log in to the expired ones)
          auth --check    (only report; logs in to nothing)

The script needs no packages, and the alias runs it with `uv run --offline`, so it starts even while
the Google credentials that the work package index needs have expired.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from collections.abc import Callable, Mapping
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from enum import Enum
from typing import NewType, Protocol, assert_never

LoginName = NewType("LoginName", str)
ArgoServer = NewType("ArgoServer", str)
Command = tuple[str, ...]

# The work emails and the Spacelift account are already public, so they are not private values
INTERNAL_ACCOUNT = "michael.uloth@recursion.com"
EXTERNAL_ACCOUNT = "michael.uloth@rxrx.tech"
SPACELIFT_ACCOUNT = "recursion"
SPACELIFT_ENDPOINT = f"https://{SPACELIFT_ACCOUNT}.app.spacelift.io/"
ARGOCD_SERVER_KEY = "PRIVATE_ARGOCD_SERVER"

# Long enough for a slow token refresh, short enough that a hung check doesn't hold up the others
CHECK_TIMEOUT_SECONDS = 30
# What a shell reports for a command stopped by Ctrl-C (128 + SIGINT)
INTERRUPTED_EXIT_CODE = 130

# What argocd printed on this laptop when its refresh token had been revoked (invalid_grant) and when
# the server rejected the session (Unauthenticated)
ARGOCD_EXPIRED_MARKERS = ("invalid_grant", "code = Unauthenticated")
# What gcloud prints when a login would fix the check, from the messages in the SDK's
# googlecloudsdk/core/credentials and google/auth: a revoked or expired refresh token, a reauth it
# can't prompt for, an account with no credentials, and no ADC file. An unreachable network prints
# none of these.
GCLOUD_EXPIRED_MARKERS = (
    "invalid_grant",
    "Reauthentication",
    "reauthenticating",
    "does not have any valid credentials",
    "default credentials were not found",
)
# What spacectl 1.29 printed on this laptop with no profile, and what its binary prints when the
# server rejects the token
SPACECTL_EXPIRED_MARKERS = ("please login first", "failed to query user information: unauthorized")


class Mode(Enum):
    CHECK = "check"
    REFRESH = "refresh"


@dataclass(frozen=True)
class Settings:
    argocd_server: ArgoServer | None


@dataclass(frozen=True)
class CheckResult:
    exit_code: int
    stdout: str
    stderr: str


@dataclass(frozen=True)
class TimedOut:
    command: Command


@dataclass(frozen=True)
class Valid:
    pass


@dataclass(frozen=True)
class Expired:
    pass


@dataclass(frozen=True)
class Unchecked:
    """The check could not tell whether the credential is valid, so its login is not run."""

    reason: str


@dataclass(frozen=True)
class NotInstalled:
    command: str


@dataclass(frozen=True)
class NotConfigured:
    key: str


Status = Valid | Expired | Unchecked | NotInstalled | NotConfigured


@dataclass(frozen=True)
class Login:
    name: LoginName
    check: Command
    read_status: Callable[[CheckResult], Status]
    login: Command


@dataclass(frozen=True)
class Unconfigured:
    """A login that can't be built because a private.env key it needs is unset."""

    name: LoginName
    key: str


@dataclass(frozen=True)
class Outcome:
    name: LoginName
    before: Status
    after: Status | None  # None when no login ran


class Shell(Protocol):
    def has(self, command: str) -> bool: ...
    def capture(self, command: Command) -> CheckResult | TimedOut: ...
    def attach(self, command: Command) -> int: ...


class SubprocessShell:
    def has(self, command: str) -> bool:
        return shutil.which(command) is not None

    def capture(self, command: Command) -> CheckResult | TimedOut:
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=False,
                stdin=subprocess.DEVNULL,
                timeout=CHECK_TIMEOUT_SECONDS,
            )
        except subprocess.TimeoutExpired:
            return TimedOut(command)
        return CheckResult(result.returncode, result.stdout, result.stderr)

    def attach(self, command: Command) -> int:
        # The login shares this terminal, so its browser prompt and any questions reach the user.
        # Ctrl-C stops only this login: the login gets the interrupt too, and the run goes on to
        # check it again and to the next login.
        try:
            return subprocess.run(command, check=False).returncode
        except KeyboardInterrupt:
            return INTERRUPTED_EXIT_CODE


def read_settings(environ: Mapping[str, str]) -> Settings:
    server = environ.get(ARGOCD_SERVER_KEY, "").strip()
    return Settings(argocd_server=ArgoServer(server) if server else None)


def read_gcloud_token(result: CheckResult) -> Status:
    """gcloud exits non-zero both when its credentials have expired and when it can't reach Google,
    so only a failure naming the credentials counts as expired. Its first line holds the error."""
    return read_failure(result, GCLOUD_EXPIRED_MARKERS, first_line(result.stderr))


def read_spacectl_whoami(result: CheckResult) -> Status:
    """spacectl exits non-zero both when it isn't logged in and when it can't reach Spacelift, so
    only a failure naming the login counts as expired. Its last line holds the error."""
    return read_failure(result, SPACECTL_EXPIRED_MARKERS, last_line(result.stderr))


def read_failure(result: CheckResult, expired_markers: tuple[str, ...], error: str) -> Status:
    if result.exit_code == 0:
        return Valid()
    if any(marker in result.stderr for marker in expired_markers):
        return Expired()
    return Unchecked(error or f"the check exited {result.exit_code}")


def read_argocd_user_info(result: CheckResult) -> Status:
    """An expired session usually exits 0 with JSON whose loggedIn field says so. A refresh token
    the server has revoked, or a session it rejects, exits non-zero naming that, and counts as
    expired. Any other failure, such as an unreachable server, can't tell."""
    if result.exit_code != 0:
        if any(marker in result.stderr for marker in ARGOCD_EXPIRED_MARKERS):
            return Expired()
        return Unchecked(last_line(result.stderr) or f"argocd exited {result.exit_code}")
    try:
        info = json.loads(result.stdout)
    except json.JSONDecodeError:
        return Unchecked(f"argocd printed something other than JSON: {last_line(result.stdout)}")
    match info:
        case {"loggedIn": True}:
            return Valid()
        case dict():
            return Expired()
        case _:
            return Unchecked(
                f"argocd printed JSON that isn't an object: {last_line(result.stdout)}"
            )


def first_line(text: str) -> str:
    lines = text.strip().splitlines()
    return lines[0] if lines else ""


def last_line(text: str) -> str:
    lines = text.strip().splitlines()
    return lines[-1] if lines else ""


def logins(settings: Settings) -> tuple[Login | Unconfigured, ...]:
    argocd_name = LoginName("Argo CD")
    argocd: Login | Unconfigured
    match settings.argocd_server:
        case None:
            argocd = Unconfigured(argocd_name, ARGOCD_SERVER_KEY)
        case server:
            argocd = Login(
                name=argocd_name,
                check=("argocd", "account", "get-user-info", "--grpc-web", "--output", "json")
                + ("--server", server),
                read_status=read_argocd_user_info,
                login=("argocd", "login", "--sso", "--grpc-web", server),
            )
    return (
        Login(
            name=LoginName("Google (recursion.com)"),
            check=("gcloud", "auth", "application-default", "print-access-token"),
            read_status=read_gcloud_token,
            login=("gcloud", "auth", "login", "--update-adc", INTERNAL_ACCOUNT),
        ),
        Login(
            name=LoginName("Google (rxrx.tech)"),
            check=("gcloud", "auth", "print-access-token", f"--account={EXTERNAL_ACCOUNT}"),
            read_status=read_gcloud_token,
            login=("gcloud", "auth", "login", "--no-activate", EXTERNAL_ACCOUNT),
        ),
        Login(
            name=LoginName("Spacelift"),
            check=("spacectl", "whoami"),
            read_status=read_spacectl_whoami,
            # --method skips the menu that asks which kind of login to use, and --endpoint skips the
            # prompt for the account's URL, which spacectl asks for even when the profile has one
            login=(
                "spacectl",
                "profile",
                "login",
                "--method",
                "browser",
                "--endpoint",
                SPACELIFT_ENDPOINT,
                SPACELIFT_ACCOUNT,
            ),
        ),
        argocd,
    )


def check_status(item: Login | Unconfigured, shell: Shell) -> Status:
    match item:
        case Unconfigured(key=key):
            return NotConfigured(key)
        case Login():
            if not shell.has(item.check[0]):
                return NotInstalled(item.check[0])
            match shell.capture(item.check):
                case TimedOut():
                    return Unchecked(f"the check took longer than {CHECK_TIMEOUT_SECONDS} s")
                case CheckResult() as result:
                    return item.read_status(result)
                case unexpected:
                    assert_never(unexpected)
        case _:
            assert_never(item)


def log_in(login: Login, before: Status, mode: Mode, shell: Shell) -> Status:
    assert mode is Mode.REFRESH, f"{login.name}: a login must never run in {mode.value} mode"
    assert before == Expired(), f"{login.name} is {before}, so its login must not run"
    print(f"\n🔑 Logging in to {login.name}...", file=sys.stderr, flush=True)
    # The fresh check decides the outcome, because a login can exit 0 without fixing anything
    shell.attach(login.login)
    return check_status(login, shell)


def run(mode: Mode, items: tuple[Login | Unconfigured, ...], shell: Shell) -> tuple[Outcome, ...]:
    """Check every login at once, then log in to the expired ones one at a time."""
    with ThreadPoolExecutor(max_workers=len(items)) as pool:
        befores = list(pool.map(lambda item: check_status(item, shell), items))
    outcomes: list[Outcome] = []
    for item, before in zip(items, befores, strict=True):
        match (mode, item, before):
            case (Mode.REFRESH, Login() as login, Expired()):
                outcomes.append(Outcome(item.name, before, log_in(login, before, mode, shell)))
            case _:
                outcomes.append(Outcome(item.name, before, None))
    return tuple(outcomes)


def final_status(outcome: Outcome) -> Status:
    return outcome.before if outcome.after is None else outcome.after


def all_valid(outcomes: tuple[Outcome, ...]) -> bool:
    return all(final_status(outcome) == Valid() for outcome in outcomes)


def describe_status(status: Status) -> str:
    match status:
        case Valid():
            return "valid"
        case Expired():
            return "expired"
        case Unchecked(reason=reason):
            return f"couldn't check ({reason})"
        case NotInstalled(command=command):
            return f"{command} is not installed"
        case NotConfigured(key=key):
            return f"not configured: set {key} in private.env (see private.env.example)"
        case _:
            assert_never(status)


def describe(outcome: Outcome) -> str:
    icon = "✅" if final_status(outcome) == Valid() else "❌"
    match outcome.after:
        case None:
            change = describe_status(outcome.before)
        case Expired():
            change = "expired → still expired after logging in"
        case after:
            change = f"{describe_status(outcome.before)} → {describe_status(after)}"
    return f"{icon} {outcome.name}: {change}"


def read_mode(argv: list[str]) -> Mode:
    parser = argparse.ArgumentParser(
        prog="auth", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--check", action="store_true", help="only report each login's status; log in to nothing"
    )
    return Mode.CHECK if parser.parse_args(argv).check else Mode.REFRESH


def main(argv: list[str]) -> int:
    mode = read_mode(argv)
    try:
        outcomes = run(mode, logins(read_settings(os.environ)), SubprocessShell())
    except KeyboardInterrupt:
        # Reached only from a check, since each login catches its own Ctrl-C
        print("\nStopped. Run `auth --check` to see where each login stands.", file=sys.stderr)
        return INTERRUPTED_EXIT_CODE
    if any(outcome.after is not None for outcome in outcomes):
        print(file=sys.stderr)
    for outcome in outcomes:
        print(describe(outcome))
    if mode is Mode.CHECK and any(outcome.before == Expired() for outcome in outcomes):
        print("\nRun `auth` to log in to the expired ones.", file=sys.stderr)
    return 0 if all_valid(outcomes) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
