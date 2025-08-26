#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

uninstall_and_unlink() {
  local tool_lower="${1}"
  local tool_upper="${2}"
  local tool_emoji="${3}"
  local uninstall_command="${4}"
  local unlink_script_path="${5}"

  info "${tool_emoji} Uninstalling ${tool_lower}"

  if ! have "${tool_lower}"; then
    printf "✅ ${tool_upper} is already uninstalled\n"
  else
    bash -c "${uninstall_command}"
  fi

  # Unlink config files
  source "${unlink_script_path}"

  # Confirm uninstallation
  "${SHELL}" -lc "exit"

  if have "${tool_lower}"; then
    error "❌ ${tool_lower} command still found"
    return 1
  fi

  debug "🚀 ${tool_upper} has been uninstalled"
}
