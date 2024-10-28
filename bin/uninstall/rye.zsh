#!/usr/bin/env zsh

# Return if not installed
if ! have rye; then
  printf "\n🌾 Rye is not installed\n"
  source "$DOTFILES/config/zsh/alias.zsh"
  return_or_exit 0
fi

# Otherwise, uninstall
source "$DOTFILES/config/zsh/utils.zsh"
info "🌾 Uninstalling rye"

# See: https://www.rust-lang.org/tools/install
rye self uninstall
