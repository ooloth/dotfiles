-- install the formatter
require('mason-tool-installer').setup({ ensure_installed = { 'stylua' } })
vim.api.nvim_command('MasonToolsInstall')

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },
  },
})

--  TODO: lsp
--  TODO: treesitter
--  TODO: linting
--  TODO: dap?
