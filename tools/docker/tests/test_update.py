#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/docker/update.bash, which `u` runs to say when Docker could free space.

Run with: uv run tools/docker/tests/test_update.py

Each test runs the script under macOS's own bash with a throwaway HOME and a PATH holding only a
`docker` stub and the system directories, so no test reaches the real Docker. The stub records
every call, prints the Reclaimable column a test gives it, refuses, or hangs.
"""

from __future__ import annotations

import subprocess
import tempfile
import time
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent.parent
SCRIPT = REPO / "tools/docker/update.bash"

DOCKER_STUB = """#!/bin/bash
echo "$*" >> "${DOCKER_LOG}"
case "${DOCKER_MODE}" in
  refuse) echo "failed to connect to the docker API" >&2; exit 1 ;;
  hang) exec sleep 30 ;;  # exec, so a kill reaches the waiting process, as with the real CLI
  *) cat "${DOCKER_RECLAIMABLE}" ;;
esac
"""


class Run:
    def __init__(self, output: str, code: int, seconds: float, calls: list[str]) -> None:
        self.output = output
        self.code = code
        self.seconds = seconds
        self.calls = calls


def run(*, reclaimable: list[str] | None = None, mode: str = "df", docker: bool = True) -> Run:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        bin_dir = root / "bin"
        bin_dir.mkdir()
        log = root / "docker.log"
        log.touch()
        rows = root / "reclaimable"
        rows.write_text("".join(f"{row}\n" for row in reclaimable or []))
        if docker:
            stub = bin_dir / "docker"
            stub.write_text(DOCKER_STUB)
            stub.chmod(0o755)
        env = {
            "HOME": str(root),
            "PATH": f"{bin_dir}:/usr/bin:/bin",
            "DOCKER_LOG": str(log),
            "DOCKER_MODE": mode,
            "DOCKER_RECLAIMABLE": str(rows),
        }
        started = time.monotonic()
        result = subprocess.run(
            ["/bin/bash", str(SCRIPT)], env=env, capture_output=True, text=True, timeout=60
        )
        seconds = time.monotonic() - started
        calls = log.read_text().splitlines()
    return Run(result.stdout + result.stderr, result.returncode, seconds, calls)


class ReportTest(unittest.TestCase):
    def assert_nothing_deleted(self, outcome: Run) -> None:
        self.assertFalse([call for call in outcome.calls if "prune" in call], outcome.calls)

    def test_over_ten_gigabytes_reclaimable_suggests_dp_and_dpa(self) -> None:
        outcome = run(reclaimable=["18.57GB (70%)", "1.098GB (99%)", "1.962GB (89%)", "697.6MB"])

        self.assertEqual(outcome.code, 0, outcome.output)
        self.assertIn("22.3 GB", outcome.output)
        self.assertIn("dp", outcome.output)
        self.assertIn("dpa", outcome.output)
        self.assert_nothing_deleted(outcome)

    def test_under_ten_gigabytes_reclaimable_prints_nothing(self) -> None:
        outcome = run(reclaimable=["9.5GB (70%)", "400MB (10%)", "0B", "99.9kB"])

        self.assertEqual((outcome.code, outcome.output), (0, ""))
        self.assert_nothing_deleted(outcome)

    def test_exactly_ten_gigabytes_is_not_over_the_threshold(self) -> None:
        outcome = run(reclaimable=["5GB (50%)", "4000MB", "999999kB", "1000B"])

        self.assertEqual((outcome.code, outcome.output), (0, ""))

    def test_every_unit_docker_prints_counts_towards_the_total(self) -> None:
        outcome = run(reclaimable=["0.01TB", "500MB", "250000kB", "250000000B"])

        self.assertEqual(outcome.code, 0, outcome.output)
        self.assertIn("11.0 GB", outcome.output)

    def test_an_unknown_unit_is_named_instead_of_guessed(self) -> None:
        outcome = run(reclaimable=["18.57GB (70%)", "3.2XB"])

        self.assertEqual(outcome.code, 0, outcome.output)
        self.assertIn("3.2XB", outcome.output)
        self.assertNotIn("dpa", outcome.output)
        self.assert_nothing_deleted(outcome)

    def test_no_docker_on_path_prints_nothing(self) -> None:
        outcome = run(docker=False)

        self.assertEqual((outcome.code, outcome.output), (0, ""))

    def test_a_daemon_that_refuses_prints_nothing(self) -> None:
        outcome = run(mode="refuse")

        self.assertEqual((outcome.code, outcome.output), (0, ""))
        self.assert_nothing_deleted(outcome)

    def test_a_daemon_that_hangs_is_given_up_on_at_the_deadline(self) -> None:
        # The deadline is 5 s and sourcing utils.bash takes under 1 s; the stub would hang for 30
        outcome = run(mode="hang")

        self.assertEqual((outcome.code, outcome.output), (0, ""))
        self.assertLess(outcome.seconds, 8)
        self.assert_nothing_deleted(outcome)


if __name__ == "__main__":
    unittest.main()
