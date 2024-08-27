-- ensure leader is set before loading plugins
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- install lazy.nvim (see: https://lazy.folke.io/installation)
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- load my neovim config (see: https://lazy.folke.io/configuration)
-- for more about moving your config into a plugin, see: https://www.mitchellhanberg.com/create-your-own-neovim-distribution/
require('lazy').setup({
  spec = {
    {
      dir = '~/Repos/ooloth/config.nvim', -- the location on GitHub for our distro
      import = 'config.plugins', -- the path to your plugins lazy plugin spec
      opts = {},
    },
  },
  change_detection = { notify = false }, -- shhh
  checker = { notify = false }, -- shhh
  defaults = { version = '*' }, -- try installing the latest stable versions of plugins that support semver
})
