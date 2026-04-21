#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🥧 Uninstalling Pi"
npm uninstall --global @mariozechner/pi-coding-agent
