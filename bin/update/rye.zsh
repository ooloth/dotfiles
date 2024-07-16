#!/usr/bin/env zsh

# Install if missing
if ! command -v rye &> /dev/null; then
  source "$HOME/Repos/ooloth/dotfiles/bin/install/rye.zsh"
  return
fi

# Otherwise, update
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🌾 Updating rye"

rye self update