#!/usr/bin/env bash
set -euo pipefail

readonly HOMECLAUDE="${HOME}/.claude"

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/claude/config/agents" "${HOMECLAUDE}"
symlink "${DOTFILES}/tools/claude/config/CLAUDE.md" "${HOMECLAUDE}"
symlink "${DOTFILES}/tools/claude/config/commands" "${HOMECLAUDE}"
symlink "${DOTFILES}/tools/claude/config/settings.json" "${HOMECLAUDE}"
