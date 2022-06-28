vim.opt.background = "dark"

-- -- See: https://github.com/marko-cerovac/material.nvim#%EF%B8%8F-configuration
-- vim.g.material_style = "deep ocean" -- 'darker', 'lighter', 'palenight', 'oceanic' or 'deep ocean'
-- vim.g.material_contrast = true -- Make sidebars and popup menus like nvim-tree and telescope have a different background
-- vim.g.material_italic_comments = true
-- vim.g.material_italic_functions = false
-- vim.g.material_italic_keywords = false
-- vim.g.material_italic_strings = false
-- vim.g.material_italic_variables = false
-- vim.g.material_borders = true -- Enable the border between verticaly split windows visable
-- vim.g.material_disable_background = false -- Disable the setting of background color so that NeoVim can use your terminal background
-- vim.g.material_hide_eob = true -- Hide the end of buffer lines ( ~ )

-- -- Adapted from this starting point: https://github.com/marko-cerovac/material.nvim/blob/main/lua/material/colors.lua
-- vim.g.material_custom_colors = {
-- 	bg = "#0F111A",
-- 	bg_alt = "#090B10",
-- 	fg = "#8F93A2",
-- 	text = "#717CB4",
-- 	comments = "#464B5D",
-- 	selection = "#1F2233",
-- 	contrast = "#090B10",
-- 	active = "#1A1C25",
-- 	border = "#1f2233",
-- 	line_numbers = "#3B3F51",
-- 	highlight = "#1F2233",
-- 	disabled = "#464B5D",
-- 	accent = "#84FFFF",
-- }

vim.g.material_terminal_italics = 1
vim.g.material_theme_style = "ocean"

vim.api.nvim_command("colorscheme material")
