#!/usr/bin/env zsh


# Return if not installed
if ! have rustup; then
  printf "\n🦀 Rust is not installed\n"
  source "$DOTFILES/zsh/config/alias.zsh"
  return_or_exit 0
fi

# Otherwise, uninstall
source "$DOTFILES/zsh/config/utils.zsh"
info "🦀 Uninstalling rust"

# See: https://www.rust-lang.org/tools/install
rustup self uninstall
