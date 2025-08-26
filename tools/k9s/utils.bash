#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="k9s"
export TOOL_UPPER="K9s"
export TOOL_PACKAGE="k9s"
export TOOL_EMOJI="🚛"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
