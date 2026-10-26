#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/zsh/utils.zsh: cached_completion, which keeps a tool's generated zsh completion in
a file on fpath instead of generating and parsing it on every shell start; load_brew_shellenv, which
caches `brew shellenv` the same way; shell_config_files, which lists the files .zshrc sources; and
the TEXT_* colors.

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


def zsh(script: str, env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["zsh", "-f", "-c", f"source '{UTILS}'\n{script}"],
        env={"HOME": os.environ["HOME"], "TERM": "dumb", "COMPUTER_NAME": "Air", **env},
        capture_output=True,
        text=True,
        check=True,
    )


# Prints a zsh shellenv, or fails when FAKE_FAIL is set
FAKE_BREW = """#!/bin/sh
echo run >> "$FAKE_CALLS"
if [ -n "$FAKE_FAIL" ]; then exit 1; fi
[ "$1 $2" = "shellenv zsh" ] || exit 2
echo 'export HOMEBREW_PREFIX="/fake/homebrew";'
"""


class LoadBrewShellenv(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.brew = self.root / "brew"
        self.brew.write_text(FAKE_BREW)
        self.brew.chmod(0o755)
        self.cache = self.root / "cache" / "zsh" / "brew-shellenv.zsh"
        self.calls = self.root / "calls"

    def load(self, *, fail: bool = False) -> tuple[int, str]:
        result = zsh(
            f"load_brew_shellenv '{self.brew}'\n"
            'print -r -- "status=$? prefix=${HOMEBREW_PREFIX-<unset>}"',
            {
                "PATH": "/usr/bin:/bin",
                "XDG_CACHE_HOME": str(self.root / "cache"),
                "FAKE_CALLS": str(self.calls),
                **({"FAKE_FAIL": "1"} if fail else {}),
            },
        )
        loaded = re.fullmatch(r"status=(\d+) prefix=(.*)", result.stdout.strip())
        assert loaded is not None, f"unexpected output: {result.stdout!r}"
        return int(loaded[1]), loaded[2]

    def runs(self) -> int:
        return len(self.calls.read_text().splitlines()) if self.calls.exists() else 0

    def test_the_first_shell_runs_brew_and_keeps_its_output(self) -> None:
        self.assertEqual(self.load(), (0, "/fake/homebrew"))
        self.assertEqual(self.runs(), 1)
        self.assertIn("HOMEBREW_PREFIX", self.cache.read_text())

    def test_later_shells_apply_the_cache_without_running_brew(self) -> None:
        self.load()
        self.assertEqual(self.load(), (0, "/fake/homebrew"))
        self.assertEqual(self.runs(), 1)

    def test_a_failing_brew_leaves_no_cache_and_sets_nothing(self) -> None:
        status, prefix = self.load(fail=True)
        self.assertNotEqual(status, 0)
        self.assertEqual(prefix, "<unset>")
        self.assertEqual(list(self.cache.parent.glob("*")), [])

    def test_u_clears_the_same_cache_the_shell_writes(self) -> None:
        # The next shell after `u` upgrades Homebrew writes the cache again
        cache = '"${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/brew-shellenv.zsh"'
        self.assertIn(cache, UTILS.read_text())
        self.assertIn(f"rm -f {cache}", (REPO / "tools" / "homebrew" / "update.bash").read_text())


class ShellConfigFiles(unittest.TestCase):
    def test_it_lists_the_same_files_in_the_same_order_as_find(self) -> None:
        dotfiles = Path(os.environ["HOME"]) / "Repos" / "ooloth" / "dotfiles"
        env = {"PATH": "/usr/bin:/bin", "LANG": os.environ.get("LANG", "en_CA.UTF-8")}
        found = subprocess.run(
            [
                "bash",
                "-c",
                'find "$1/features" "$1/tools" \\( -name @new -o -name @archive \\) -prune -o '
                "-name shell.zsh -print | sort",
                "_",
                str(dotfiles),
            ],
            env=env,
            capture_output=True,
            text=True,
            check=True,
        ).stdout.splitlines()
        listed = zsh("shell_config_files; print -rl -- $reply", env).stdout.splitlines()
        self.assertGreater(len(found), 0)
        self.assertEqual(listed, found)

    def test_every_shell_file_sits_where_the_glob_looks(self) -> None:
        # The glob looks only at tools/*/shell.zsh and features/*/shell.zsh, so a deeper one would
        # silently stop being sourced
        deeper = [
            str(path.relative_to(REPO))
            for top in ("tools", "features")
            for path in (REPO / top).rglob("*.zsh")
            if (path.name == "shell.zsh" or path.parent.name == "shell")
            and len(path.relative_to(REPO / top).parts) != 2
            and not {"@new", "@archive", "wip"} & set(path.parts)
        ]
        self.assertEqual(deeper, [])


class Colors(unittest.TestCase):
    EXPECTED = {
        "TEXT_BLACK": "\x1b[30m",
        "TEXT_RED": "\x1b[31m",
        "TEXT_GREEN": "\x1b[32m",
        "TEXT_YELLOW": "\x1b[33m",
        "TEXT_BLUE": "\x1b[34m",
        "TEXT_MAGENTA": "\x1b[35m",
        "TEXT_CYAN": "\x1b[36m",
        "TEXT_WHITE": "\x1b[37m",
        "TEXT_BRIGHT": "\x1b[1m",
        "TEXT_NORMAL": "\x1b(B\x1b[m",
        "TEXT_BLINK": "\x1b[5m",
        "TEXT_REVERSE": "\x1b[7m",
        "TEXT_UNDERLINE": "\x1b[4m",
    }

    def test_colors_are_what_tput_prints_and_need_no_tput(self) -> None:
        # Without /usr/bin on PATH, tput can't run, so only codes written in the file come through
        script = "".join(
            f'print -rn -- "${{{name}}}"; print -rn -- "|"\n' for name in self.EXPECTED
        )
        values = zsh(script, {"PATH": "/bin", "TERM": "xterm-256color"}).stdout.split("|")[:-1]
        self.assertEqual(dict(zip(self.EXPECTED, values, strict=True)), self.EXPECTED)


if __name__ == "__main__":
    unittest.main()
