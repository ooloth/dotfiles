-- inherit everything from after/ftplugin/javascript.lua
-- includes lsp (tsserver) and linting (eslint-lsp)
vim.cmd.runtime({ 'after/ftplugin/javascript.lua', bang = true })

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    javascriptreact = { 'prettier' },
  },
})

--  TODO: treesitter
--  TODO: dap?
