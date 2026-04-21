#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/sesh/config/sesh.toml" "${HOME}/.config/sesh"
