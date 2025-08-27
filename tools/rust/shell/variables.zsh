#!/usr/bin/env zsh

source "${DOTFILES}/tools/zsh/utils.zsh"

export CARGO_HOME="${HOME}/.config/cargo"
export RUSTUP_HOME="${HOME}/.config/rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"

if have rustup; then
  source "${CARGO_HOME}/env"
fi

