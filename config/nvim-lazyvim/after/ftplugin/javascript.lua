-- see: https://www.lazyvim.org/extras/lang/typescript

-- install everything we need (see: https://mason-registry.dev/registry/list)
require('mason-tool-installer').setup({ ensure_installed = { 'eslint-lsp', 'prettier', 'tsserver' } })
vim.api.nvim_command('MasonToolsInstall')

-- lsp (see: https://github.com/neovim/nvim-lspconfig#quickstart)
require('lspconfig').tsserver.setup({
  -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#tsserver
  -- see: https://github.com/typescript-language-server/typescript-language-server/blob/master/docs/configuration.md#tsserver-options
  settings = {
    -- TODO: prefer node modules version over mason version
    completions = {
      completeFunctionCalls = true,
    },
  },
})

--  TODO: lsp
--  TODO: treesitter
--  TODO: linting
--  TODO: dap
