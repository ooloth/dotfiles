#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/claude/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/agents" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/CLAUDE.md" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/commands" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/rules" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/skills" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/settings.json" "${TOOL_CONFIG_DIR}"
