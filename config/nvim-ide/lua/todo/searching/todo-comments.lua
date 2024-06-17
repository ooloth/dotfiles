return {
  {
    'folke/todo-comments.nvim',
    keys = function() -- replace all keys
      return {
        { '<leader>st', '<cmd>TodoTelescope<cr>', desc = 'Todo' },
      }
    end,
    opts = {
      -- FIXME: doesn't do anything yet
      -- see: https://github.com/folke/todo-comments.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
      gui_style = {
        fg = 'BOLD', -- The gui style to use for the fg highlight group.
        bg = 'NONE', -- The gui style to use for the bg highlight group.
      },
    },
    -- FIXME: doesn't solve the problem of TODO/FIXME/NOTE not tinting
    -- init = function()
    --   require('tint').refresh()
    -- end,
  },
}
