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
  local suffix=" (${TOOL_UPPER})"

  # Everything before the suffix
  printf "${raw_version%"${suffix}"}"
}
