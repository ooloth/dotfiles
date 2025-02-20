#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/config/zsh/aliases.zsh"
source "$DOTFILES/config/zsh/utils.zsh"

# Install if missing
if ! have rustup; then
  source "$DOTFILES/bin/install/rust.zsh"
  return_or_exit 0
fi

# Otherwise, update
info "🦀 Updating rust dependencies"

rustup update
