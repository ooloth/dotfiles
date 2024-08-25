-- TODO: set up the `lua_ls` language server:
-- https://www.lazyvim.org/plugins/lsp#nvim-lspconfig
-- TODO: debugging: https://www.lazyvim.org/extras/dap/nlua
-- TODO: linting

return {
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { 'stylua' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { 'lua', 'luadoc', 'luap' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      -- LSP Server Settings
      ---@type lspconfig.options
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              codeLens = {
                enable = true,
              },
              completion = {
                callSnippet = 'Replace',
              },
              doc = {
                privateName = { '^_' },
              },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = 'Disable',
                semicolon = 'Disable',
                arrayIndex = 'Disable',
              },
            },
          },
        },
      },
      setup = {},
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = { lua = { 'stylua' } },
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
