#!/usr/bin/env bash
set -euo pipefail

readonly TOOL_LOWER="uv"
readonly TOOL_UPPER="uv"
readonly TOOL_EMOJI="🐍"

export TOOL_EMOJI TOOL_LOWER TOOL_UPPER

parse_version() {
  # Grab the second word
  local raw_version="$1"
  printf "$(echo "$raw_version" | awk '{print $2}')"
}
