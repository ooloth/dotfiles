#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/claude/utils.bash" # source last to avoid env var overrides

install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "npm install --global ${TOOL_PACKAGE}@latest" \
  "${TOOL_COMMAND} --version" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

debug "🤖 Adding user-scoped MCP servers (requires OAuth authentication on first use)"
claude mcp add --transport http --scope user notion https://mcp.notion.com/mcp 2>/dev/null || true
