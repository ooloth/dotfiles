#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/pi/utils.bash"

symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/extensions" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/themes" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/keybindings.json" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/presets.json" "${TOOL_CONFIG_DIR}"
symlink "${DOTFILES}/tools/${TOOL_LOWER}/config/settings.json" "${TOOL_CONFIG_DIR}"

# Pi Coding Agent does not support finding the global CLAUDE.md
# See comment from creator: https://github.com/badlogic/pi-mono/issues/692#issuecomment-3745162482
# Use a direct target path because this symlink must be named AGENTS.md (not CLAUDE.md).
ln -fsv "${DOTFILES}/tools/claude/config/CLAUDE.md" "${TOOL_CONFIG_DIR}/AGENTS.md"
