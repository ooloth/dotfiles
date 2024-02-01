-- LazyVim sets up the `lua_ls` language server:
-- https://www.lazyvim.org/plugins/lsp#nvim-lspconfig

return {
  {
    'williamboman/mason.nvim',
    opts = {
      -- see: https://mason-registry.dev/registry/list
      ensure_installed = { 'stylua' },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = {
      ensure_installed = {
        'lua',
        'luadoc',
        'luap',
      },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        -- see: https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatters
        yaml = { 'stylua' },
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
