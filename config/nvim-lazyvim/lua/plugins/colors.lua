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
    'ellisonleao/gruvbox.nvim',
    config = true,
    opts = {
      terminal_colors = true, -- add neovim terminal colors
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      invert_intend_guides = false,
      inverse = true, -- invert background for search, diffs, statuslines and errors
      contrast = 'hard', -- can be "hard", "soft" or empty string
      palette_overrides = {},
      overrides = {},
      dim_inactive = true,
      transparent_mode = false,
    },
  },

  {
    'marko-cerovac/material.nvim',
    opts = {},
  },

  -- Load my preferred colorscheme
  {
    'LazyVim/LazyVim',
    opts = { colorscheme = 'catppuccin' },
    -- opts = { colorscheme = 'gruvbox' },
    -- opts = { colorscheme = 'material' },
  },

  {
    'sunjon/shade.nvim',
    event = 'VeryLazy',
    config = true,
    -- see: https://github.com/sunjon/Shade.nvim?tab=readme-ov-file#configuration
    opts = {},
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
