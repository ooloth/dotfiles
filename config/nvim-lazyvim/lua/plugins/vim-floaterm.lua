vim.g.floaterm_height = 0.9999999999999999
vim.g.floaterm_title = ''
vim.g.floaterm_width = 0.9999999999999999

return {
  {
    'voldikss/vim-floaterm',
    event = 'VeryLazy',
    cmd = 'FloatermNew',
    keys = {
      { '<leader>ot', '<cmd>FloatermNew<cr>', desc = 'Terminal' },
    },
  },
}
