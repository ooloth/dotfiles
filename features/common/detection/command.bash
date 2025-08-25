#!/usr/bin/env bash
set -euo pipefail

have() {
  if [ -z "$1" ]; then
    echo "Usage: have <command, alias or function>"
    return 1 # false
  fi

  # Check if a command, alias or function with the provided name exists
  if type "$1" &>/dev/null; then
    return 0 # true
  else
    return 1 # false
  fi
}

is_command_available() {
  # Check if a command is available in the PATH
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1
  return $?
}
