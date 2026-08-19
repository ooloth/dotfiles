#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/agents/config/standards" "${HOME}/.claude"
symlink "${DOTFILES}/tools/agents/config/standards" "${HOME}/.agents"
symlink "${DOTFILES}/tools/agents/config/skills" "${HOME}/.claude"
symlink "${DOTFILES}/tools/agents/config/skills" "${HOME}/.agents"
