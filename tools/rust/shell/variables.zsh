#!/usr/bin/env zsh

export CARGO_HOME="${HOME}/.config/cargo"
export RUSTUP_HOME="${HOME}/.config/rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"

source "${CARGO_HOME}/env"


