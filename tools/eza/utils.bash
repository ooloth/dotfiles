#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="eza"
export TOOL_UPPER="eza"
export TOOL_COMMAND="eza"
export TOOL_PACKAGE="eza"
export TOOL_EMOJI="📁"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
