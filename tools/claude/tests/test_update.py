#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["hypothesis"]
# ///
"""Tests for tools/claude/update.bash, which moves Claude Code from npm to the Homebrew cask.

Run with: uv run tools/claude/tests/test_update.py

Each test builds a throwaway HOME holding the repo at ~/Repos/ooloth/dotfiles, where utils.bash
expects it, a fake Homebrew prefix and a fake fnm directory, and runs the script under macOS's own
bash. A `brew` stub on PATH installs the cask into the fake prefix the way Homebrew lays it out, and
refuses to link over an existing `bin/claude` the way Homebrew does. The cask's `claude` is a stub
that records its arguments, so no test reaches the real Claude Code.
"""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

from hypothesis import given, settings
from hypothesis import strategies as st

REPO = Path(__file__).resolve().parent.parent.parent.parent
SCRIPT = "tools/claude/update.bash"
CASK = "claude-code@latest"
PACKAGE = "lib/node_modules/@anthropic-ai/claude-code"

BREW_STUB = """#!/bin/bash
echo "$*" >> "${BREW_LOG}"
caskroom="${HOMEBREW_PREFIX}/Caskroom/$3"
case "$1 $2" in
  "list --cask") [[ -d "${caskroom}" ]] ;;
  "install --cask")
    if [[ -e "${HOMEBREW_PREFIX}/bin/claude" || -L "${HOMEBREW_PREFIX}/bin/claude" ]]; then
      echo "Error: It seems there is already a Binary at '${HOMEBREW_PREFIX}/bin/claude'." >&2
      exit 1
    fi
    mkdir -p "${caskroom}/9.9.9"
    printf '#!/bin/bash\\necho "$*" >> "${CLAUDE_LOG}"\\n' > "${caskroom}/9.9.9/claude"
    chmod +x "${caskroom}/9.9.9/claude"
    ln -s "../Caskroom/$3/9.9.9/claude" "${HOMEBREW_PREFIX}/bin/claude"
    ;;
  *) echo "unexpected brew call: $*" >&2; exit 2 ;;
esac
"""

NODE_VERSIONS = ["v20.5.0", "v23.5.0", "v24.4.1", "v24.21.0", "v26.7.0"]


@dataclass(frozen=True)
class Run:
    status: int
    output: str
    brew: list[str]
    claude: list[str]


def write_stubs(folder: Path) -> Path:
    """Write the `brew` stub into `folder`, then make the folder read-only, so examples that share
    it can't change what the others run."""
    folder.mkdir(parents=True, exist_ok=True)
    brew = folder / "brew"
    brew.write_text(BREW_STUB)
    brew.chmod(0o755)
    folder.chmod(0o555)
    return folder


class Machine:
    """A temporary HOME, Homebrew prefix and fnm directory for update.bash to run against.

    `stubs` is a folder from write_stubs to share between Machines. A newly written executable is
    slow to start the first time on a Mac running endpoint security, so a property test that builds
    a Machine per example shares one folder rather than writing the stub again each time.
    """

    def __init__(self, root: Path, stubs: Path | None = None) -> None:
        root = root.resolve()
        self.home = root / "home"
        dotfiles = self.home / "Repos" / "ooloth" / "dotfiles"
        dotfiles.parent.mkdir(parents=True)
        dotfiles.symlink_to(REPO)
        self.prefix = root / "homebrew"
        (self.prefix / "bin").mkdir(parents=True)
        self.fnm = root / "fnm"
        for version in NODE_VERSIONS:
            (self.node(version) / "bin").mkdir(parents=True)
        self.stubs = stubs or write_stubs(root / "stubs")
        self.extra_path: list[Path] = []
        self._brew_log = root / "brew.log"
        self._claude_log = root / "claude.log"

    def node(self, version: str) -> Path:
        return self.fnm / "node-versions" / version / "installation"

    def add_npm_copy(self, install: Path, target: str = "bin/claude.exe") -> None:
        """Install Claude Code into a Node install the way `npm install --global` lays it out."""
        package = install / PACKAGE
        (package / Path(target).parent).mkdir(parents=True, exist_ok=True)
        (package / target).write_text("#!/bin/bash\n")
        (install / "bin" / "claude").symlink_to(f"../{PACKAGE}/{target}")

    def install_cask(self) -> None:
        subprocess.run(
            ["/bin/bash", str(self.stubs / "brew"), "install", "--cask", CASK],
            env=self._env(),
            check=True,
        )
        self._brew_log.unlink()

    def add_foreign_claude(self) -> Path:
        """Put a `claude` on PATH that is not the cask's."""
        elsewhere = self.home / "elsewhere"
        elsewhere.mkdir()
        claude = elsewhere / "claude"
        claude.write_text("#!/bin/bash\n")
        claude.chmod(0o755)
        self.extra_path.append(elsewhere)
        return claude

    def _env(self, **overrides: str) -> dict[str, str]:
        path = [self.stubs, self.prefix / "bin", *self.extra_path]
        env = {
            "HOME": str(self.home),
            "DOTFILES": str(self.home / "Repos/ooloth/dotfiles"),
            "PATH": ":".join(str(p) for p in path) + ":/usr/bin:/bin:/usr/sbin:/sbin",
            "HOMEBREW_PREFIX": str(self.prefix),
            "FNM_DIR": str(self.fnm),
            "BREW_LOG": str(self._brew_log),
            "CLAUDE_LOG": str(self._claude_log),
        }
        env.update(overrides)
        return {k: v for k, v in env.items() if v}

    def run(self, **overrides: str) -> Run:
        result = subprocess.run(
            ["/bin/bash", str(self.home / "Repos/ooloth/dotfiles" / SCRIPT)],
            env=self._env(**overrides),
            capture_output=True,
            text=True,
            check=False,
        )
        return Run(
            result.returncode,
            result.stdout + result.stderr,
            self._lines(self._brew_log),
            self._lines(self._claude_log),
        )

    @staticmethod
    def _lines(log: Path) -> list[str]:
        return log.read_text().splitlines() if log.exists() else []


class UpdateTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.machine = Machine(Path(self._tmp.name))

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_an_npm_copy_in_homebrews_node_is_replaced_by_the_cask(self) -> None:
        self.machine.add_npm_copy(self.machine.prefix)
        run = self.machine.run()
        self.assertEqual(run.status, 0, run.output)
        self.assertFalse((self.machine.prefix / PACKAGE).exists())
        self.assertIn(f"install --cask {CASK}", run.brew)
        resolved = (self.machine.prefix / "bin" / "claude").resolve()
        self.assertTrue(resolved.is_relative_to(self.machine.prefix / "Caskroom" / CASK), resolved)

    def test_a_copy_linked_to_cli_js_is_removed_with_its_link(self) -> None:
        install = self.machine.node("v23.5.0")
        self.machine.add_npm_copy(install, target="cli.js")
        run = self.machine.run()
        self.assertEqual(run.status, 0, run.output)
        self.assertFalse((install / PACKAGE).exists())
        self.assertFalse((install / "bin" / "claude").is_symlink())

    def test_a_claude_link_that_points_outside_the_package_survives(self) -> None:
        install = self.machine.node("v24.4.1")
        mine = self.machine.home / "my-claude"
        mine.write_text("#!/bin/bash\n")
        (install / "bin" / "claude").symlink_to(mine)
        run = self.machine.run()
        self.assertTrue((install / "bin" / "claude").is_symlink(), run.output)

    def test_with_no_npm_copies_nothing_is_removed_and_nothing_warns(self) -> None:
        self.machine.install_cask()
        run = self.machine.run()
        self.assertEqual(run.status, 0, run.output)
        self.assertNotIn("npm copy", run.output)

    def test_an_installed_cask_is_not_installed_again(self) -> None:
        self.machine.install_cask()
        run = self.machine.run()
        self.assertEqual(run.status, 0, run.output)
        self.assertNotIn(f"install --cask {CASK}", run.brew)

    def test_a_missing_cask_is_installed(self) -> None:
        run = self.machine.run()
        self.assertEqual(run.status, 0, run.output)
        self.assertIn(f"install --cask {CASK}", run.brew)

    def test_the_user_scoped_notion_mcp_server_is_added_with_the_cask_claude(self) -> None:
        run = self.machine.run()
        self.assertEqual(run.status, 0, run.output)
        self.assertTrue(any(line.startswith("mcp add") for line in run.claude), run.claude)

    def test_a_claude_on_path_that_is_not_the_cask_fails_and_names_it(self) -> None:
        self.machine.install_cask()
        foreign = self.machine.add_foreign_claude()
        run = self.machine.run()
        self.assertNotEqual(run.status, 0, run.output)
        self.assertIn(str(foreign), run.output)

    def test_the_cask_listed_twice_on_path_passes(self) -> None:
        self.machine.install_cask()
        self.machine.extra_path.append(self.machine.prefix / "bin")
        run = self.machine.run()
        self.assertEqual(run.status, 0, run.output)

    def test_no_claude_on_path_fails(self) -> None:
        self.machine.install_cask()
        (self.machine.prefix / "bin" / "claude").unlink()
        # The stub sees the Caskroom and reports the cask installed, so nothing relinks it
        run = self.machine.run()
        self.assertNotEqual(run.status, 0, run.output)

    def test_a_copy_that_cannot_be_deleted_fails_and_names_its_install(self) -> None:
        install = self.machine.node("v24.21.0")
        self.machine.add_npm_copy(install)
        scope = install / "lib/node_modules/@anthropic-ai"
        scope.chmod(0o555)
        try:
            run = self.machine.run()
        finally:
            scope.chmod(0o755)
        self.assertNotEqual(run.status, 0, run.output)
        self.assertIn(str(install), run.output)

    def test_an_unset_fnm_dir_fails_and_names_it(self) -> None:
        run = self.machine.run(FNM_DIR="")
        self.assertNotEqual(run.status, 0, run.output)
        self.assertIn("FNM_DIR", run.output)

    def test_an_unset_homebrew_prefix_fails_and_names_it(self) -> None:
        run = self.machine.run(HOMEBREW_PREFIX="")
        self.assertNotEqual(run.status, 0, run.output)
        self.assertIn("HOMEBREW_PREFIX", run.output)


INSTALLS = st.sets(st.sampled_from(["homebrew", *NODE_VERSIONS]))


class UpdatePropertyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._stubs_tmp = tempfile.TemporaryDirectory()
        cls.stubs = write_stubs(Path(cls._stubs_tmp.name) / "stubs")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._stubs_tmp.cleanup()  # resets the read-only folder's permissions first

    def test_a_stub_cannot_write_beside_itself_in_the_shared_folder(self) -> None:
        with self.assertRaises(PermissionError):
            (self.stubs / "written-by-an-example").write_text("x")

    @settings(max_examples=30, deadline=None)
    @given(holding=INSTALLS)
    def test_exactly_the_installs_holding_a_copy_lose_it_and_each_is_named(
        self, holding: set[str]
    ) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            machine = Machine(Path(tmp), self.stubs)
            installs = {
                name: machine.prefix if name == "homebrew" else machine.node(name)
                for name in ["homebrew", *NODE_VERSIONS]
            }
            for name in holding:
                machine.add_npm_copy(installs[name])
            run = machine.run()
            self.assertEqual(run.status, 0, run.output)
            for name, install in installs.items():
                self.assertFalse((install / PACKAGE).exists(), name)
                named = f"Removed the npm copy of Claude Code from {install}" in run.output
                self.assertEqual(named, name in holding, name)


class UpdateOrderTest(unittest.TestCase):
    """`u` must remove npm copies before `brew bundle` tries to link the cask over them."""

    def test_u_runs_claude_after_node_and_before_homebrew(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            home = root / "home"
            repo = home / "Repos" / "ooloth" / "dotfiles"
            log = root / "order.log"
            stub = f'#!/bin/bash\necho "$(basename "$(dirname "$0")")" >> "{log}"\n'
            for path in [
                "features/update/mode.bash",
                "features/update/symlinks.bash",
                "features/update/preflight.bash",
                "features/check/dotfiles.bash",
                *(f"tools/{t}/update.bash" for t in ["aaa", "claude", "homebrew", "node", "uv"]),
            ]:
                (repo / path).parent.mkdir(parents=True, exist_ok=True)
                (repo / path).write_text(stub)
            for path in ["tools/bash/utils.bash", "tools/macos/utils.bash"]:
                (repo / path).parent.mkdir(parents=True, exist_ok=True)
                (repo / path).symlink_to(REPO / path)
            (repo / "features/update/tools.bash").symlink_to(REPO / "features/update/tools.bash")
            result = subprocess.run(
                ["/bin/bash", str(repo / "features/update/tools.bash")],
                env={"HOME": str(home), "PATH": os.environ["PATH"]},
                capture_output=True,
                text=True,
                check=False,
            )
            order = [
                line for line in log.read_text().splitlines() if line not in {"update", "check"}
            ]
            self.assertEqual(order, ["uv", "node", "claude", "homebrew", "aaa"], result.stderr)


if __name__ == "__main__":
    unittest.main()
