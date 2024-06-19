-- navigate vim splits (and tmux panes) with <C-hjkl>

return {
  'christoomey/vim-tmux-navigator',
  event = 'VeryLazy',
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
    'TmuxNavigatePrevious',
  },
  keys = {
    { '<c-h>', '<cmd><c-u>TmuxNavigateLeft<cr>' },
    { '<c-j>', '<cmd><c-u>TmuxNavigateDown<cr>' },
    { '<c-k>', '<cmd><c-u>TmuxNavigateUp<cr>' },
    { '<c-l>', '<cmd><c-u>TmuxNavigateRight<cr>' },
    { '<c-\\>', '<cmd><c-u>TmuxNavigatePrevious<cr>' },
  },
}
