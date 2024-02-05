local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'prettier', 'vue-language-server' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      -- NOTE: linting comes from eslint-lsp (which already includes vue files by default)
      servers = {
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#vuels
        vuels = {},
      },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'vue' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      extend(opts.formatters_by_ft, { vue = { 'prettier' } })
    end,
  },
}
