#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/claude/shell.zsh's cc-vertex, which starts a Claude Code session on Vertex AI.

Run with: uv run tools/claude/tests/test_shell.py

The test sources the file in a bare zsh on the work laptop, with `is_work` and `error` stubbed, and
calls `cc` and `cc-vertex` in turn. The real cc.bash runs, and stubs on PATH stand in for `uv`,
which runs the work logins, and `claude`, which records its arguments.
"""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent.parent
SHELL_ZSH = REPO / "tools" / "claude" / "shell.zsh"

CLAUDE_STUB = """#!/bin/bash
for arg in "$@"; do printf '%s\\n' "$arg"; done > "${CLAUDE_LOG}"
"""


def claude_started_by(command: str, stubs: Path) -> list[str]:
    """What the `claude` stub recorded when `command` ran in a zsh that sourced shell.zsh."""
    with tempfile.TemporaryDirectory() as folder:
        log = Path(folder) / "claude.log"
        env = {
            "HOME": folder,
            "PATH": f"{stubs}:/usr/bin:/bin:/usr/sbin:/sbin",
            "DOTFILES": str(REPO),
            "COMPUTER": "work",
            "CLAUDE_LOG": str(log),
            "PRIVATE_VERTEX_PROJECT": "example-vertex-1234",
            # Set, even empty, so cc.bash keeps what it inherited and names no related repos
            "PRIVATE_RELATED_REPOS": "",
        }
        script = (
            "is_work() { return 0 }\n"
            'error() { print -u2 -- "error: $*" }\n'
            f"source '{SHELL_ZSH}'\n"
            f"{command}\n"
        )
        result = subprocess.run(
            ["zsh", "-f", "-c", script], cwd=folder, env=env, capture_output=True, text=True
        )
        if not log.exists():
            raise AssertionError(f"{command!r} never started claude:\n{result.stderr}")
        return log.read_text().splitlines()


class CcVertex(unittest.TestCase):
    def test_starts_claude_as_cc_does_but_on_vertex(self) -> None:
        # A session on Vertex AI gets the same permission mode and related repos as `cc`, so
        # switching to it when the subscription's limit is reached keeps the same safety checks.
        # Vertex is chosen with --settings, which outranks the switch in the user settings file.
        with tempfile.TemporaryDirectory() as folder:
            stubs = Path(folder)
            (stubs / "uv").write_text("#!/bin/bash\n")
            (stubs / "claude").write_text(CLAUDE_STUB)
            for stub in stubs.iterdir():
                stub.chmod(0o755)
            cc = claude_started_by("cc --resume abc", stubs)
            vertex = claude_started_by("cc-vertex --resume abc", stubs)
        at = vertex.index("--settings")
        self.assertEqual(json.loads(vertex[at + 1]), {"env": {"CLAUDE_CODE_USE_VERTEX": "1"}})
        self.assertEqual(vertex[:at] + vertex[at + 2 :], cc)
        self.assertIn("--resume", cc)


if __name__ == "__main__":
    unittest.main()
