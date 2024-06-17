-- TODO: https://www.lazyvim.org/plugins/colorscheme

return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  config = function()
    -- see: https://github.com/catppuccin/nvim?tab=readme-ov-file#configuration
    require('catppuccin').setup({
      flavour = 'mocha', -- latte, frappe, macchiato, mocha
      transparent_background = true, -- disables setting the background color.
      show_end_of_buffer = true, -- shows the '~' characters after the end of buffers
      dim_inactive = {
        enabled = false, -- dims the background color of inactive window
        shade = 'dark',
        percentage = 0.15, -- percentage of the shade to apply to the inactive window
      },
      -- styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
      --   comments = { 'italic' }, -- Change the style of comments
      --   conditionals = { 'italic' },
      --   loops = {},
      --   functions = {},
      --   keywords = {},
      --   strings = {},
      --   variables = {},
      --   numbers = {},
      --   booleans = {},
      --   properties = {},
      --   types = {},
      --   operators = {},
      --   -- miscs = {}, -- Uncomment to turn off hard-coded styles
      -- },
      -- color_overrides = {
      --   mocha = { base = '#000000', mantle = '#000000', crust = '#000000' },
      -- },
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
    })

    -- setup must be called before loading
    vim.cmd.colorscheme('catppuccin')
  end,
}
