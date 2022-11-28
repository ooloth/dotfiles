local actions = require('telescope.actions')

require('telescope').setup({
  defaults = {
    layout_config = {
      center = { width = 0.5, height = 0.25 },
      flex = {},
      horizontal = { width = 0.75, height = 0.65 },
      vertical = { width = 0.75, height = 0.65 },
      prompt_position = 'top'
    },
    -- Default mappings: https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/mappings.lua
    mappings = {
      i = {
        ['<c-n>'] = actions.move_selection_next,
        ['<c-e>'] = actions.move_selection_previous,
        ['<esc>'] = actions.close,
      },
      n = {
        ['n'] = actions.move_selection_next,
        ['e'] = actions.move_selection_previous,
        ['<c-n>'] = actions.move_selection_next,
        ['<c-e>'] = actions.move_selection_previous,
      },
    },
    prompt_prefix = ' 🔍 ',
    sorting_strategy = 'ascending'
  },
  pickers = {
    buffers = {
      sort_lastused = true,
    },
    lsp_code_actions = {
      theme = "cursor"
    }
  }
})

-- This will load fzf and have it override the default file sorter (must come after telescope setup)
require('telescope').load_extension('fzf')
