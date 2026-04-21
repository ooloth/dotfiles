#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

if ! have rustc; then
  bash "${DOTFILES}/tools/rust/install.bash"
  exit 0
fi

info "🦀 Updating Rust"
rustup update
