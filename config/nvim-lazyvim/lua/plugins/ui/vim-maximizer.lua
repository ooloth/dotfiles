vim.g.maximizer_set_default_mapping = false

return {
  'szw/vim-maximizer',
  event = 'VeryLazy',
  keys = {
    { '<leader>wm', '<cmd>MaximizerToggle!<cr>', 'Toggle maximize' },
  },
}
