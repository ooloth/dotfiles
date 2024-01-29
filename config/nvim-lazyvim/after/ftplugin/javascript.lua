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

-- linting (see: https://github.com/neovim/nvim-lspconfig#quickstart)
require('lspconfig').eslint.setup({
  -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#eslint
  on_attach = function(_, bufnr)
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      command = 'EslintFixAll',
    })
  end,
  settings = {
    -- TODO: prefer node modules version over mason version
    -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
    workingDirectory = { mode = 'auto' },
  },
})

--  TODO: treesitter

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').formatters_by_ft = {
  javascript = { 'prettier' },
  javascriptreact = { 'prettier' },
}

--  TODO: dap

-- TODO: refactor to multiple after/ftplugin/javascript/*.lua files if this one gets too long?
-- TODO: separate javascript + javascriptreact (if any special react config)? if so, add a typescriptreact that inherits from javascriptreact
