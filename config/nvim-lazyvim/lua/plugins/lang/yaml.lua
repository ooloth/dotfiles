--  TODO: linting?

-- The LazyVim YAML extra is installed (includes lsp + treesitter):
-- https://www.lazyvim.org/extras/lang/yaml

return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = { "yamlls" },
    },
    -- opts = function(_, opts)
    --   opts.ensure_installed = opts.ensure_installed or {}
    --   table.insert(opts.ensure_installed, "yamlls")
    -- end,
  },


  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        yaml = { "prettier" }
      }
    },
  },
}

-- -- install everything we need (see: https://mason-registry.dev/registry/list)
-- require('mason-tool-installer').setup({ ensure_installed = { 'yamlls' } })
-- vim.api.nvim_command('MasonToolsInstall')

-- -- lsp
-- require('lspconfig').yamlls.setup({
--   settings = {
--     yaml = {
--       -- see: https://github.com/b0o/SchemaStore.nvim?tab=readme-ov-file#usage
--       schemas = require('schemastore').yaml.schemas(),
--       validate = { enable = true },
--     },
--   },
-- })

-- -- formatting (see: https://github.com/stevearc/conform.nvim#setup)
-- require('conform').setup({
--   formatters_by_ft = {
--     yaml = { 'prettier' },
--   },
-- })
