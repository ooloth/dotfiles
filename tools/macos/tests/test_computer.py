#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for tools/macos/computer.rb, which tells Brewfiles which Mac they are evaluated on.

Run with: uv run tools/macos/tests/test_computer.py

The helper has to agree with tools/macos/utils.bash and shell.zsh, because the shell decides which
tools run and the Brewfiles decide which get installed. The Ruby tests run macOS's own
/usr/bin/ruby, which is older than the Ruby Homebrew evaluates Brewfiles with, so syntax that
passes here passes there.
"""

from __future__ import annotations

import functools
import json
import re
import subprocess
import sys
import unittest
from pathlib import Path

MACOS = Path(__file__).resolve().parent.parent
TOOLS = MACOS.parent
HELPER = MACOS / "computer.rb"
UTILS = MACOS / "utils.bash"
SHELL_ZSH = MACOS / "shell.zsh"
GENERATOR = TOOLS / "homebrew" / "generate-brewfile.bash"
GENERATED = TOOLS / "homebrew" / "Brewfile.generated"
REQUIRE = 'require_relative "../macos/computer"'
SHELL_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"

ON_MACOS = unittest.skipUnless(sys.platform == "darwin", "needs macOS's /usr/bin/ruby")

# Names that sort into each machine, the empty name included, in the order the rule lists them
NAMES = {"Air": "air", "Mini": "mini", "": "work", "work": "work", "air": "work", "Laptop": "work"}

# Evaluates Brewfiles the way Homebrew's bundle/dsl.rb does, with instance_eval and the Brewfile's
# path, so require_relative resolves from it. networksetup is the system boundary, so the backtick
# that asks it is replaced to report the name under test, or File.executable? reports it missing.
# ARGV is: the name, "missing" or "present", the combined file's path, then each Brewfile's path.
EVALUATE = r"""
require "json"
NAME, NETWORKSETUP_STATE, COMBINED_PATH, *PATHS = ARGV

module Kernel
  def `(command)
    raise "unexpected command: #{command}" unless command.end_with?(" -getcomputername")
    "#{NAME}\n"
  end
end

class << File
  alias_method :real_executable?, :executable?
  def executable?(path)
    path == "/usr/sbin/networksetup" ? NETWORKSETUP_STATE == "present" : real_executable?(path)
  end
end

class Recorder
  attr_reader :entries
  def initialize
    @entries = []
  end
  %w[brew cask tap mas vscode].each do |kind|
    define_method(kind) { |name, *_rest, **_options| @entries << "#{kind} #{name}" }
  end
end

def evaluate(text, path)
  recorder = Recorder.new
  recorder.instance_eval(text, path)
  recorder.entries
rescue Exception => error
  { "error" => "#{error.class}: #{error.message}" }
end

files = PATHS.map { |path| [path, evaluate(File.read(path), path)] }.to_h
combined = PATHS.reject { |path| path.include?("/@new/") }.map { |path| File.read(path) }
puts JSON.generate("files" => files, "combined" => evaluate(combined.join("\n"), COMBINED_PATH))
"""


def ruby(expression: str, *args: str) -> str:
    result = subprocess.run(
        ["/usr/bin/ruby", "-r", str(HELPER), "-e", f"print({expression})", "--", *args],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout


def brewfiles() -> list[Path]:
    return sorted(TOOLS.glob("*/Brewfile"))


@functools.cache
def evaluated(name: str, networksetup: str = "present") -> dict:
    paths = [str(path) for path in brewfiles()]
    result = subprocess.run(
        ["/usr/bin/ruby", "-e", EVALUATE, "--", name, networksetup, str(GENERATED), *paths],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


@ON_MACOS
class ComputerFor(unittest.TestCase):
    def test_names_the_two_personal_macs_and_calls_every_other_name_work(self) -> None:
        for name, expected in NAMES.items():
            with self.subTest(name=name):
                self.assertEqual(ruby("computer_for(ARGV[0])", name), expected)

    def test_agrees_with_shell_zsh_on_every_name(self) -> None:
        # An empty COMPUTER_NAME makes shell.zsh ask scutil instead, so only non-empty names
        for name in (name for name in NAMES if name):
            with self.subTest(name=name):
                shell = subprocess.run(
                    ["zsh", "-f", "-c", 'source "$1"; print -rn -- "$COMPUTER"', "_", SHELL_ZSH],
                    env={"PATH": SHELL_PATH, "COMPUTER_NAME": name},
                    capture_output=True,
                    text=True,
                    check=True,
                ).stdout
                self.assertEqual(ruby("computer_for(ARGV[0])", name), shell)

    def test_agrees_with_utils_bash_on_the_mac_the_tests_run_on(self) -> None:
        # utils.bash asks networksetup by absolute path, so only this Mac's own name reaches it
        shell = subprocess.run(
            ["/bin/bash", "-c", 'source "$1"; printf "%s" "$COMPUTER"', "_", str(UTILS)],
            env={"PATH": SHELL_PATH},
            capture_output=True,
            text=True,
            check=True,
        ).stdout
        self.assertEqual(ruby("COMPUTER"), shell)

    def test_exactly_one_predicate_holds_on_this_mac(self) -> None:
        self.assertEqual(ruby("[air?, mini?, work?].count(true)"), "1")


@ON_MACOS
class BrewfilesOnEachMachine(unittest.TestCase):
    def test_every_brewfile_evaluates_on_every_machine_alone_and_combined(self) -> None:
        cases = [(name, "present") for name in NAMES] + [("", "missing")]
        for name, networksetup in cases:
            result = evaluated(name, networksetup)
            for path, entries in [*result["files"].items(), ("combined", result["combined"])]:
                with self.subTest(name=name, networksetup=networksetup, brewfile=path):
                    self.assertIsInstance(entries, list, entries)

    def test_the_combined_brewfile_lists_what_the_tool_brewfiles_list(self) -> None:
        for name in ("Air", "Mini", "Laptop"):
            result = evaluated(name)
            tools = [
                entry
                for path, entries in result["files"].items()
                if "/@new/" not in path
                for entry in entries
            ]
            with self.subTest(name=name):
                self.assertEqual(result["combined"], tools)

    def test_machine_specific_entries_land_on_the_right_machines(self) -> None:
        expected = {
            "brew argocd": {"work"},
            "cask spacelift-io/spacelift/spacectl": {"work"},
            "cask 1password": {"air", "mini"},
            "brew go": {"air"},
            "cask handy": {"air", "work"},
        }
        machines = {"Air": "air", "Mini": "mini", "Laptop": "work"}
        for entry, where in expected.items():
            found = {
                machine
                for name, machine in machines.items()
                if entry in evaluated(name)["combined"]
            }
            with self.subTest(entry=entry):
                self.assertEqual(found, where)

    def test_the_combined_brewfile_is_evaluated_where_the_generator_writes_it(self) -> None:
        relative = GENERATED.relative_to(TOOLS.parent)
        self.assertIn(f'output="${{DOTFILES}}/{relative}"', GENERATOR.read_text())


class Brewfiles(unittest.TestCase):
    def test_no_brewfile_works_out_the_machine_itself(self) -> None:
        for path in brewfiles():
            with self.subTest(brewfile=str(path.relative_to(TOOLS))):
                self.assertNotRegex(
                    path.read_text(), r"networksetup|computer_name|scutil|hostname|\bENV\b"
                )

    def test_every_brewfile_that_asks_which_mac_loads_the_helper(self) -> None:
        for path in brewfiles():
            text = path.read_text()
            code = "\n".join(
                line for line in text.splitlines() if not line.lstrip().startswith("#")
            )
            if re.search(r"\b(air|mini|work)\?|\bCOMPUTER\b", code):
                with self.subTest(brewfile=str(path.relative_to(TOOLS))):
                    self.assertIn(REQUIRE, text)


if __name__ == "__main__":
    unittest.main()
