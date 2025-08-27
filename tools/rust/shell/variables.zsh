#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

# See: https://rust-lang.github.io/rustup/environment-variables.html
export CARGO_HOME="${HOME}/.config/cargo"
export RUSTUP_HOME="${HOME}/.config/rustup"

if have rustup; then
  export PATH="${CARGO_HOME}/bin:${PATH}"
  source "${CARGO_HOME}/env"
fi

