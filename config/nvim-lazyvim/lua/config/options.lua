-- Options are automatically loaded before lazy.nvim startup
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- checkhealth
vim.cmd([[
  let g:loaded_perl_provider = 0
  let g:loaded_ruby_provider = 0
]])

-- custom file -> filetype associations
vim.filetype.add({
  filename = {
    ['tsconfig.json'] = 'jsonc',
  },
  pattern = {
    ['.*/vscode/.*%.json'] = 'jsonc',
  },
})

-- python
if vim.env.IS_WORK_LAPTOP == 'true' then
  vim.cmd([[
    let g:python3_host_prog = '$HOME/.pyenv/versions/py3nvim/bin/python'
  ]])
end

-- UI
vim.opt.cmdheight = 0
vim.opt.fillchars = { eob = ' ' } -- hide ~ at end of buffer
vim.opt.laststatus = 0            -- disable statusline since showing in tabline (via lualine)
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.scrolloff = 10
vim.opt.showtabline = 2
vim.opt.spell = false
