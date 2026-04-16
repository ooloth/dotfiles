#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "📋 Installing Jira CLI"
brew bundle --file="${DOTFILES}/tools/jira/Brewfile"
