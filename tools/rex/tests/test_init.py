#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Tests for tools/rex/config/init.lua, which binds ctrl+h/j/k/l to move between nvim windows, Rex
panes and Rex tabs, and cmd keys to tabs, sessions, splits and lazygit.

Run with: uv run tools/rex/tests/test_init.py

Each test loads init.lua in a bare `lua` with the `rex` API stubbed by a fake session, presses one
key, and reads what happened: whether the key was handled, which way Rex was asked to move focus,
where focus ended up, what the app was asked to do, which calls went to nvim, what was recorded in
focus.log, and which splits and zooms were asked for. The fake session's tabs are rows of panes
side by side, and its revision rises only when focus changes, as Rex's does. A pane can run nvim,
whose windows are also a row, and the fake rex.exec answers nvim's move and enter calls the way
config.nvim's lua/config/rex.lua does. A key bound to an action runs that action the way Rex does,
with the app as its client. Pressing <actions> instead lists every key bound to a named action,
with its arguments, <action> runs the focus_pane_or_tab action as `rex do` would, and <sweep>
presses one key in each of many layouts.
"""

from __future__ import annotations

import itertools
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path

INIT_LUA = Path(__file__).resolve().parent.parent / "config" / "init.lua"

# Rex runs init.lua on its own embedded Lua 5.1. LuaJIT implements Lua 5.1, so every test runs under
# it as well as under Lua 5.5, which catches a feature from a later Lua that Rex would reject.
INTERPRETERS = ("lua", "luajit")
LUA = INTERPRETERS[0]

# Stands in for Rex. LAYOUT lists tabs separated by |, the active one marked with *. Each tab is its
# panes separated by commas, then @ and the focused pane. A pane is the name of its foreground
# program, or nvim:WINDOWS:FOCUSED (with :busy when nvim is typing text). FAIL names the call that
# returns an error: view, focus_direction, focus_window, landing (focus_direction, but only after a
# tab switch), lookup (the process lookup), new_split or zoom_block, or split_none, split_two or
# split_same for a split that returns no block, two blocks, or the pane it split. RESTLESS makes
# every focus_direction after a tab switch raise the revision, as if the server never settled. APP
# is ok when an app ran the key or action, none when none did, and fails when the app refuses to
# show a tab. ORIGIN is how <action> was run. NVIM is ok, or how every call to nvim goes wrong:
# fails, timeout or garbage. CWD is the working directory the process lookup reports, or empty.
HARNESS = r"""
local init_lua, key, direction, fail = arg[1], arg[2], arg[3], arg[4]
local exec_mode = arg[5] or "ok"
local layout, restless, cases = arg[6] or "*zsh,zsh,zsh@2", arg[7] == "true", arg[8]
local app, origin, nvim_mode, cwd = arg[9] or "ok", arg[10] or "palette", arg[11] or "ok", arg[12] or ""
local bindings, actions, logs, started = {}, {}, {}, {}
local focus_calls, nvim_calls, shown, opened = {}, {}, {}, {}
local fake

local function reset(spec)
  fake = { tabs = {}, active = 1, revision = 1, switched = false }
  for tab_spec in spec:gmatch("[^|]+") do
    local is_active = tab_spec:sub(1, 1) == "*"
    local panes_spec, focused = (is_active and tab_spec:sub(2) or tab_spec):match("^(.*)@(%d+)$")
    local tab = { panes = {}, focused = tonumber(focused) }
    for pane_spec in panes_spec:gmatch("[^,]+") do
      local windows, window, busy = pane_spec:match("^nvim:(%d+):(%d+)(.*)$")
      if windows then
        tab.panes[#tab.panes + 1] = { program = "nvim", windows = tonumber(windows), window = tonumber(window), busy = busy == ":busy" }
      else
        tab.panes[#tab.panes + 1] = { program = pane_spec }
      end
    end
    fake.tabs[#fake.tabs + 1] = tab
    if is_active then fake.active = #fake.tabs end
  end
  focus_calls, nvim_calls, shown, opened = {}, {}, {}, {}
end

local function changed() fake.revision = fake.revision + 1 end

local function check_session(args) assert(args.session_id == "session:test", "session_id not passed from ctx") end

local function block_of(t, p) return "block:" .. t .. "-" .. p end

local function pane_of(block_id)
  local t, p = tostring(block_id):match("^block:(%d+)%-(%d+)$")
  local tab = t and fake.tabs[tonumber(t)]
  return tab and tab.panes[tonumber(p)]
end

local function result(stdout) return { ok = true, code = 0, stdout = stdout, stderr = "", timed_out = false } end

-- Answers nvim --clean --server SOCKET --remote-expr EXPR the way config.nvim's rex module does.
local function fake_nvim(argv, opts)
  nvim_calls[#nvim_calls + 1] = table.concat(argv, " ", 2) .. " timeout=" .. tostring(opts and opts.timeout)
  local t, p = tostring(argv[4]):match("/%.local/state/rex/nvim/(%d+)%-(%d+)%.sock$")
  local pane = t and pane_of(block_of(t, p))
  if pane == nil or pane.program ~= "nvim" then
    return { ok = false, code = 1, stdout = "", stderr = "E247: Failed to connect to server", timed_out = false }
  end
  if nvim_mode == "fails" then return { ok = false, code = 1, stdout = "", stderr = "E5108: error in rex.move", timed_out = false } end
  if nvim_mode == "timeout" then return { ok = false, code = -1, signal = "SIGTERM", stdout = "", stderr = "", timed_out = true } end
  if nvim_mode == "garbage" then return result("what\n") end
  local call, letter = tostring(argv[6]):match("^v:lua%.require'config%.rex'%.(%a+)%('(%a)'%)$")
  assert(call, "unexpected expression " .. tostring(argv[6]))
  if call == "move" then
    if pane.busy then return result("busy\n") end
    local step = ({ h = -1, l = 1 })[letter]
    if step and pane.window + step >= 1 and pane.window + step <= pane.windows then
      pane.window = pane.window + step
      return result("moved\n")
    end
    return result("edge\n")
  end
  assert(call == "enter", "unexpected nvim call " .. call)
  if letter == "h" then pane.window = 1 elseif letter == "l" then pane.window = pane.windows end
  return result("entered\n")
end

local exec = setmetatable({
  start = function(argv, opts)
    if exec_mode == "raises" then error("exec.start exploded") end
    if exec_mode == "fails" then return nil, "no such file" end
    assert(opts.detach == true, "the saver must outlive this call")
    started[#started + 1] = argv
    return { pid = 1 }
  end,
}, {
  __call = function(_, argv, opts)
    if argv[1] == "mkdir" then
      os.execute("mkdir -p '" .. argv[3] .. "'")
      return result("")
    end
    return fake_nvim(argv, opts)
  end,
})

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
      if fail == "lookup" then return nil, "lookup failed" end
      local pane = pane_of(args.block_id)
      assert(pane, "process lookup for an unknown block " .. tostring(args.block_id))
      return { foreground = { name = pane.program, cwd = cwd ~= "" and cwd or nil } }
    end,
  },
  exec = exec,
  session = {
    view = function(args)
      check_session(args)
      if fail == "view" then return nil, "view unavailable" end
      local windows = {}
      for i, tab in ipairs(fake.tabs) do
        windows[i] = { window_id = "window:" .. i, focused_block_id = block_of(i, tab.focused) }
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
        if pane < 1 or pane > #tab.panes then
          pane = args.wrap and (pane - 1) % #tab.panes + 1 or tab.focused
        end
        if pane ~= tab.focused then
          tab.focused = pane
          changed()
        end
      end
      return { revision = fake.revision }
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
  },
}

if exec_mode == "missing" then rex.exec = nil end

reset(layout)
dofile(init_lua)

local function list(t)
  local out = {}
  for i, v in ipairs(t) do out[i] = string.format("%q", v) end
  return "[" .. table.concat(out, ",") .. "]"
end

local function place()
  local tab = fake.tabs[fake.active]
  local pane = tab.panes[tab.focused]
  return string.format('"tab":%d,"pane":%d,"window":%d,"shown":%s,"nvim_calls":%s',
    fake.active, tab.focused, pane.window or 0, list(shown), list(nvim_calls))
end

-- Presses K as Rex does: a function gets ctx, and an action runs with the app as its client.
-- Returns whether the key was handled, and the action's error if it failed.
local function press(k)
  local b = bindings[k]
  local key_ctx = { session_id = "session:test", block_id = block_of(fake.active, fake.tabs[fake.active].focused) }
  if type(b.target) == "function" then return b.target(key_ctx, { keybinding = k }) == true end
  local def = actions[b.target]
  assert(def, k .. " is bound to an undefined action " .. tostring(b.target))
  key_ctx.client_id = app ~= "none" and "client:test" or nil
  key_ctx.origin = "key"
  local ok, outcome = pcall(def.run, key_ctx, b.args or {})
  if ok then return true end
  return false, tostring(outcome)
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
  local client_id = app ~= "none" and "client:test" or nil
  local block_id = block_of(fake.active, fake.tabs[fake.active].focused)
  local action_ctx = { session_id = "session:test", block_id = block_id, client_id = client_id, origin = origin }
  local ok, outcome = pcall(def.run, action_ctx, { direction = direction ~= "" and direction or nil })
  local reported = ok and type(outcome) == "table" and string.format("%q", tostring(outcome.outcome)) or "null"
  local message = ok and "null" or string.format("%q", tostring(outcome))
  io.write(string.format('{"ok":%s,"outcome":%s,"message":%s,"focused":%s,%s}',
    tostring(ok), reported, message, list(focus_calls), place()))
  return
end

if key == "<sweep>" then
  local out = {}
  for spec, k in cases:gmatch("([^/;]+)/([^;]+)") do
    reset(spec)
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
class Nvim:
    windows: int
    window: int
    busy: bool = False


Pane = str | Nvim


@dataclass(frozen=True)
class Tab:
    panes: tuple[Pane, ...]
    focused: int


@dataclass(frozen=True)
class Layout:
    tabs: tuple[Tab, ...]
    active: int = 1


@dataclass(frozen=True)
class Place:
    tab: int
    pane: int
    window: int = 0


def shells(count: int, focused: int, program: str = "zsh") -> Tab:
    return Tab(tuple([program] * count), focused)


def spec(layout: Layout) -> str:
    def pane_spec(pane: Pane) -> str:
        if isinstance(pane, Nvim):
            return f"nvim:{pane.windows}:{pane.window}" + (":busy" if pane.busy else "")
        return pane

    tabs = []
    for i, tab in enumerate(layout.tabs, start=1):
        marker = "*" if i == layout.active else ""
        tabs.append(marker + ",".join(pane_spec(p) for p in tab.panes) + f"@{tab.focused}")
    return "|".join(tabs)


@dataclass
class Run:
    """One harness run, with the HOME it wrote focus.log under."""

    outcome: dict | list
    home: Path

    def focus_log(self) -> str:
        path = self.home / ".local/state/rex/focus.log"
        return path.read_text() if path.exists() else ""


def run_harness(*args: str, home: Path | None = None, saver_home: str | None = None) -> Run:
    home = home or Path(tempfile.mkdtemp())
    env = {"HOME": saver_home or str(home), "PATH": os.environ["PATH"]}
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
    return Run(outcome, home)


@dataclass(frozen=True)
class KeyOutcome:
    handled: bool
    failure: str | None
    focused: list[str]
    place: Place
    shown: list[str]
    nvim_calls: list[str]
    focus_log: str
    logs: list[str]
    opened: list[str]


def place_of(outcome: dict) -> Place:
    return Place(outcome["tab"], outcome["pane"], outcome["window"])


DEFAULT_LAYOUT = Layout((shells(3, 2),))


def press(
    key: str,
    *,
    layout: Layout = DEFAULT_LAYOUT,
    fail: str = "",
    restless: bool = False,
    app: str = "ok",
    nvim: str = "ok",
    cwd: str = "",
    home: Path | None = None,
) -> KeyOutcome:
    run = run_harness(
        key,
        "",
        fail,
        "ok",
        spec(layout),
        str(restless).lower(),
        "",
        app,
        "key",
        nvim,
        cwd,
        home=home,
    )
    outcome = run.outcome
    assert isinstance(outcome, dict)
    return KeyOutcome(
        outcome["handled"],
        outcome["failure"],
        outcome["focused"],
        place_of(outcome),
        outcome["shown"],
        outcome["nvim_calls"],
        run.focus_log(),
        outcome["logs"],
        outcome["opened"],
    )


@dataclass(frozen=True)
class ActionOutcome:
    ok: bool
    outcome: str | None
    message: str | None
    focused: list[str]
    place: Place
    shown: list[str]
    nvim_calls: list[str]


def run_action(
    direction: str,
    *,
    layout: Layout = DEFAULT_LAYOUT,
    fail: str = "",
    app: str = "ok",
    origin: str = "palette",
    nvim: str = "ok",
) -> ActionOutcome:
    run = run_harness(
        "<action>", direction, fail, "ok", spec(layout), "false", "", app, origin, nvim
    )
    outcome = run.outcome
    assert isinstance(outcome, dict)
    return ActionOutcome(
        outcome["ok"],
        outcome["outcome"],
        outcome["message"],
        outcome["focused"],
        place_of(outcome),
        outcome["shown"],
        outcome["nvim_calls"],
    )


@dataclass(frozen=True)
class Startup:
    started: list[list[str]]
    logs: list[str]
    bindings: int


def start_rex(exec_mode: str = "ok", home: str = "/Users/someone") -> Startup:
    run = run_harness("<startup>", "", "", exec_mode, saver_home=home)
    outcome = run.outcome
    assert isinstance(outcome, dict)
    return Startup(outcome["started"], outcome["logs"], outcome["bindings"])


DIRECTIONS = {"ctrl+h": "left", "ctrl+j": "down", "ctrl+k": "up", "ctrl+l": "right"}
SIDEWAYS = {"ctrl+h": "left", "ctrl+l": "right"}
LETTERS = {"ctrl+h": "h", "ctrl+j": "j", "ctrl+k": "k", "ctrl+l": "l"}


def action_bindings() -> dict[str, dict[str, object]]:
    outcome = run_harness("<actions>", "", "").outcome
    assert isinstance(outcome, dict)
    return outcome["actions"]


def sweep(cases: list[tuple[Layout, str]]) -> list[dict]:
    encoded = ";".join(f"{spec(layout)}/{key}" for layout, key in cases)
    outcome = run_harness("<sweep>", "", "", "ok", spec(DEFAULT_LAYOUT), "false", encoded).outcome
    assert isinstance(outcome, list)
    return outcome


def with_each_tab_active(tabs: tuple[Tab, ...]) -> Iterator[Layout]:
    for active in range(1, len(tabs) + 1):
        yield Layout(tabs, active)


def shell_layouts() -> Iterator[Layout]:
    """Every session of one to three tabs, each a row of one to three shells with any one focused."""
    one_tab = [shells(panes, focused) for panes in range(1, 4) for focused in range(1, panes + 1)]
    for count in range(1, 4):
        for tabs in itertools.product(one_tab, repeat=count):
            yield from with_each_tab_active(tabs)


def mixed_layouts() -> Iterator[Layout]:
    """Every session of one or two tabs of one or two panes, each a shell or an nvim with one or two
    windows, with any pane and any nvim window focused."""
    kinds: list[Pane] = ["zsh", Nvim(1, 1), Nvim(2, 1), Nvim(2, 2)]
    one_tab = [
        Tab(panes, focused)
        for count in (1, 2)
        for panes in itertools.product(kinds, repeat=count)
        for focused in range(1, count + 1)
    ]
    for count in (1, 2):
        for tabs in itertools.product(one_tab, repeat=count):
            yield from with_each_tab_active(tabs)


def windows_of(pane: Pane) -> int:
    return pane.windows if isinstance(pane, Nvim) else 0


def expected_place(layout: Layout, direction: str) -> Place:
    """The next thing along the row of tabs, panes and nvim windows: one nvim window over, else one
    pane over, else the neighbouring tab's near-edge pane. Entering an nvim lands on its window on the
    side entered from."""
    step = 1 if direction == "right" else -1
    tab = layout.tabs[layout.active - 1]
    pane = tab.panes[tab.focused - 1]
    if isinstance(pane, Nvim) and 1 <= pane.window + step <= pane.windows:
        return Place(layout.active, tab.focused, pane.window + step)

    def entered(t: int, p: int) -> Place:
        landed = layout.tabs[t - 1].panes[p - 1]
        near_edge = 1 if direction == "right" else windows_of(landed)
        return Place(t, p, near_edge if isinstance(landed, Nvim) else 0)

    if 1 <= tab.focused + step <= len(tab.panes):
        return entered(layout.active, tab.focused + step)
    target = (layout.active - 1 + step) % len(layout.tabs) + 1
    return entered(target, 1 if direction == "right" else len(layout.tabs[target - 1].panes))


def crosses_tab_edge(layout: Layout, direction: str) -> bool:
    step = 1 if direction == "right" else -1
    tab = layout.tabs[layout.active - 1]
    pane = tab.panes[tab.focused - 1]
    if isinstance(pane, Nvim) and 1 <= pane.window + step <= pane.windows:
        return False
    return not 1 <= tab.focused + step <= len(tab.panes)


def shown_tab(tab: int) -> list[str]:
    """What the app is asked to do when focus crosses into tab number TAB."""
    return [f"session.select session:test window:{tab}"]


TWO_TABS = Layout((shells(2, 2), shells(3, 2)))


class AcrossPanesTabsAndNvimWindows(unittest.TestCase):
    def check(self, layouts: Iterator[Layout]) -> None:
        cases = [(layout, key) for layout in layouts for key in SIDEWAYS]
        results = sweep(cases)
        self.assertEqual(len(results), len(cases))
        for (layout, key), result in zip(cases, results, strict=True):
            with self.subTest(layout=spec(layout), key=key):
                self.assertTrue(result["handled"])
                expected = expected_place(layout, SIDEWAYS[key])
                self.assertEqual(place_of(result), expected)
                crossed = crosses_tab_edge(layout, SIDEWAYS[key])
                self.assertEqual(result["shown"], shown_tab(expected.tab) if crossed else [])

    def test_ctrl_h_and_l_reach_the_next_pane_or_tab_in_every_layout_of_shells(self) -> None:
        self.check(shell_layouts())

    def test_ctrl_h_and_l_reach_the_next_window_pane_or_tab_in_every_layout_with_nvim(self) -> None:
        self.check(mixed_layouts())


class InNvim(unittest.TestCase):
    NVIM_BETWEEN_SHELLS = Layout((Tab(("zsh", Nvim(2, 1, busy=True), "zsh"), 2),))

    def test_a_busy_nvim_gets_every_key_and_nothing_moves(self) -> None:
        for key in DIRECTIONS:
            with self.subTest(key=key):
                outcome = press(key, layout=self.NVIM_BETWEEN_SHELLS)
                self.assertTrue(outcome.handled)
                self.assertEqual(outcome.shown, [f"pane.send_key {key}"])
                self.assertEqual(outcome.focused, [])
                self.assertEqual(outcome.place, Place(1, 2, 1))

    def test_an_nvim_rex_cannot_reach_gets_the_key_and_the_reason_is_recorded(self) -> None:
        layout = Layout((Tab(("zsh", Nvim(2, 1), "zsh"), 2),))
        reasons = {"fails": "E5108", "timeout": "0.5", "garbage": "what"}
        for nvim, reason in reasons.items():
            for key in DIRECTIONS:
                with self.subTest(nvim=nvim, key=key):
                    outcome = press(key, layout=layout, nvim=nvim)
                    self.assertTrue(outcome.handled)
                    self.assertEqual(outcome.shown, [f"pane.send_key {key}"])
                    self.assertEqual(outcome.focused, [])
                    self.assertIn("1-2.sock", outcome.focus_log)
                    self.assertIn(reason, outcome.focus_log)

    def test_nvim_is_asked_at_its_blocks_socket_with_a_half_second_timeout(self) -> None:
        outcome = press("ctrl+l", layout=Layout((Tab((Nvim(2, 1),), 1),)))
        self.assertEqual(len(outcome.nvim_calls), 1)
        call = outcome.nvim_calls[0]
        self.assertTrue(call.startswith("--clean --server "), call)
        self.assertIn("/.local/state/rex/nvim/1-1.sock --remote-expr", call)
        self.assertIn("v:lua.require'config.rex'.move('l')", call)
        self.assertTrue(call.endswith(" timeout=0.5"), call)

    def test_at_nvims_top_or_bottom_edge_rex_wraps_and_enters_from_the_side_it_came_in(
        self,
    ) -> None:
        layout = Layout((Tab((Nvim(2, 1), "zsh"), 1),))
        for key, back in [("ctrl+j", "k"), ("ctrl+k", "j")]:
            with self.subTest(key=key):
                outcome = press(key, layout=layout)
                self.assertTrue(outcome.handled)
                self.assertEqual(outcome.focused, [f"{DIRECTIONS[key]}+wrap"])
                self.assertEqual(len(outcome.nvim_calls), 2)
                self.assertIn(f"move('{LETTERS[key]}')", outcome.nvim_calls[0])
                self.assertIn(f"enter('{back}')", outcome.nvim_calls[1])

    def test_from_the_palette_a_busy_nvim_does_not_stop_rex(self) -> None:
        outcome = run_action("right", layout=self.NVIM_BETWEEN_SHELLS)
        self.assertTrue(outcome.ok)
        self.assertEqual(outcome.place, Place(1, 3))
        self.assertEqual(outcome.shown, [])

    def test_a_failed_enter_keeps_focus_on_the_new_pane_and_is_recorded(self) -> None:
        layout = Layout((Tab(("zsh", Nvim(2, 2)), 1),))
        outcome = press("ctrl+l", layout=layout, nvim="fails")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.place, Place(1, 2, 2))
        self.assertIn("enter", outcome.focus_log)
        self.assertIn("E5108", outcome.focus_log)


class InProgramsThatNavigateThemselves(unittest.TestCase):
    def test_vim_vi_view_and_fzf_get_every_key_and_nvim_is_never_asked(self) -> None:
        for program in ["vim", "vi", "view", "fzf"]:
            for key in DIRECTIONS:
                with self.subTest(program=program, key=key):
                    outcome = press(key, layout=Layout((shells(2, 1, program),)))
                    self.assertTrue(outcome.handled)
                    self.assertEqual(outcome.shown, [f"pane.send_key {key}"])
                    self.assertEqual(outcome.focused, [])
                    self.assertEqual(outcome.nvim_calls, [])

    def test_a_name_that_only_contains_vim_gets_pane_navigation(self) -> None:
        outcome = press("ctrl+h", layout=Layout((shells(3, 2, "nvim-qt"),)))
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.place, Place(1, 1))
        self.assertEqual(outcome.nvim_calls, [])


class UpAndDown(unittest.TestCase):
    def test_ctrl_j_and_k_move_focus_their_own_way_and_wrap(self) -> None:
        for key in ["ctrl+j", "ctrl+k"]:
            with self.subTest(key=key):
                outcome = press(key)
                self.assertTrue(outcome.handled)
                self.assertEqual(outcome.focused, [f"{DIRECTIONS[key]}+wrap"])
                self.assertEqual(outcome.shown, [])


class WhenRexCallsFail(unittest.TestCase):
    def test_a_failed_process_lookup_still_moves_focus_and_is_recorded(self) -> None:
        outcome = press("ctrl+h", fail="lookup")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.place, Place(1, 1))
        self.assertIn("block:1-2", outcome.focus_log)
        self.assertIn("lookup failed", outcome.focus_log)

    def test_a_failed_focus_moves_nothing_and_reports_why(self) -> None:
        outcome = press("ctrl+l", fail="focus_direction")
        self.assertFalse(outcome.handled)
        self.assertIn("right", outcome.failure or "")
        self.assertIn("conflict", outcome.failure or "")
        self.assertIn("conflict", outcome.focus_log)

    def test_a_failed_view_moves_nothing_and_reports_why(self) -> None:
        outcome = press("ctrl+l", fail="view")
        self.assertFalse(outcome.handled)
        self.assertEqual(outcome.place, Place(1, 2))
        self.assertIn("view unavailable", outcome.failure or "")
        self.assertIn("view unavailable", outcome.focus_log)

    def test_a_failed_tab_switch_moves_nothing_and_reports_why(self) -> None:
        outcome = press("ctrl+l", fail="focus_window", layout=TWO_TABS)
        self.assertFalse(outcome.handled)
        self.assertEqual(outcome.place, Place(1, 2))
        self.assertIn("window:2", outcome.failure or "")
        self.assertIn("window gone", outcome.failure or "")
        self.assertEqual(outcome.shown, [])

    def test_a_failed_landing_keeps_the_new_tab_and_is_recorded(self) -> None:
        outcome = press("ctrl+l", fail="landing", layout=TWO_TABS)
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.place, Place(2, 2))
        self.assertEqual(outcome.shown, shown_tab(2))
        self.assertIn("left", outcome.focus_log)
        self.assertIn("conflict", outcome.focus_log)

    def test_a_landing_that_never_settles_stops_after_32_steps_and_is_recorded(self) -> None:
        outcome = press("ctrl+l", restless=True, layout=TWO_TABS)
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.place.tab, 2)
        self.assertEqual(outcome.focused, ["right"] + ["left"] * 32)
        self.assertIn("32", outcome.focus_log)


class FocusLog(unittest.TestCase):
    def test_past_one_megabyte_the_log_moves_aside_and_starts_again(self) -> None:
        home = Path(tempfile.mkdtemp())
        log = home / ".local/state/rex/focus.log"
        log.parent.mkdir(parents=True)
        log.write_text("x" * (1024 * 1024 + 1))
        outcome = press("ctrl+l", fail="view", home=home)
        self.assertIn("view unavailable", outcome.focus_log)
        self.assertLess(len(outcome.focus_log), 1024)
        self.assertEqual((home / ".local/state/rex/focus.log.1").stat().st_size, 1024 * 1024 + 1)

    def test_nothing_is_recorded_when_nothing_goes_wrong(self) -> None:
        outcome = press("ctrl+l", layout=TWO_TABS)
        self.assertEqual(outcome.focus_log, "")


class FocusPaneOrTabAction(unittest.TestCase):
    def test_it_moves_focus_and_reports_what_it_did(self) -> None:
        within = run_action("right")
        self.assertTrue(within.ok)
        self.assertEqual(within.outcome, "moved")
        self.assertEqual(within.place, Place(1, 3))

        across = run_action("right", layout=TWO_TABS)
        self.assertTrue(across.ok)
        self.assertEqual(across.outcome, "switched_tab")
        self.assertEqual(across.place, Place(2, 1))
        self.assertEqual(across.shown, shown_tab(2))

    def test_a_direction_other_than_the_four_fails_and_moves_nothing(self) -> None:
        for direction in ["sideways", ""]:
            with self.subTest(direction=direction):
                outcome = run_action(direction)
                self.assertFalse(outcome.ok)
                self.assertIn("left, right, up or down", outcome.message or "")
                self.assertEqual(outcome.focused, [])
                self.assertEqual(outcome.place, Place(1, 2))

    def test_a_failed_rex_call_fails_the_action_with_the_reason(self) -> None:
        outcome = run_action("left", fail="view")
        self.assertFalse(outcome.ok)
        self.assertIn("view unavailable", outcome.message or "")


class WhenNoAppCanShowTheTab(unittest.TestCase):
    def test_focus_still_moves_within_a_tab(self) -> None:
        outcome = run_action("right", app="none")
        self.assertTrue(outcome.ok)
        self.assertEqual(outcome.outcome, "moved")
        self.assertEqual(outcome.place, Place(1, 3))

    def test_the_action_fails_at_the_edge_and_leaves_the_tab_alone(self) -> None:
        outcome = run_action("right", app="none", layout=TWO_TABS)
        self.assertFalse(outcome.ok)
        self.assertIn("no Rex app", outcome.message or "")
        self.assertEqual(outcome.place, Place(1, 2))
        self.assertEqual(outcome.shown, [])

    def test_run_from_the_cli_the_action_stops_at_the_edge_even_with_an_app(self) -> None:
        # The CLI names the app as the client, but the app refuses actions from the CLI unless
        # Remote Control is on, and that refusal comes after the action has already returned.
        for origin in ["cli", "api"]:
            with self.subTest(origin=origin):
                outcome = run_action("right", origin=origin, layout=TWO_TABS)
                self.assertFalse(outcome.ok)
                self.assertIn("no Rex app", outcome.message or "")
                self.assertEqual(outcome.place, Place(1, 2))
                self.assertEqual(outcome.shown, [])

    def test_an_app_that_refuses_to_show_the_tab_is_recorded(self) -> None:
        outcome = press("ctrl+l", app="fails", layout=TWO_TABS)
        self.assertTrue(outcome.handled)
        self.assertIn("window:2", outcome.focus_log)
        self.assertIn("app refused", outcome.focus_log)


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

    def test_ctrl_h_j_k_l_run_focus_pane_or_tab(self) -> None:
        bound = action_bindings()
        for key, direction in DIRECTIONS.items():
            with self.subTest(key=key):
                self.assertEqual(
                    bound[key], {"action": "focus_pane_or_tab", "args": {"direction": direction}}
                )

    def test_no_other_keys_are_bound(self) -> None:
        self.assertEqual(len(action_bindings()), 15)
        self.assertEqual(start_rex().bindings, 15)


REPO = "/Users/someone/Repos/project"
PRESSED = "block:1-2"


def split_beside(cwd: str) -> str:
    """The split cmd+g asks for: lazygit to the right of the pressed pane, closing when it exits.
    It starts through an interactive zsh, because PATH, EDITOR and XDG_CONFIG_HOME are set in .zshrc,
    which the login shell Rex would otherwise use doesn't read."""
    return (
        f"new_split {PRESSED} horizontal after focus=true com.superlogical.terminal.shell "
        f"shell=none /opt/homebrew/bin/zsh -i -c lazygit cwd={cwd} on_completion=true"
    )


ZOOM_LAZYGIT = "zoom_block block:lazygit zoom=true"


class Lazygit(unittest.TestCase):
    def test_cmd_g_opens_lazygit_zoomed_in_the_pressed_panes_directory(self) -> None:
        for program in ["zsh", "nvim", "fzf"]:
            with self.subTest(program=program):
                outcome = press("cmd+g", layout=Layout((shells(3, 2, program),)), cwd=REPO)
                self.assertTrue(outcome.handled)
                self.assertEqual(outcome.opened, [split_beside(REPO), ZOOM_LAZYGIT])
                self.assertEqual(outcome.logs, [])

    def test_a_failed_process_lookup_still_opens_lazygit_without_a_directory(self) -> None:
        outcome = press("cmd+g", fail="lookup")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.opened, [split_beside("nil"), ZOOM_LAZYGIT])
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("lookup failed", outcome.logs[0])

    def test_a_process_with_no_directory_still_opens_lazygit_and_is_logged(self) -> None:
        outcome = press("cmd+g", cwd="")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.opened, [split_beside("nil"), ZOOM_LAZYGIT])
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("working directory", outcome.logs[0])

    def test_a_failed_split_fails_with_the_reason_and_zooms_nothing(self) -> None:
        outcome = press("cmd+g", cwd=REPO, fail="new_split")
        self.assertFalse(outcome.handled)
        self.assertIn("too many blocks", outcome.failure or "")
        self.assertIn(REPO, outcome.failure or "")
        self.assertEqual(outcome.opened, [split_beside(REPO)])

    def test_a_failed_zoom_leaves_lazygit_open_and_is_logged(self) -> None:
        outcome = press("cmd+g", cwd=REPO, fail="zoom_block")
        self.assertTrue(outcome.handled)
        self.assertEqual(outcome.opened, [split_beside(REPO), ZOOM_LAZYGIT])
        self.assertEqual(len(outcome.logs), 1)
        self.assertIn("block:lazygit", outcome.logs[0])
        self.assertIn("block gone", outcome.logs[0])

    def test_a_split_that_returns_anything_but_one_new_block_zooms_nothing(self) -> None:
        for fail in ["split_none", "split_two", "split_same"]:
            with self.subTest(fail=fail):
                outcome = press("cmd+g", cwd=REPO, fail=fail)
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
