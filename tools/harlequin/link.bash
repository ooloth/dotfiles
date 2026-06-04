#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

symlink "${DOTFILES}/tools/harlequin/config/config.toml" "${HOME}/.config/harlequin"
