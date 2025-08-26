#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"

tool_lower="uv"
tool_upper="uv"

parse_version() {
  # Grab the second word
  local raw_version="$1"
  printf "$(echo "$raw_version" | awk '{print $2}')"
}

install_or_update \
  "${tool_lower}" \
  "${tool_upper}" \
  "🐍" \
  "uv self update" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash" \
  "${DOTFILES}/tools/${tool_lower}/install.bash" \
  "${tool_lower} --version" \
  "parse_version"
