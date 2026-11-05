#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for activate_venv in tools/zsh/config/hooks.zsh, which activates the nearest Python virtual
environment when zsh starts and on every cd, for the Python search paths the shell leaves unset, and
for warn_secret_in_history, which keeps lines holding a literal secret out of the history file.

Run with: uv run tools/zsh/tests/test_hooks.py

Each test builds folders in a temporary directory, with fake activate scripts that set VIRTUAL_ENV,
then starts a bare zsh in one of them, sources the real file, and prints VIRTUAL_ENV. A few tests
cd somewhere else afterwards, which runs the chpwd hook.
"""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
UTILS = REPO / "tools" / "zsh" / "utils.zsh"
HOOKS = REPO / "tools" / "zsh" / "config" / "hooks.zsh"
TOOLS = REPO / "tools" / "zsh" / "config" / "tools.zsh"


class ActivateVenv(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name).resolve()

    def venv(self, path: str) -> Path:
        venv = self.root / path
        (venv / "bin").mkdir(parents=True)
        (venv / "bin" / "activate").write_text(
            f'export VIRTUAL_ENV="{venv}"\ndeactivate() {{ unset -f deactivate; }}\n'
        )
        return venv

    def folder(self, path: str) -> Path:
        folder = self.root / path
        folder.mkdir(parents=True, exist_ok=True)
        return folder

    def virtual_env(self, start: Path, then: Path | None = None) -> str:
        script = f"source '{UTILS}'\nsource '{HOOKS}'\n"
        if then is not None:
            script += f"cd '{then}'\n"
        script += 'print -r -- "${VIRTUAL_ENV-<none>}"\n'
        result = subprocess.run(
            ["zsh", "-f", "-c", script],
            cwd=start,
            env={
                "HOME": os.environ["HOME"],
                "PATH": "/usr/bin:/bin",
                "TERM": "dumb",
                "COMPUTER_NAME": "Air",
            },
            capture_output=True,
            text=True,
            check=True,
            timeout=10,
        )
        return result.stdout.strip()

    def test_a_venv_in_the_starting_folder_is_activated(self) -> None:
        venv = self.venv("project/.venv")
        self.assertEqual(self.virtual_env(self.root / "project"), str(venv))

    def test_the_nearest_venv_above_a_deep_folder_is_activated(self) -> None:
        self.venv("project/.venv")
        nearer = self.venv("project/packages/app/.venv")
        self.assertEqual(
            self.virtual_env(self.folder("project/packages/app/src/module")), str(nearer)
        )

    def test_a_folder_named_venv_counts_when_there_is_no_dot_venv(self) -> None:
        venv = self.venv("project/venv")
        self.assertEqual(self.virtual_env(self.folder("project/src")), str(venv))

    def test_dot_venv_wins_over_venv_in_the_same_folder(self) -> None:
        dot_venv = self.venv("project/.venv")
        self.venv("project/venv")
        self.assertEqual(self.virtual_env(self.root / "project"), str(dot_venv))

    def test_no_venv_anywhere_above_leaves_none_active(self) -> None:
        self.assertEqual(self.virtual_env(self.folder("plain/deep/folder")), "<none>")

    def test_leaving_a_project_deactivates_its_venv(self) -> None:
        self.venv("project/.venv")
        self.assertEqual(
            self.virtual_env(self.root / "project", then=self.folder("elsewhere")), "<none>"
        )

    def test_moving_into_another_project_activates_its_venv(self) -> None:
        self.venv("one/.venv")
        two = self.venv("two/.venv")
        self.assertEqual(self.virtual_env(self.root / "one", then=self.root / "two"), str(two))


class PythonSearchPaths(unittest.TestCase):
    # Every Python process started from the shell reads PYTHONPATH, so a project folder exported
    # there could shadow the modules of programs that have nothing to do with the project
    def test_a_python_project_gets_no_pythonpath_or_mypypath(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        root = Path(directory.name).resolve()
        home = root / "home"
        home.mkdir()
        project = root / "project"
        project.mkdir()
        (project / "pyproject.toml").write_text("")

        # tools.zsh also sources every tool's shell.zsh, so a variable any of them sets shows here
        script = (
            f"source '{UTILS}'\nsource '{TOOLS}'\nsource '{HOOKS}'\n"
            f"cd /\ncd '{project}'\n"
            'print -r -- "${PYTHONPATH-<none>} ${MYPYPATH-<none>}"\n'
        )
        result = subprocess.run(
            ["zsh", "-f", "-c", script],
            cwd=project,
            env={
                "HOME": str(home),
                "PATH": "/usr/bin:/bin",
                "TERM": "dumb",
                "COMPUTER": "Air",
                "DOTFILES": str(REPO),
            },
            capture_output=True,
            text=True,
            check=True,
            timeout=30,
        )
        self.assertEqual(result.stdout.strip(), "<none> <none>")


# Every way a secret was seen or could plausibly be typed after each marker. Flags take a space or
# `=`, a header takes a space, and an assignment takes `=`, with or without `export`.
FLAG_MARKERS = ("--api-key", "--password", "--token")
ASSIGNMENTS = ("JIRA_API_TOKEN", "EGNYTE_CLIENT_SECRET", "AWS_SECRET_ACCESS_KEY", "DB_PASSWORD")
QUOTES = ("", '"', "'")
LITERALS = ("abc123", "ATATT3xFf-Zx_9")
REFERENCES = ("$TOKEN", "${TOKEN}", "$(secret get codefresh)")


def secret_lines(values: tuple[str, ...]) -> list[str]:
    lines = []
    for quote in QUOTES:
        for value in values:
            quoted = f"{quote}{value}{quote}"
            for marker in FLAG_MARKERS:
                lines.append(f"tool {marker} {quoted} --verbose")
                lines.append(f"tool {marker}={quoted}")
            lines.append(f'curl -H "Authorization: Bearer {value}" https://example.com')
            for name in ASSIGNMENTS:
                lines.append(f"{name}={quoted}")
                lines.append(f"export {name}={quoted}")
    return lines


def history_verdicts(lines: list[str]) -> list[tuple[int, str]]:
    """Run the registered zshaddhistory hooks on each line, as zsh does, and return each line's
    status and what the hooks printed to stderr."""
    script = (
        f"source '{UTILS}'\nsource '{HOOKS}'\n"
        'for line in "$@"; do\n'
        "  err=$({ for hook in $zshaddhistory_functions; do $hook \"$line\"$'\\n'"
        ' || { print -r -- "<status:$?>"; break; }; done } 2>&1)\n'
        '  print -r -- "${err:-<status:0>}"\n'
        "  print -r -- '<end>'\n"
        "done\n"
    )
    result = subprocess.run(
        ["zsh", "-f", "-c", script, "zsh", *lines],
        env={"HOME": tempfile.gettempdir(), "PATH": "/usr/bin:/bin", "TERM": "dumb"},
        capture_output=True,
        text=True,
        check=True,
        timeout=30,
    )
    verdicts = []
    for block in result.stdout.split("<end>\n")[:-1]:
        status = int(block.rsplit("<status:", 1)[1].split(">", 1)[0])
        verdicts.append((status, block.rsplit("<status:", 1)[0].strip()))
    return verdicts


class SecretsStayOutOfHistory(unittest.TestCase):
    def test_a_literal_after_any_marker_is_held_back_with_the_safe_way_named(self) -> None:
        lines = secret_lines(LITERALS)
        for line, (status, warning) in zip(lines, history_verdicts(lines), strict=True):
            with self.subTest(line=line):
                # 2 keeps the line for up-arrow in this shell but out of the history file
                self.assertEqual(status, 2)
                self.assertIn("secret add", warning)
                self.assertIn("secret get", warning)

    def test_a_reference_after_any_marker_is_saved_without_a_warning(self) -> None:
        lines = secret_lines(REFERENCES)
        for line, (status, warning) in zip(lines, history_verdicts(lines), strict=True):
            with self.subTest(line=line):
                self.assertEqual((status, warning), (0, ""))

    def test_lines_without_a_marker_are_saved_without_a_warning(self) -> None:
        lines = [
            "git status",
            "kubectl get pods -n example -o wide",
            "tool --password-file=secrets.txt",
            "echo TOKEN=abc",
            "ls ~/.ssh",
        ]
        self.assertEqual(history_verdicts(lines), [(0, "")] * len(lines))


class SecretsStayOutOfTheHistoryFile(unittest.TestCase):
    """Runs a real interactive zsh on a pseudo-terminal, because zsh records history only for lines
    it reads interactively, and only that shows the hook's status keeps a line out of the file."""

    def test_the_file_keeps_references_and_drops_literals(self) -> None:
        import pty
        import select
        import time

        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        root = Path(directory.name)
        history = root / "history"
        (root / ".zshrc").write_text(
            f"source '{UTILS}'\nsource '{HOOKS}'\n"
            f"HISTFILE='{history}'\nSAVEHIST=100\nHISTSIZE=100\nPS1='> '\n"
        )
        lines = [
            "echo kept",
            "true --api-key abc123",
            'true --api-key "$(true)"',
            "export EXAMPLE_TOKEN=abc123",
            "exit",
        ]

        leader, follower = pty.openpty()
        shell = subprocess.Popen(
            ["zsh", "-i"],
            stdin=follower,
            stdout=follower,
            stderr=follower,
            env={"HOME": str(root), "ZDOTDIR": str(root), "PATH": "/usr/bin:/bin", "TERM": "dumb"},
            cwd=root,
        )
        os.close(follower)
        self.addCleanup(os.close, leader)

        def drain(seconds: float) -> None:
            deadline = time.monotonic() + seconds
            while time.monotonic() < deadline:
                ready, _, _ = select.select([leader], [], [], 0.05)
                if ready:
                    try:
                        os.read(leader, 4096)
                    except OSError:
                        return

        drain(1.0)
        for line in lines:
            os.write(leader, f"{line}\n".encode())
            drain(0.3)
        shell.wait(timeout=10)

        self.assertEqual(
            history.read_text().splitlines(), ["echo kept", 'true --api-key "$(true)"', "exit"]
        )


if __name__ == "__main__":
    unittest.main()
