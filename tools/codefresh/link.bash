#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/codefresh/bin/codefresh" "${HOME}/.local/bin"
