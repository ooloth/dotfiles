#!/usr/bin/env zsh

repo="ooloth/config.nvim"
local_repo="$HOME/Repos/$repo"

if [ -d "$local_repo" ]; then
  printf "\n📂 config.nvim is already installed\n"
  source "$DOTFILES/config/zsh/alias.zsh"
  return_or_exit 0
fi

# Otherwise, clone
source "$DOTFILES/config/zsh/utils.zsh"
info "📂 Installing config.nvim"

mkdir -p "$local_repo"
git clone "git@github.com:$repo.git" "$local_repo"

printf "\n📦 TODO: install lazy.nvim plugins + reload as needed for first setup?\n"
