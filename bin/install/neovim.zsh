#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/zsh/config/aliases.zsh"
source "$DOTFILES/zsh/config/utils.zsh"

repo="ooloth/config.nvim"
local_repo="$HOME/Repos/$repo"

if [ -d "$local_repo" ]; then
  printf "\n📂 config.nvim is already installed\n"
  return_or_exit 0
fi

# Otherwise, clone
info "📂 Installing config.nvim"

mkdir -p "$local_repo"
git clone "git@github.com:$repo.git" "$local_repo"

# TODO: does the lockfile need to be symlinked first?
info "📂 Installing Lazy plugin versions from lazy-lock.json"
NVIM_APPNAME=nvim-ide nvim --headless "+Lazy! restore" +qa
