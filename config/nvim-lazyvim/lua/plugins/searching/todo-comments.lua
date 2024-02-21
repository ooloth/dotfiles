return {
  {
    'folke/todo-comments.nvim',
    keys = function() -- replace all keys
      return {
        { '<leader>st', '<cmd>TodoTelescope<cr>', desc = 'Todo' },
      }
    end,
    -- FIXME: doesn't solve the problem of TODO/FIXME/NOTE not tinting
    -- init = function()
    --   require('tint').refresh()
    -- end,
  },
}
