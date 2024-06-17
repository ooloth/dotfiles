--  TODO: lsp
--  TODO: linting
--  TODO: dap?

local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'prettier' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'graphql' })
    end,
  },

  -- {
  --   'neovim/nvim-lspconfig',
  --   opts = {
  --     servers = {
  --     },
  --   },
  -- },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        graphql = { 'prettier' },
      },
    },
  },
}
