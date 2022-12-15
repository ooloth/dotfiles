local nvim_tree_ok, nvim_tree = pcall(require, 'nvim-tree')
if not nvim_tree_ok then
  return
end

-- NOTE: vim-rhubarb depends on netrw, so don't disable it (even though nvim-tree says to)

nvim_tree.setup({
  actions = {
    change_dir = {
      enable = false, -- don't change cwd when changing folders in tree
    },
    open_file = {
      -- disable window_picker for explorer to work well with window splits
      window_picker = {
        enable = false,
      },
    },
  },
  diagnostics = {
    enable = true,
  },
  git = {
    ignore = false,
  },
  live_filter = {
    prefix = '[FILTER]: ',
    always_show_folders = false, -- filter out folders as well
  },
  renderer = {
    highlight_git = true,
    icons = {
      padding = '  ',
      show = {
        file = true,
        folder = true,
        folder_arrow = false,
        git = false,
      },
    },
  },
  update_focused_file = {
    enable = true,
  },
  view = {
    adaptive_size = true,
    mappings = {
      custom_only = false,
      list = {
        { key = 'l', action = 'edit' },
        { key = 'L', action = 'expand_all' },
        { key = 'h', action = 'close_node' },
        { key = 'H', action = 'collapse_all' },
      },
    },
    side = 'right',
  },
})
