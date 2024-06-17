-- TODO: toggle running lazygit instance instead of quitting and restarting lazygit each time?
-- TODO: command! Yazi FloatermNew yazi

vim.g.floaterm_borderchars = ''
vim.g.floaterm_height = 0.9999999999999999
vim.g.floaterm_title = ''
vim.g.floaterm_width = 0.9999999999999999

return {
  {
    'voldikss/vim-floaterm',
    event = 'VeryLazy',
    cmd = 'FloatermNew',
    keys = {
      { '<leader>gg', '<cmd>FloatermNew lazygit<cr>', desc = 'Lazygit' },
    },
  },
}
