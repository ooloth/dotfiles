#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/tools/zsh/config/aliases.zsh"
source "$DOTFILES/tools/zsh/utils.zsh"

repo="ooloth/content"
local_repo="$HOME/Repos/$repo"

if [ -d "$local_repo" ]; then
  printf "\n📂 content repo is already installed\n"
  return_or_exit 0
fi

# Otherwise, clone
info "📂 Installing content repo"

mkdir -p "$local_repo"
git clone "git@github.com:$repo.git" "$local_repo"

