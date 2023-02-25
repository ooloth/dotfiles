return {
  {
    'folke/todo-comments.nvim',
    keys = function() -- replace all keys
      return {
        {
          ']t',
          function()
            require('todo-comments').jump_next()
          end,
          desc = 'Next todo comment',
        },
        {
          '[t',
          function()
            require('todo-comments').jump_prev()
          end,
          desc = 'Previous todo comment',
        },
        -- "find"
        { '<leader>ft', '<cmd>TodoTelescope<cr>', desc = 'Todo' },
      }
    end,
  },
}
