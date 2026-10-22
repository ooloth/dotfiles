-- https://www.superlogical.com/rex/docs/customize/config
-- https://www.superlogical.com/rex/docs/reference/lua
-- https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts

local terminal = "com.superlogical.terminal"

-- Programs that use ctrl+h/l for their own split navigation (the same list as is_vim in tmux.conf)
local navigates_itself = { nvim = true, vim = true, vi = true, view = true, fzf = true }

-- Like vim-tmux-navigator: pass the key to a program that navigates itself, otherwise move focus.
-- Wraps at the edge, as tmux's select-pane does.
local function focus_pane_unless_program_navigates(direction)
  assert(direction == "left" or direction == "right", "unexpected direction: " .. tostring(direction))

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
rex.bind("ctrl+l", focus_pane_unless_program_navigates("right"))
