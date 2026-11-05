#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for features/secret/secret.py, which stores secrets in the login Keychain and reads them.

Run with: uv run features/secret/tests/test_secret.py

Each test runs the script with a `security` stub on PATH, so no test reads or writes the real
Keychain. The stub records its arguments separated by NUL bytes, and answers a lookup with
STUB_VALUE when that is set and with the real tool's not-found message otherwise. STUB_FAIL makes
every call fail the way a locked or refused Keychain does.
"""

from __future__ import annotations

import getpass
import subprocess
import sys
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "secret.py"

STUB = """#!/bin/bash
for arg in "$@"; do printf '%s\\0' "$arg"; done > "${STUB_LOG}"
if [[ -n "${STUB_FAIL-}" ]]; then
  echo 'security: SecKeychainItemCreateFromContent: User interaction is not allowed.' >&2
  exit 51
fi
case "$1" in
  find-generic-password)
    if [[ -n "${STUB_VALUE-}" ]]; then
      printf '%s\\n' "${STUB_VALUE}"
      exit 0
    fi
    echo 'security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain.' >&2
    exit 44
    ;;
  add-generic-password)
    exit 0
    ;;
esac
exit 1
"""


@dataclass(frozen=True)
class Run:
    status: int
    stdout: str
    stderr: str
    security: list[str] | None  # the arguments security got, or None when it never ran


class SecretTest(unittest.TestCase):
    stubs: Path
    _folder: tempfile.TemporaryDirectory

    @classmethod
    def setUpClass(cls) -> None:
        cls._folder = tempfile.TemporaryDirectory()
        cls.stubs = Path(cls._folder.name) / "stubs"
        cls.stubs.mkdir()
        stub = cls.stubs / "security"
        stub.write_text(STUB)
        stub.chmod(0o755)
        cls.stubs.chmod(0o555)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.stubs.chmod(0o755)
        cls._folder.cleanup()

    def secret(self, *args: str, stdin: str = "", **env: str) -> Run:
        with tempfile.TemporaryDirectory() as home:
            log = Path(home) / "security.log"
            result = subprocess.run(
                [sys.executable, str(SCRIPT), *args],
                input=stdin,
                capture_output=True,
                text=True,
                check=False,
                env={"HOME": home, "PATH": f"{self.stubs}:/usr/bin:/bin", "STUB_LOG": str(log)}
                | env,
            )
            security = log.read_bytes().decode().split("\0")[:-1] if log.exists() else None
        return Run(result.returncode, result.stdout, result.stderr, security)


class Add(SecretTest):
    def test_the_value_goes_to_the_login_keychain_under_the_name_and_this_user(self) -> None:
        run = self.secret("add", "codefresh", stdin="test-value-123\n")

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(
            run.security,
            [
                "add-generic-password",
                "-U",
                "-a",
                getpass.getuser(),
                "-s",
                "codefresh",
                "-w",
                "test-value-123",
            ],
        )

    def test_a_value_longer_than_the_security_prompts_limit_is_stored_whole(self) -> None:
        # security's own prompt keeps only 128 characters, which cut an Atlassian token short
        value = "A" * 300
        run = self.secret("add", "jira", stdin=f"{value}\n")

        self.assertEqual(run.security and run.security[-1], value)
        self.assertIn("300 characters", run.stderr)

    def test_an_account_stores_the_item_another_tool_looks_up(self) -> None:
        # jira-cli reads the item named jira-cli whose account is the login email
        run = self.secret(
            "add", "jira-cli", "--account", "alice@example.com", stdin="test-value-123\n"
        )

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(
            run.security,
            [
                "add-generic-password",
                "-U",
                "-a",
                "alice@example.com",
                "-s",
                "jira-cli",
                "-w",
                "test-value-123",
            ],
        )
        self.assertIn("alice@example.com", run.stderr)

    def test_an_account_security_could_misread_is_refused_before_security_runs(self) -> None:
        for account in ("-x", "a b", ""):
            with self.subTest(account=account):
                run = self.secret("add", "jira-cli", "--account", account, stdin="v\n")
                self.assertEqual(run.status, 2, run.stderr)
                self.assertIsNone(run.security)

    def test_the_value_is_never_printed(self) -> None:
        run = self.secret("add", "codefresh", stdin="test-value-123\n")

        self.assertNotIn("test-value-123", run.stdout + run.stderr)

    def test_an_empty_value_is_refused_before_security_runs(self) -> None:
        run = self.secret("add", "codefresh", stdin="\n")

        self.assertEqual(run.status, 1)
        self.assertIsNone(run.security)
        self.assertIn("empty", run.stderr)

    def test_a_refused_keychain_write_says_what_security_said(self) -> None:
        run = self.secret("add", "codefresh", stdin="test-value-123\n", STUB_FAIL="1")

        self.assertEqual(run.status, 1)
        self.assertIn("User interaction is not allowed", run.stderr)


class Get(SecretTest):
    def test_a_stored_value_is_printed_for_use_in_a_command_substitution(self) -> None:
        run = self.secret("get", "codefresh", STUB_VALUE="test-value-123")

        self.assertEqual((run.status, run.stdout), (0, "test-value-123\n"), run.stderr)
        self.assertEqual(run.security, ["find-generic-password", "-s", "codefresh", "-w"])

    def test_a_missing_name_prints_nothing_and_says_to_store_it_first(self) -> None:
        run = self.secret("get", "missing")

        self.assertEqual((run.status, run.stdout), (1, ""))
        self.assertIn("secret add missing", run.stderr)

    def test_a_refused_keychain_read_prints_nothing_and_says_what_security_said(self) -> None:
        run = self.secret("get", "codefresh", STUB_FAIL="1")

        self.assertEqual((run.status, run.stdout), (1, ""))
        self.assertIn("User interaction is not allowed", run.stderr)


class Arguments(SecretTest):
    def test_a_name_security_could_misread_is_refused_before_security_runs(self) -> None:
        for name in ("has space", "-s", "", "a/b"):
            with self.subTest(name=name):
                run = self.secret("get", name)
                self.assertEqual(run.status, 2, run.stderr)
                self.assertIsNone(run.security)

    def test_help_runs_nothing(self) -> None:
        run = self.secret("--help")

        self.assertEqual(run.status, 0, run.stderr)
        self.assertIsNone(run.security)
        self.assertIn("secret add", run.stdout)


if __name__ == "__main__":
    unittest.main()
