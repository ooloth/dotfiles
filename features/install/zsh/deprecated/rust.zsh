#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

###########
# INSTALL #
###########

if have rustup; then
  printf "\n🦀 Rust is already installed\n"
else
  info "🦀 Installing rust"

  # Use custom paths
  export CARGO_HOME=$HOME/.config/cargo
  export RUSTUP_HOME=$HOME/.config/rustup

  # See: https://www.rust-lang.org/tools/install
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  printf "\n🚀 Finished installing rustup, rustc and cargo.\n"
fi

##########
# UPDATE #
##########

info "🦀 Updating rust dependencies"

rustup update

printf "\n🎉 All rust dependencies are up to date\n"
