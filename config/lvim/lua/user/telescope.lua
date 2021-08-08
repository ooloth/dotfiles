local actions = require("telescope.actions")

lvim.builtin.telescope.defaults = {
	layout_config = {
		center = { width = 0.5, height = 0.25 },
		flex = {},
		horizontal = { width = 0.75, height = 0.65 },
		vertical = { width = 0.75, height = 0.65 },
		prompt_position = "top",
	},
	-- Default mappings: https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/mappings.lua
	mappings = {
		i = {
			["<c-n>"] = actions.move_selection_next,
			["<c-e>"] = actions.move_selection_previous,
			["<esc>"] = actions.close,
		},
		n = {
			["n"] = actions.move_selection_next,
			["e"] = actions.move_selection_previous,
			["<c-n>"] = actions.move_selection_next,
			["<c-e>"] = actions.move_selection_previous,
		},
	},
	prompt_prefix = " 🔍 ",
	sorting_strategy = "ascending",
}

lvim.builtin.telescope.pickers = {
	buffers = {
		sort_lastused = true,
	},
	lsp_code_actions = {
		theme = "cursor",
	},
}
