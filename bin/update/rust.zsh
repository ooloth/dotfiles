#!/usr/bin/env zsh

# Install if missing
if ! command -v rustup &> /dev/null; then
  source "$HOME/Repos/ooloth/dotfiles/bin/install/rust.zsh"
  return
fi

# Otherwise, update
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🦀 Updating rust dependencies"

rustup update