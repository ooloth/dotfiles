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

require('lazy').setup({
  -- see: https://github.com/folke/lazy.nvim?tab=readme-ov-file#-structuring-your-plugins
  spec = {
    { import = 'intelligence' }, -- all files in lua/intelligence
    { import = 'lang' }, -- all files in lua/lang
    { import = 'testing' }, -- all files in lua/testing
    { import = 'ui' }, -- all files in lua/ui
    { import = 'plugins' }, -- all files in lua/plugins
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
