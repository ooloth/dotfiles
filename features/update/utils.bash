#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/features/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

update_and_symlink() {
  local tool_lower="${1}"
  local tool_upper="${2}"
  local tool_command="${3}"
  local tool_emoji="${4}"
  local update_command="${5}"
  local symlink_script_path="${6}"
  local install_script_path="${7}"
  local version_command="${8}"
  local version_parsing_function="${9}"

  # If command not found, install + symlink instead of updating
  if ! have "${tool_command}"; then
    bash "${install_script_path}"
    local new_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"
    debug "🚀 Installed ${tool_lower} ${new_version}"
    return 0
  fi

  # Otherwise, update + symlink
  info "${tool_emoji} Updating ${tool_lower}"
  local current_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"

  bash -c "${update_command}"
  local new_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"

  if [ "${current_version}" == "${new_version}" ]; then
    debug "✅ Already using the latest ${tool_lower} version (${new_version})"
  else
    debug "⬆️ Updated ${tool_lower} from version ${current_version} to ${new_version}"
  fi

  # Symlink config files
  bash -c "VERBOSE=true ${symlink_script_path}"

  debug "🚀 ${tool_upper} is up-to-date"
}
