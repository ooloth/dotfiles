-- editing
use('tpope/vim-unimpaired') -- pairs of '[' and ']' mappings
use('inkarkat/vim-ReplaceWithRegister') -- replace text with register contents (gr + motion)
use('tpope/vim-repeat') -- repeat plugin commands with .

-- autocompletion
use('hrsh7th/cmp-buffer') -- source for text in buffer
use('hrsh7th/cmp-path') -- source for file system paths

-- snippets
use('L3MON4D3/LuaSnip') -- snippet engine
use('saadparwaiz1/cmp_luasnip') -- add snippets to autocompletions
use('rafamadriz/friendly-snippets') -- useful snippets

-- lsp servers
use('onsails/lspkind.nvim') -- vs-code like icons for autocompletion

-- treesetter extensions
use('nvim-treesitter/nvim-treesitter-textobjects') -- add more syntax aware text-objects
use({ 'windwp/nvim-ts-autotag', after = 'nvim-treesitter' }) -- autoclose tags
use({ 'nvim-treesitter/nvim-treesitter-context', after = 'nvim-treesitter' }) -- sticky scroll context

-- git
use({ 'tpope/vim-rhubarb', requires = 'tpope/vim-fugitive' }) -- open GitHub URLs with :GBrowse
