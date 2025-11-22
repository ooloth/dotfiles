#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🍞 Uninstalling btop"
brew uninstall --formula bun
