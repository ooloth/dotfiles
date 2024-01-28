-- inherit everything from after/ftplugin/javascript.lua
vim.cmd.runtime('after/ftplugin/javascript.lua')

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
  },
})

--  TODO: lsp
--  TODO: treesitter
--  TODO: linting
--  TODO: dap?
