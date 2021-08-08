return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	-- languages
	use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
	use("nvim-treesitter/playground")
	use("nvim-treesitter/nvim-treesitter-textobjects") -- e.g. class, function
	use("neovim/nvim-lspconfig") -- lsp client config
	use({ "kabouzeid/nvim-lspinstall", requires = "neovim/nvim-lspconfig" }) -- easily install language servers

	-- completion
	use("hrsh7th/nvim-compe") -- completion

	-- search
	use("mhinz/vim-startify") -- startup page
	use("folke/which-key.nvim") -- leader keymap menu
	use({
		"nvim-telescope/telescope.nvim",
		requires = { { "nvim-lua/popup.nvim" }, { "nvim-lua/plenary.nvim" } },
	})
	use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })
	use({ "kyazdani42/nvim-tree.lua" })
	use({
		"hoob3rt/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
	})

	-- editing
	use("tpope/vim-commentary")
	use("windwp/nvim-autopairs")

	-- colours
	use({ "sainnhe/everforest" })
	use({ "sainnhe/gruvbox-material" })
	use({ "crispgm/nord-vim", branch = "develop" }) -- forked from official nord-vim, with treesitter and lsp supported
	use({ "drewtempelmeyer/palenight.vim" })

	-- git
	use("tpope/vim-fugitive")

	vim.cmd([[autocmd BufWritePost plugins.lua source <afile> | PackerCompile]])

	-- Simple plugins can be specified as strings
	--   use '9mm/vim-closer'

	-- Lazy loading:
	-- Load on specific commands
	--   use {'tpope/vim-dispatch', opt = true, cmd = {'Dispatch', 'Make', 'Focus', 'Start'}}

	-- Load on an autocommand event
	--   use {'andymass/vim-matchup', event = 'VimEnter'}

	-- Load on a combination of conditions: specific filetypes or commands
	-- Also run code after load (see the "config" key)
	--   use {
	--     'w0rp/ale',
	--     ft = {'sh', 'zsh', 'bash', 'c', 'cpp', 'cmake', 'html', 'markdown', 'racket', 'vim', 'tex'},
	--     cmd = 'ALEEnable',
	--     config = 'vim.cmd[[ALEEnable]]'
	--   }

	-- Plugins can have dependencies on other plugins
	--   use {
	--     'haorenW1025/completion-nvim',
	--     opt = true,
	--     requires = {{'hrsh7th/vim-vsnip', opt = true}, {'hrsh7th/vim-vsnip-integ', opt = true}}
	--   }

	-- Plugins can also depend on rocks from luarocks.org:
	--   use {
	--     'my/supercoolplugin',
	--     rocks = {'lpeg', {'lua-cjson', version = '2.1.0'}}
	--   }

	-- You can specify rocks in isolation
	--   use_rocks 'penlight'
	--   use_rocks {'lua-resty-http', 'lpeg'}

	-- Plugins can have post-install/update hooks
	--   use {'iamcco/markdown-preview.nvim', run = 'cd app && yarn install', cmd = 'MarkdownPreview'}

	-- Post-install/update hook with call of vimscript function with argument
	--   use { 'glacambre/firenvim', run = function() vim.fn['firenvim#install'](0) end }

	-- Use dependency and run lua function after load
	--   use {
	--     'lewis6991/gitsigns.nvim', requires = { 'nvim-lua/plenary.nvim' },
	--     config = function() require('gitsigns').setup() end
	--   }

	-- You can specify multiple plugins in a single call
	--   use {'tjdevries/colorbuddy.vim', {'nvim-treesitter/nvim-treesitter', opt = true}}

	-- You can alias plugin names
	--   use {'dracula/vim', as = 'dracula'}
end)

-- toggle comment

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
--
-- Plug 'mbbill/undotree'
--
-- " File tree
-- Plug 'vifm/vifm.vim'
--
-- " Git
-- Plug 'tpope/vim-fugitive'
--
-- " Tests
-- " Plug 'vim-test/vim-test'
--
-- " Organization
-- Plug 'Asheq/close-buffers.vim'
-- Plug 'liuchengxu/vim-which-key'
-- Plug 'mhinz/vim-startify'
-- Plug 'vim-airline/vim-airline'
--
-- " Convenience
-- Plug 'mattn/emmet-vim'
-- Plug 'tpope/vim-commentary'
-- Plug 'tpope/vim-surround'
-- Plug 'tpope/vim-repeat'               " extends . functionality to plugins like vim-surround
-- Plug 'norcalli/nvim-colorizer.lua'
-- " Plug 'alvan/vim-closetag'
-- " Plug 'tpope/vim-unimpaired'           " pairs of '[' and ']' mappings
-- " Plug 'christoomey/vim-tmux-navigator' " navigate seamlessly between vim + tmux splits
-- " Plug 'christoomey/vim-tmux-runner'

-- -- Plugins
-- require "paq" {
--   "airblade/vim-gitgutter",
--   "alvan/vim-closetag",
--   "b3nj5m1n/kommentary",
--   "glepnir/lspsaga.nvim",
--   "hoob3rt/lualine.nvim",
--   "hrsh7th/nvim-compe",
--   "hrsh7th/vim-vsnip",
--   "jiangmiao/auto-pairs",
--   "kyazdani42/nvim-web-devicons",
--   "mhartington/formatter.nvim",
--   "neovim/nvim-lspconfig",
--   "nvim-lua/plenary.nvim",
--   "nvim-lua/popup.nvim",
--   "nvim-telescope/telescope.nvim",
--   "nvim-treesitter/nvim-treesitter",
--   "phaazon/hop.nvim",
--   "rmagatti/auto-session",
--   "sainnhe/everforest",
--   "savq/paq-nvim",
--   "tpope/vim-repeat",
--   "tpope/vim-surround",
--   "wellle/targets.vim",
--   "wfxr/minimap.vim"
-- }

-- -- plugins
-- try_require('plugins.setups')
-- try_require('plugins.emmet')
-- try_require('plugins.gitblame')
-- try_require('plugins.gitsigns')
-- try_require('plugins.hardline')
-- try_require('plugins.prettier')
-- try_require('plugins.toggleterm')
-- try_require('plugins.vsnip')
