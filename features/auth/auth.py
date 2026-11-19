#!/usr/bin/env -S uv run --offline --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Log in to each work tool whose credentials have expired.

Checks the internal and external Google accounts, Spacelift and Argo CD, then runs the browser login
for each one that has expired, one at a time, and checks it again. Exits 0 only when every login
ends up valid.

Runs that start together, such as Claude sessions opened at once, share the logins: a run that finds
a login expired waits for any other run's logins to finish, checks again, and logs in unless that
check finds it valid or its tool missing, or can't tell after waiting. A run whose logins are all
valid never waits. When the lock can't be set up, the run says why and logs in without sharing.

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
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from enum import Enum
from typing import NewType, Protocol, assert_never

# Beside this file, which Python puts first on the import path when it runs a script
from login_lock import LOCK_PATH, HeldLoginLock, LoginLock, LoginPermit, file_login_lock

LoginName = NewType("LoginName", str)
ArgoServer = NewType("ArgoServer", str)
SpaceliftAccount = NewType("SpaceliftAccount", str)
Command = tuple[str, ...]

# The work emails are already public, so they are not private values
INTERNAL_ACCOUNT = "michael.uloth@recursion.com"
EXTERNAL_ACCOUNT = "michael.uloth@rxrx.tech"
SPACELIFT_ACCOUNT_KEY = "PRIVATE_SPACELIFT_ACCOUNT"
ARGOCD_SERVERS_KEY = "PRIVATE_ARGOCD_SERVERS"

# A healthy check takes about a second, so this leaves room for a slow token refresh while keeping a
# server that hangs from holding up the start of every work session cc.bash runs for long. Argo CD's
# token endpoint has hung for 30 s before answering 504.
CHECK_TIMEOUT_SECONDS = 10
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
    # Unique, in the order private.env lists them; the first is argocd's default context
    argocd_servers: tuple[ArgoServer, ...]
    spacelift_account: SpaceliftAccount | None


@dataclass(frozen=True)
class CheckResult:
    exit_code: int
    stdout: str
    stderr: str


@dataclass(frozen=True)
class TimedOut:
    pass


@dataclass(frozen=True)
class Valid:
    pass


@dataclass(frozen=True)
class Expired:
    pass


@dataclass(frozen=True)
class Unchecked:
    """The check could not tell whether the credential is valid, so its login is not run, unless an
    earlier check in the same run found it expired and the run didn't wait for the login lock."""

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
    after: (
        Status | None
    )  # None when nothing checked it again: it wasn't expired, or this run only checks
    # Whether this run logged in. A run that waited for another run's logins can find a login
    # valid, or its tool gone, on its second check without logging in.
    login_ran: bool

    def __post_init__(self) -> None:
        assert not self.login_ran or self.after is not None, f"{self.name} ran with no status after"


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
            return TimedOut()
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
    # dict.fromkeys drops a server listed twice and keeps the order of first appearance
    servers = tuple(
        dict.fromkeys(ArgoServer(server) for server in environ.get(ARGOCD_SERVERS_KEY, "").split())
    )
    account = environ.get(SPACELIFT_ACCOUNT_KEY, "").strip()
    return Settings(
        argocd_servers=servers,
        spacelift_account=SpaceliftAccount(account) if account else None,
    )


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
    spacelift_name = LoginName("Spacelift")
    spacelift: Login | Unconfigured
    match settings.spacelift_account:
        case None:
            spacelift = Unconfigured(spacelift_name, SPACELIFT_ACCOUNT_KEY)
        case account:
            spacelift = Login(
                name=spacelift_name,
                check=("spacectl", "whoami"),
                read_status=read_spacectl_whoami,
                # --method skips the menu that asks which kind of login to use, and --endpoint skips
                # the prompt for the account's URL, which spacectl asks for even when the profile
                # has one
                login=(
                    "spacectl",
                    "profile",
                    "login",
                    "--method",
                    "browser",
                    "--endpoint",
                    f"https://{account}.app.spacelift.io/",
                    account,
                ),
            )
    # Each server has its own Dex and its own refresh token, so each gets its own check and login
    argocd: tuple[Login | Unconfigured, ...] = tuple(
        Login(
            name=argocd_login_name(server),
            check=("argocd", "account", "get-user-info", "--grpc-web", "--output", "json")
            + ("--server", server),
            read_status=read_argocd_user_info,
            login=("argocd", "login", "--sso", "--grpc-web", server),
        )
        for server in settings.argocd_servers
    ) or (Unconfigured(LoginName("Argo CD"), ARGOCD_SERVERS_KEY),)
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
        spacelift,
        *argocd,
    )


def argocd_login_name(server: ArgoServer) -> LoginName:
    return LoginName(f"Argo CD ({server})")


def default_context_command(settings: Settings, outcomes: tuple[Outcome, ...]) -> Command | None:
    """`argocd login` makes the server it logged in to the current context, so after any Argo CD
    login this switches back to the first server, the default private.env names."""
    if not settings.argocd_servers:
        return None
    argocd_names = {argocd_login_name(server) for server in settings.argocd_servers}
    if not any(o.name in argocd_names and o.login_ran for o in outcomes):
        return None
    return ("argocd", "context", settings.argocd_servers[0])


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


def log_in(login: Login, mode: Mode, shell: Shell, _permit: LoginPermit) -> Status:
    assert mode is Mode.REFRESH, f"{login.name}: a login must never run in {mode.value} mode"
    print(f"\n🔑 Logging in to {login.name}...", file=sys.stderr, flush=True)
    # The fresh check decides the outcome, because a login can exit 0 without fixing anything
    shell.attach(login.login)
    return check_status(login, shell)


def run(
    mode: Mode,
    items: tuple[Login | Unconfigured, ...],
    shell: Shell,
    report: Callable[[Outcome], None],
    lock: LoginLock,
    after_logins: Callable[[tuple[Outcome, ...]], None] = lambda _outcomes: None,
) -> tuple[Outcome, ...]:
    """Check every login at once, then log in to the expired ones one at a time inside `lock`, which
    holds the login lock unless it couldn't be set up. Inside it, every expired login is checked
    again at once, and each is logged in to unless that check finds it valid or its tool missing,
    so a login another run completed meanwhile is not opened again. A check that can't tell logs in
    only when this run didn't wait for the lock, since a run that waited follows one that has just
    tried that login. `after_logins` then runs with the outcomes, still inside `lock`.

    Each outcome goes to `report` as soon as it is final: when its check finishes, or for an expired
    login, once its check under the lock and any login and check after it are done. So the order of
    the reports follows the order the checks finish in, and the returned outcomes keep the order of
    `items`."""
    befores: dict[int, Status] = {}
    reported: list[LoginName] = []

    def report_and_record(outcome: Outcome) -> None:
        reported.append(outcome.name)
        report(outcome)

    with ThreadPoolExecutor(max_workers=len(items)) as pool:
        checks = {pool.submit(check_status, item, shell): index for index, item in enumerate(items)}
        for check in as_completed(checks):
            index = checks[check]
            befores[index] = check.result()
            if login_to_run(mode, items[index], befores[index]) is None:
                report_and_record(unchanged(items[index], befores[index]))
    expired = {
        index
        for index, item in enumerate(items)
        if login_to_run(mode, item, befores[index]) is not None
    }

    def outcomes_with(after_lock: Mapping[int, Outcome]) -> tuple[Outcome, ...]:
        return tuple(
            after_lock.get(index, unchanged(item, befores[index]))
            for index, item in enumerate(items)
        )

    after_lock: dict[int, Outcome] = {}
    if expired:
        with lock as permit:
            after_lock = log_in_expired(
                items, befores, expired, mode, shell, permit, report_and_record
            )
            after_logins(outcomes_with(after_lock))
    outcomes = outcomes_with(after_lock)
    assert len(reported) == len(set(reported)), f"a login was reported twice: {reported}"
    assert set(reported) == {item.name for item in items}, f"a login went unreported: {reported}"
    return outcomes


def unchanged(item: Login | Unconfigured, before: Status) -> Outcome:
    """The outcome of a login this run doesn't log in to: what its first check found."""
    return Outcome(item.name, before, None, False)


def log_in_expired(
    items: tuple[Login | Unconfigured, ...],
    befores: Mapping[int, Status],
    expired: set[int],
    mode: Mode,
    shell: Shell,
    permit: LoginPermit,
    report: Callable[[Outcome], None],
) -> dict[int, Outcome]:
    """Check every expired login again at once, then go through them in order, logging in to each
    unless its check found it valid or its tool missing, and reporting each outcome once final."""
    with ThreadPoolExecutor(max_workers=len(expired)) as pool:
        rechecks = {index: pool.submit(check_status, items[index], shell) for index in expired}
    outcomes: dict[int, Outcome] = {}
    for index in sorted(expired):
        outcomes[index] = log_in_unless_settled(
            items[index], befores[index], rechecks[index].result(), mode, shell, permit
        )
        report(outcomes[index])
    return outcomes


def log_in_unless_settled(
    item: Login | Unconfigured,
    before: Status,
    again: Status,
    mode: Mode,
    shell: Shell,
    permit: LoginPermit,
) -> Outcome:
    """The login's outcome given its check under the lock, `again`: logged in to unless that check
    found it valid or its tool gone. A check that can't tell logs in, since the first one found it
    expired: a second browser login shows, while a session started with an expired login doesn't.
    A run that waited for the lock leaves it alone instead, since the run before it has just tried
    that login, and every waiting run opening it again would ask for it once per session."""
    login = login_to_run(mode, item, before)
    assert login is not None, f"{item.name} is {before}, so it must not be checked again"
    match (again, permit):
        case (Valid() | NotInstalled(), _) | (Unchecked(), HeldLoginLock(waited=True)):
            return Outcome(item.name, before, again, False)
        case (Expired() | Unchecked(), _):
            return Outcome(item.name, before, log_in(login, mode, shell, permit), True)
        case (NotConfigured(), _):
            raise AssertionError(f"{item.name} is configured, so its check can't say otherwise")
        case unexpected:
            assert_never(unexpected)


def login_to_run(mode: Mode, item: Login | Unconfigured, before: Status) -> Login | None:
    """The login to run for an item whose check found it expired, in refresh mode only."""
    match (mode, item, before):
        case (Mode.REFRESH, Login() as login, Expired()):
            return login
        case _:
            return None


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
        case after if not outcome.login_ran:
            before, now = describe_status(outcome.before), describe_status(after)
            change = f"{before} → {now} (checked again, no login run)"
        case after:
            change = f"{describe_status(outcome.before)} → {describe_status(after)}"
    return f"{icon} {outcome.name}: {change}"


def restore_default_context(command: Command, shell: Shell) -> None:
    match shell.capture(command):
        case CheckResult(exit_code=0):
            print(f"Argo CD's default context is {command[-1]}.", file=sys.stderr)
        case CheckResult() as result:
            error = last_line(result.stderr) or f"argocd exited {result.exit_code}"
            print(f"⚠️  Couldn't make {command[-1]} the default context: {error}", file=sys.stderr)
        case TimedOut():
            print(
                f"⚠️  `{' '.join(command)}` took longer than {CHECK_TIMEOUT_SECONDS} s",
                file=sys.stderr,
            )
        case unexpected:
            assert_never(unexpected)


def restore_default_context_after(
    settings: Settings, outcomes: tuple[Outcome, ...], shell: Shell
) -> None:
    """Make the first Argo CD server the default context again, after any Argo CD login."""
    match default_context_command(settings, outcomes):
        case None:
            pass
        case command:
            restore_default_context(command, shell)


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
    settings = read_settings(os.environ)
    shell = SubprocessShell()
    print("Checking logins...", file=sys.stderr, flush=True)
    try:
        outcomes = run(
            mode,
            logins(settings),
            shell,
            lambda outcome: print(describe(outcome), flush=True),
            file_login_lock(LOCK_PATH),
            # Inside the lock, so while it holds one, no other run is logging in to Argo CD as the
            # config is written
            after_logins=lambda outcomes: restore_default_context_after(settings, outcomes, shell),
        )
    except KeyboardInterrupt:
        # Reached from a check or from waiting for another run's logins, since each login catches
        # its own Ctrl-C
        print("\nStopped. Run `auth --check` to see where each login stands.", file=sys.stderr)
        return INTERRUPTED_EXIT_CODE
    if mode is Mode.CHECK and any(outcome.before == Expired() for outcome in outcomes):
        print("\nRun `auth` to log in to the expired ones.", file=sys.stderr)
    return 0 if all_valid(outcomes) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
