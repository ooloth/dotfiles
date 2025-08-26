#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="zed"
export TOOL_UPPER="Zed"
export TOOL_PACKAGE="zed"
export TOOL_EMOJI="🦸"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_cask="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_cask}"}"
}
