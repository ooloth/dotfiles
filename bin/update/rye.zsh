#!/usr/bin/env zsh

# Install if missing
if ! have rye; then
  source "$HOME/Repos/ooloth/dotfiles/bin/install/rye.zsh"
  return
fi

# Otherwise, update
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🌾 Updating rye"

rye self update
