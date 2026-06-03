#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

export CARGO_HOME="${HOME}/.config/cargo"
export RUSTUP_HOME="${HOME}/.config/rustup"
export PATH="${CARGO_HOME}/bin:${PATH}"

info "🦀 Installing Rust"
# See: https://www.rust-lang.org/tools/install
# See: https://users.rust-lang.org/t/how-can-i-cleanup-changes-in-profile/67012
# See: https://rust-lang.github.io/rustup/installation/index.html
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path -y

debug "📦 Adding rustup completions"
mkdir -p ~/.zfunc
rustup completions zsh >~/.zfunc/_rustup

debug "📦 Adding rust-analyzer"
rustup component add rust-analyzer

debug "📦 Adding cargo-nextest"
cargo install cargo-nextest --locked
