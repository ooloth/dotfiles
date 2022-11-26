-- automatically install packer if not installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
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
local status, packer = pcall(require, "packer")
if not status then
  return
end

-- install plugins
return packer.startup(function(use)
  use("wbthomason/packer.nvim") -- packer can manage itself

  use("nvim-lua/plenary.nvim") -- lua functions that many plugins use

  -- colors
  use("bluz71/vim-nightfly-guicolors") 

  -- navigating
  use("nvim-tree/nvim-tree.lua") -- file explorer
  use("nvim-tree/nvim-web-devicons") -- vs code-like icons
  use("christoomey/vim-tmux-navigator") -- navigate vim splits (and tmux panes) with <C-hjkl>
  use("szw/vim-maximizer") -- maximizes and restores the current split

  -- editing
  use("tpope/vim-surround") -- add, delete, change surrounding characters
  use("inkarkat/vim-ReplaceWithRegister") -- replace text with register contents (gr + motion)
  use("numToStr/Comment.nvim") -- comment text (gc + motion)

  -- if packer was just installed, sync plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
