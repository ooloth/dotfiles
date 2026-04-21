#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🤖 Uninstalling Claude Code"
npm uninstall --global @anthropic-ai/claude-code
