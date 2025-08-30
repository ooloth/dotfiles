#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="homebrew"
export TOOL_UPPER="Homebrew"
export TOOL_COMMAND="brew"
export TOOL_PACKAGE="brew"
export TOOL_EMOJI="🍺"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix="${TOOL_UPPER} "

  # Everything after the prefix
  printf "${raw_version#"${prefix}"}"
}
