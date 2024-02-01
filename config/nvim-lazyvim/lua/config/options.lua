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
  extension = {
    -- see: https://sbulav.github.io/vim/neovim-improving-work-with-terraform/#correctly-detecting-tf-filetype
    tf = 'terraform',
    tfvars = 'terraform',
    tfstate = 'json',
  },
  filename = {
    ['tsconfig.json'] = 'jsonc',
    -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#docker_compose_language_service
    ['docker-compose.yaml'] = 'yaml.docker-compose',
  },
  pattern = {
    ['docker-compose.*%.yaml'] = 'yaml.docker-compose',
    ['.*/kitty/.*%.conf'] = 'bash',
    ['.*/kitty/.*/.*%.conf'] = 'bash',
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
vim.opt.laststatus = 0 -- disable statusline since showing in tabline (via lualine)
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.scrolloff = 10
vim.opt.showtabline = 2
vim.opt.spell = false
