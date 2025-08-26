#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

update_and_symlink() {
  local tool_lower="${1}"
  local tool_upper="${2}"
  local tool_emoji="${3}"
  local update_command="${4}"
  local symlink_script_path="${5}"
  local install_script_path="${6}"
  local version_command="${7}"
  local version_parsing_function="${8}"

  if ! have "${tool_lower}"; then
    # Install if command not found
    source "${install_script_path}"
    local new_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"
    debug "✅ Installed ${tool_lower} ${new_version}"
  else
    # Update if command found
    info "${tool_emoji} Updating ${tool_lower}"
    local current_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"

    bash -c "${update_command}"
    local new_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"

    if [ "${current_version}" == "${new_version}" ]; then
      debug "✅ Already using the latest version (${new_version})"
    else
      debug "⬆️ Updated from version ${current_version} to ${new_version}"
    fi
  fi

  # Symlink config files
  source "${symlink_script_path}"

  debug "🚀 ${tool_upper} is up to date"
}
