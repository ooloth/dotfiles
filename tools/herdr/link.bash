#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# Link only the config file: ~/.config/herdr also holds herdr's sockets, logs and session state
symlink "${DOTFILES}/tools/herdr/config/config.toml" "${HOME}/.config/herdr"
