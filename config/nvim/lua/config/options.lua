-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.diagnostic.config({
  float = { border = 'rounded', source = 'always' },
  severity_sort = true,
  -- update_in_insert = true,
  virtual_text = { source = 'always' },
})

-- quieter checkhealth
vim.cmd([[
  let g:loaded_perl_provider = 0
  let g:loaded_ruby_provider = 0
]])

-- python
if vim.env.IS_WORK_LAPTOP == 'true' then
  vim.cmd([[
    let g:python3_host_prog = '$HOME/.pyenv/versions/py3nvim/bin/python'
  ]])
end

-- UI
vim.opt.cmdheight = 0
vim.opt.number = false
vim.opt.relativenumber = false
