-- https://www.superlogical.com/rex/docs/customize/config
-- https://www.superlogical.com/rex/docs/reference/lua
-- https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts

local terminal = "com.superlogical.terminal"

-- Programs without a socket Rex can ask that use ctrl+h/j/k/l for their own split navigation (the
-- same list as is_vim in tmux.conf). nvim is asked instead; see ask_nvim below.
local forwards_keys = { vim = true, vi = true, view = true, fzf = true }

-- Each direction ctrl+h/j/k/l moves in: the one it comes back from, nvim's wincmd letter, and the key.
local directions = {
  left = { opposite = "right", letter = "h", key = "ctrl+h" },
  right = { opposite = "left", letter = "l", key = "ctrl+l" },
  up = { opposite = "down", letter = "k", key = "ctrl+k" },
  down = { opposite = "up", letter = "j", key = "ctrl+j" },
}

-- Problems moving focus go here: rex.log output appears in neither the server log nor rex events.
-- One old copy is kept, so it never takes more than twice focus_log_max_bytes.
local focus_log_max_bytes = 1024 * 1024

local function record(message)
  local home = os.getenv("HOME")
  if home == nil then return end
  local directory = home .. "/.local/state/rex"
  local path = directory .. "/focus.log"
  local log = io.open(path, "a")
  if log == nil and rex.exec then
    pcall(rex.exec, { "mkdir", "-p", directory })
    log = io.open(path, "a")
  end
  if log == nil then
    rex.log("focus: can't write " .. path .. ": " .. message)
    return
  end
  if log:seek("end") > focus_log_max_bytes then
    log:close()
    os.rename(path, path .. ".1")
    log = io.open(path, "a")
    if log == nil then return end
  end
  log:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
  log:close()
end

-- The name of the program in front in BLOCK_ID, or nil and why it can't be read.
local function foreground_program(block_id)
  local process, lookup_err = rex.block.call(terminal, "process", { block_id = block_id })
  if process == nil then
    return nil, "process lookup failed for " .. tostring(block_id) .. ": " .. tostring(lookup_err)
  end
  return process.foreground and process.foreground.name
end

-- An nvim started in a Rex pane listens on a socket named after the pane's block, and config.nvim's
-- lua/config/rex.lua answers move and enter on it. Both repos build this path the same way.
local function nvim_socket(block_id)
  local id = type(block_id) == "string" and block_id:match("^block:(.+)$")
  local home = os.getenv("HOME")
  if not id or home == nil then return nil end
  return home .. "/.local/state/rex/nvim/" .. id .. ".sock"
end

-- The server Rex starts from the app may not have Homebrew on its PATH.
local nvim_binary = (function()
  local installed = io.open("/opt/homebrew/bin/nvim", "r")
  if installed == nil then return "nvim" end
  installed:close()
  return "/opt/homebrew/bin/nvim"
end)()

-- Long enough for nvim to answer (about 8 ms measured), short enough that a hung nvim can't hold a key.
local nvim_timeout_seconds = 0.5

local nvim_answers = {
  move = { moved = true, edge = true, busy = true },
  enter = { entered = true },
}

-- Asks the nvim in BLOCK_ID to move (or, on landing, to enter from) DIRECTION. Returns its answer,
-- or nil and why it couldn't be asked or didn't answer as expected.
local function ask_nvim(block_id, call, direction)
  assert(nvim_answers[call], "unexpected nvim call: " .. tostring(call))
  assert(directions[direction], "unexpected direction: " .. tostring(direction))
  local letter = directions[direction].letter
  local socket = nvim_socket(block_id)
  if socket == nil then return nil, "no nvim socket for " .. tostring(block_id) end

  local expression = string.format("v:lua.require'config.rex'.%s('%s')", call, letter)
  local problem = "nvim " .. call .. "('" .. letter .. "') at " .. socket .. ": "
  local result, exec_err = rex.exec(
    { nvim_binary, "--clean", "--server", socket, "--remote-expr", expression },
    { timeout = nvim_timeout_seconds }
  )
  if result == nil then return nil, problem .. tostring(exec_err) end
  if result.timed_out then return nil, problem .. "no answer within " .. nvim_timeout_seconds .. " s" end
  if not result.ok then return nil, problem .. "exit " .. tostring(result.code) .. ": " .. tostring(result.stderr) end
  local answer = tostring(result.stdout):match("^%s*(.-)%s*$")
  if not nvim_answers[call][answer] then return nil, problem .. "unexpected answer " .. string.format("%q", answer) end
  return answer
end

-- Long enough to cross any row of panes that fits on a screen.
local landing_steps_max = 32

-- The tab after (right) or before (left) the active one, in the order Rex shows tabs, wrapping
-- from the last to the first. With one tab it is the active tab itself.
local function neighbour_tab(tab_ids, active_id, direction)
  local active_index
  for i, id in ipairs(tab_ids) do
    if id == active_id then active_index = i end
  end
  if active_index == nil then
    return nil, "the active tab " .. tostring(active_id) .. " is not among the session's tabs"
  end

  local index = (active_index - 1 + (direction == "right" and 1 or -1)) % #tab_ids + 1
  assert(index >= 1, "neighbour tab index below 1: " .. index)
  assert(index <= #tab_ids, "neighbour tab index past the last tab: " .. index)
  return tab_ids[index]
end

-- Moves focus to the pane on the left or right. At the tab's edge it moves to the neighbouring tab
-- instead and focuses that tab's pane nearest the edge just crossed, so pressing the opposite key
-- comes straight back. Returns "moved" or "switched_tab", plus a problem to log if landing in the
-- new tab or showing it went wrong. Returns nil and the problem when nothing moved.
--
-- The app chooses which tab it shows and does not follow session.focus_window, so show_tab asks
-- the app to show the new tab. Without it, nothing crosses a tab's edge, because the server and
-- the app would then disagree about which tab is active.
local function focus_pane_or_tab(session_id, direction, show_tab)
  assert(direction == "left" or direction == "right", "unexpected direction: " .. tostring(direction))
  local back = directions[direction].opposite

  local view, view_err = rex.session.view({ session_id = session_id })
  if view == nil then return nil, "session view failed: " .. tostring(view_err) end

  -- At the edge, focus_direction without wrap changes nothing, so the revision stays the same.
  local moved, focus_err = rex.session.focus_direction({ session_id = session_id, direction = direction, wrap = false })
  if moved == nil then return nil, "focus " .. direction .. " failed: " .. tostring(focus_err) end
  if moved.revision ~= view.revision then return "moved" end

  local tab_ids = {}
  for i, window in ipairs(view.windows or {}) do tab_ids[i] = window.window_id end
  local target, tab_err = neighbour_tab(tab_ids, view.active_window_id, direction)
  if target == nil then return nil, tab_err end
  if show_tab == nil then return nil, "no Rex app to show tab " .. target .. " in, so focus stays in this tab" end

  local switched, switch_err = rex.session.focus_window({ session_id = session_id, window_id = target })
  if switched == nil then return nil, "switching to tab " .. target .. " failed: " .. tostring(switch_err) end

  -- The new tab focuses the pane it last had focused, so walk back to the edge just crossed.
  local landing_problem = "landing in tab " .. target .. " stopped after " .. landing_steps_max .. " steps without reaching the edge"
  local revision = switched.revision
  for _ = 1, landing_steps_max do
    local step, step_err = rex.session.focus_direction({ session_id = session_id, direction = back, wrap = false })
    if step == nil then
      landing_problem = "landing " .. back .. " in tab " .. target .. " failed: " .. tostring(step_err)
      break
    end
    if step.revision == revision then
      landing_problem = nil
      break
    end
    revision = step.revision
  end

  local shown, show_err = pcall(show_tab, view.session_id or session_id, target)
  if not shown then
    return "switched_tab", "asking the app to show tab " .. target .. " failed: " .. tostring(show_err)
  end
  return "switched_tab", landing_problem
end

-- After Rex moves focus, an nvim in the pane it landed on focuses its window on the side Rex came in
-- from, as entering a tab lands on its near-edge pane. Returns a problem to record, if any.
local function enter_landed_nvim(session_id, direction)
  local view, view_err = rex.session.view({ session_id = session_id })
  if view == nil then return "session view after moving failed: " .. tostring(view_err) end
  local landed
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == view.active_window_id then landed = window.focused_block_id end
  end
  if landed == nil then return "no focused pane after moving " .. direction end

  local program, lookup_problem = foreground_program(landed)
  if program ~= "nvim" then return lookup_problem end
  local _, enter_problem = ask_nvim(landed, "enter", directions[direction].opposite)
  return enter_problem
end

rex.action({
  name = "focus_pane_or_tab",
  title = "Focus Pane or Tab",
  description = "Focus the nvim window, pane or tab to the left, right, above or below.",
  category = "Pane",
  args = {
    type = "object",
    properties = { direction = { type = "string", enum = { "left", "right", "up", "down" } } },
    required = { "direction" },
    additionalProperties = false,
  },
  run = function(ctx, args)
    local direction = directions[args.direction]
    if direction == nil then
      error("direction must be left, right, up or down, not " .. tostring(args.direction), 0)
    end
    local function problem_with(text) return "focus " .. args.direction .. ": " .. text end

    -- A key bound to an action can't pass itself on, so the action sends it to the program. From the
    -- command palette or the CLI nothing was typed, so Rex moves instead.
    local from_key = ctx.origin == "key"
    local function send_key_on()
      rex.client.queue("pane.send_key", { key = direction.key })
      return { outcome = "sent_to_program" }
    end

    local program, lookup_problem = foreground_program(ctx.block_id)
    if lookup_problem then record(problem_with(lookup_problem)) end

    -- nvim moves between its own windows. Rex moves only when nvim is at its edge, and nvim keeps the
    -- key while it's typing text or can't be asked.
    if program == "nvim" then
      local answer, nvim_problem = ask_nvim(ctx.block_id, "move", args.direction)
      if nvim_problem then record(problem_with(nvim_problem)) end
      if answer == "moved" then return { outcome = "nvim_moved" } end
      if answer ~= "edge" and from_key then return send_key_on() end
    elseif forwards_keys[program] and from_key then
      return send_key_on()
    end

    local outcome, problem
    if args.direction == "up" or args.direction == "down" then
      -- Up and down wrap at the edge, as tmux's select-pane does.
      local _, focus_err = rex.session.focus_direction({ session_id = ctx.session_id, direction = args.direction, wrap = true })
      if focus_err then problem = "focus " .. args.direction .. " failed: " .. tostring(focus_err) else outcome = "moved" end
    else
      -- Only an action has the app that ran it, which rex.client.queue needs. The app acts on the
      -- queue after run returns, so a refusal can't be seen here. Run from the CLI or the API, the
      -- action still names the app as its client, but the app refuses unless Remote Control is on,
      -- so only a key or the command palette may cross into another tab.
      local app_ran_it = ctx.client_id ~= nil and (ctx.origin == "key" or ctx.origin == "palette")
      local show_tab = app_ran_it and function(session_id, window_id)
        rex.client.queue("session.select", { session_id = session_id, window_id = window_id })
      end or nil
      outcome, problem = focus_pane_or_tab(ctx.session_id, args.direction, show_tab)
    end
    if outcome == nil then
      record(problem_with(problem))
      error(problem, 0)
    end
    if problem then record(problem_with(problem)) end

    local enter_problem = enter_landed_nvim(ctx.session_id, args.direction)
    if enter_problem then record(problem_with(enter_problem)) end
    return { outcome = outcome }
  end,
})

-- Every key runs the action, because only an action can ask the app to show a tab or send a key on.
rex.bind("ctrl+h", "focus_pane_or_tab", { direction = "left" })
rex.bind("ctrl+j", "focus_pane_or_tab", { direction = "down" })
rex.bind("ctrl+k", "focus_pane_or_tab", { direction = "up" })
rex.bind("ctrl+l", "focus_pane_or_tab", { direction = "right" })

-- The cmd keys Ghostty sent to tmux (tools/ghostty/config/config), bound to Rex's own actions.
-- Physical key names keep them on the same keys whatever the keyboard layout.

-- Tabs
rex.bind("cmd+[BracketLeft]", "client.tab.previous")
rex.bind("cmd+[BracketRight]", "client.tab.next")
rex.bind("cmd+n", "client.tab.new")
rex.bind("cmd+r", "client.tab.rename")

-- Sessions
rex.bind("cmd+s", "session.switch")
rex.bind("cmd+shift+r", "session.rename")
rex.bind("cmd+shift+[BracketLeft]", "session.previous")
rex.bind("cmd+shift+[BracketRight]", "session.next")

-- Panes
rex.bind("cmd+[Backslash]", "pane.split.right")
rex.bind("cmd+shift+m", "pane.zoom")

-- The working directory of the program running in BLOCK_ID, or nil and why it can't be read.
local function program_directory(block_id)
  local process, lookup_err = rex.block.call(terminal, "process", { block_id = block_id })
  if process == nil then
    return nil, "process lookup failed for " .. tostring(block_id) .. ": " .. tostring(lookup_err)
  end
  local cwd = process.foreground and process.foreground.cwd
  if cwd == nil or cwd == "" then
    return nil, "the program in " .. tostring(block_id) .. " has no readable working directory"
  end
  return cwd
end

-- Rex runs a command through a login shell that isn't interactive, which doesn't read .zshrc, where
-- PATH, EDITOR and XDG_CONFIG_HOME are set (tools/zsh/config/core.zsh). Lazygit starts through an
-- interactive zsh instead, so it finds itself, nvim and its config as it would in any other pane.
local lazygit_command = { "/opt/homebrew/bin/zsh", "-i", "-c", "lazygit" }

-- Like the full-screen tmux popup on prefix g (tools/tmux/config/tmux.conf): lazygit fills the tab,
-- and quitting it closes its pane, which ends the zoom and leaves the tab as it was. The zoom names
-- the new block, so it can't land on the pane lazygit was opened from.
rex.action({
  name = "lazygit",
  title = "Lazygit",
  description = "Open lazygit zoomed beside the focused pane, in that pane's directory.",
  category = "Pane",
  run = function(ctx)
    assert(ctx.session_id ~= nil, "lazygit: ctx has no session_id")
    assert(ctx.block_id ~= nil, "lazygit: ctx has no block_id")

    -- Without a directory, lazygit starts in the home directory and says it isn't a repository.
    local directory, directory_problem = program_directory(ctx.block_id)
    if directory == nil then rex.log("lazygit: opening without a directory: " .. directory_problem) end

    local split, split_err = rex.session.new_split({
      session_id = ctx.session_id,
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = {
        block = {
          flavor = terminal .. ".shell",
          label = "lazygit",
          options = { shell = "none", command = lazygit_command, cwd = directory, exit = { on_completion = true } },
        },
      },
    })
    if split == nil then
      error("lazygit: splitting " .. ctx.block_id .. " in " .. tostring(directory) .. " failed: " .. tostring(split_err), 0)
    end

    -- One block was asked for, so any other answer is a server bug.
    local block_ids = split.block_ids
    assert(type(block_ids) == "table", "lazygit: the split returned no block_ids")
    assert(#block_ids == 1, "lazygit: the split returned " .. #block_ids .. " blocks, not 1")
    local lazygit_id = block_ids[1]
    assert(lazygit_id ~= ctx.block_id, "lazygit: the split returned the pane it split, " .. ctx.block_id)

    local _, zoom_err = rex.session.zoom_block({ session_id = ctx.session_id, block_id = lazygit_id, zoom = true })
    if zoom_err then
      rex.log("lazygit: opened in " .. lazygit_id .. " but zooming it failed: " .. tostring(zoom_err))
      return { outcome = "opened_unzoomed" }
    end
    return { outcome = "zoomed" }
  end,
})

rex.bind("cmd+g", "lazygit")

-- Session saver (tools/rex/saver.py): saves every session's layout and rebuilds the sessions after
-- the server restarts. This file runs again on every reload and `rex config check`; the saver holds
-- a lock, so only one copy keeps running. It starts last, and guarded, so that a failure here can
-- never stop the bindings above from loading.
local function start_session_saver()
  local home = os.getenv("HOME")
  if not home then
    rex.log("session saver: HOME is not set, so the saver was not started")
    return
  end
  if not (rex.exec and rex.exec.start) then
    rex.log("session saver: rex.exec.start is unavailable, so the saver was not started")
    return
  end
  local ok, started, err = pcall(rex.exec.start, {
    home .. "/.local/bin/uv", "run", "--offline", "--quiet", "--script",
    home .. "/Repos/ooloth/dotfiles/tools/rex/saver.py",
    "run", "--state-dir", home .. "/.local/state/rex-restore",
  }, { detach = true, stdout = false, stderr = false })
  if not ok then
    rex.log("session saver: failed to start: " .. tostring(started))
  elseif not started then
    rex.log("session saver: failed to start: " .. tostring(err))
  end
end
start_session_saver()
