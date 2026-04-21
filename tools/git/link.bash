#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/git/config/config" "${HOME}/.config/git"
symlink "${DOTFILES}/tools/git/config/config.work" "${HOME}/.config/git"
