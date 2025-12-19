#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📿 Uninstalling beads"
brew uninstall --formula beads
