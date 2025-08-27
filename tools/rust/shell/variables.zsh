#!/usr/bin/env zsh

# See: https://rust-lang.github.io/rustup/environment-variables.html
export CARGO_HOME="${HOME}/.config/cargo"
export RUSTUP_HOME="${HOME}/.config/rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"

