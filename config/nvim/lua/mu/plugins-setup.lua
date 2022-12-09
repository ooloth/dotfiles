-- automatically install packer if not installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd([[packadd packer.nvim]])
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer() -- true if packer was just installed

-- reload neovim and install/update/remove plugins when this file is saved
vim.cmd([[ 
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins-setup.lua source <afile> | PackerSync
  augroup end
]])

-- import packer safely
local status, packer = pcall(require, 'packer')
if not status then
  return
end

-- install plugins
return packer.startup(function(use)
  use('wbthomason/packer.nvim') -- packer can manage itself

  -- colors
  use('Mofiqul/dracula.nvim')
  -- use('bluz71/vim-nightfly-guicolors')

  -- navigating
  -- use('mhinz/vim-startify') -- start screen + session manager
  use({ 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }) -- telescope dependency for faster sorting
  use({ 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' }, branch = '0.1.x' }) -- fuzzy finder

  use('nvim-tree/nvim-tree.lua') -- file explorer
  use('nvim-tree/nvim-web-devicons') -- vs code-like icons
  use('christoomey/vim-tmux-navigator') -- navigate vim splits (and tmux panes) with <C-hjkl>
  use('szw/vim-maximizer') -- maximizes and restores the current split
  use('moll/vim-bbye') -- close buffers without closing splits

  -- editing
  use('tpope/vim-surround') -- add, delete, change surrounding characters
  use('inkarkat/vim-ReplaceWithRegister') -- replace text with register contents (gr + motion)
  use('numToStr/Comment.nvim') -- comment text (gc + motion)
  use('tpope/vim-repeat') -- repeat plugin commands with .

  -- status
  use('nvim-lualine/lualine.nvim') -- statusline

  -- autocompletion
  use('hrsh7th/nvim-cmp') -- completion plugin
  use('hrsh7th/cmp-buffer') -- source for text in buffer
  use('hrsh7th/cmp-path') -- source for file system paths

  -- snippets
  use('L3MON4D3/LuaSnip') -- snippet engine
  use('saadparwaiz1/cmp_luasnip') -- add snippets to autocompletions
  use('rafamadriz/friendly-snippets') -- useful snippets

  -- managing & installing lsp servers, linters & formatters
  use('williamboman/mason.nvim') -- in charge of managing lsp servers, linters & formatters
  use('williamboman/mason-lspconfig.nvim') -- bridges gap b/w mason & lspconfig
  use('jayp0521/mason-null-ls.nvim') -- bridges gap b/w mason & null-ls

  -- configuring lsp servers
  use('neovim/nvim-lspconfig') -- configure language servers
  use('hrsh7th/cmp-nvim-lsp') -- add lsp server info to autocompletions
  use({ 'glepnir/lspsaga.nvim', branch = 'main' }) -- enhanced lsp uis
  use('jose-elias-alvarez/typescript.nvim') -- additional functionality for typescript server (e.g. rename file & update imports)
  use('onsails/lspkind.nvim') -- vs-code like icons for autocompletion

  -- formatting & linting
  use({ 'jose-elias-alvarez/null-ls.nvim', requires = { 'nvim-lua/plenary.nvim' } }) -- configure formatters & linters

  -- treesitter configuration
  use({
    'nvim-treesitter/nvim-treesitter',
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end,
  })

  -- auto closing (to help treesitter)
  use('windwp/nvim-autopairs') -- autoclose parens, brackets, quotes, etc...
  use({ 'windwp/nvim-ts-autotag', after = 'nvim-treesitter' }) -- autoclose tags

  use({ 'nvim-treesitter/nvim-treesitter-context', after = 'nvim-treesitter' }) -- sticky scroll context

  -- git
  use('lewis6991/gitsigns.nvim') -- show line modifications on left hand side
  use('tpope/vim-fugitive')

  -- mappings
  use('folke/which-key.nvim')

  -- if packer was just installed, sync plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
