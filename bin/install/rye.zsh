#!/usr/bin/env zsh

if have rye; then
  printf "\n🌾 Rye is already installed\n"
  source "$DOTFILES/config/zsh/alias.zsh"
  return_or_exit 0
fi

# Otherwise, install
source "$DOTFILES/config/zsh/utils.zsh"
info "🌾 Installing rye"

# Use custom paths
export RYE_HOME="$HOME/.config/rye"

# See: https://rye.astral.sh/guide/installation/
curl -sSf https://rye.astral.sh/get | bash

printf "\n🚀 Finished installing rye.\n"
