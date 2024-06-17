-- TODO: https://www.lazyvim.org/extras/lang/toml
-- TODO: lsp?
-- TODO: formatting?
-- TODO: linting?

local extend = require('util').extend

return {
  -- {
  --   'williamboman/mason.nvim',
  --   opts = function(_, opts)
  --     extend(opts.ensure_installed, {})
  --   end,
  -- },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'toml' })
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
  --     formatters_by_ft = {},
  --   },
  -- },
}
