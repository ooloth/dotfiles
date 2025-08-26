#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="lazygit"
export TOOL_UPPER="Lazygit"
export TOOL_COMMAND="lazygit"
export TOOL_PACKAGE="lazygit"
export TOOL_EMOJI="🌳"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
