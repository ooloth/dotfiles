return {
  'axieax/urlview.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  keys = {
    { '<leader>fu', '<cmd>UrlView buffer<cr>', desc = 'Undo' },
  },
  opts = {
    default_picker = 'telescope',
  },
}
