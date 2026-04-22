#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

config_dir="${HOME}/.claude"

symlink "${DOTFILES}/tools/claude/config/agents" "${config_dir}"
symlink "${DOTFILES}/tools/claude/config/conventions" "${config_dir}"
symlink "${DOTFILES}/tools/claude/config/skills" "${config_dir}"
symlink "${DOTFILES}/tools/claude/config/CLAUDE.md" "${config_dir}"
symlink "${DOTFILES}/tools/claude/config/settings.json" "${config_dir}"
symlink "${DOTFILES}/tools/claude/config/statusline.sh" "${config_dir}"
