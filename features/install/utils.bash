#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/features/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"

install_and_symlink() {
  local tool_lower="${1}"
  local tool_upper="${2}"
  local tool_emoji="${3}"
  local install_command="${4}"
  local symlink_script_path="${5}"
  local version_command="${6}"
  local version_parsing_function="${7}"

  info "${tool_emoji} Installing ${tool_lower}"

  if have "${tool_lower}"; then
    local current_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"
    printf "✅ ${tool_upper} ${current_version} is already installed\n"
  else
    bash -c "${install_command}"
  fi

  # Symlink config files
  bash -c "VERBOSE=true ${symlink_script_path}"

  # Confirm installation
  "${SHELL}" -lc "exit"

  if ! have "${tool_lower}"; then
    error "❌ ${tool_lower} command not found"
    return 1
  fi

  local new_version="$(get_tool_version "${version_command}" "${version_parsing_function}")"

  debug "🚀 ${tool_upper} ${new_version} has been installed"
}
