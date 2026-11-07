#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for features/secret/secret.py, which stores secrets in the login Keychain and reads them.

Run with: uv run features/secret/tests/test_secret.py

Each test runs the script with a `security` stub on PATH, so no test reads or writes the real
Keychain. The stub records the arguments of its last call separated by NUL bytes. It answers a
lookup of a value (-w) with STUB_VALUE, and a lookup of an item's attributes with an item stored
under STUB_ACCOUNT, each when that is set and with the real tool's not-found message otherwise.
STUB_FAIL makes every call fail the way a locked or refused Keychain does.
"""

from __future__ import annotations

import getpass
import importlib.util
import os
import pty
import select
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
    if [[ " $* " == *" -w "* && -n "${STUB_VALUE-}" ]]; then
      printf '%s\\n' "${STUB_VALUE}"
      exit 0
    fi
    if [[ " $* " != *" -w "* && -n "${STUB_ACCOUNT+set}" ]]; then
      echo 'keychain: "/Users/alice/Library/Keychains/login.keychain-db"'
      echo 'class: "genp"'
      echo 'attributes:'
      [[ -n "${STUB_ACCOUNT}" ]] && printf '    "acct"<blob>="%s"\\n' "${STUB_ACCOUNT}"
      printf '    "svce"<blob>="%s"\\n' "${@: -1}"
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
        # a tool that reads the item named some-tool whose account is the login email
        run = self.secret(
            "add", "some-tool", "--account", "alice@example.com", stdin="test-value-123\n"
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
                "some-tool",
                "-w",
                "test-value-123",
            ],
        )
        self.assertIn("alice@example.com", run.stderr)

    def test_an_account_security_could_misread_is_refused_before_security_runs(self) -> None:
        for account in ("-x", "a b", ""):
            with self.subTest(account=account):
                run = self.secret("add", "some-tool", "--account", account, stdin="v\n")
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

    def test_a_name_stored_under_another_account_is_refused_and_names_that_account(self) -> None:
        # Storing it anyway would leave two values under one name, and get would return either
        run = self.secret(
            "add", "some-tool", stdin="test-value-123\n", STUB_ACCOUNT="alice@example.com"
        )

        self.assertEqual(run.status, 1)
        self.assertEqual(run.security, ["find-generic-password", "-s", "some-tool"])
        self.assertIn("secret add some-tool --account alice@example.com", run.stderr)

    def test_a_name_stored_under_the_same_account_is_replaced(self) -> None:
        run = self.secret(
            "add", "codefresh", stdin="test-value-123\n", STUB_ACCOUNT=getpass.getuser()
        )

        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(run.security and run.security[0], "add-generic-password")

    def test_a_stored_item_whose_account_security_does_not_print_is_refused(self) -> None:
        run = self.secret("add", "codefresh", stdin="test-value-123\n", STUB_ACCOUNT="")

        self.assertEqual(run.status, 1)
        self.assertEqual(run.security and run.security[0], "find-generic-password")
        self.assertIn("--account", run.stderr)

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


class Prompt(SecretTest):
    def type_at_the_prompt(self, keys: bytes) -> tuple[int, str, bool]:
        """Runs `secret add example` in a terminal of its own, types `keys` once the hidden prompt
        shows, and returns the exit status, what the terminal showed and whether security ran."""
        with tempfile.TemporaryDirectory() as home:
            log = Path(home) / "security.log"
            env = {"HOME": home, "PATH": f"{self.stubs}:/usr/bin:/bin", "STUB_LOG": str(log)}
            pid, terminal = pty.fork()
            if pid == 0:
                os.execve(sys.executable, [sys.executable, str(SCRIPT), "add", "example"], env)
            shown = b""
            while b"(hidden)" not in shown:
                ready, _, _ = select.select([terminal], [], [], 10)
                self.assertTrue(ready, f"no prompt appeared: {shown!r}")
                shown += os.read(terminal, 1024)
            os.write(terminal, keys)
            while True:
                ready, _, _ = select.select([terminal], [], [], 10)
                try:
                    chunk = os.read(terminal, 1024) if ready else b""
                except OSError:  # the script exited and closed the terminal
                    chunk = b""
                if not chunk:
                    break
                shown += chunk
            _, status = os.waitpid(pid, 0)
            os.close(terminal)
            return os.waitstatus_to_exitcode(status), shown.decode(errors="replace"), log.exists()

    def test_ctrl_c_or_ctrl_d_at_the_prompt_stores_nothing_and_shows_no_traceback(self) -> None:
        for key in (b"\x03", b"\x04"):  # Ctrl-C, then Ctrl-D
            with self.subTest(key=key):
                status, shown, security_ran = self.type_at_the_prompt(key)

                self.assertEqual(status, 1, shown)
                self.assertIn("cancelled", shown)
                self.assertNotIn("Traceback", shown)
                self.assertFalse(security_ran)


class FoundValue(unittest.TestCase):
    def test_a_found_value_is_left_out_of_its_repr(self) -> None:
        spec = importlib.util.spec_from_file_location("secret", SCRIPT)
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        sys.modules["secret"] = module
        self.addCleanup(sys.modules.pop, "secret")
        spec.loader.exec_module(module)

        self.assertNotIn("example-test-value", repr(module.Found("example-test-value")))


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
