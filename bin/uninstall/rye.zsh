#!/usr/bin/env zsh

# Return if not installed
if ! have rye; then
  printf "\n🌾 Rye is not installed\n"
  return
fi

# Otherwise, uninstall
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🌾 Uninstalling rye"

# See: https://www.rust-lang.org/tools/install
rye self uninstall
