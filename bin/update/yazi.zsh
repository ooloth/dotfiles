#!/usr/bin/env zsh

if $IS_WORK; then
  return_or_exit 0
fi

local_repo="$HOME/Repos/yazi-rs/flavors"

# Install if missing
if [ ! -d "$local_repo" ]; then
  source "$DOTFILES/bin/install/yazi.zsh"
  source "$DOTFILES/config/zsh/alias.zsh"
  return_or_exit 0
fi

# Otherwise, update
source "$DOTFILES/config/zsh/utils.zsh"
info "📂 Updating yazi flavors"

git -C "$local_repo" pull
