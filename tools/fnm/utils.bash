#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="fnm"
export TOOL_UPPER="Fast Node Manager"
export TOOL_COMMAND="fnm"
export TOOL_PACKAGE="fnm"
export TOOL_EMOJI="⚡"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
