#!/usr/bin/env zsh

if $IS_WORK; then
  return_or_exit 0
fi

if have rustup; then
  printf "\n🦀 Rust is already installed\n"
  source "$DOTFILES/config/zsh/alias.zsh"
  return_or_exit 0
fi

# Otherwise, install
source "$DOTFILES/config/zsh/utils.zsh"
info "🦀 Installing rust"

# Use custom paths
export CARGO_HOME=$HOME/.config/cargo
export RUSTUP_HOME=$HOME/.config/rustup

# See: https://www.rust-lang.org/tools/install
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

printf "\n🚀 Finished installing rustup, rustc and cargo.\n"
