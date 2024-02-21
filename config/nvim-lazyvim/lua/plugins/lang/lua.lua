-- LazyVim sets up the `lua_ls` language server:
-- https://www.lazyvim.org/plugins/lsp#nvim-lspconfig

local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'stylua' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'lua', 'luadoc', 'luap' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
      },
    },
  },

  -- {
  --   -- see: https://github.com/mfussenegger/nvim-lint
  --   'mfussenegger/nvim-lint',
  --   opts = {
  --     -- see: https://www.lazyvim.org/plugins/linting#nvim-lint
  --     -- see: https://github.com/mfussenegger/nvim-lint#available-linters
  --     linters_by_ft = {
  --       lua = { 'luacheck' },
  --     },
  --   },
  -- },
}

--  TODO: linting
--  TODO: dap?
