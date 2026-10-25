#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for tools/things/update.bash and uninstall.bash, which keep things-cli at a pinned version.

Run with: uv run tools/things/tests/test_update.py

Each test builds a throwaway HOME holding the repo at ~/Repos/ooloth/dotfiles, where utils.bash
expects it, and runs the script under macOS's own bash. A `go` stub on PATH answers `go env`,
writes a fake `things` binary on `go install` whose content is the version it was installed at, and
reports that version on `go version -m` the way Go prints a binary's main module. No test reaches
the network or the real things-cli.
"""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent.parent
PINNED = "v0.11.0"
MODULE = "github.com/ryanlewis/things-cli/cmd/things"

GO_STUB = """#!/bin/bash
echo "$*" >> "${GO_LOG}"
case "$1" in
  env)
    case "$2" in
      GOBIN) echo "${FAKE_GOBIN:-}" ;;
      GOPATH) echo "${FAKE_GOPATH}" ;;
    esac
    ;;
  version)
    [[ -f "$3" ]] || { echo "$3: open: no such file or directory" >&2; exit 1; }
    printf '%s: go1.27.3\\n\\tpath\\tgithub.com/ryanlewis/things-cli/cmd/things\\n' "$3"
    printf '\\tmod\\tgithub.com/ryanlewis/things-cli\\t%s\\th1:abc=\\n' "$(cat "$3")"
    ;;
  install)
    bin="${FAKE_GOBIN:-${FAKE_GOPATH}/bin}"
    mkdir -p "${bin}"
    printf '%s' "${FAKE_INSTALLED_VERSION:-${2##*@}}" > "${bin}/things"
    ;;
  *) echo "unexpected go call: $*" >&2; exit 2 ;;
esac
"""


@dataclass(frozen=True)
class Run:
    status: int
    output: str
    go: list[str]


class Machine:
    """A temporary HOME and Go directory for the things scripts to run against."""

    def __init__(self, root: Path) -> None:
        root = root.resolve()
        self.home = root / "home"
        dotfiles = self.home / "Repos" / "ooloth" / "dotfiles"
        dotfiles.parent.mkdir(parents=True)
        dotfiles.symlink_to(REPO)
        self.gopath = root / "go"
        self.gobin: Path | None = None
        self.stubs = root / "stubs"
        self.stubs.mkdir()
        go = self.stubs / "go"
        go.write_text(GO_STUB)
        go.chmod(0o755)
        self.go_log = root / "go.log"
        self.installed_version: str | None = None

    @property
    def binary(self) -> Path:
        return (self.gobin or self.gopath / "bin") / "things"

    def install_binary(self, version: str) -> None:
        self.binary.parent.mkdir(parents=True, exist_ok=True)
        self.binary.write_text(version)

    def run(self, script: str, computer: str = "air") -> Run:
        self.go_log.write_text("")
        env = {
            "HOME": str(self.home),
            "PATH": f"{self.stubs}:/usr/bin:/bin",
            "COMPUTER": computer,
            "DOTFILES": str(self.home / "Repos" / "ooloth" / "dotfiles"),
            "GO_LOG": str(self.go_log),
            "FAKE_GOPATH": str(self.gopath),
        }
        if self.gobin is not None:
            env["FAKE_GOBIN"] = str(self.gobin)
        if self.installed_version is not None:
            env["FAKE_INSTALLED_VERSION"] = self.installed_version
        result = subprocess.run(
            ["/bin/bash", str(REPO / "tools" / "things" / script)],
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        calls = [line for line in self.go_log.read_text().splitlines() if line]
        return Run(result.returncode, result.stdout + result.stderr, calls)


def installs(run: Run) -> list[str]:
    return [call for call in run.go if call.startswith("install")]


class UpdateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.machine = Machine(Path(self.tmp.name))

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_installs_the_pinned_version_when_things_cli_is_missing(self) -> None:
        run = self.machine.run("update.bash")
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(installs(run), [f"install {MODULE}@{PINNED}"])
        self.assertEqual(self.machine.binary.read_text(), PINNED)
        self.assertIn(f"installed things-cli {PINNED}", run.output)

    def test_installs_on_every_machine(self) -> None:
        for computer in ("air", "mini", "work"):
            with self.subTest(computer=computer):
                if self.machine.binary.exists():
                    self.machine.binary.unlink()
                run = self.machine.run("update.bash", computer=computer)
                self.assertEqual(run.status, 0, run.output)
                self.assertEqual(installs(run), [f"install {MODULE}@{PINNED}"])

    def test_installs_nothing_when_the_pinned_version_is_already_installed(self) -> None:
        self.machine.install_binary(PINNED)
        run = self.machine.run("update.bash")
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(installs(run), [])
        self.assertIn(f"things-cli is already {PINNED}", run.output)

    def test_replaces_a_different_version_with_the_pinned_one(self) -> None:
        self.machine.install_binary("v0.10.0")
        run = self.machine.run("update.bash")
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(installs(run), [f"install {MODULE}@{PINNED}"])
        self.assertEqual(self.machine.binary.read_text(), PINNED)

    def test_fails_naming_both_versions_when_the_install_leaves_another_version(self) -> None:
        self.machine.installed_version = "v0.0.1"
        run = self.machine.run("update.bash")
        self.assertNotEqual(run.status, 0)
        self.assertIn(PINNED, run.output)
        self.assertIn("v0.0.1", run.output)

    def test_checks_and_installs_in_gobin_when_it_is_set(self) -> None:
        self.machine.gobin = Path(self.tmp.name).resolve() / "gobin"
        self.machine.install_binary(PINNED)
        run = self.machine.run("update.bash")
        self.assertEqual(run.status, 0, run.output)
        self.assertEqual(installs(run), [])


class UninstallTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.machine = Machine(Path(self.tmp.name))

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_removes_the_things_cli_binary(self) -> None:
        self.machine.install_binary(PINNED)
        run = self.machine.run("uninstall.bash")
        self.assertEqual(run.status, 0, run.output)
        self.assertFalse(self.machine.binary.exists())

    def test_succeeds_when_things_cli_is_already_gone(self) -> None:
        run = self.machine.run("uninstall.bash")
        self.assertEqual(run.status, 0, run.output)


if __name__ == "__main__":
    os.environ.pop("DOTFILES", None)
    unittest.main()
