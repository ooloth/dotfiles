#!/usr/bin/env bash
set -euo pipefail

readonly TOOL_LOWER="visidata"
readonly TOOL_UPPER="Visidata"
readonly TOOL_EMOJI="📊"

export TOOL_EMOJI TOOL_LOWER TOOL_UPPER

parse_version() {
  # Drop the prefix
  local raw_version="$1"
  printf "${raw_version#saul.pw/VisiData v}"
}
