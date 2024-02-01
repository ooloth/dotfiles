return {
  'ruifm/gitlinker.nvim',
  event = 'VeryLazy',
  config = function()
    require('gitlinker').setup()
  end,
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { '<leader>gy', desc = 'Copy URL for selected lines' },
  },
}
