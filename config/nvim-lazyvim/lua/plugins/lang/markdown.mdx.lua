-- inherit everything from after/ftplugin/markdown.lua
vim.cmd.runtime({ 'after/ftplugin/markdown.lua', bang = true })

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    ['markdown.mdx'] = { 'prettier' },
  },
})

--  TODO: lsp
--  TODO: treesitter
--  TODO: linting
--  TODO: dap?
