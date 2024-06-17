return {
  {
    'akinsho/bufferline.nvim',
    keys = {
      { '<leader>bp', '<cmd>BufferLineTogglePin<cr>', desc = 'Toggle pin' },
      { '<leader>bP', '<cmd>BufferLineGroupClose ungrouped<cr>', desc = 'Close non-pinned buffers' },
      { '<leader>p', '<cmd>BufferLineTogglePin<cr>', desc = 'Toggle pin' },
      { '<leader>P', '<cmd>BufferLineGroupClose ungrouped<cr>', desc = 'Close non-pinned buffers' },
    },
    opts = {
      options = {
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },

  -- only show the current tab's buffers in bufferline
  {
    'tiagovla/scope.nvim',
    event = 'VeryLazy',
    config = function()
      require('scope').setup()
    end,
  },
}
