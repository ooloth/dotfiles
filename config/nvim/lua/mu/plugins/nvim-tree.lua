local setup, nvimtree = pcall(require, "nvim-tree") -- import nvim-tree plugin safely
if not setup then
  return
end

-- nvim tree docs: "It is strongly advised to eagerly disable netrw due to race conditions at vim startup"
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- change color for arrows in tree to light blue
-- vim.cmd([[ highlight NvimTreeIndentMarker guifg=#3FC5FF ]])

-- configure nvim-tree
nvimtree.setup({
  diagnostics = {
    enable = true,
  },
  live_filter = {
    prefix = "[FILTER]: ",
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
  -- disable window_picker for explorer to work well with window splits
  actions = {
    -- change_dir = {
    --   enable = false -- don't change cwd when changing folders in tree
    -- },
    open_file = {
      window_picker = {
        enable = false,
      },
    },
  },
  git = {
    ignore = false,
  },
  update_focused_file = {
    enable = true,
  },
  view = {
    adaptive_size = true,
    mappings = {
      custom_only = false,
      list = {
        { key = "l", action = "edit" },
        { key = "L", action = "expand_all" },
        { key = "h", action = "close_node" },
        { key = "H", action = "collapse_all" }
      } 
    },
    side = 'right',
  },
})
