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

install_or_update() {
  local tool_lower="$1"
  local tool_upper="$2"
  local tool_emoji="$3"
  local update_command="$4"
  local symlink_script_path="$5"
  local install_script_path="$6"
  local version_command="$7"
  local version_parsing_function="$8"

  if ! have "$tool_lower"; then
    # Install if command not found
    source "$install_script_path"
    local new_version
    new_version="$(get_tool_version "$version_command" "$version_parsing_function")"
    debug "✅ Installed $tool_lower $new_version"
  else
    # Update if command found
    info "$tool_emoji Updating $tool_lower"
    local current_version
    current_version="$(get_tool_version "$version_command" "$version_parsing_function")"

    bash -c "$update_command"
    local new_version
    new_version="$(get_tool_version "$version_command" "$version_parsing_function")"

    if [ "$current_version" == "$new_version" ]; then
      debug "✅ Already using the latest version ($new_version)"
    else
      debug "⬆️ Updated from version $current_version to $new_version"
    fi
  fi

  # Symlink config files
  source "$symlink_script_path"

  debug "🚀 $tool_upper is up to date"
}
