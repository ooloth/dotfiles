#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/zsh/config/aliases.zsh"
source "$DOTFILES/zsh/config/utils.zsh"

# Install if missing
if ! have rustup; then
  source "$DOTFILES/bin/install/rust.zsh"
  return_or_exit 0
fi

# Otherwise, update
info "🦀 Updating rust dependencies"

rustup update

printf "\n🎉 All rust dependencies are up to date\n"
