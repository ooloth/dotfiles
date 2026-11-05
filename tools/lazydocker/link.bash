#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

symlink "${DOTFILES}/tools/lazydocker/config/config.yml" "${HOME}/.config/lazydocker"
