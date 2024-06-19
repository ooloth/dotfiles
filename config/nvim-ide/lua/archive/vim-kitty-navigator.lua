-- NOTE: I'm using vim-tmux-navigator instead

-- navigate across vim splits and kitty window with <C-hjkl>

return {
  'knubie/vim-kitty-navigator',
  event = 'VeryLazy',
  -- build = ':do cp ./*.py ~/.config/kitty/',
  cmd = {
    'KittyNavigateLeft',
    'KittyNavigateDown',
    'KittyNavigateUp',
    'KittyNavigateRight',
  },
  init = function()
    -- see: https://github.com/knubie/vim-kitty-navigator/issues/43#issuecomment-1906432799
    if os.getenv('TERM') == 'xterm-kitty' then
      vim.g.kitty_navigator_no_mappings = 1
      vim.g.tmux_navigator_no_mappings = 1

      vim.api.nvim_set_keymap('n', 'C-h', ':KittyNavigateLeft <CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', 'C-j', ':KittyNavigateDown <CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', 'C-k', ':KittyNavigateUp <CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', 'C-l', ':KittyNavigateRight <CR>', { noremap = true, silent = true })
    end
  end,
  keys = {
    { '<c-h>', '<cmd><C-U>KittyNavigateLeft<cr>' },
    { '<c-j>', '<cmd><C-U>KittyNavigateDown<cr>' },
    { '<c-k>', '<cmd><C-U>KittyNavigateUp<cr>' },
    { '<c-l>', '<cmd><C-U>KittyNavigateRight<cr>' },
  },
}
