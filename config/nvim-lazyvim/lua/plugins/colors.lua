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
    opts = {
      contrast = {
        terminal = false, -- Enable contrast for the built-in terminal
        sidebars = false, -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
        floating_windows = false, -- Enable contrast for floating windows
        cursor_line = false, -- Enable darker background for the cursor line
        non_current_windows = false, -- Enable contrasted background for non-current windows
        filetypes = {}, -- Specify which filetypes get the contrasted (darker) background
      },

      styles = { -- Give comments style such as bold, italic, underline etc.
        comments = { --[[ italic = true ]]
        },
        strings = { --[[ bold = true ]]
        },
        keywords = { --[[ underline = true ]]
        },
        functions = { --[[ bold = true, undercurl = true ]]
        },
        variables = {},
        operators = {},
        types = {},
      },

      plugins = { -- Uncomment the plugins that you use to highlight them
        -- Available plugins:
        -- "dap",
        -- "dashboard",
        -- "eyeliner",
        -- "fidget",
        -- "flash",
        -- "gitsigns",
        -- "harpoon",
        -- "hop",
        -- "illuminate",
        -- "indent-blankline",
        -- "lspsaga",
        -- "mini",
        -- "neogit",
        -- "neotest",
        -- "neo-tree",
        -- "neorg",
        -- "noice",
        -- "nvim-cmp",
        -- "nvim-navic",
        -- "nvim-tree",
        -- "nvim-web-devicons",
        -- "rainbow-delimiters",
        -- "sneak",
        -- 'telescope',
        -- "trouble",
        -- "which-key",
        -- "nvim-notify",
      },

      disable = {
        colored_cursor = false, -- Disable the colored cursor
        borders = false, -- Disable borders between verticaly split windows
        background = false, -- Prevent the theme from setting the background (NeoVim then uses your terminal background)
        term_colors = false, -- Prevent the theme from setting terminal colors
        eob_lines = false, -- Hide the end-of-buffer lines
      },

      high_visibility = {
        lighter = false, -- Enable higher contrast text for lighter style
        darker = false, -- Enable higher contrast text for darker style
      },

      lualine_style = 'default', -- Lualine style ( can be 'stealth' or 'default' )

      async_loading = true, -- Load parts of the theme asyncronously for faster startup (turned on by default)

      custom_colors = nil, -- If you want to override the default colors, set this to a function

      custom_highlights = {}, -- Overwrite highlights with your own
    },
  },

  -- Configure LazyVim to load dracula
  {
    'LazyVim/LazyVim',
    -- opts = { colorscheme = 'gruvbox' },
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
