-- inherit everything from after/ftplugin/json.lua
vim.cmd.runtime({ 'after/ftplugin/json.lua', bang = true })

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    jsonc = { 'prettier' },
  },
})

--  TODO: treesitter
--  TODO: linting?