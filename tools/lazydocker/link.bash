#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/lazydocker/config/config.yml" "${HOME}/.config/lazydocker"
