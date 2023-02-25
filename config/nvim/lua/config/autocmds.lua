-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local Util = require('lazyvim.util')

Util.on_very_lazy(function()
  vim.cmd([[
      autocmd InsertEnter * set nocursorline
      autocmd InsertLeave * set cursorline
    ]])
end)
