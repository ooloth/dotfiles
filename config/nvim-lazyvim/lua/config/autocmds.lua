-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local Util = require('lazyvim.util')

-- wait for lsp server to attach
-- see: https://github.com/LazyVim/LazyVim/blob/befa6c67a4387b0db4f8421d463f5d03f91dc829/lua/lazyvim/util/init.lua#L8-L16
Util.lsp.on_attach(function()
  -- show line diagnostics in floating window while cursor is on line
  -- see: https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization#show-line-diagnostics-automatically-in-hover-window
  vim.api.nvim_create_autocmd('CursorHold', {
    callback = function()
      vim.diagnostic.open_float(nil, { focusable = false })
    end,
  })
end)

Util.on_very_lazy(function()
  vim.cmd([[
    autocmd InsertEnter * set nocursorline
    autocmd InsertLeave * set cursorline
  ]])
end)

-- override default LazyVim options for Markdown files
vim.api.nvim_create_autocmd('FileType', {
  group = 'lazyvim_wrap_spell',
  pattern = { 'markdown' },
  callback = function()
    vim.opt_local.spell = false
    vim.opt_local.wrap = false -- or set conceallevel=0?
  end,
})
