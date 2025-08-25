#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

source "$DOTFILES/tools/zsh/config/aliases.zsh"
source "$DOTFILES/tools/zsh/utils.zsh"

# Install if missing
if ! have rustup; then
  source "$DOTFILES/features/install/zsh/rust.zsh"
  return_or_exit 0
fi

# Otherwise, update
info "🦀 Updating rust dependencies"

rustup update

printf "\n🎉 All rust dependencies are up to date\n"
