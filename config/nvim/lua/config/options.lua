-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- checkhealth settings
vim.cmd([[
  let g:loaded_perl_provider = 0
  let g:loaded_ruby_provider = 0
]])

if vim.env.IS_WORK_LAPTOP == 'true' then
  vim.cmd([[
    let g:python3_host_prog = '$HOME/.pyenv/versions/py3nvim/bin/python'
  ]])
end

vim.opt.cmdheight = 0
vim.opt.number = false
vim.opt.relativenumber = false
