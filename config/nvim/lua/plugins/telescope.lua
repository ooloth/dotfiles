local actions = require('telescope.actions')

return {
  'nvim-telescope/telescope.nvim',
  opts = {
    defaults = {
      builtin = {
        find_files = {
          hidden = true, -- show hidden files
          no_ignore = true, -- show ignored files
        },
        git_files = {
          show_untracked = true,
        },
        oldfiles = {
          cwd_only = true,
        },
      },
      mappings = {
        i = {
          ['<esc>'] = actions.close,
          ['<C-j>'] = actions.move_selection_next,
          ['<C-k>'] = actions.move_selection_previous,
          ['<C-h>'] = actions.cycle_history_prev,
          ['<C-l>'] = actions.cycle_history_next,
          ['<C-n>'] = actions.preview_scrolling_down,
          ['<C-p>'] = actions.preview_scrolling_up,
        },
      },
    },
  },
}
