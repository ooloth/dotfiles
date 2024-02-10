return {
  'folke/trouble.nvim',
  keys = {
    { '<leader>xx', '<cmd>TroubleToggle document_diagnostics<cr>', desc = 'Diagnostics (file)' },
    { '<leader>xa', '<cmd>TroubleToggle workspace_diagnostics<cr>', desc = 'Diagnostics (all)' },
    { '<leader>xX', false },
    { '<leader>xL', false },
    { '<leader>xQ', false },
  },
  opts = {
    -- see: https://github.com/folke/trouble.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
    auto_close = true,
    height = 14,
  },
}
