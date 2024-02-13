vim.g.material_style = 'deep ocean'

return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    opts = {
      -- see: https://github.com/catppuccin/nvim#integrations
      integrations = {
        harpoon = true,
        native_lsp = {
          inlay_hints = {
            background = true,
          },
        },
        octo = true,
      },
    },
  },

  -- {
  --   'Mofiqul/dracula.nvim',
  --   -- See: https://github.com/Mofiqul/dracula.nvim#-configuration
  --   opts = {
  --     italic_comment = true,
  --     lualine_bg_color = '#282A36',
  --   },
  -- },

  -- {
  --   'ellisonleao/gruvbox.nvim',
  --   config = true,
  --   opts = {
  --     terminal_colors = true, -- add neovim terminal colors
  --     undercurl = true,
  --     underline = true,
  --     bold = true,
  --     italic = {
  --       strings = true,
  --       emphasis = true,
  --       comments = true,
  --       operators = false,
  --       folds = true,
  --     },
  --     strikethrough = true,
  --     invert_selection = false,
  --     invert_signs = false,
  --     invert_tabline = false,
  --     invert_intend_guides = false,
  --     inverse = true, -- invert background for search, diffs, statuslines and errors
  --     contrast = 'hard', -- can be "hard", "soft" or empty string
  --     palette_overrides = {},
  --     overrides = {},
  --     dim_inactive = true,
  --     transparent_mode = false,
  --   },
  -- },

  -- {
  --   'marko-cerovac/material.nvim',
  --   opts = {},
  -- },

  {
    'LazyVim/LazyVim',
    opts = { colorscheme = 'catppuccin' },
  },

  {
    'levouh/tint.nvim',
    lazy = true,
    opts = {
      -- see: https://github.com/levouh/tint.nvim/blob/master/DOC.md
      tint = -30,
      saturation = 0.7,
      highlight_ignore_patterns = {},
      window_ignore_function = function(winid)
        local bufid = vim.api.nvim_win_get_buf(winid)
        local buftype = vim.api.nvim_buf_get_option(bufid, 'buftype')
        local filetype = vim.api.nvim_buf_get_option(bufid, 'filetype')
        local floating = vim.api.nvim_win_get_config(winid).relative ~= ''

        -- Do not tint `terminal`, floating or dapui windows, but tint everything else
        return buftype == 'terminal' or floating or string.find(filetype, 'dap')
      end,
    },
    -- keys = {
    -- { '<leader>um', '<cmd>lua require("tint").toggle()<cr>', desc = 'Toggle dimming' },
    -- { '<leader>um', function() require("tint").toggle() end, desc = 'Toggle dimming' },
    -- },
    init = function()
      vim.api.nvim_set_keymap(
        'n',
        '<leader>um',
        '<cmd>lua require("tint").toggle()<cr>',
        { desc = 'Toggle dimming', noremap = true, silent = true }
      )
    end,
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
