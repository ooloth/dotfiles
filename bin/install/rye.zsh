#!/usr/bin/env zsh

# Return if installed
if have rye; then
  printf "\n🌾 Rye is already installed\n"
  return
fi

# Otherwise, install
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🌾 Installing rye"

# Use custom paths
export RYE_HOME="$HOME/.config/rye"

# See: https://rye.astral.sh/guide/installation/
curl -sSf https://rye.astral.sh/get | bash

printf "\n🚀 Finished installing rye.\n"
