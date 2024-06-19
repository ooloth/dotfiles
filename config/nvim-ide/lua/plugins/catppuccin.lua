-- TODO: integrate with other plugins? https://github.com/catppuccin/nvim?tab=readme-ov-file#integrations

-- mocha colors: https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/palettes/mocha.lua

return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  config = function()
    -- see: https://github.com/catppuccin/nvim?tab=readme-ov-file#configuration
    require('catppuccin').setup({
      -- color_overrides = {
      --   mocha = { base = '#000000', mantle = '#000000', crust = '#000000' },
      -- },
      dim_inactive = {
        enabled = false, -- dims the background color of inactive window
        shade = 'dark',
        percentage = 0.15, -- percentage of the shade to apply to the inactive window
      },
      flavour = 'mocha', -- latte, frappe, macchiato, mocha
      highlight_overrides = {
        -- see: https://github.com/catppuccin/nvim?tab=readme-ov-file#overwriting-highlight-groups
        mocha = function(mocha)
          return {
            -- Comment = { fg = '#7f849c' }, -- brighter comments
          }
        end,
      },
      -- see: https://github.com/catppuccin/nvim#integrations
      integrations = {
        cmp = true,
        -- flash = true,
        -- gitsigns = true,
        harpoon = true,
        headlines = true,
        -- illuminate = true,
        -- indent_blankline = { enabled = true },
        -- leap = true,
        -- lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          inlay_hints = {
            background = true,
          },
          underlines = {
            errors = { 'undercurl' },
            hints = { 'undercurl' },
            warnings = { 'undercurl' },
            information = { 'undercurl' },
          },
        },
        -- navic = { enabled = true, custom_bg = 'lualine' },
        -- neotest = true,
        noice = true,
        notify = true,
        -- octo = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
      show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
      transparent_background = true, -- disables setting the background color.
      -- styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
      --   booleans = {},
      --   comments = { 'italic' }, -- Change the style of comments
      --   conditionals = { 'italic' },
      --   functions = {},
      --   keywords = {},
      --   loops = {},
      --   numbers = {},
      --   operators = {},
      --   -- miscs = {}, -- Uncomment to turn off hard-coded styles
      -- },
      --   properties = {},
      --   strings = {},
      --   types = {},
      --   variables = {},
    })

    -- Must call after setup
    vim.cmd.colorscheme('catppuccin')
  end,
}
