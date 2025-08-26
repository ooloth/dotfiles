#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="claude"
export TOOL_UPPER="Claude Code"
export TOOL_COMMAND="claude"
export TOOL_PACKAGE="@anthropic-ai/claude-code"
export TOOL_EMOJI="🫟"
export TOOL_CONFIG_DIR="${HOME}/.claude"

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
