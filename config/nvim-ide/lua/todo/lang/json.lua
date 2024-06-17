--  TODO: treesitter
--  TODO: lsp?
--  TODO: linting?
--  TODO: https://www.lazyvim.org/extras/lang/json

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
      extend(opts.ensure_installed, { 'jq', 'json', 'json5', 'jsonc' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        jsonls = {
          -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#jsonls
          settings = {
            json = {
              -- see: https://github.com/b0o/SchemaStore.nvim?tab=readme-ov-file#usage
              schemas = require('schemastore').json.schemas(),
              validate = { enable = true },
            },
          },
        },
      },
      -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#jsonls
      setup = {
        jsonls = function()
          require('lazyvim.util').lsp.on_attach(function(client, _)
            if client.name == 'jsonls' then
              --Enable (broadcasting) snippet capability for completion
              local capabilities = vim.lsp.protocol.make_client_capabilities()
              capabilities.textDocument.completion.completionItem.snippetSupport = true
              capabilities = capabilities
            end
          end)
        end,
      },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        json = { 'prettier' },
        jsonc = { 'prettier' },
      },
    },
  },
}
-- -- require('lspconfig').jsonls.setup({
-- --   settings = {
-- --     json = {
-- --       -- see: https://github.com/b0o/SchemaStore.nvim?tab=readme-ov-file#usage
-- --       schemas = require('schemastore').json.schemas(),
-- --       validate = { enable = true },
-- --     },
-- --   },
-- -- })
