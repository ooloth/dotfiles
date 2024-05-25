#!/usr/bin/env zsh

repo="yazi-rs/flavors"
local_repo="$HOME/Repos/$repo"

# Return if installed
if [ -d "$local_repo" ]; then
  printf "\n📂 yazi flavors are already installed\n"
  return
fi

# Otherwise, clone and symlink
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "📂 Installing yazi flavors"

mkdir -p "$local_repo"
git clone "git@github.com:$repo.git" "$local_repo"
ln -sfv "$local_repo/catppuccin-mocha.yazi" "$HOME/.config/yazi/flavors"