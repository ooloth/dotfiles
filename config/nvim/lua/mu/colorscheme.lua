require('mu.plugins.colorscheme.dracula') -- require relative to init.lua
-- require('mu.plugins.colorscheme.nightfly') -- require relative to init.lua

-- style lsp floating windows
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = 'single',
})

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signatureHelp, {
  border = 'single',
})

vim.diagnostic.config({ float = { border = 'single' } })

-- display correct colors when vim opened inside tmux
vim.cmd([[ 
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum" 
]])
