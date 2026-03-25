#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="pi"
export TOOL_UPPER="Pi"
export TOOL_COMMAND="pi"
export TOOL_PACKAGE="@mariozechner/pi-coding-agent"
export TOOL_EMOJI="🥧"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}/agent"

parse_version() {
  local raw_version="${1}"
  local suffix=" (${TOOL_UPPER})"

  # Everything before the suffix
  printf "${raw_version%"${suffix}"}"
}
