#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/zsh/config/.hushlogin" "${HOME}"
symlink "${DOTFILES}/tools/zsh/config/.zshenv" "${HOME}"
symlink "${DOTFILES}/tools/zsh/config/.zshrc" "${HOME}"
