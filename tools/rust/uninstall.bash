#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# See: https://www.rust-lang.org/tools/install
info "🦀 Uninstalling Rust"
rustup self uninstall
