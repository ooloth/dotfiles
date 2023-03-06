return {
  'echasnovski/mini.surround',
  config = function(_, opts)
    local mini_surround = require('mini.surround')
    mini_surround.setup(opts)
    -- see: https://github.com/echasnovski/mini.surround/blob/main/doc/mini-surround.txt#L473
    -- Remap adding surrounding to Visual mode selection
    vim.keymap.del('x', 'gs')
    vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })
    -- Make special mapping for "add surrounding for line"
    vim.keymap.set('n', 'gss', 'ys_', { remap = true })
  end,
  opts = {
    mappings = {
      add = 'gs', -- Add surrounding in Normal and Visual modes
      delete = 'ds', -- Delete surrounding
      find = '', -- Find surrounding (to the right)
      find_left = '', -- Find surrounding (to the left)
      highlight = '', -- Highlight surrounding
      replace = 'cs', -- Replace surrounding
      update_n_lines = '', -- Update `n_lines`
      suffix_last = '',
      suffix_next = '',
      search_method = 'cover_or_next',
    },
  },
}
