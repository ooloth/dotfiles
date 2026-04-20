#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🥧 Updating Pi"
npm install --global @mariozechner/pi-coding-agent@latest
