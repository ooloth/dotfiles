#!/usr/bin/env zsh

if $IS_WORK; then
  return_or_exit 0
fi

repo="yazi-rs/flavors"
local_repo="$HOME/Repos/$repo"

if [ -d "$local_repo" ]; then
  printf "\n📂 yazi flavors are already installed\n"
  source "$DOTFILES/config/zsh/alias.zsh"
  return_or_exit 0
fi

# Otherwise, clone and symlink
source "$DOTFILES/config/zsh/utils.zsh"
info "📂 Installing yazi flavors"

mkdir -p "$local_repo"
git clone "git@github.com:$repo.git" "$local_repo"
ln -sfv "$local_repo/catppuccin-mocha.yazi" "$HOME/.config/yazi/flavors"
