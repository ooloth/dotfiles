#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

get_version() {
  local version
  version="$(uv --version | awk '{print $2}')"
  printf "${version}"
}

# Install or update
if ! have uv; then
  source "${DOTFILES}/tools/uv/install.bash"
  new_version="$(get_version)"
  debug "✅ Installed uv $new_version"
else
  info "🐍 Updating uv"
  current_version="$(get_version)"

  uv self update
  new_version="$(get_version)"

  if [ "$current_version" == "$new_version" ]; then
    debug "✅ Already at the latest version ($new_version)"
  else
    debug "⬆️ Updated from version $current_version to $new_version"
  fi
fi

# Symlink config files
source "${DOTFILES}/tools/uv/symlinks/link.bash"

debug "🚀 uv is up to date"
