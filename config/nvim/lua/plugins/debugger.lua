return {
  -- {
  -- 'microsoft/vscode-js-debug',
  -- build = 'npm install --legacy-peer-deps && npm run compile',
  -- dependencies = { 'mfussenegger/nvim-dap' },
  -- },

  {
    'jay-babu/mason-nvim-dap.nvim',
    config = function(opt)
      require('mason-nvim-dap').setup(opts)
      require('mason-nvim-dap').setup_handlers({})
    end,
    dependencies = {
      'williamboman/mason.nvim',
      'mfussenegger/nvim-dap',
    },
    opts = {
      automatic_installation = true,
      automatic_setup = true,
      ensure_installed = { 'js' },
    },
  },

  { 'rcarriga/nvim-dap-ui', dependencies = { 'mfussenegger/nvim-dap' } },
}
