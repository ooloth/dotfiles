#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# See: https://docs.astral.sh/uv/getting-started/installation/#uninstallation
info "🐍 Uninstalling uv"
uv cache clean
trash "$(uv python dir)"
trash "$(uv tool dir)"
trash "${HOME}/.local/bin/uv"
trash "${HOME}/.local/bin/uvx"
