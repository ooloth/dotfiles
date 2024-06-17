return {
  {
    'folke/noice.nvim',
    keys = function() -- replace all keys
      return {
        { '<leader>sn', '<cmd>Telescope noice<cr>', desc = 'Noice' },
      }
    end,
    opts = {
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
      presets = {
        bottom_search = false,
      },
    },
  },
}
