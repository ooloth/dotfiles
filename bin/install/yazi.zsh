#!/usr/bin/env zsh

if $IS_WORK; then
  return_or_exit 0
fi

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/zsh/config/aliases.zsh"
source "$DOTFILES/zsh/config/utils.zsh"

repo="yazi-rs/flavors"
local_repo="$HOME/Repos/$repo"

if [ -d "$local_repo" ]; then
  printf "\n📂 yazi flavors are already installed\n"
  return_or_exit 0
fi

# Otherwise, clone and symlink
info "📂 Installing yazi flavors"

mkdir -p "$local_repo"
git clone "git@github.com:$repo.git" "$local_repo"
ln -sfv "$local_repo/catppuccin-mocha.yazi" "$HOME/.config/yazi/flavors"
