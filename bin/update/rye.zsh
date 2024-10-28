#!/usr/bin/env zsh

# Install if missing
if ! have rye; then
  source "$DOTFILES/bin/install/rye.zsh"
  source "$DOTFILES/config/zsh/aliases.zsh"
  return_or_exit 0
fi

# Otherwise, update
source "$DOTFILES/config/zsh/utils.zsh"
info "🌾 Updating rye"

rye self update
