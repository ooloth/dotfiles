#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"

# TODO: update names
tool_lower="visidata"
tool_upper="Visidata"

parse_version() {
  local raw_version="$1"
  printf "${raw_version#harlequin, version }" | head -n 1
}

# TODO: update emoji + update command + version command
install_or_update \
  "${tool_lower}" \
  "${tool_upper}" \
  "🤪" \
  "uv tool upgrade ${tool_lower}" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash" \
  "${DOTFILES}/tools/${tool_lower}/install.bash" \
  "${tool_lower} --version" \
  "parse_version"
