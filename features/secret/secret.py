#!/usr/bin/env -S uv run --offline --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Store secrets in the login Keychain, then read them into commands.

Run with: secret add <name>   (asks for the value without showing it)
          secret get <name>   (prints the value, for "$(secret get <name>)")

A secret goes into the Keychain first, with `secret add`, and every command that needs it reads it
with "$(secret get <name>)", so the value never reaches shell history, the clipboard or a command
you typed. The login Keychain stays on this Mac.
"""

from __future__ import annotations

import argparse
import getpass
import re
import subprocess
import sys
from dataclasses import dataclass, field
from typing import NewType, assert_never

SecretName = NewType("SecretName", str)
KeychainAccount = NewType("KeychainAccount", str)

# Letters, digits, dots, underscores and hyphens, not starting with a hyphen, so security can't
# read a name as one of its options
NAME_PATTERN = re.compile(r"[A-Za-z0-9._][A-Za-z0-9._-]*")
# The same, plus @ and + so an email address can be an account
ACCOUNT_PATTERN = re.compile(r"[A-Za-z0-9._@+][A-Za-z0-9._@+-]*")

# `security find-generic-password` exits 44 with this message when no item has the name. Either one
# counts, since neither has been checked against every macOS version.
NOT_FOUND_EXIT_CODE = 44
NOT_FOUND_MESSAGE = "could not be found"
# How `security find-generic-password` prints an item's account when run without -w
ACCOUNT_ATTRIBUTE = re.compile(r'^\s*"acct"<blob>="(.*)"$', re.MULTILINE)


@dataclass(frozen=True)
class Add:
    name: SecretName
    account: KeychainAccount


@dataclass(frozen=True)
class Get:
    name: SecretName


Request = Add | Get


@dataclass(frozen=True)
class Stored:
    name: SecretName
    account: KeychainAccount
    length: int


@dataclass(frozen=True)
class Found:
    # Kept out of repr, so a traceback or a test failure that shows a Found never shows the secret
    value: str = field(repr=False)


@dataclass(frozen=True)
class Cancelled:
    name: SecretName


@dataclass(frozen=True)
class EmptyValue:
    name: SecretName


@dataclass(frozen=True)
class ExistingItem:
    account: KeychainAccount | None  # None when security printed no account we could read


@dataclass(frozen=True)
class StoredUnderAnotherAccount:
    """-U replaces only an item with the same name and account, and `get` looks only at the name,
    so storing under a second account would leave two values and `get` would return either."""

    name: SecretName
    other: KeychainAccount | None  # None when security printed no account we could read


@dataclass(frozen=True)
class NotFound:
    name: SecretName


@dataclass(frozen=True)
class KeychainError:
    message: str


Result = (
    Stored | Found | EmptyValue | Cancelled | StoredUnderAnotherAccount | NotFound | KeychainError
)


def secret_name(text: str) -> SecretName:
    if not NAME_PATTERN.fullmatch(text):
        raise argparse.ArgumentTypeError(
            f"{text!r} isn't a usable name: use letters, digits, dots, underscores and hyphens,"
            " not starting with a hyphen"
        )
    return SecretName(text)


def keychain_account(text: str) -> KeychainAccount:
    if not ACCOUNT_PATTERN.fullmatch(text):
        raise argparse.ArgumentTypeError(
            f"{text!r} isn't a usable account: use letters, digits and . _ @ + -,"
            " not starting with a hyphen"
        )
    return KeychainAccount(text)


def read_request(argv: list[str]) -> Request:
    parser = argparse.ArgumentParser(
        prog="secret", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    commands = parser.add_subparsers(dest="command", required=True)
    add = commands.add_parser("add", help="store a secret, asking for its value without showing it")
    add.add_argument("name", type=secret_name, help="the name to store it under, such as codefresh")
    add.add_argument(
        "--account",
        type=keychain_account,
        default=KeychainAccount(getpass.getuser()),
        help="the account to store it under (default: your user name). Use the one a tool"
        " looks up, such as your login email for jira-cli",
    )
    get = commands.add_parser("get", help="print a stored secret")
    get.add_argument("name", type=secret_name, help="the name it was stored under")
    args = parser.parse_args(argv)
    match args.command:
        case "add":
            return Add(args.name, args.account)
        case "get":
            return Get(args.name)
        case other:
            raise AssertionError(f"argparse accepted an unknown command: {other}")


def read_value(name: SecretName) -> str | Cancelled:
    """Asks for the value without echoing it. Unlike security's own prompt, which keeps only the
    first 128 characters, this takes a whole pasted token. Piped input is read as one line. Ctrl-C
    or Ctrl-D at the prompt cancels."""
    if sys.stdin.isatty():
        try:
            return getpass.getpass(f"Value for {name} (hidden): ")
        except (KeyboardInterrupt, EOFError):
            print(file=sys.stderr)
            return Cancelled(name)
    return sys.stdin.readline().removesuffix("\n").removesuffix("\r")


def add(name: SecretName, account: KeychainAccount, value: str | Cancelled) -> Result:
    match value:
        case Cancelled():
            return value
        case "":
            return EmptyValue(name)
        case str():
            pass
        case _:
            assert_never(value)
    match stored_item(name):
        case KeychainError() as error:
            return error
        case None:
            pass
        case ExistingItem(account=existing) if existing == account:
            pass
        case ExistingItem(account=existing):
            return StoredUnderAnotherAccount(name, existing)
        case unexpected:
            assert_never(unexpected)
    # The value passes through security's arguments while it runs, and is never written to shell
    # history, the clipboard or anything printed. -U replaces a value already stored under this name
    # and account.
    result = subprocess.run(
        ["security", "add-generic-password", "-U", "-a", account, "-s", name] + ["-w", value],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return KeychainError(last_line(result.stderr) or f"security exited {result.returncode}")
    return Stored(name, account, len(value))


def stored_item(name: SecretName) -> ExistingItem | None | KeychainError:
    """The item already stored under this name, or None when there is none. Without -w, security
    prints only the item's attributes, never its value."""
    result = subprocess.run(
        ["security", "find-generic-password", "-s", name],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode == NOT_FOUND_EXIT_CODE or NOT_FOUND_MESSAGE in result.stderr:
        return None
    if result.returncode != 0:
        return KeychainError(last_line(result.stderr) or f"security exited {result.returncode}")
    found = ACCOUNT_ATTRIBUTE.search(result.stdout)
    return ExistingItem(KeychainAccount(found.group(1)) if found else None)


def get(name: SecretName) -> Result:
    # No account filter, so items stored by other tools under the same name are found too
    result = subprocess.run(
        ["security", "find-generic-password", "-s", name, "-w"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode == NOT_FOUND_EXIT_CODE or NOT_FOUND_MESSAGE in result.stderr:
        return NotFound(name)
    if result.returncode != 0:
        return KeychainError(last_line(result.stderr) or f"security exited {result.returncode}")
    return Found(result.stdout.removesuffix("\n"))


def last_line(text: str) -> str:
    lines = text.strip().splitlines()
    return lines[-1] if lines else ""


def report(result: Result) -> int:
    """Prints a found value on stdout and everything else on stderr, so "$(secret get x)" gets the
    value or nothing."""
    match result:
        case Found(value=value):
            print(value)
            return 0
        case Stored(name=name, account=account, length=length):
            print(
                f"✅ Stored {length} characters as {name} (account {account})."
                f' Use it as "$(secret get {name})".',
                file=sys.stderr,
            )
            return 0
        case Cancelled(name=name):
            print(f"Nothing stored for {name}: cancelled.", file=sys.stderr)
            return 1
        case EmptyValue(name=name):
            print(f"❌ Nothing stored: the value for {name} was empty.", file=sys.stderr)
            return 1
        case StoredUnderAnotherAccount(name=name, other=None):
            print(
                f"❌ Nothing stored: {name} is already in the Keychain under an account security"
                " didn't print. Pass that account with --account to replace it.",
                file=sys.stderr,
            )
            return 1
        case StoredUnderAnotherAccount(name=name, other=other):
            print(
                f"❌ Nothing stored: {name} is already stored under account {other}. To replace it,"
                f" run: secret add {name} --account {other}",
                file=sys.stderr,
            )
            return 1
        case NotFound(name=name):
            print(
                f"❌ No secret named {name} in the login Keychain. Store it first with:"
                f" secret add {name}",
                file=sys.stderr,
            )
            return 1
        case KeychainError(message=message):
            print(f"❌ The Keychain refused: {message}", file=sys.stderr)
            return 1
        case _:
            assert_never(result)


def main(argv: list[str]) -> int:
    match read_request(argv):
        case Add(name=name, account=account):
            return report(add(name, account, read_value(name)))
        case Get(name=name):
            return report(get(name))
        case other:
            assert_never(other)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
