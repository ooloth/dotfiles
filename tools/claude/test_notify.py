#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/claude/notify.bash, the Claude Code Notification hook.

Run with: uv run tools/claude/test_notify.py

Each test feeds the hook an input on stdin and runs it under macOS's own bash with a PATH holding
only stub posters, a link to the real jq, and the system directories. The stubs record the
arguments they were given, so no test puts a card on screen. A PATH that included all of
/opt/homebrew/bin would reach the real terminal-notifier.

terminal-notifier drops one leading backslash from a value and refuses a message that starts with
'-', '[', '(', '{' or a quote, so the hook prefixes every message and subtitle with a backslash.
osascript reads an argument starting with '-' as an option unless '--' comes first. The stubs
accept anything, so these tests check the hook sends those forms. Neither rule can be checked
without the real tools, which only the manual check in the commit runs.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

from hypothesis import given, settings
from hypothesis import strategies as st

HOOK = Path(__file__).resolve().parent / "notify.bash"

# Records each argument followed by a NUL, so arguments holding newlines stay intact.
STUB = """#!/bin/bash
printf '%s\\0' "$@" > "${STUB_LOG_DIR}/$(basename "$0")"
if [[ -n "${STUB_STDERR:-}" ]]; then printf '%s\\n' "${STUB_STDERR}" >&2; fi
exit "${STUB_EXIT:-0}"
"""

# Argv cannot carry NUL, and JSON cannot carry lone surrogates.
TEXT = st.text(
    alphabet=st.characters(blacklist_categories=("Cs",), blacklist_characters="\x00"), min_size=1
)


@dataclass(frozen=True)
class Run:
    status: int
    stderr: str
    terminal_notifier: list[str] | None
    osascript: list[str] | None


class Sandbox:
    """A bin directory of stub posters and a folder for the hook to run in."""

    def __init__(self, root: Path, *, terminal_notifier: bool = True) -> None:
        self.bin = root / "bin"
        self.bin.mkdir()
        self.logs = root / "logs"
        self.logs.mkdir()
        self.folder = root / "my project"
        self.folder.mkdir()
        posters = ["osascript", "terminal-notifier"] if terminal_notifier else ["osascript"]
        for name in posters:
            stub = self.bin / name
            stub.write_text(STUB)
            stub.chmod(0o755)
        jq = shutil.which("jq")
        assert jq is not None, "jq must be installed to run these tests"
        (self.bin / "jq").symlink_to(jq)

    def run(self, stdin: str, *, stub_exit: int = 0, stub_stderr: str = "") -> Run:
        env = {
            "HOME": os.environ.get("HOME", "/tmp"),
            "PATH": f"{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "STUB_LOG_DIR": str(self.logs),
            "STUB_EXIT": str(stub_exit),
            "STUB_STDERR": stub_stderr,
        }
        for log in self.logs.iterdir():
            log.unlink()
        result = subprocess.run(
            ["/bin/bash", str(HOOK)],
            input=stdin,
            env=env,
            cwd=self.folder,
            capture_output=True,
            text=True,
            check=False,
        )
        return Run(
            result.returncode,
            result.stderr,
            self._recorded("terminal-notifier"),
            self._recorded("osascript"),
        )

    def _recorded(self, name: str) -> list[str] | None:
        log = self.logs / name
        if not log.exists():
            return None
        # Bytes, because read_text() would turn a "\r" in an argument into "\n".
        return log.read_bytes().decode().split("\0")[:-1]


def flag(args: list[str] | None, name: str) -> str:
    assert args is not None, "terminal-notifier was not called"
    return args[args.index(name) + 1]


def shown(value: str) -> str:
    """What terminal-notifier is sent so that it shows `value`."""
    return "\\" + value


def hook_input(**fields: str) -> str:
    return json.dumps({"hook_event_name": "Notification", **fields})


class NotifyTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.sandbox = Sandbox(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_a_message_and_cwd_become_a_terminal_notifier_card_that_activates_ghostty(self) -> None:
        run = self.sandbox.run(
            hook_input(message="Claude needs your permission to use Bash", cwd="/x/dotfiles")
        )
        self.assertEqual(run.status, 0, run.stderr)
        self.assertEqual(
            run.terminal_notifier,
            [
                "-title", "Claude Code",
                "-subtitle", shown("dotfiles"),
                "-message", shown("Claude needs your permission to use Bash"),
                "-group", "claude-code:/x/dotfiles",
                "-activate", "com.mitchellh.ghostty",
            ],
        )  # fmt: skip
        self.assertIsNone(run.osascript)

    def test_input_that_is_not_json_gets_the_default_message(self) -> None:
        run = self.sandbox.run("not json")
        self.assertEqual(flag(run.terminal_notifier, "-message"), shown("Needs your attention"))

    def test_input_with_no_message_gets_the_default_message(self) -> None:
        run = self.sandbox.run(hook_input(cwd="/x/dotfiles"))
        self.assertEqual(flag(run.terminal_notifier, "-message"), shown("Needs your attention"))

    def test_input_with_no_cwd_uses_the_folder_the_hook_runs_in(self) -> None:
        run = self.sandbox.run(hook_input(message="hi"))
        self.assertEqual(flag(run.terminal_notifier, "-subtitle"), shown("my project"))
        self.assertEqual(
            flag(run.terminal_notifier, "-group"),
            f"claude-code:{self.sandbox.folder.resolve()}",
        )

    def test_a_cwd_with_a_trailing_slash_still_names_its_folder(self) -> None:
        run = self.sandbox.run(hook_input(message="hi", cwd="/x/dotfiles/"))
        self.assertEqual(flag(run.terminal_notifier, "-subtitle"), shown("dotfiles"))

    def test_a_refused_post_falls_back_to_osascript_and_reports_why(self) -> None:
        run = self.sandbox.run(
            hook_input(message="hi", cwd="/x/dotfiles"),
            stub_exit=3,
            stub_stderr="Notifications are turned off for this application.",
        )
        self.assertIsNotNone(run.terminal_notifier)
        self.assertEqual(run.osascript[-2:] if run.osascript else None, ["hi", "dotfiles"])
        self.assertIn("Notifications are turned off for this application.", run.stderr)


class NotifyWithoutTerminalNotifierTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.sandbox = Sandbox(Path(self._tmp.name), terminal_notifier=False)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_osascript_gets_the_message_and_folder_as_arguments(self) -> None:
        run = self.sandbox.run(hook_input(message="hi", cwd="/x/dotfiles"))
        self.assertEqual(run.status, 0, run.stderr)
        self.assertIsNone(run.terminal_notifier)
        assert run.osascript is not None
        self.assertEqual(run.osascript[-3:], ["--", "hi", "dotfiles"])
        script = "\n".join(run.osascript[:-3])
        self.assertIn("on run argv", script)
        self.assertNotIn("hi", script)


class NotifyPropertyTest(unittest.TestCase):
    @settings(max_examples=50, deadline=None)
    @given(message=TEXT)
    def test_any_message_reaches_both_posters_unchanged(self, message: str) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            sandbox = Sandbox(Path(tmp))
            run = sandbox.run(hook_input(message=message, cwd="/x/dotfiles"), stub_exit=1)
            self.assertEqual(flag(run.terminal_notifier, "-message"), shown(message))
            assert run.osascript is not None
            self.assertEqual(run.osascript[-3:-1], ["--", message])

    @settings(max_examples=50, deadline=None)
    @given(cwd=TEXT)
    def test_any_cwd_gives_a_claude_group_that_hub_never_claims(self, cwd: str) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            sandbox = Sandbox(Path(tmp))
            group = flag(sandbox.run(hook_input(message="hi", cwd=cwd)).terminal_notifier, "-group")
            self.assertTrue(group.startswith("claude-code:"), group)
            self.assertFalse(group.startswith("hub-"), group)


if __name__ == "__main__":
    unittest.main()
