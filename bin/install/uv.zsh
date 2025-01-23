#!/usr/bin/env zsh

source "$DOTFILES/config/zsh/alias.zsh"
source "$DOTFILES/config/zsh/utils.zsh"

if have uv; then
  printf "\n⚡️ uv is already installed\n"
  return_or_exit 0
fi

# Otherwise, install
info "⚡️ Installing uv"

# See: https://docs.astral.sh/uv/getting-started/installation/
brew install uv

printf "\n🚀 Finished installing $(uv --version).\n"
