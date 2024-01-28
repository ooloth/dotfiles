-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    protobuf = { 'buf' },
  },
})

--  TODO: lsp
--  TODO: treesitter
--  TODO: linting
