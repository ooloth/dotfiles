local M = {}

M.setup = function()
	require("lualine").setup({
		options = {
			icons_enabled = true,
			-- theme = "calvera-nvim",
			-- theme = "everforest",
			-- theme = "github",
			theme = "gruvbox",
			-- theme = "material",
			-- theme = "material-nvim",
			-- theme = "nord",
			-- theme = "palenight",
			component_separators = { "", "" },
			section_separators = { "", "" },
			disabled_filetypes = {},
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch" },
			lualine_c = {
				{
					"filename",
					file_status = true, -- displays file status (readonly status, modified status)
					path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
				},
			},
			lualine_x = {
				{
					"diff",
					colored = true, -- displays diff status in color if set to true
					-- all colors are in format #rrggbb
					color_added = nil, -- changes diff's added foreground color
					color_modified = nil, -- changes diff's modified foreground color
					color_removed = nil, -- changes diff's removed foreground color
					symbols = { added = "+", modified = "~", removed = "-" }, -- changes diff symbols
				},
				{
					"diagnostics",
					sources = { "nvim_lsp" },
					color_error = "#8F93A2",
					color_warn = "#8F93A2",
					color_info = "#8F93A2",
					color_hint = "#8F93A2",
					symbols = { error = "🐞 ", warn = " 🚧 ", info = " ℹ️  ", hint = " 💡 " },
				},
				{
					-- Lsp server name .
					function(msg)
						msg = msg or "LSP Inactive"

						local buf_ft = vim.bo.filetype
						local buf_clients = vim.lsp.buf_get_clients()

						if next(buf_clients) == nil then
							return msg
						end

						local buf_client_names = {}

						for _, client in pairs(buf_clients) do
							if client.name == "null-ls" then
								table.insert(buf_client_names, lvim.lang[buf_ft].linters[1])
								table.insert(buf_client_names, lvim.lang[buf_ft].formatter.exe)
							else
								table.insert(buf_client_names, client.name)
							end
						end

						return table.concat(buf_client_names, ", ")
					end,
					icon = "",
					color = { fg = "#8F93A2" },
				},
			},
			lualine_y = { "filetype" },
			lualine_z = { "location" },
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {
				{
					"filename",
					file_status = true, -- displays file status (readonly status, modified status)
					path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
				},
			},
			lualine_x = { "location" },
			lualine_y = {},
			lualine_z = {},
		},
		tabline = {},
		extensions = { "quickfix", "fugitive", "nvim-tree" },
	})
end

return M
