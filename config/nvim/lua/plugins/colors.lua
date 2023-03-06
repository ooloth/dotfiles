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
      -- see: https://github.com/NvChad/nvim-colorizer.lua#customization
      filetypes = { '*', '!lazy', css = { names = true } },
      buftype = { '*', '!prompt', '!nofile' },
      user_default_options = {
        mode = 'virtualtext', -- 'foreground' | 'background' | 'virtualtext'
        RGB = true, -- #RGB hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        AARRGGBB = true, -- 0xAARRGGBB hex codes
        rgb_fn = true, -- CSS rgb() and rgba() functions
        hsl_fn = true, -- CSS hsl() and hsla() functions
        names = false, -- Named codes like "blue" (not accurate in configs that reference theme colors)
        tailwind = false,
      },
    },
  },
}
