#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# TODO: update names
tool_lower="x"
tool_upper="X"

# TODO: update version finding logic
get_version() {
  local version
  version="$("$tool_lower" --version)"
  printf "${version#harlequin, version }" | head -n 1
}

# Install or update
if ! have "$tool_lower"; then
  source "${DOTFILES}/tools/$tool_lower/install.bash"
  new_version="$(get_version)"
  debug "✅ Installed $tool_lower $new_version"
else
  info "📦 Updating $tool_lower"
  current_version="$(get_version)"

  # TODO: update install command
  uv tool upgrade "$tool_lower"
  new_version="$(get_version)"

  if [ "$current_version" == "$new_version" ]; then
    debug "✅ Already using the latest version ($new_version)"
  else
    debug "⬆️ Updated from version $current_version to $new_version"
  fi
fi

# Symlink config files
source "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash"

debug "🚀 $tool_upper is up to date"
