local M = {}

M.setup = function()
	lvim.builtin.nvimtree.show_icons.git = 0
	lvim.builtin.nvimtree.side = "right"
	lvim.builtin.nvimtree.width = 60
	lvim.builtin.nvimtree.auto_open = 1 -- opens the tree when typing `vim $DIR` or `vim`
	lvim.builtin.nvimtree.auto_ignore_ft = { "startify", "dashboard" } -- don't auto open tree on these filetypes
	lvim.builtin.nvimtree.quit_on_open = 1 -- closes the tree when you open a file
	lvim.builtin.nvimtree.git_hl = 1 -- enable file highlight for git attributes (can be used without the icons)
	lvim.builtin.nvimtree.nvim_tree_highlight_opened_files = 1 -- enable folder and file icon highlight for opened files/directories
	lvim.builtin.nvimtree.nvim_tree_add_trailing = 1 -- append a trailing slash to folder names

	lvim.builtin.nvimtree.on_config_done = function(nvimtree)
		-- FIXME: these bindings aren't working
		local tree_cb = require("nvim-tree.config").nvim_tree_callback

		nvimtree.nvim_tree_bindings = {
			{ key = { "<CR>", "o", "<2-LeftMouse>" }, cb = tree_cb("edit") },
			{ key = { "<2-RightMouse>", "<C-]>" }, cb = tree_cb("cd") },
			{ key = "<C-v>", cb = tree_cb("vsplit") },
			{ key = "<C-x>", cb = tree_cb("split") },
			{ key = "<C-t>", cb = tree_cb("tabnew") },
			{ key = "<", cb = tree_cb("prev_sibling") },
			{ key = ">", cb = tree_cb("next_sibling") },
			{ key = "P", cb = tree_cb("parent_node") },
			{ key = { "<BS>", "<S-CR>" }, cb = tree_cb("close_node") },
			{ key = "<Tab>", cb = tree_cb("preview") },
			{ key = "K", cb = tree_cb("first_sibling") },
			{ key = "J", cb = tree_cb("last_sibling") },
			{ key = "I", cb = tree_cb("toggle_ignored") },
			{ key = "H", cb = tree_cb("toggle_dotfiles") },
			{ key = "R", cb = tree_cb("refresh") },
			{ key = "a", cb = tree_cb("create") },
			{ key = "d", cb = tree_cb("remove") },
			{ key = "r", cb = tree_cb("rename") },
			{ key = "<C-r>", cb = tree_cb("full_rename") },
			{ key = "x", cb = tree_cb("cut") },
			{ key = "c", cb = tree_cb("copy") },
			{ key = "p", cb = tree_cb("paste") },
			{ key = "y", cb = tree_cb("copy_name") },
			{ key = "Y", cb = tree_cb("copy_path") },
			{ key = "gy", cb = tree_cb("copy_absolute_path") },
			{ key = "[c", cb = tree_cb("prev_git_item") },
			{ key = "]c", cb = tree_cb("next_git_item") },
			{ key = "-", cb = tree_cb("dir_up") },
			{ key = { "q", "<Esc>" }, cb = tree_cb("close") },
			{ key = "g?", cb = tree_cb("toggle_help") },
		}
	end
end

return M
