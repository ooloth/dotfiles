#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="vscode"
export TOOL_UPPER="Visual Studio Code"
export TOOL_COMMAND="code"
export TOOL_PACKAGE="visual-studio-code"
export TOOL_EMOJI="🦸"
export TOOL_CONFIG_DIR="${HOME}/Library/Application Support/Code/User"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_cask="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_cask}"}"
}
