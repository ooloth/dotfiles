return {
  {
    'folke/trouble.nvim',
    keys = {
      { '<leader>xx', '<cmd>TroubleToggle document_diagnostics<cr>', desc = 'Diagnostics (file)' },
      { '<leader>xa', '<cmd>TroubleToggle workspace_diagnostics<cr>', desc = 'Diagnostics (all)' },
      { '<leader>xX', false },
      { '<leader>xL', false },
      { '<leader>xQ', false },
    },
    opts = {
      auto_close = true,
      height = 14,
    },
  },
}
