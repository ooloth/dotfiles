-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    go = { 'gofumpt', 'goimports', 'gci' },
  },
})

--  TODO: lsp
--  TODO: treesitter
--  TODO: linting
--  TODO: dap
