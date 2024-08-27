-- TODO: https://www.lazyvim.org/plugins/editor#todo-commentsnvim

return {
  'folke/todo-comments.nvim',
  event = 'VeryLazy',
  opts = {
    -- FIXME: doesn't do anything yet
    -- see: https://github.com/folke/todo-comments.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
    gui_style = {
      fg = 'NONE', -- The gui style to use for the fg highlight group.
      bg = 'NONE', -- The gui style to use for the bg highlight group.
    },
    highlight = {
      after = 'fg',
      -- after = '',
      keyword = 'fg',
      multiline = false,
    },
  },
  -- FIXME: doesn't solve the problem of TODO/FIXME/NOTE not tinting
  init = function()
    vim.keymap.set('n', '<leader>st', '<cmd>TodoTelescope<cr>', { desc = 'Todo' })
  end,
}
