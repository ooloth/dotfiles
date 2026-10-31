#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for how `u` checks update prerequisites before updating anything.

Run with: uv run features/update/tests/test_preflight.py

Each test builds a throwaway HOME holding a repo at ~/Repos/ooloth/dotfiles, where utils.bash
expects it. The repo links in the real features/update scripts and the bash utils, and adds fake
tools whose preflight.bash passes, fails or hangs and whose update.bash leaves a marker file. A
`curl` stub on PATH stands in for the network check. Everything runs under macOS's own bash 3.2.
"""

from __future__ import annotations

import os
import subprocess
import tempfile
import time
import unittest
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]

LINKED = [
    "tools/bash/utils.bash",
    "tools/macos/utils.bash",
    "features/update/tools.bash",
    "features/update/preflight.bash",
]

PASS = "#!/usr/bin/env bash\nexit 0\n"
HANG = "#!/usr/bin/env bash\nsleep 30\n"


def fail(message: str) -> str:
    return f"#!/usr/bin/env bash\necho '{message}' >&2\nexit 1\n"


def barrier(started: Path, name: str, count: int) -> str:
    """A check that marks itself started, then passes only once `count` checks have started.

    It gives up after 4 s, inside preflight's 5 s deadline, so a check left waiting fails rather
    than timing out.
    """
    return (
        "#!/usr/bin/env bash\n"
        f"touch '{started / name}'\n"
        "for _ in $(seq 40); do\n"
        f"  [ \"$(ls '{started}' | wc -l)\" -ge {count} ] && exit 0\n"
        "  sleep 0.1\n"
        "done\n"
        f"echo '{name} never saw the other checks running' >&2\n"
        "exit 1\n"
    )


@dataclass(frozen=True)
class Run:
    status: int
    output: str
    updated: set[str]
    seconds: float


class FakeHome:
    def __init__(self, root: Path, *, network_up: bool = True) -> None:
        self.home = root
        self.repo = root / "Repos/ooloth/dotfiles"
        for path in LINKED:
            target = self.repo / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(REPO / path)
        self.bin = root / "bin"
        self.bin.mkdir()
        curl = self.bin / "curl"
        curl.write_text(f"#!/bin/sh\nexit {0 if network_up else 6}\n")
        curl.chmod(0o755)
        self.markers = root / "updated"
        self.markers.mkdir()

    def slow_polls(self) -> None:
        # Stands in for a busy machine: each 0.1 s poll takes 0.6 s, while a hung check's
        # `sleep 30` still lasts 30 s. A deadline that counted its 50 polls would also end at 30 s,
        # by which time the hung check has finished on its own, so the test would fail on the
        # missing "timed out" before it reached the 20 s bound.
        sleep = self.bin / "sleep"
        sleep.write_text('#!/bin/sh\n[ "$1" = 0.1 ] && exec /bin/sleep 0.6\nexec /bin/sleep "$@"\n')
        sleep.chmod(0o755)

    def tool(self, name: str, preflight: str | None) -> None:
        folder = self.repo / "tools" / name
        folder.mkdir(parents=True)
        (folder / "update.bash").write_text(f"#!/usr/bin/env bash\ntouch '{self.markers / name}'\n")
        if preflight is not None:
            (folder / "preflight.bash").write_text(preflight)

    def u(self, *args: str) -> Run:
        return self._run("features/update/tools.bash", *args)

    def preflight(self, *args: str) -> Run:
        return self._run("features/update/preflight.bash", *args)

    def _run(self, script: str, *args: str) -> Run:
        env = {**os.environ, "HOME": str(self.home), "PATH": f"{self.bin}:{os.environ['PATH']}"}
        start = time.monotonic()
        result = subprocess.run(
            ["/bin/bash", str(self.repo / script), *args],
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        return Run(
            status=result.returncode,
            output=result.stdout + result.stderr,
            updated={p.name for p in self.markers.iterdir()},
            seconds=time.monotonic() - start,
        )


class PreflightTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_a_failed_check_stops_u_before_any_update(self) -> None:
        home = FakeHome(self.root)
        home.tool("docker-user", fail("docker-user needs Docker"))
        home.tool("other", PASS)
        run = home.u()
        self.assertNotEqual(run.status, 0)
        self.assertEqual(run.updated, set())

    def test_every_failure_is_reported_in_one_run(self) -> None:
        home = FakeHome(self.root)
        home.tool("first", fail("first needs Docker"))
        home.tool("second", fail("second needs gcloud"))
        run = home.u()
        self.assertIn("first needs Docker", run.output)
        self.assertIn("second needs gcloud", run.output)

    def test_a_network_failure_stops_u(self) -> None:
        home = FakeHome(self.root, network_up=False)
        home.tool("other", PASS)
        run = home.u()
        self.assertNotEqual(run.status, 0)
        self.assertIn("network", run.output)
        self.assertEqual(run.updated, set())

    def test_a_hanging_check_is_reported_as_timed_out_within_the_deadline(self) -> None:
        home = FakeHome(self.root)
        home.tool("slow", HANG)
        run = home.u()
        self.assertNotEqual(run.status, 0)
        self.assertIn("slow", run.output)
        self.assertIn("timed out", run.output)
        # The deadline is 5 s and the hung check sleeps 30 s. 20 s leaves room for a machine busy
        # running every other test at once.
        self.assertLess(run.seconds, 20)

    def test_slow_polls_do_not_stretch_the_deadline(self) -> None:
        home = FakeHome(self.root)
        home.slow_polls()
        home.tool("slow", HANG)
        run = home.u()
        self.assertIn("timed out", run.output)
        self.assertLess(run.seconds, 20)

    def test_checks_run_in_parallel(self) -> None:
        # Each check passes only once all three have started, which checks run one at a time can
        # never see. No clock is involved, so a busy machine can't fail it.
        home = FakeHome(self.root)
        started = self.root / "started"
        started.mkdir()
        for name in ("a", "b", "c"):
            home.tool(name, barrier(started, name, 3))
        run = home.u()
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(run.updated, {"a", "b", "c"})

    def test_one_tool_runs_only_its_own_check(self) -> None:
        home = FakeHome(self.root)
        home.tool("wanted", PASS)
        home.tool("unrelated", fail("unrelated needs Docker"))
        run = home.u("wanted")
        self.assertEqual(run.status, 0)
        self.assertEqual(run.updated, {"wanted"})

    def test_the_template_check_never_runs(self) -> None:
        home = FakeHome(self.root)
        home.tool("@new", fail("template ran"))
        home.tool("other", PASS)
        run = home.u()
        self.assertNotIn("template ran", run.output)
        self.assertIn("other", run.updated)

    def test_passing_checks_print_nothing(self) -> None:
        # u reports only errors, so a clean pass leaves no output to read past
        home = FakeHome(self.root)
        home.tool("checked", PASS)
        run = home.preflight()
        self.assertEqual((run.status, run.output), (0, ""))

    def test_updates_run_when_every_check_passes(self) -> None:
        home = FakeHome(self.root)
        home.tool("checked", PASS)
        home.tool("unchecked", None)
        run = home.u()
        self.assertEqual(run.updated, {"checked", "unchecked"})


if __name__ == "__main__":
    unittest.main()
