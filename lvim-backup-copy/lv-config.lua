------------------
-- LVIM OPTIONS --
------------------

lvim.format_on_save = true
lvim.lint_on_save = true

-----------------
-- VIM OPTIONS --
-----------------

require("user.options")

------------------
-- AUTOCOMMANDS --
------------------

-----------------
-- KEYMAPPINGS --
-----------------

require("user.keymaps").setup() -- non-leader key mappings
require("user.which-key").setup() -- leader key mappings

------------------
-- CORE PLUGINS --
------------------
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile

lvim.builtin.dashboard.active = false
lvim.builtin.galaxyline.active = false

require("user.nvim-tree").setup()
require("user.telescope")

lvim.builtin.terminal.active = true

lvim.builtin.treesitter.ensure_installed = "maintained"
lvim.builtin.treesitter.highlight.enabled = true

----------------
-- MY PLUGINS --
----------------

lvim.plugins = {
	-- {
	-- 	"Pocco81/AutoSave.nvim",
	-- 	config = function()
	-- 		require("autosave").setup()
	-- 	end,
	-- },
	{
		"folke/lsp-colors.nvim",
		event = "BufRead",
	},
	{
		"ahmedkhalf/lsp-rooter.nvim",
		event = "BufRead",
		config = function()
			require("lsp-rooter").setup()
		end,
	},
	{
		"hoob3rt/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
		config = function()
			require("user.lualine").setup()
		end,
	},
	{
		"karb94/neoscroll.nvim",
		event = "WinScrolled",
		config = function()
			require("user.neoscroll")
		end,
	},
	{
		"nacro90/numb.nvim",
		event = "BufRead",
		config = function()
			require("user.numb")
		end,
	},
	{
		"norcalli/nvim-colorizer.lua",
		config = function()
			require("user.colorizer")
		end,
	},
	{
		"folke/todo-comments.nvim",
		event = "BufRead",
	},
	{
		"tpope/vim-fugitive",
		cmd = {
			"G",
			"Git",
			"Gdiffsplit",
			"Gread",
			"Gwrite",
			"Ggrep",
			"GMove",
			"GDelete",
			"GBrowse",
			"GRemove",
			"GRename",
			"Glgrep",
			"Gedit",
		},
		ft = { "fugitive" },
	},
	{
		"tpope/vim-repeat",
		keys = { "." },
	},
	{
		"mhinz/vim-startify",
		config = function()
			require("user.vim-startify").setup()
		end,
	},
	{
		"tpope/vim-surround",
		keys = { "c", "d", "y" },
	},

	-- colorschemes
	-- {
	-- 	"dracula/vim",
	-- 	as = "dracula",
	-- 	config = function()
	-- 		vim.api.nvim_command("colorscheme dracula")
	-- 	end,
	-- },
	-- {
	-- 	"sainnhe/everforest",
	-- 	config = function()
	-- 		require("user.everforest")
	-- 	end,
	-- },
	{
		"gruvbox-community/gruvbox",
		config = function()
			require("user.gruvbox")
		end,
	},
	-- {
	-- 	"kaicataldo/material.vim",
	-- 	branch = "main",
	-- 	config = function()
	-- 		require("user.material")
	-- 	end,
	-- },
	-- {
	-- 	"marko-cerovac/material.nvim",
	-- 	config = function()
	-- 		require("user.material")
	-- 	end,
	-- },
	-- forked from official nord-vim, with treesitter and lsp supported
	-- {
	-- 	"crispgm/nord-vim",
	-- 	branch = "develop",
	-- 	config = function()
	-- 		require("user.nord")
	-- 	end,
	-- },
	-- {
	-- 	"folke/tokyonight.nvim",
	-- 	config = function()
	-- 		vim.g.tokyonight_style = "storm"
	-- 		vim.api.nvim_command("colorscheme tokyonight")
	-- 	end,
	-- },
	-- {
	-- 	"drewtempelmeyer/palenight.vim",
	-- 	config = function()
	-- 		require("user.palenight")
	-- 	end,
	-- },

	-- {"lervag/vimtex", opt=true};      -- Use braces when passing options

	-- file
	-- paq('akinsho/nvim-toggleterm.lua') -- terminal
	-- paq('farmergreg/vim-lastplace') -- reopen files at your last edit position
	-- paq('AndrewRadev/undoquit.vim') -- restore closed tabs

	-- view
	-- paq('ojroques/nvim-hardline') -- status line paq('crispgm/nvim-tabline') -- tab line
	-- paq('dstein64/nvim-scrollview') -- scroll bar
	-- paq('google/vim-searchindex') -- search index
	-- paq('wincent/ferret') -- find and replace
	-- paq('editorconfig/editorconfig-vim') -- editorconfig support
	-- paq('Yggdroot/indentLine') -- indent line
	-- paq('RRethy/vim-illuminate') -- highlight hover word
	-- paq('lewis6991/gitsigns.nvim') -- git signs
	-- paq('f-person/git-blame.nvim') -- toggle git blame info
	-- paq('rhysd/conflict-marker.vim') -- git conflict
	-- paq('norcalli/nvim-colorizer.lua') -- color codes rendering
	-- paq('winston0410/cmd-parser.nvim') -- dependency of range-highlight
	-- paq('winston0410/range-highlight.nvim') -- highlight range lines

	-- edit
	-- paq('psliwka/vim-smoothie') -- smoothy scroll
	-- paq('phaazon/hop.nvim') -- jump to anywhere within 2 strokes
	-- paq('tpope/vim-repeat') -- repeat that support plugin
	-- paq('tpope/vim-surround') -- toggle surround
	-- paq('tpope/vim-abolish') -- eh, hard to describe, see README
	-- paq({
	--     'prettier/vim-prettier', -- prettier formatter
	--     run = 'yarn install',
	--     branch = 'release/0.x',
	-- })
	-- paq('christoomey/vim-system-copy') -- copy to system clipboard
	-- paq('monaqa/dial.nvim') -- <c-a> <c-x> enhancement
	-- paq('kana/vim-textobj-user') -- define textobj by user
	-- paq('haya14busa/vim-textobj-number') -- number textobj
	-- paq('AndrewRadev/splitjoin.vim') -- split and join in vim
	-- paq('steelsojka/pears.nvim') -- auto symbol pairs

	-- language

	-- paq('hrsh7th/vim-vsnip') -- snippets
	-- paq('hrsh7th/vim-vsnip-integ') -- vsnip integration for nvim-compe
	-- paq('mattn/emmet-vim') -- html/css snippets

	-- paq('junegunn/vader.vim') -- vim plugin testing
}
