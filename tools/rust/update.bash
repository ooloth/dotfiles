#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/rust/utils.bash"

if ! have rustc; then
  bash "${DOTFILES}/tools/rust/install.bash"
  exit 0
fi

info "🦀 Updating Rust"
rustup update

# cargo install upgrades a package when a newer version exists and skips it otherwise
debug "📦 Updating cargo dependencies"
for package in "${TOOL_CARGO_DEPENDENCIES[@]}"; do
  cargo install --locked "${package}"
done
