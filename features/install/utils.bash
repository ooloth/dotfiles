#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/features/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

install_and_symlink() {
  local tool_lower="${1}"
  local tool_upper="${2}"
  local tool_command="${3}"
  local tool_emoji="${4}"
  local install_command="${5}"
  local symlink_script_path="${6}"
  local version_command="${7}"
  local version_parsing_function="${8}"

  info "${tool_emoji} Installing ${tool_lower}"

  if have "${tool_command}"; then
    local current_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"
    printf "✅ ${tool_upper} ${current_version} is already installed\n"
    return 0
  fi

  bash -c "${install_command}"

  if [ -f "${symlink_script_path}" ]; then
    bash -c "VERBOSE=true ${symlink_script_path}"
  fi

  # Confirm installation
  if ! have "${tool_command}"; then
    error "❌ ${tool_command} command not found"
    return 1
  fi

  local new_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"

  debug "🚀 ${tool_upper} ${new_version} has been installed"
}
