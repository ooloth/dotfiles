#!/usr/bin/env zsh

# Install if missing
if ! have rustup; then
  source "$HOME/Repos/ooloth/dotfiles/bin/install/rust.zsh"
  return
fi

# Otherwise, update
source "$HOME/Repos/ooloth/dotfiles/config/zsh/utils.zsh"
info "🦀 Updating rust dependencies"

rustup update
