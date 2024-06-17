-- see: https://github.com/folke/lazy.nvim?tab=readme-ov-file#-installation
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- see: https://github.com/folke/lazy.nvim?tab=readme-ov-file#-structuring-your-plugins
require('lazy').setup({
  spec = {
    { import = 'lang' }, -- all files in lua/lang
    { import = 'plugins' }, -- all files in lua/plugins
  },
})
