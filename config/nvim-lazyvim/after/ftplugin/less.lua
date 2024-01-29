-- inherit everything from after/ftplugin/css.lua
vim.cmd.runtime({ 'after/ftplugin/css.lua', bang = true })

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    less = { 'prettier' },
  },
})

--  TODO: lsp?
--  TODO: treesitter
--  TODO: linting?
