#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "🤖 Uninstalling Claude Code"
# Never --zap: the cask's zap stanza deletes ~/.claude.json, which holds settings and MCP servers
brew uninstall --cask claude-code@latest
