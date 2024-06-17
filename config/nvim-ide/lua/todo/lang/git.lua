-- TODO: https://www.lazyvim.org/extras/lang/git
--  TODO: lsp?
--  TODO: linting?

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
      -- see: https://github.com/virchau13/tree-sitter-astro/#troubleshooting
      extend(opts.ensure_installed, { 'diff', 'git_config', 'git_rebase', 'gitattributes', 'gitcommit', 'gitignore' })
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

-- -- -- -- -- install everything we need (see: https://mason-registry.dev/registry/list)
-- -- -- -- require('mason-tool-installer').setup({ ensure_installed = { 'cssls' } })
-- -- -- -- vim.api.nvim_command('MasonToolsInstall')
-- -- -- --
-- -- -- -- enable (broadcasting) snippet capability for completion
-- -- -- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- -- -- capabilities.textDocument.completion.completionItem.snippetSupport = true
-- -- --
-- -- -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#cssls
-- -- require('lspconfig').cssls.setup({
-- --   capabilities = capabilities,
-- -- })
