#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

symlink "${DOTFILES}/tools/zsh/config/.hushlogin" "${HOME}"
symlink "${DOTFILES}/tools/zsh/config/.zshenv" "${HOME}"
symlink "${DOTFILES}/tools/zsh/config/.zshrc" "${HOME}"
