-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    markdown = { 'prettier' },
  },
})

--  TODO: lsp
--  TODO: treesitter
--  TODO: linting
