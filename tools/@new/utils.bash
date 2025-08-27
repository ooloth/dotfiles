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
  local second_word="$(printf "${raw_version}" | awk '{print $2}')"
  local prefix="${TOOL_PACKAGE}, version "

  # Everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"

  # Just the second word
  printf "${second_word}"

  # Everything after the prefix on the first line only
  printf "${raw_version#"${prefix}"}" | head -n 1
}
