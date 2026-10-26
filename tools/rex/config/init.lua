-- https://www.superlogical.com/rex/docs/customize/config
-- https://www.superlogical.com/rex/docs/reference/lua
-- https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts

local terminal = "com.superlogical.terminal"

-- Programs that use ctrl+h/j/k/l for their own split navigation (the same list as is_vim in tmux.conf)
local navigates_itself = { nvim = true, vim = true, vi = true, view = true, fzf = true }

-- Like vim-tmux-navigator: pass the key to a program that navigates itself, otherwise move focus.
-- Wraps at the edge, as tmux's select-pane does.
local function focus_pane_unless_program_navigates(direction)
  assert(
    direction == "left" or direction == "right" or direction == "up" or direction == "down",
    "unexpected direction: " .. tostring(direction)
  )

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

rex.bind("ctrl+h", focus_pane_unless_program_navigates("left"))
rex.bind("ctrl+j", focus_pane_unless_program_navigates("down"))
rex.bind("ctrl+k", focus_pane_unless_program_navigates("up"))
rex.bind("ctrl+l", focus_pane_unless_program_navigates("right"))

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
