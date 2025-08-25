#!/usr/bin/env bash
set -euo pipefail

# TODO: Skip installation if found
# TODO: Validate update (e.g. command is available, version is correct)
# TODO: Symlink configuration files (overkill? might as well?)
# TODO: Validate configuration (e.g. options are still valid)

source "${DOTFILES}/tools/bash/utils.bash"

get_version() {
  local version
  version="$(vd -v)"
  printf "${version#saul.pw/VisiData v}"
}

current_version="$(get_version)"

info "📊 Updating visidata"

uv tool upgrade visidata

new_version="$(get_version)"

if [ "$current_version" != "$new_version" ]; then
  debug "🚀 Visidata updated from version $current_version to $new_version"
else
  debug "🚀 Visidata $new_version is already up to date"
fi
