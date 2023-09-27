vim.g.material_style = 'deep ocean'

return {
  {
    'Mofiqul/dracula.nvim',
    -- See: https://github.com/Mofiqul/dracula.nvim#-configuration
    opts = {
      italic_comment = true,
      lualine_bg_color = '#282A36',
    },
  },

  {
    'marko-cerovac/material.nvim',
    opts = {
      high_visibility = {
        lighter = false, -- Enable higher contrast text for lighter style
        darker = true, -- Enable higher contrast text for darker style
      },
    },
  },

  -- Configure LazyVim to load dracula
  {
    'LazyVim/LazyVim',
    opts = { colorscheme = 'catppuccin' },
    -- opts = { colorscheme = 'material' },
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
