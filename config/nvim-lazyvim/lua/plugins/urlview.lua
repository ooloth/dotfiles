return {
  'axieax/urlview.nvim',
  event = 'BufRead',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  keys = {
    { '<leader>fl', '<cmd>UrlView buffer<cr>', desc = 'Links in buffer' },
  },
  opts = {
    default_picker = 'telescope',
  },
}
