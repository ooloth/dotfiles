return {
  {
    'folke/trouble.nvim',
    keys = {
      { '<leader>dd', '<cmd>TroubleToggle document_diagnostics<cr>', desc = 'Diagnostics (document)' },
      { '<leader>da', '<cmd>TroubleToggle workspace_diagnostics<cr>', desc = 'Diagnostics (all)' },
      { '<leader>xx', false },
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
