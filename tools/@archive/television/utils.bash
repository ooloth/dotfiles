#!/usr/bin/env bash

export TOOL_LOWER="television"
export TOOL_UPPER="Television"
export TOOL_COMMAND="tv"
export TOOL_PACKAGE="television"
export TOOL_EMOJI="📺"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
