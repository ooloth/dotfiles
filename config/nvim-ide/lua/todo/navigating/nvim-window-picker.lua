local function focus_window()
  local window = require('window-picker').pick_window()

  -- if the type of window is not an integer, return
  if type(window) ~= 'number' then
    return
  end

  -- see: https://github.com/s1n7ax/nvim-window-picker/issues/1#issuecomment-1088623130
  vim.api.nvim_set_current_win(window)
end

return {
  's1n7ax/nvim-window-picker',
  name = 'window-picker',
  event = 'VeryLazy',
  version = '2.*',
  keys = {
    -- stylua: ignore
    { '<leader>ww', focus_window, desc = 'Pick a window' },
  },
  opts = {
    -- see: https://github.com/s1n7ax/nvim-window-picker?tab=readme-ov-file#configuration
    hint = 'floating-big-letter',
    show_prompt = false,
    filter_rules = {
      bo = { filetype = { 'noice', 'neo-tree', 'notify' }, buftype = {} },
    },
  },
}
