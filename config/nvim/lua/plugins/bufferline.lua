return {
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    keys = {
      { '<leader>bp', '<cmd>BufferLineTogglePin<cr>', desc = 'Toggle pin' },
      { '<leader>bP', '<cmd>BufferLineGroupClose ungrouped<cr>', desc = 'Close non-pinned buffers' },
      { '<leader>p', '<cmd>BufferLineTogglePin<cr>', desc = 'Toggle pin' },
      { '<leader>P', '<cmd>BufferLineGroupClose ungrouped<cr>', desc = 'Close non-pinned buffers' },
    },
  },
}
