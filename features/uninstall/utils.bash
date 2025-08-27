#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

uninstall_and_unlink() {
  local tool_lower="${1}"
  local tool_upper="${2}"
  local tool_command="${3}"
  local tool_emoji="${4}"
  local uninstall_command="${5}"
  local unlink_script_path="${6}"

  info "${tool_emoji} Uninstalling ${tool_lower}"

  if ! have "${tool_command}"; then
    printf "✅ ${tool_upper} is already uninstalled\n"
  else
    bash -c "${uninstall_command}"
  fi

  # Unlink config files
  bash -c "${unlink_script_path}"

  # Confirm uninstallation
  if have "${tool_command}"; then
    error "❌ ${tool_command} command still found"
    return 1
  fi

  debug "🚀 ${tool_upper} has been uninstalled"
}
