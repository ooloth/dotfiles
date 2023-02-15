return {
  -- add dracula
  {
    'Mofiqul/dracula.nvim',
    -- See: https://github.com/Mofiqul/dracula.nvim#-configuration
    opts = {
      italic_comment = true,
      lualine_bg_color = '#282A36',
    },
  },

  -- Configure LazyVim to load dracula
  {
    'LazyVim/LazyVim',
    opts = { colorscheme = 'dracula' },
  },
}
