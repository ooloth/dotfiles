#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="gemini"
export TOOL_UPPER="Gemini CLI"
export TOOL_PACKAGE="gemini-cli"
export TOOL_EMOJI="💎"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
