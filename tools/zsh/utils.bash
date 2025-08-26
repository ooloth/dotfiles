#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="zsh"
export TOOL_UPPER="Zsh"
export TOOL_PACKAGE="zsh"
export TOOL_EMOJI="🐚"
export TOOL_CONFIG_DIR="${HOME}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
