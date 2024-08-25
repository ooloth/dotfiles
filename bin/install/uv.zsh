#!/usr/bin/env zsh

# Return if installed
if command -v uv &> /dev/null; then
  printf "\n uv is already installed\n"
  return
fi

# Otherwise, install
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🌾 Installing uv"

# Use custom paths
# export RYE_HOME="$HOME/.config/uv"

# See: https://docs.astral.sh/uv/getting-started/installation/
brew install uv

printf "\n🚀 Finished installing uv.\n"

