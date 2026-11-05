#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

symlink "${DOTFILES}/tools/git/config/config" "${HOME}/.config/git"
symlink "${DOTFILES}/tools/git/config/config.work" "${HOME}/.config/git"
