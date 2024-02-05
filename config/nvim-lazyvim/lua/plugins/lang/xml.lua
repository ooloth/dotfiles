local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'lemminx', 'prettier' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        lemminx = {},
      },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'xml' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      -- Also need to install @prettier/plugin-xml in project:
      -- https://github.com/prettier/plugin-xml
      extend(opts.formatters_by_ft, { xml = { 'prettier' } })
    end,
  },

  {
    'mfussenegger/nvim-lint',
    opts = function(_, opts)
      extend(opts.linters_by_ft, { xml = { 'tidy' } })
    end,
  },
}
