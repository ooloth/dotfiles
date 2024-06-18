-- TODO: use FloatermNew instead of FloatermToggle if no "lazygit" window to toggle?
-- TODO: only apply esc/q keymaps to floaterm windows? e.g. via after/ftplugin/floaterm.lua?
-- TODO: only apply esc/q keymaps to lazygit window?
-- TODO: https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#advanced-topics
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
      { '<leader>gg', '<cmd>FloatermToggle lazygit<cr>', desc = 'Lazygit' },
    },
    init = function()
      -- On startup, start lazygit in a hiddle terminal so it's ready to appear instantly
      -- https://github.com/voldikss/vim-floaterm?tab=readme-ov-file#commands
      vim.cmd([[ FloatermNew --silent --name=lazygit lazygit ]])

      -- Use 'esc' or 'q' to hide floaterm without stopping the process running in it
      vim.keymap.set('t', '<esc>', '<cmd>FloatermHide<cr>', { desc = 'Hide terminal' })
      vim.keymap.set('t', 'q', '<cmd>FloatermHide<cr>', { desc = 'Hide terminal' })
    end,
  },
}
