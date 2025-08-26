#!/usr/bin/env bash
set -euo pipefail

tool_lower="uv"
tool_upper="uv"

source "${DOTFILES}/tools/${tool_lower}/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

update_or_install_and_symlink \
  "${tool_lower}" \
  "${tool_upper}" \
  "🐍" \
  "uv self update" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash" \
  "${DOTFILES}/tools/${tool_lower}/install.bash" \
  "${tool_lower} --version" \
  "parse_version"
