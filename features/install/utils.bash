#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

get_tool_version() {
  local version_command="$1"
  local parse_function="$2"

  local version_raw
  version_raw="$(eval "$version_command")"

  # Use the optional version parsing function if provided, otherwise return raw version
  if [[ -n "$parse_function" ]]; then
    "$parse_function" "$version_raw"
  else
    printf "$version_raw"
  fi
}

install_and_symlink() {
  local tool_lower="$1"
  local tool_upper="$2"
  local tool_emoji="$3"
  local install_command="$4"
  local symlink_script_path="$5"
  local version_command="$6"
  local version_parsing_function="$7"

  info "${tool_emoji} Installing ${tool_lower}"

  if have "$tool_lower"; then
    local current_version
    current_version="$(get_tool_version "$version_command" "$version_parsing_function")"
    printf "✅ ${tool_upper} ${current_version} is already installed\n"
  else
    bash -c "$install_command"
  fi

  # Symlink config files
  source "$symlink_script_path"

  # Confirm installation
  exec "${SHELL}" -l

  if ! have "${tool_lower}"; then
    error "❌ ${tool_lower} command not found"
    return 1
  fi

  local new_version
  new_version="$(get_tool_version "$version_command" "$version_parsing_function")"
  debug "🚀 ${tool_upper} ${new_version} is installed"
}
