#!/usr/bin/env zsh

if $IS_WORK; then
  return_or_exit 0
fi

local_repo="$HOME/Repos/yazi-rs/flavors"

# Install if missing
if [ ! -d "$local_repo" ]; then
  source "$DOTFILES/bin/install/yazi.zsh"
  source "$DOTFILES/zsh/config/alias.zsh"
  return_or_exit 0
fi

# Otherwise, update
source "$DOTFILES/zsh/config/utils.zsh"
info "📂 Updating yazi flavors"

git -C "$local_repo" pull

printf "\n🎉 All yazi flavors are up to date\n"
