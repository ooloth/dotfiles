#!/usr/bin/env bash
set -euo pipefail

# TODO: update names
tool_lower="x"
tool_upper="X"

source "${DOTFILES}/tools/${tool_lower}/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

# TODO: update emoji + install command + version command
install_and_symlink \
  "${tool_lower}" \
  "${tool_upper}" \
  "🤪" \
  "uv tool install ${tool_lower}" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash" \
  "${tool_lower} --version" \
  "parse_version"
