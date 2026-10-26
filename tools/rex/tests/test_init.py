#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/rex/config/init.lua, which binds ctrl+h/j/k/l to move between Rex panes and tabs,
and cmd keys to tabs, sessions and splits.

Run with: uv run tools/rex/tests/test_init.py

Each test loads init.lua in a bare `lua` with the `rex` API stubbed by a fake session, presses one
key, and reads what the binding did: whether it handled the key, which way it asked Rex to move
focus, where focus ended up, what it asked the app to do, and what it logged. A key bound to an
action runs that action the way Rex does, with the app as its client. The fake session's tabs are rows of panes side by
side, and its revision rises only when focus changes, as Rex's does.
cmd+g opens lazygit beside the pane, and the fake records each split and zoom it asks for.
Pressing <actions> instead lists every key bound to a named action, with its arguments, <action>
runs the focus_pane_or_tab action as `rex do` would, and <sweep> presses ctrl+h or ctrl+l once in
each of many layouts.
"""

from __future__ import annotations

import itertools
import json
import os
import shutil
import subprocess
import sys
import unittest
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path

INIT_LUA = Path(__file__).resolve().parent.parent / "config" / "init.lua"

# Rex runs init.lua on its own embedded Lua 5.1. LuaJIT implements Lua 5.1, so every test runs under
# it as well as under Lua 5.5, which catches a feature from a later Lua that Rex would reject.
INTERPRETERS = ("lua", "luajit")
LUA = INTERPRETERS[0]

# Stands in for Rex. FOREGROUND is the program the pane's process lookup reports, or <lookup fails>.
# FAIL names the session call that returns an error: view, focus_direction, focus_window, or landing
# (focus_direction, but only after a tab switch). RESTLESS makes every focus_direction after a tab
# switch raise the revision, as if the server never settled. LAYOUT is each tab's pane count and
# focused pane, such as "3:2,1:1", and ACTIVE is the active tab's position in it. APP is ok when an
# app ran the key or action, none when none did, and fails when the app refuses to show a tab.
# ORIGIN is how <action> was run: key, palette, cli or api. CWD is the working directory the process
# lookup reports, or empty for none. FAIL can also be new_split or zoom_block, or split_none,
# split_two or split_same for a split that returns no block, two blocks, or the pane it split.
HARNESS = r"""
local init_lua, key, foreground, fail = arg[1], arg[2], arg[3], arg[4]
local exec_mode = arg[5] or "ok"
local layout, active, restless, cases = arg[6] or "3:2", tonumber(arg[7] or "1"), arg[8] == "true", arg[9]
local app = arg[10] or "ok"
local origin = arg[11] or "palette"
local cwd = arg[12] or ""
local bindings, actions, focus_calls, logs, started, shown, opened = {}, {}, {}, {}, {}, {}, {}
local fake

local function reset(spec, active_tab)
  fake = { tabs = {}, active = active_tab, revision = 1, switched = false }
  for panes, focused in spec:gmatch("(%d+):(%d+)") do
    fake.tabs[#fake.tabs + 1] = { panes = tonumber(panes), focused = tonumber(focused) }
  end
end

local function changed() fake.revision = fake.revision + 1 end

local function check_session(args) assert(args.session_id == "session:test", "session_id not passed from ctx") end

rex = {
  bind = function(k, target, args) bindings[k] = { target = target, args = args } end,
  action = function(def) actions[def.name] = def end,
  log = function(message) logs[#logs + 1] = message end,
  client = {
    queue = function(name, args)
      if app == "none" then error("no client to ask") end
      if app == "fails" then error("app refused") end
      if name == "pane.send_key" then
        shown[#shown + 1] = name .. " " .. tostring(args.key)
      else
        shown[#shown + 1] = name .. " " .. tostring(args.session_id) .. " " .. tostring(args.window_id)
      end
    end,
  },
  block = {
    call = function(_, method, args)
      assert(method == "process", "unexpected block method " .. method)
      assert(args.block_id == "block:test", "block_id not passed from ctx")
      if foreground == "<lookup fails>" then return nil, "lookup failed" end
      return { foreground = { name = foreground, cwd = cwd ~= "" and cwd or nil } }
    end,
  },
  exec = {
    start = function(argv, opts)
      if exec_mode == "raises" then error("exec.start exploded") end
      if exec_mode == "fails" then return nil, "no such file" end
      assert(opts.detach == true, "the saver must outlive this call")
      started[#started + 1] = argv
      return { pid = 1 }
    end,
  },
  session = {
    view = function(args)
      check_session(args)
      if fail == "view" then return nil, "view unavailable" end
      local windows = {}
      for i, tab in ipairs(fake.tabs) do
        windows[i] = { window_id = "window:" .. i, focused_block_id = "block:" .. i .. ":" .. tab.focused }
      end
      return { revision = fake.revision, session_id = "session:test", active_window_id = "window:" .. fake.active, windows = windows }
    end,
    focus_direction = function(args)
      check_session(args)
      focus_calls[#focus_calls + 1] = args.direction .. (args.wrap and "+wrap" or "")
      if fail == "focus_direction" or (fail == "landing" and fake.switched) then return nil, "conflict" end
      if restless and fake.switched then
        changed()
        return { revision = fake.revision }
      end
      local tab = fake.tabs[fake.active]
      local step = ({ left = -1, right = 1 })[args.direction]
      if step then
        local pane = tab.focused + step
        if pane < 1 or pane > tab.panes then
          pane = args.wrap and (pane - 1) % tab.panes + 1 or tab.focused
        end
        if pane ~= tab.focused then
          tab.focused = pane
          changed()
        end
      end
      return { revision = fake.revision }
    end,
    new_split = function(args)
      check_session(args)
      local block = args.layout.block
      local options = block.options
      opened[#opened + 1] = string.format("new_split %s %s %s focus=%s %s shell=%s %s cwd=%s on_completion=%s",
        args.anchor_id, args.direction, args.side, tostring(args.focus), block.flavor, tostring(options.shell),
        table.concat(options.command, " "), tostring(options.cwd), tostring(options.exit and options.exit.on_completion))
      if fail == "new_split" then return nil, "too many blocks" end
      if fail == "split_none" then return { block_ids = {}, revision = 2 } end
      if fail == "split_two" then return { block_ids = { "block:lazygit", "block:extra" }, revision = 2 } end
      if fail == "split_same" then return { block_ids = { args.anchor_id }, revision = 2 } end
      return { block_ids = { "block:lazygit" }, revision = 2 }
    end,
    zoom_block = function(args)
      check_session(args)
      opened[#opened + 1] = string.format("zoom_block %s zoom=%s", args.block_id, tostring(args.zoom))
      if fail == "zoom_block" then return nil, "block gone" end
      return { revision = 3 }
    end,
    focus_window = function(args)
      check_session(args)
      if fail == "focus_window" then return nil, "window gone" end
      local index = tonumber(args.window_id:match("^window:(%d+)$"))
      assert(fake.tabs[index], "focus_window got an unknown window " .. tostring(args.window_id))
      fake.switched = true
      if index ~= fake.active then
        fake.active = index
        changed()
      end
      return { revision = fake.revision }
    end,
  },
}

if exec_mode == "missing" then rex.exec = nil end

reset(layout, active)
dofile(init_lua)

local function list(t)
  local out = {}
  for i, v in ipairs(t) do out[i] = string.format("%q", v) end
  return "[" .. table.concat(out, ",") .. "]"
end

local function place()
  return string.format('"tab":%d,"pane":%d,"shown":%s', fake.active, fake.tabs[fake.active].focused, list(shown))
end

local ctx = { session_id = "session:test", block_id = "block:test" }

-- Presses KEY as Rex does: a function gets ctx, and an action runs with the app as its client.
-- Returns whether the key was handled, and the action's error if it failed.
local function press(k)
  local b = bindings[k]
  if type(b.target) == "function" then return b.target(ctx, { keybinding = k }) == true end
  local def = actions[b.target]
  assert(def, k .. " is bound to an undefined action " .. tostring(b.target))
  local client_id = app ~= "none" and "client:test" or nil
  local key_ctx = { session_id = "session:test", block_id = "block:test", client_id = client_id, origin = "key" }
  local ok, result = pcall(def.run, key_ctx, b.args or {})
  if ok then return true end
  return false, tostring(result)
end

if key == "<startup>" then
  local runs, count = {}, 0
  for i, argv in ipairs(started) do runs[i] = list(argv) end
  for _ in pairs(bindings) do count = count + 1 end
  io.write(string.format('{"started":[%s],"logs":%s,"bindings":%d}', table.concat(runs, ","), list(logs), count))
  return
end

if key == "<actions>" then
  local out = {}
  for k, b in pairs(bindings) do
    if type(b.target) == "string" then
      local args = {}
      for name, value in pairs(b.args or {}) do args[#args + 1] = string.format("%q:%q", name, tostring(value)) end
      out[#out + 1] = string.format('%q:{"action":%q,"args":{%s}}', k, b.target, table.concat(args, ","))
    end
  end
  io.write('{"actions":{' .. table.concat(out, ",") .. "}}")
  return
end

if key == "<action>" then
  local def = actions.focus_pane_or_tab
  if def == nil then
    io.write('{"error":"focus_pane_or_tab is not defined"}')
    return
  end
  local direction = foreground ~= "" and foreground or nil
  local client_id = app ~= "none" and "client:test" or nil
  local action_ctx = { session_id = "session:test", block_id = "block:test", client_id = client_id, origin = origin }
  local ok, result = pcall(def.run, action_ctx, { direction = direction })
  local outcome = ok and type(result) == "table" and string.format("%q", tostring(result.outcome)) or "null"
  local message = ok and "null" or string.format("%q", tostring(result))
  io.write(string.format('{"ok":%s,"outcome":%s,"message":%s,"focused":%s,"logs":%s,%s}',
    tostring(ok), outcome, message, list(focus_calls), list(logs), place()))
  return
end

if key == "<sweep>" then
  local out = {}
  for spec, active_tab, k in cases:gmatch("([^/;]+)/(%d+)/([^;]+)") do
    reset(spec, tonumber(active_tab))
    shown = {}
    local handled = press(k)
    out[#out + 1] = string.format('{"handled":%s,%s}', tostring(handled == true), place())
  end
  io.write("[" .. table.concat(out, ",") .. "]")
  return
end

if bindings[key] == nil then
  io.write('{"error":"' .. key .. ' is not bound"}')
  return
end
local handled, failure = press(key)
io.write(string.format('{"handled":%s,"failure":%s,"focused":%s,"logs":%s,"opened":%s,%s}', tostring(handled),
  failure and string.format("%q", failure) or "null", list(focus_calls), list(logs), list(opened), place()))
"""


@dataclass(frozen=True)
class Tab:
    panes: int
    focused: int


@dataclass(frozen=True)
class Place:
    tab: int
    pane: int


@dataclass(frozen=True)
class KeyOutcome:
    handled: bool
    failure: str | None
    focused: list[str]
    logs: list[str]
    place: Place
    shown: list[str]
    opened: list[str]


def shown_tab(tab: int) -> list[str]:
    """What the app is asked to do when focus crosses into tab number TAB."""
    return [f"session.select session:test window:{tab}"]


def spec(tabs: tuple[Tab, ...]) -> str:
    return ",".join(f"{tab.panes}:{tab.focused}" for tab in tabs)


def run_harness(*args: str, env: dict[str, str] | None = None) -> dict:
    result = subprocess.run(
        [LUA, "-", str(INIT_LUA), *args],
        input=HARNESS,
        capture_output=True,
        text=True,
        check=True,
        env=env,
    )
    outcome = json.loads(result.stdout)
    if isinstance(outcome, dict) and "error" in outcome:
        raise AssertionError(outcome["error"])
    return outcome


def press(
    key: str,
    *,
    foreground: str,
    fail: str = "",
    tabs: tuple[Tab, ...] = (Tab(3, 2),),
    active: int = 1,
    restless: bool = False,
    app: str = "ok",
    cwd: str = "",
) -> KeyOutcome:
    outcome = run_harness(
        key,
        foreground,
        fail,
        "ok",
        spec(tabs),
        str(active),
        str(restless).lower(),
        "",
        app,
        "palette",
        cwd,
    )
    place = Place(outcome["tab"], outcome["pane"])
    return KeyOutcome(
        outcome["handled"],
        outcome["failure"],
        outcome["focused"],
        outcome["logs"],
        place,
        outcome["shown"],
        outcome["opened"],
    )


@dataclass(frozen=True)
class ActionOutcome:
    ok: bool
    outcome: str | None
    message: str | None
    focused: list[str]
    logs: list[str]
    place: Place
    shown: list[str]


def run_action(
    direction: str,
    *,
    fail: str = "",
    tabs: tuple[Tab, ...] = (Tab(3, 2),),
    app: str = "ok",
    origin: str = "palette",
) -> ActionOutcome:
    outcome = run_harness(
        "<action>", direction, fail, "ok", spec(tabs), "1", "false", "", app, origin
    )
    place = Place(outcome["tab"], outcome["pane"])
    return ActionOutcome(
        outcome["ok"],
        outcome["outcome"],
        outcome["message"],
        outcome["focused"],
        outcome["logs"],
        place,
        outcome["shown"],
    )


@dataclass(frozen=True)
class Startup:
    started: list[list[str]]
    logs: list[str]
    bindings: int


def start_rex(exec_mode: str = "ok", home: str = "/Users/someone") -> Startup:
    outcome = run_harness(
        "<startup>", "", "", exec_mode, env={"HOME": home, "PATH": os.environ["PATH"]}
    )
    return Startup(outcome["started"], outcome["logs"], outcome["bindings"])


DIRECTIONS = {"ctrl+h": "left", "ctrl+j": "down", "ctrl+k": "up", "ctrl+l": "right"}
SIDEWAYS = {"ctrl+h": "left", "ctrl+l": "right"}


def action_bindings() -> dict[str, dict[str, object]]:
    return run_harness("<actions>", "", "")["actions"]


def layouts() -> Iterator[tuple[Tab, ...]]:
    """Every session of one to three tabs, each a row of one to three panes with any one focused."""
    one_tab = [Tab(panes, focused) for panes in range(1, 4) for focused in range(1, panes + 1)]
    for count in range(1, 4):
        yield from itertools.product(one_tab, repeat=count)


def crosses_edge(tabs: tuple[Tab, ...], active: int, direction: str) -> bool:
    pane = tabs[active - 1].focused + (1 if direction == "right" else -1)
    return not 1 <= pane <= tabs[active - 1].panes


def expected_place(tabs: tuple[Tab, ...], active: int, direction: str) -> Place:
    """One pane over within the tab, or across its edge to the neighbouring tab's near-edge pane."""
    step = 1 if direction == "right" else -1
    pane = tabs[active - 1].focused + step
    if 1 <= pane <= tabs[active - 1].panes:
        return Place(active, pane)
    target = (active - 1 + step) % len(tabs) + 1
    return Place(target, 1 if direction == "right" else tabs[target - 1].panes)


class InProgramsThatNavigateThemselves(unittest.TestCase):
    PROGRAMS = ["nvim", "vim", "vi", "view", "fzf"]

    def test_ctrl_j_and_k_pass_through_to_the_program(self) -> None:
        for program in self.PROGRAMS:
            for key in ["ctrl+j", "ctrl+k"]:
                with self.subTest(program=program, key=key):
                    outcome = press(key, foreground=program)
                    self.assertFalse(outcome.handled)
                    self.assertEqual(outcome.focused, [])

    def test_ctrl_h_and_l_are_sent_on_to_the_program_and_move_nothing(self) -> None:
        for program in self.PROGRAMS:
            for key in SIDEWAYS:
                with self.subTest(program=program, key=key):
                    outcome = press(key, foreground=program, tabs=(Tab(2, 1), Tab(2, 1)))
                    self.assertTrue(outcome.handled)
                    self.assertEqual(outcome.focused, [])
                    self.assertEqual(outcome.shown, [f"pane.send_key {key}"])
                    self.assertEqual(outcome.place, Place(1, 1))


class EverywhereElse(unittest.TestCase):
    def test_ctrl_h_and_l_reach_the_neighbouring_pane_or_tab_in_every_layout(self) -> None:
        cases = [
            (tabs, active, key)
            for tabs in layouts()
            for active in range(1, len(tabs) + 1)
            for key in SIDEWAYS
        ]
        encoded = ";".join(f"{spec(tabs)}/{active}/{key}" for tabs, active, key in cases)
        results = run_harness("<sweep>", "zsh", "", "ok", "3:2", "1", "false", encoded)
        self.assertEqual(len(results), len(cases))
        for (tabs, active, key), result in zip(cases, results, strict=True):
            with self.subTest(tabs=spec(tabs), active=active, key=key):
                self.assertTrue(result["handled"])
                expected = expected_place(tabs, active, SIDEWAYS[key])
                self.assertEqual(Place(result["tab"], result["pane"]), expected)
                crossed = crosses_edge(tabs, active, SIDEWAYS[key])
                self.assertEqual(result["shown"], shown_tab(expected.tab) if crossed else [])

    def test_ctrl_j_and_k_move_focus_their_own_way_and_wrap(self) -> None:
        for key in ["ctrl+j", "ctrl+k"]:
            with self.subTest(key=key):
                outcome = press(key, foreground="zsh")
                self.assertTrue(outcome.handled)
                self.assertEqual(outcome.focused, [f"{DIRECTIONS[key]}+wrap"])

    def test_a_name_that_only_contains_vim_gets_pane_navigation(self) -> None:
        outcome = press("ctrl+h", foreground="nvim-qt")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.place, Place(1, 1))


class WhenRexCallsFail(unittest.TestCase):
    TWO_TABS = (Tab(2, 2), Tab(3, 2))

    def test_a_failed_process_lookup_still_moves_focus_and_is_logged(self) -> None:
        outcome = press("ctrl+h", foreground="<lookup fails>")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.place, Place(1, 1))
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("block:test", outcome.logs[0])
        self.assertIn("lookup failed", outcome.logs[0])

    def test_a_failed_focus_passes_the_key_on_and_is_logged(self) -> None:
        outcome = press("ctrl+l", foreground="zsh", fail="focus_direction")
        self.assertFalse(outcome.handled)
        self.assertIn("right", outcome.failure or "")
        self.assertIn("conflict", outcome.failure or "")

    def test_a_failed_view_moves_nothing_and_reports_why(self) -> None:
        outcome = press("ctrl+l", foreground="zsh", fail="view")
        self.assertFalse(outcome.handled)
        self.assertEqual(outcome.place, Place(1, 2))
        self.assertIn("view unavailable", outcome.failure or "")

    def test_a_failed_tab_switch_moves_nothing_and_reports_why(self) -> None:
        outcome = press("ctrl+l", foreground="zsh", fail="focus_window", tabs=self.TWO_TABS)
        self.assertFalse(outcome.handled)
        self.assertEqual(outcome.place, Place(1, 2))
        self.assertIn("window:2", outcome.failure or "")
        self.assertIn("window gone", outcome.failure or "")
        self.assertEqual(outcome.shown, [])

    def test_a_failed_landing_keeps_the_new_tab_and_is_logged(self) -> None:
        outcome = press("ctrl+l", foreground="zsh", fail="landing", tabs=self.TWO_TABS)
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.place, Place(2, 2))
        self.assertEqual(outcome.shown, shown_tab(2))
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("left", outcome.logs[0])
        self.assertIn("conflict", outcome.logs[0])

    def test_a_landing_that_never_settles_stops_after_32_steps_and_is_logged(self) -> None:
        outcome = press("ctrl+l", foreground="zsh", restless=True, tabs=self.TWO_TABS)
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.place.tab, 2)
        self.assertEqual(outcome.focused, ["right"] + ["left"] * 32)
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("32", outcome.logs[0])


class FocusPaneOrTabAction(unittest.TestCase):
    def test_it_moves_focus_and_reports_what_it_did(self) -> None:
        within = run_action("right")
        self.assertTrue(within.ok)
        self.assertEqual(within.outcome, "moved")
        self.assertEqual(within.place, Place(1, 3))

        across = run_action("right", tabs=(Tab(2, 2), Tab(3, 2)))
        self.assertTrue(across.ok)
        self.assertEqual(across.outcome, "switched_tab")
        self.assertEqual(across.place, Place(2, 1))
        self.assertEqual(across.shown, shown_tab(2))

    def test_a_direction_other_than_left_or_right_fails_and_moves_nothing(self) -> None:
        for direction in ["up", "sideways", ""]:
            with self.subTest(direction=direction):
                outcome = run_action(direction)
                self.assertFalse(outcome.ok)
                self.assertIn("left or right", outcome.message or "")
                self.assertEqual(outcome.focused, [])
                self.assertEqual(outcome.place, Place(1, 2))

    def test_a_failed_rex_call_fails_the_action_with_the_reason(self) -> None:
        outcome = run_action("left", fail="view")
        self.assertFalse(outcome.ok)
        self.assertIn("view unavailable", outcome.message or "")


class WhenNoAppCanShowTheTab(unittest.TestCase):
    TWO_TABS = (Tab(2, 2), Tab(3, 2))

    def test_focus_still_moves_within_a_tab(self) -> None:
        outcome = run_action("right", app="none")
        self.assertTrue(outcome.ok)
        self.assertEqual(outcome.outcome, "moved")
        self.assertEqual(outcome.place, Place(1, 3))

    def test_the_action_fails_at_the_edge_and_leaves_the_tab_alone(self) -> None:
        outcome = run_action("right", app="none", tabs=self.TWO_TABS)
        self.assertFalse(outcome.ok)
        self.assertIn("no Rex app", outcome.message or "")
        self.assertEqual(outcome.place, Place(1, 2))
        self.assertEqual(outcome.shown, [])

    def test_run_from_the_cli_the_action_stops_at_the_edge_even_with_an_app(self) -> None:
        # The CLI names the app as the client, but the app refuses actions from the CLI unless
        # Remote Control is on, and that refusal comes after the action has already returned.
        for origin in ["cli", "api"]:
            with self.subTest(origin=origin):
                outcome = run_action("right", origin=origin, tabs=self.TWO_TABS)
                self.assertFalse(outcome.ok)
                self.assertIn("no Rex app", outcome.message or "")
                self.assertEqual(outcome.place, Place(1, 2))
                self.assertEqual(outcome.shown, [])

    def test_an_app_that_refuses_to_show_the_tab_is_logged(self) -> None:
        outcome = press("ctrl+l", foreground="zsh", app="fails", tabs=self.TWO_TABS)
        self.assertTrue(outcome.handled)
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("window:2", outcome.logs[0])
        self.assertIn("app refused", outcome.logs[0])


class CmdKeys(unittest.TestCase):
    def test_each_cmd_key_runs_its_action(self) -> None:
        expected = {
            "cmd+[BracketLeft]": ("client.tab.previous", {}),
            "cmd+[BracketRight]": ("client.tab.next", {}),
            "cmd+n": ("client.tab.new", {}),
            "cmd+r": ("client.tab.rename", {}),
            "cmd+s": ("session.switch", {}),
            "cmd+shift+r": ("session.rename", {}),
            "cmd+shift+[BracketLeft]": ("session.previous", {}),
            "cmd+shift+[BracketRight]": ("session.next", {}),
            "cmd+[Backslash]": ("pane.split.right", {}),
            "cmd+shift+m": ("pane.zoom", {}),
            "cmd+g": ("lazygit", {}),
        }
        bound = action_bindings()
        for key, (action, args) in expected.items():
            with self.subTest(key=key):
                self.assertIn(key, bound)
                self.assertEqual(bound[key], {"action": action, "args": args})

    def test_ctrl_h_and_l_run_focus_pane_or_tab(self) -> None:
        bound = action_bindings()
        self.assertEqual(
            bound["ctrl+h"], {"action": "focus_pane_or_tab", "args": {"direction": "left"}}
        )
        self.assertEqual(
            bound["ctrl+l"], {"action": "focus_pane_or_tab", "args": {"direction": "right"}}
        )

    def test_no_other_keys_are_bound_to_actions(self) -> None:
        self.assertEqual(len(action_bindings()), 13)


REPO = "/Users/someone/Repos/project"


def split_beside(cwd: str) -> str:
    """The split cmd+g asks for: lazygit to the right of the pressed pane, closing when it exits.
    It starts through an interactive zsh, because PATH, EDITOR and XDG_CONFIG_HOME are set in .zshrc,
    which the login shell Rex would otherwise use doesn't read."""
    return (
        "new_split block:test horizontal after focus=true com.superlogical.terminal.shell "
        f"shell=none /opt/homebrew/bin/zsh -i -c lazygit cwd={cwd} on_completion=true"
    )


ZOOM_LAZYGIT = "zoom_block block:lazygit zoom=true"


class Lazygit(unittest.TestCase):
    def test_cmd_g_opens_lazygit_zoomed_in_the_pressed_panes_directory(self) -> None:
        for program in ["zsh", "nvim", "fzf"]:
            with self.subTest(program=program):
                outcome = press("cmd+g", foreground=program, cwd=REPO)
                self.assertTrue(outcome.handled)
                self.assertEqual(outcome.opened, [split_beside(REPO), ZOOM_LAZYGIT])
                self.assertEqual(outcome.logs, [])

    def test_a_failed_process_lookup_still_opens_lazygit_without_a_directory(self) -> None:
        outcome = press("cmd+g", foreground="<lookup fails>")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.opened, [split_beside("nil"), ZOOM_LAZYGIT])
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("lookup failed", outcome.logs[0])

    def test_a_process_with_no_directory_still_opens_lazygit_and_is_logged(self) -> None:
        outcome = press("cmd+g", foreground="zsh", cwd="")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.opened, [split_beside("nil"), ZOOM_LAZYGIT])
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("working directory", outcome.logs[0])

    def test_a_failed_split_fails_with_the_reason_and_zooms_nothing(self) -> None:
        outcome = press("cmd+g", foreground="zsh", cwd=REPO, fail="new_split")
        self.assertFalse(outcome.handled)
        self.assertIn("too many blocks", outcome.failure or "")
        self.assertIn(REPO, outcome.failure or "")
        self.assertEqual(outcome.opened, [split_beside(REPO)])

    def test_a_failed_zoom_leaves_lazygit_open_and_is_logged(self) -> None:
        outcome = press("cmd+g", foreground="zsh", cwd=REPO, fail="zoom_block")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.opened, [split_beside(REPO), ZOOM_LAZYGIT])
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("block:lazygit", outcome.logs[0])
        self.assertIn("block gone", outcome.logs[0])

    def test_a_split_that_returns_anything_but_one_new_block_zooms_nothing(self) -> None:
        for fail in ["split_none", "split_two", "split_same"]:
            with self.subTest(fail=fail):
                outcome = press("cmd+g", foreground="zsh", cwd=REPO, fail=fail)
                self.assertFalse(outcome.handled)
                self.assertIn("lazygit", outcome.failure or "")
                self.assertEqual(outcome.opened, [split_beside(REPO)])


class SessionSaver(unittest.TestCase):
    def test_loading_the_config_starts_the_saver_once_with_uv(self) -> None:
        startup = start_rex()
        self.assertEqual(
            startup.started,
            [
                [
                    "/Users/someone/.local/bin/uv",
                    "run",
                    "--offline",
                    "--quiet",
                    "--script",
                    "/Users/someone/Repos/ooloth/dotfiles/tools/rex/saver.py",
                    "run",
                    "--state-dir",
                    "/Users/someone/.local/state/rex-restore",
                ]
            ],
        )
        self.assertEqual(startup.logs, [])

    def test_every_binding_loads_when_the_saver_cannot_start(self) -> None:
        expected = start_rex().bindings
        for mode in ("missing", "raises", "fails"):
            with self.subTest(mode=mode):
                startup = start_rex(mode)
                self.assertEqual(startup.started, [])
                self.assertEqual(startup.bindings, expected)
                self.assertEqual(len(startup.logs), 1)
                self.assertIn("session saver", startup.logs[0])


def main() -> int:
    global LUA
    failed = False
    for interpreter in INTERPRETERS:
        if shutil.which(interpreter) is None:
            print(
                f"{interpreter} is not installed, so init.lua is not tested under it",
                file=sys.stderr,
            )
            return 1
        LUA = interpreter
        print(f"== {interpreter}", file=sys.stderr)
        result = unittest.main(exit=False).result
        failed = failed or not result.wasSuccessful()
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
