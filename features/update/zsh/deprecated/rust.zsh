#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"


# Install if missing
if ! have rustup; then
  source "$DOTFILES/features/install/zsh/deprecated/rust.zsh"
  return_or_exit 0
fi

# Otherwise, update
info "🦀 Updating rust dependencies"

rustup update

printf "\n🎉 All rust dependencies are up to date\n"
