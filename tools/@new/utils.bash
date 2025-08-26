#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="x"
export TOOL_UPPER="X"
export TOOL_COMMAND="x"
export TOOL_PACKAGE="x"
export TOOL_EMOJI="🤪"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "
  local prefix_uv_tool="$(printf "${raw_version}" | awk '{print $2}')"
  local prefix="${TOOL_PACKAGE}, version "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"

  # Grab the second word
  printf "${raw_version#"${prefix_uv_tool}"}"

  # Grab everything after the prefix on the first line only
  printf "${raw_version#"${prefix}"}" | head -n 1
}
