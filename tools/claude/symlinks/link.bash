#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/claude/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/claude/config/agents" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/claude/config/CLAUDE.md" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/claude/config/commands" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/claude/config/settings.json" "${TOOL_CONFIG_DIR}"
