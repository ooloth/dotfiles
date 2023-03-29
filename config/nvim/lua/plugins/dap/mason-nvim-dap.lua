return {
  'jay-babu/mason-nvim-dap.nvim',
  event = 'VeryLazy',
  dependencies = {
    'williamboman/mason.nvim',
    'mfussenegger/nvim-dap',
  },
  -- config = function(opts)
  --   -- local dap = require('dap')
  --   require('mason-nvim-dap').setup(opts)
  --   require('mason-nvim-dap').setup_handlers()
  -- end,
  opts = {
    automatic_installation = true,
    automatic_setup = true,
    -- see: https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
    ensure_installed = { 'chrome', 'js', 'node2', 'python' },
  },
}
