#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/docker/shell.zsh, the Docker shortcuts in an interactive shell.

Run with: uv run tools/docker/tests/test_shell.py

Each test sources the file in a bare zsh with `have` and `is_work` stubbed and `docker` defined as a
function that records its arguments, then runs one shortcut. No test reaches the real Docker.
"""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

SHELL_ZSH = Path(__file__).resolve().parent.parent / "shell.zsh"


def docker_calls(shortcut: str) -> list[str]:
    with tempfile.TemporaryDirectory() as tmp:
        log = Path(tmp) / "docker.log"
        script = (
            "have() { return 0 }\n"
            "is_work() { return 1 }\n"
            f"source '{SHELL_ZSH}'\n"
            f"docker() {{ print -r -- \"$*\" >> '{log}' }}\n"
            f"{shortcut}\n"
        )
        subprocess.run(["zsh", "-f", "-c", script], capture_output=True, text=True, check=True)
        return log.read_text().splitlines()


class PruneTest(unittest.TestCase):
    def test_dp_shows_disk_use_around_a_prune_of_things_older_than_a_week(self) -> None:
        self.assertEqual(
            docker_calls("dp"),
            ["system df", "system prune --filter until=168h", "system df"],
        )

    def test_dpa_also_prunes_unused_images_older_than_thirty_days(self) -> None:
        self.assertEqual(
            docker_calls("dpa"),
            ["system df", "system prune --all --filter until=720h", "system df"],
        )

    def test_neither_prune_skips_its_question_or_removes_volumes(self) -> None:
        for shortcut in ("dp", "dpa"):
            for call in docker_calls(shortcut):
                with self.subTest(shortcut=shortcut, call=call):
                    # Also catches -f combined with other short flags, such as -af
                    self.assertNotRegex(call, r"(^| )(-[a-zA-Z]*f[a-zA-Z]*|--force|--volumes)( |$)")


class ComposeTest(unittest.TestCase):
    def test_dcu_recreates_and_starts_services(self) -> None:
        self.assertEqual(
            docker_calls("dcu api"), ["compose up --build --detach --remove-orphans api"]
        )

    def test_dcd_stops_and_removes_services(self) -> None:
        self.assertEqual(docker_calls("dcd api"), ["compose down api"])

    def test_dcc_runs_any_compose_command(self) -> None:
        self.assertEqual(docker_calls("dcc ps --all"), ["compose ps --all"])

    def test_dl_follows_the_last_hundred_log_lines(self) -> None:
        self.assertEqual(docker_calls("dl"), ["compose logs --follow --tail=100"])

    def test_dl_follows_only_the_services_it_is_given(self) -> None:
        self.assertEqual(docker_calls("dl api"), ["compose logs --follow --tail=100 api"])


class StandardNamesTest(unittest.TestCase):
    def test_no_shortcut_hides_a_builtin_or_a_command(self) -> None:
        # A shortcut named like a command, such as `du`, hides that command in an interactive shell
        script = (
            "have() { return 0 }\n"
            "is_work() { return 1 }\n"
            "typeset -a before=(${(k)functions} ${(k)aliases})\n"
            f"source '{SHELL_ZSH}'\n"
            "for name in ${(k)functions} ${(k)aliases}; do\n"
            "  (( ${before[(Ie)$name]} )) && continue\n"
            "  (( $+builtins[$name] || $+commands[$name] )) && print -r -- $name\n"
            "done\n"
        )
        result = subprocess.run(
            ["zsh", "-f", "-c", script], capture_output=True, text=True, check=True
        )
        self.assertEqual(result.stdout.split(), [])


if __name__ == "__main__":
    unittest.main()
