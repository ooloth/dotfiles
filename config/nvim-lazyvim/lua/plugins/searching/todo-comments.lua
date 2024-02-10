return {
  {
    'folke/todo-comments.nvim',
    keys = function() -- replace all keys
      return {
        -- "find"
        { '<leader>ft', '<cmd>TodoTelescope<cr>', desc = 'Todo' },
      }
    end,
    -- init = function()
    --   require('tint').refresh()
    -- end,
  },
}
