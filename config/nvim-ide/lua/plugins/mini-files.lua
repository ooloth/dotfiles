return {
  'echasnovski/mini.files',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  version = '*',
  keys = {
    {
      '-',
      function()
        require('mini.files').open(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = 'Open file explorer (mini.files)',
    },
  },
  opts = {
    -- see: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-files.md#default-config
    -- Use `''` (empty string) to not create one.
    mappings = {
      close = '<esc>',
      -- close = 'q',
      go_in = '',
      go_in_plus = 'l', -- close mini.files when opening a file
      go_out = 'h',
      go_out_plus = 'H',
      reset = '<BS>',
      show_help = '?',
      synchronize = '<cr>',
      -- synchronize = '=',
      trim_left = '<',
      trim_right = '>',
    },

    -- General options
    options = {
      -- Whether to delete permanently or move into module-specific trash
      permanent_delete = true,
      -- Whether to use for editing directories
      use_as_default_explorer = true,
    },

    windows = {
      max_number = 2, -- Maximum number of windows to show side by side
      preview = true,
      width_focus = 35,
      -- width_nofocus = 35,
      width_preview = 100,
    },
  },
}
