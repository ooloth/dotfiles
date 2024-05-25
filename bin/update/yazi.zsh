#!/usr/bin/env zsh

local_repo="$HOME/Repos/yazi-rs/flavors"

# Install if missing
if [ ! -d "$local_repo" ]; then
  source "$HOME/Repos/ooloth/dotfiles/bin/install/yazi.zsh"
  return
fi

# Otherwise, update
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "📂 Updating yazi flavors"

git -C "$local_repo" pull;