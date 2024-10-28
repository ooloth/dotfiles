#!/usr/bin/env zsh

# Return if installed
if have rustup; then
  printf "\n🦀 Rust is already installed\n"
  return
fi

# Otherwise, install
source "$HOME/Repos/ooloth/dotfiles/config/zsh/utils.zsh"
info "🦀 Installing rust"

# Use custom paths
export CARGO_HOME=$HOME/.config/cargo
export RUSTUP_HOME=$HOME/.config/rustup

# See: https://www.rust-lang.org/tools/install
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

printf "\n🚀 Finished installing rustup, rustc and cargo.\n"
