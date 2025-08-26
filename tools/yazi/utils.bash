#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="yazi"
export TOOL_UPPER="Yazi"
export TOOL_COMMAND="yazi"
export TOOL_PACKAGE="yazi"
export TOOL_EMOJI="📁"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
