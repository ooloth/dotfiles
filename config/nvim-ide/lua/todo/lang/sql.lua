-- TODO: https://www.lazyvim.org/extras/lang/sql
-- TODO: lsp?
-- TODO: formatting?
-- TODO: linting?

local extend = require('util').extend

return {
  -- {
  --   'williamboman/mason.nvim',
  --   opts = function(_, opts)
  --     extend(opts.ensure_installed, { 'prettier' })
  --   end,
  -- },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'sql' })
    end,
  },

  -- {
  --   'neovim/nvim-lspconfig',
  --   opts = {
  --     servers = {
  --     },
  --   },
  -- },

  -- {
  --   'stevearc/conform.nvim',
  --   opts = {
  --     formatters_by_ft = {
  --     },
  --   },
  -- },
}
