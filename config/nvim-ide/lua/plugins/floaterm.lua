-- TODO: https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#advanced-topics
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
      -- TODO: use toggle when possible since it loads instantly
      -- { '<leader>gg', '<cmd>FloatermToggle lazygit<cr>', desc = 'Lazygit' },
      { '<leader>gg', '<cmd>FloatermNew lazygit<cr>', desc = 'Lazygit' },
    },
    init = function()
      -- on startup, start lazygit in a hiddle terminal so it's ready to appear instantly
      vim.cmd([[ FloatermNew --silent --name=lazygit lazygit ]])

      -- FIXME: gets to normal mode, but doesn't toggle...
      -- vim.cmd([[ tmap <Esc> <c-\><c-n> :FloatermToggle<CR> ]])
    end,
  },
}
