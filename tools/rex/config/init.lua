-- https://www.superlogical.com/rex/docs/customize/config
-- https://www.superlogical.com/rex/docs/reference/lua
-- https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts

local terminal = "com.superlogical.terminal"

-- Programs that use ctrl+h/j/k/l for their own split navigation (the same list as is_vim in tmux.conf)
local navigates_itself = { nvim = true, vim = true, vi = true, view = true, fzf = true }

local opposite = { left = "right", right = "left" }

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
  assert(opposite[direction], "unexpected direction: " .. tostring(direction))

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
    local step, step_err = rex.session.focus_direction({ session_id = session_id, direction = opposite[direction], wrap = false })
    if step == nil then
      landing_problem = "landing " .. opposite[direction] .. " in tab " .. target .. " failed: " .. tostring(step_err)
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

rex.action({
  name = "focus_pane_or_tab",
  title = "Focus Pane or Tab",
  description = "Focus the pane to the left or right, or the neighbouring tab when at the edge.",
  category = "Pane",
  args = {
    type = "object",
    properties = { direction = { type = "string", enum = { "left", "right" } } },
    required = { "direction" },
    additionalProperties = false,
  },
  run = function(ctx, args)
    if not opposite[args.direction] then
      error("direction must be left or right, not " .. tostring(args.direction), 0)
    end

    -- Like vim-tmux-navigator: a program that navigates itself gets the key. A key bound to an action
    -- can't pass itself on, so the action sends it to the program.
    if ctx.origin == "key" then
      local process, lookup_err = rex.block.call(terminal, "process", { block_id = ctx.block_id })
      if process == nil then
        rex.log("focus_pane_or_tab " .. args.direction .. ": process lookup failed for " .. tostring(ctx.block_id) .. ": " .. tostring(lookup_err))
      elseif process.foreground and navigates_itself[process.foreground.name] then
        rex.client.queue("pane.send_key", { key = args.direction == "left" and "ctrl+h" or "ctrl+l" })
        return { outcome = "sent_to_program" }
      end
    end

    -- Only an action has the app that ran it, which rex.client.queue needs. The app acts on the
    -- queue after run returns, so a refusal can't be seen here. Run from the CLI or the API, the
    -- action still names the app as its client, but the app refuses unless Remote Control is on, so
    -- only a key or the command palette may cross into another tab.
    local app_ran_it = ctx.client_id ~= nil and (ctx.origin == "key" or ctx.origin == "palette")
    local show_tab = app_ran_it and function(session_id, window_id)
      rex.client.queue("session.select", { session_id = session_id, window_id = window_id })
    end or nil
    local outcome, problem = focus_pane_or_tab(ctx.session_id, args.direction, show_tab)
    if outcome == nil then error(problem, 0) end
    if problem then rex.log("focus_pane_or_tab " .. args.direction .. ": " .. problem) end
    return { outcome = outcome }
  end,
})

-- Like vim-tmux-navigator: pass the key to a program that navigates itself, otherwise move focus.
-- Wraps at the edge, as tmux's select-pane does.
local function focus_pane_unless_program_navigates(direction)
  assert(direction == "up" or direction == "down", "unexpected direction: " .. tostring(direction))

  return function(ctx)
    local process, lookup_err = rex.block.call(terminal, "process", { block_id = ctx.block_id })
    if process == nil then
      rex.log("pane focus " .. direction .. ": process lookup failed for " .. tostring(ctx.block_id) .. ": " .. tostring(lookup_err))
    elseif process.foreground and navigates_itself[process.foreground.name] then
      return false
    end

    local _, focus_err = rex.session.focus_direction({ session_id = ctx.session_id, direction = direction, wrap = true })
    if focus_err then
      rex.log("pane focus " .. direction .. " failed in " .. tostring(ctx.session_id) .. ": " .. tostring(focus_err))
      return false
    end
    return true
  end
end

-- ctrl+h and ctrl+l run the action itself, because only an action can ask the app to show a tab.
rex.bind("ctrl+h", "focus_pane_or_tab", { direction = "left" })
rex.bind("ctrl+j", focus_pane_unless_program_navigates("down"))
rex.bind("ctrl+k", focus_pane_unless_program_navigates("up"))
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
