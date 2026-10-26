#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for cached_completion in tools/zsh/utils.zsh, which keeps a tool's generated zsh completion
in a file on fpath instead of generating and parsing it on every shell start.

Run with: uv run tools/zsh/tests/test_utils.py

Each test sources the real file in a bare zsh, with a fake tool on PATH that prints a completion
script and counts how often it runs, and with the cache in a temporary directory. File and link
times are set by hand, so each test chooses whether the tool looks newer than its cached completion.
"""

from __future__ import annotations

import os
import re
import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
UTILS = REPO / "tools" / "zsh" / "utils.zsh"

# Prints a completion script, or fails halfway through when FAKE_FAIL is set.
FAKE_TOOL = """#!/bin/sh
echo run >> "$FAKE_CALLS"
echo '#compdef fake'
if [ -n "$FAKE_FAIL" ]; then exit 1; fi
echo '_fake() { compadd from-the-cache; }'
"""

OLD = 1_700_000_000
NEW = OLD + 1000


@dataclass(frozen=True)
class Sourced:
    status: int
    registered: str
    fpath_first: str


class Sandbox:
    """A temporary home for the fake tool and the cache."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self.bin = root / "bin"
        self.cache = root / "cache"
        self.calls = root / "calls"
        self.bin.mkdir()
        self.tool = self.write_tool(root / "fake-1.0" / "fake")
        (self.bin / "fake").symlink_to(self.tool)
        self.set_link_time(OLD)

    def write_tool(self, path: Path) -> Path:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(FAKE_TOOL)
        path.chmod(0o755)
        os.utime(path, (OLD, OLD))
        return path

    def set_link_time(self, when: int) -> None:
        os.utime(self.bin / "fake", (when, when), follow_symlinks=False)

    @property
    def completion(self) -> Path:
        return self.cache / "zsh" / "completions" / "_fake"

    def runs(self) -> int:
        return len(self.calls.read_text().splitlines()) if self.calls.exists() else 0

    def source(self, *, fail: bool = False) -> Sourced:
        script = (
            f"source '{UTILS}'\n"
            "autoload -Uz compinit && compinit -D -u\n"
            "cached_completion fake fake completion zsh\n"
            'print -r -- "status=$?"\n'
            'print -r -- "registered=${_comps[fake]}"\n'
            'print -r -- "fpath_first=${fpath[1]}"\n'
        )
        env = {
            "HOME": os.environ["HOME"],
            "PATH": f"{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "TERM": "dumb",
            "COMPUTER_NAME": "Air",
            "XDG_CACHE_HOME": str(self.cache),
            "FAKE_CALLS": str(self.calls),
            **({"FAKE_FAIL": "1"} if fail else {}),
        }
        result = subprocess.run(
            ["zsh", "-f", "-c", script], env=env, capture_output=True, text=True, check=True
        )
        values = dict(re.findall(r"^(\w+)=(.*)$", result.stdout, re.MULTILINE))
        return Sourced(int(values["status"]), values["registered"], values["fpath_first"])


class CachedCompletion(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.sandbox = Sandbox(Path(directory.name))

    def cache_written_at(self, when: int) -> None:
        self.sandbox.source()
        os.utime(self.sandbox.completion, (when, when))

    def test_the_first_shell_writes_the_completion_and_registers_it(self) -> None:
        sourced = self.sandbox.source()
        self.assertEqual(sourced.status, 0)
        self.assertEqual(self.sandbox.runs(), 1)
        self.assertIn("compadd from-the-cache", self.sandbox.completion.read_text())
        self.assertEqual(sourced.registered, "_fake")
        self.assertEqual(sourced.fpath_first, str(self.sandbox.completion.parent))

    def test_later_shells_use_the_cache_without_running_the_tool(self) -> None:
        self.cache_written_at(NEW)
        sourced = self.sandbox.source()
        self.assertEqual(self.sandbox.runs(), 1)
        self.assertEqual(sourced.registered, "_fake")

    def test_a_tool_replaced_in_place_is_asked_again(self) -> None:
        # uv self update rewrites the binary where it is
        self.cache_written_at(OLD)
        os.utime(self.sandbox.tool, (NEW, NEW))
        self.sandbox.source()
        self.assertEqual(self.sandbox.runs(), 2)

    def test_a_link_moved_to_a_new_version_is_asked_again(self) -> None:
        # A brew cask upgrade points the link at a new folder whose binary keeps its older time
        self.cache_written_at(OLD + 10)
        upgraded = self.sandbox.write_tool(self.sandbox.root / "fake-2.0" / "fake")
        (self.sandbox.bin / "fake").unlink()
        (self.sandbox.bin / "fake").symlink_to(upgraded)
        self.sandbox.set_link_time(NEW)
        self.sandbox.source()
        self.assertEqual(self.sandbox.runs(), 2)

    def test_a_failing_tool_leaves_no_completion_and_registers_nothing(self) -> None:
        sourced = self.sandbox.source(fail=True)
        self.assertNotEqual(sourced.status, 0)
        self.assertFalse(self.sandbox.completion.exists())
        self.assertEqual(list(self.sandbox.completion.parent.glob("*")), [])
        self.assertEqual(sourced.registered, "")

    def test_a_failing_tool_keeps_the_completion_it_had(self) -> None:
        self.cache_written_at(OLD)
        os.utime(self.sandbox.tool, (NEW, NEW))
        sourced = self.sandbox.source(fail=True)
        self.assertIn("compadd from-the-cache", self.sandbox.completion.read_text())
        self.assertEqual(sourced.registered, "_fake")


class EveryShellZsh(unittest.TestCase):
    # A completion generated with eval runs a subprocess and parses its output on every shell start
    GENERATED = re.compile(r'eval "\$\([^)]*completion')

    def test_no_tool_generates_its_completion_at_shell_start(self) -> None:
        files = sorted((REPO / "tools").glob("*/shell.zsh")) + sorted(
            (REPO / "features").glob("*/shell.zsh")
        )
        self.assertNotEqual(files, [])
        offenders = [
            f"{path.relative_to(REPO)}:{number}"
            for path in files
            for number, line in enumerate(path.read_text().splitlines(), start=1)
            if self.GENERATED.search(line) and not line.lstrip().startswith("#")
        ]
        self.assertEqual(offenders, [], "use cached_completion from tools/zsh/utils.zsh instead")


if __name__ == "__main__":
    unittest.main()
