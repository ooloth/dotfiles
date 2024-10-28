#!/usr/bin/env zsh


# Install if missing
if ! have rustup; then
  source "$DOTFILES/bin/install/rust.zsh"
  source "$DOTFILES/config/zsh/aliases.zsh"
  return_or_exit 0
fi

# Otherwise, update
source "$DOTFILES/config/zsh/utils.zsh"
info "🦀 Updating rust dependencies"

rustup update
