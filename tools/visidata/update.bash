#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"

parse_visidata_version() {
  local raw_version="$1"
  printf "${raw_version#saul.pw/VisiData v}"
}

install_or_update \
  "visidata" \
  "Visidata" \
  "📊" \
  "uv tool upgrade visidata" \
  "${DOTFILES}/tools/visidata/symlinks/link.bash" \
  "${DOTFILES}/tools/visidata/install.bash" \
  "vd -v" \
  "parse_visidata_version"
