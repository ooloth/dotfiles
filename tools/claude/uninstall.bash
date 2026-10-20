#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🤖 Uninstalling Claude Code"
# Never --zap: the cask's zap stanza deletes ~/.claude.json, which holds settings and MCP servers
brew uninstall --cask claude-code@latest
