#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="kitty"
export TOOL_UPPER="kitty"
export TOOL_PACKAGE="kitty"
export TOOL_EMOJI="🐱"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_cask="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_cask}"}"
}
