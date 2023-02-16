-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.cmd([[
  autocmd InsertEnter * set nocursorline
  autocmd InsertLeave * set cursorline
]])

vim.cmd([[
  "see: https://eslint.org/docs/user-guide/configuring
  autocmd BufNewFile,BufRead .eslintrc.json setlocal filetype=jsonc
  "see: https://github.com/microsoft/TypeScript/pull/5450
  autocmd BufNewFile,BufRead tsconfig.json setlocal filetype=jsonc
]])
