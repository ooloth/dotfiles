#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "🤖 Updating Claude Code"
npm install --global @anthropic-ai/claude-code@latest

debug "🤖 Adding user-scoped MCP servers (requires OAuth on first use)"
claude mcp add --transport http --scope user notion https://mcp.notion.com/mcp 2>/dev/null || true
