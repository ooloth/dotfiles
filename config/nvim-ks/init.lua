-- [[ Install `lazy.nvim` plugin manager ]]
-- see: https://lazy.folke.io/installation
-- see `:help lazy.nvim.txt`
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

-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('lazy').setup({
  -- see: https://github.com/folke/lazy.nvim?tab=readme-ov-file#-structuring-your-plugins
  spec = {
    {
      -- see: https://www.mitchellhanberg.com/create-your-own-neovim-distribution/
      'ooloth/config.nvim', -- the location on GitHub for our distro
      dev = true, -- tells lazy.nvim to actually load a local copy
      opts = {},
      import = 'config.plugins', -- the path to your plugins lazy plugin spec
    },
  },

  change_detection = {
    notify = false,
  },

  checker = {
    notify = false,
  },

  -- see: https://github.com/folke/lazy.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
  defaults = {
    version = '*', -- enable this to try installing the latest stable versions of plugins
  },

  -- dev = { path = '~/Repos', fallback = true }, -- the path to where `dev = true` looks for local plugins
  dev = {
    path = '~/Repos', -- string directory where you store your local plugin projects
    -- plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = { 'ooloth' }, -- For example {"folke"}
    fallback = true, -- Fallback to git when local plugin doesn't exist
  },

  diff = {
    -- diff command <d> can be one of:
    -- * browser: opens the github compare view. Note that this is always mapped to <K> as well,
    --   so you can have a different command for diff <d>
    -- * git: will run git diff and open a buffer with filetype git
    -- * terminal_git: will open a pseudo terminal with git diff
    -- * diffview.nvim: will open Diffview to show the diff
    cmd = 'git',
  },

  install = {
    colorscheme = {},
    missing = true,
  },

  performance = {
    rtp = {
      reset = true, -- reset the runtime path to $VIMRUNTIME and your config directory
      ---@type string[] list any plugins you want to disable here
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        -- "tarPlugin",
        -- "tohtml",
        -- "tutor",
        -- "zipPlugin",
      },
    },
  },

  -- Enable profiling of lazy.nvim. This will add some overhead,
  -- so only enable this when you are debugging lazy.nvim
  profiling = {
    -- Enables extra stats on the debug tab related to the loader cache.
    -- Additionally gathers stats about all package.loaders
    loader = false,
    -- Track each new require in the Lazy profiling tab
    require = false,
  },
})
