return {
  {
    'folke/noice.nvim',
    opts = {
      presets = {
        bottom_search = false,
      },
      lsp = {
        hover = {
          opts = {
            border = {
              style = 'rounded',
              padding = { 0, 1 },
            },
          },
        },
      },
    },
  },
}
