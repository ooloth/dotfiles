#!/usr/bin/env bash
set -euo pipefail

export TOOL_CONFIG_DIR="${HOME}/.config/gh"
export TOOL_EMOJI="🌳"
export TOOL_LOWER="gh"
export TOOL_PACKAGE="gh"
export TOOL_UPPER="GitHub CLI"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
