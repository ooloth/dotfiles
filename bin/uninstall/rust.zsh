#!/usr/bin/env zsh

# Return if not installed
if command -v rustup &> /dev/null; then
  printf "\n🦀 Rust is not installed\n"
  return
fi

# Otherwise, uninstall
source "$HOME/Repos/ooloth/dotfiles/config/zsh/banners.zsh"
info "🦀 Uninstalling rust"

# See: https://www.rust-lang.org/tools/install
rustup self uninstall