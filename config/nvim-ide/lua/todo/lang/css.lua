--  TODO: linting?
--  TODO: https://www.lazyvim.org/extras/lang/tailwind

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
      extend(opts.ensure_installed, { 'css', 'scss', 'styled' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        cssls = {},
      },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        css = { 'prettier' },
        less = { 'prettier' },
        scss = { 'prettier' },
      },
    },
  },
}
