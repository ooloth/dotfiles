return {
  {
    'Mofiqul/dracula.nvim',
    lazy = true,
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

  {
    'NvChad/nvim-colorizer.lua',
    event = 'BufReadPre',
    opts = {
      filetypes = { '*', '!lazy' },
      buftype = { '*', '!prompt', '!nofile' },
      user_default_options = {
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        AARRGGBB = true, -- 0xAARRGGBB hex codes
        css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
        tailwind = true,
      },
    },
  },
}
