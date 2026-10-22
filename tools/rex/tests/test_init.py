#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/rex/config/init.lua, which binds ctrl+h/j/k/l to move between Rex panes and cmd
keys to tabs, sessions and splits.

Run with: uv run tools/rex/tests/test_init.py

Each test loads init.lua in a bare `lua` with the `rex` API stubbed, presses one key, and reads
what the binding did: whether it handled the key, which way it moved focus, and what it logged.
Pressing <actions> instead lists every key bound to a named action, with its arguments.
"""

from __future__ import annotations

import json
import subprocess
import unittest
from dataclasses import dataclass
from pathlib import Path

INIT_LUA = Path(__file__).resolve().parent.parent / "config" / "init.lua"

# Stands in for Rex. FOREGROUND is the program the pane's process lookup reports, or <lookup fails>.
# FOCUS_FAILS makes session.focus_direction return an error.
HARNESS = r"""
local init_lua, key, foreground, focus_fails = arg[1], arg[2], arg[3], arg[4] == "true"
local bindings, focused, logs = {}, {}, {}

rex = {
  bind = function(k, target, args) bindings[k] = { target = target, args = args } end,
  log = function(message) logs[#logs + 1] = message end,
  block = {
    call = function(_, method, args)
      assert(method == "process", "unexpected block method " .. method)
      assert(args.block_id == "block:test", "block_id not passed from ctx")
      if foreground == "<lookup fails>" then return nil, "lookup failed" end
      return { foreground = { name = foreground } }
    end,
  },
  session = {
    focus_direction = function(args)
      assert(args.session_id == "session:test", "session_id not passed from ctx")
      if focus_fails then return nil, "conflict" end
      focused[#focused + 1] = args.direction .. (args.wrap and "+wrap" or "")
      return { revision = 1 }
    end,
  },
}

dofile(init_lua)

if key == "<actions>" then
  local out = {}
  for k, b in pairs(bindings) do
    if type(b.target) == "string" then
      local args = {}
      for name, value in pairs(b.args or {}) do args[#args + 1] = string.format("%q:%s", name, tostring(value)) end
      out[#out + 1] = string.format('%q:{"action":%q,"args":{%s}}', k, b.target, table.concat(args, ","))
    end
  end
  io.write('{"actions":{' .. table.concat(out, ",") .. "}}")
  return
end

local binding = bindings[key] and bindings[key].target
if type(binding) ~= "function" then
  io.write('{"error":"' .. key .. ' is not bound to a function"}')
  return
end
local handled = binding({ session_id = "session:test", block_id = "block:test" }, { keybinding = key })
local function list(t)
  local out = {}
  for i, v in ipairs(t) do out[i] = string.format("%q", v) end
  return "[" .. table.concat(out, ",") .. "]"
end
io.write(string.format('{"handled":%s,"focused":%s,"logs":%s}', tostring(handled == true), list(focused), list(logs)))
"""


@dataclass(frozen=True)
class KeyOutcome:
    handled: bool
    focused: list[str]
    logs: list[str]


def press(key: str, *, foreground: str, focus_fails: bool = False) -> KeyOutcome:
    result = subprocess.run(
        ["lua", "-", str(INIT_LUA), key, foreground, str(focus_fails).lower()],
        input=HARNESS,
        capture_output=True,
        text=True,
        check=True,
    )
    outcome = json.loads(result.stdout)
    if "error" in outcome:
        raise AssertionError(outcome["error"])
    return KeyOutcome(outcome["handled"], outcome["focused"], outcome["logs"])


DIRECTIONS = {"ctrl+h": "left", "ctrl+j": "down", "ctrl+k": "up", "ctrl+l": "right"}


def action_bindings() -> dict[str, dict[str, object]]:
    result = subprocess.run(
        ["lua", "-", str(INIT_LUA), "<actions>", "", "false"],
        input=HARNESS,
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)["actions"]


class InProgramsThatNavigateThemselves(unittest.TestCase):
    def test_ctrl_h_j_k_l_reach_the_program(self) -> None:
        for program in ["nvim", "vim", "vi", "view", "fzf"]:
            for key in DIRECTIONS:
                with self.subTest(program=program, key=key):
                    outcome = press(key, foreground=program)
                    self.assertFalse(outcome.handled)
                    self.assertEqual(outcome.focused, [])


class EverywhereElse(unittest.TestCase):
    def test_ctrl_h_moves_focus_left_and_wraps(self) -> None:
        for program in ["zsh", "claude"]:
            with self.subTest(program=program):
                outcome = press("ctrl+h", foreground=program)
                self.assertTrue(outcome.handled)
                self.assertEqual(outcome.focused, ["left+wrap"])

    def test_each_key_moves_focus_its_own_way_and_wraps(self) -> None:
        for key, direction in DIRECTIONS.items():
            with self.subTest(key=key):
                outcome = press(key, foreground="zsh")
                self.assertTrue(outcome.handled)
                self.assertEqual(outcome.focused, [f"{direction}+wrap"])

    def test_a_name_that_only_contains_vim_gets_pane_navigation(self) -> None:
        outcome = press("ctrl+h", foreground="nvim-qt")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.focused, ["left+wrap"])


class WhenRexCallsFail(unittest.TestCase):
    def test_a_failed_process_lookup_still_moves_focus_and_is_logged(self) -> None:
        outcome = press("ctrl+h", foreground="<lookup fails>")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.focused, ["left+wrap"])
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("block:test", outcome.logs[0])
        self.assertIn("lookup failed", outcome.logs[0])

    def test_a_failed_focus_passes_the_key_on_and_is_logged(self) -> None:
        outcome = press("ctrl+l", foreground="zsh", focus_fails=True)
        self.assertFalse(outcome.handled)
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("right", outcome.logs[0])
        self.assertIn("conflict", outcome.logs[0])


class CmdKeys(unittest.TestCase):
    def test_each_cmd_key_runs_its_action(self) -> None:
        expected = {
            "cmd+[BracketLeft]": ("client.tab.previous", {}),
            "cmd+[BracketRight]": ("client.tab.next", {}),
            "cmd+n": ("client.tab.new", {}),
            "cmd+r": ("client.tab.rename", {}),
            "cmd+s": ("session.switch", {}),
            "cmd+shift+[BracketLeft]": ("session.previous", {}),
            "cmd+shift+[BracketRight]": ("session.next", {}),
            "cmd+[Backslash]": ("pane.split.right", {}),
            "cmd+shift+m": ("pane.zoom", {}),
        }
        bound = action_bindings()
        for key, (action, args) in expected.items():
            with self.subTest(key=key):
                self.assertIn(key, bound)
                self.assertEqual(bound[key], {"action": action, "args": args})

    def test_no_other_keys_are_bound_to_actions(self) -> None:
        self.assertEqual(len(action_bindings()), 9)


if __name__ == "__main__":
    unittest.main()
