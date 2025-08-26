#!/usr/bin/env bash
set -euo pipefail

# TODO: update names
tool_lower="x"
tool_upper="X"

source "${DOTFILES}/tools/${tool_lower}/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

# TODO: update emoji + update command + version command
install_or_update \
  "${tool_lower}" \
  "${tool_upper}" \
  "🤪" \
  "uv tool upgrade ${tool_lower}" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash" \
  "${DOTFILES}/tools/${tool_lower}/install.bash" \
  "${tool_lower} --version" \
update_or_install_and_symlink \
  "parse_version"
