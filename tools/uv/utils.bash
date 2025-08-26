#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="uv"
export TOOL_UPPER="uv"
export TOOL_PACKAGE="uv"
export TOOL_EMOJI="🐍"

parse_version() {
  local raw_version="${1}"
  local prefix_uv_tool="$(printf "${raw_version}" | awk '{print $2}')"

  # Grab the second word
  printf "${raw_version#"${prefix_uv_tool}"}"
}
