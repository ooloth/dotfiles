-- TODO: dap?

local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'bash-language-server', 'shellcheck', 'shfmt' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      -- NOTE: linting comes from eslint-lsp (which already includes vue files by default)
      servers = {
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#bashls
        bashls = {},
      },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'bash' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      extend(opts.formatters_by_ft, { bash = { 'shfmt' }, sh = { 'shfmt' } })
    end,
  },

  {
    'mfussenegger/nvim-lint',
    opts = function(_, opts)
      extend(opts.linters_by_ft, { bash = { 'shellcheck' }, sh = { 'shellcheck' } })
    end,
  },
}
