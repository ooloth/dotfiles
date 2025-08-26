#!/usr/bin/env bash
set -euo pipefail

readonly TOOL_LOWER="x"
readonly TOOL_UPPER="X"
readonly TOOL_EMOJI="🤪"

export TOOL_EMOJI TOOL_LOWER TOOL_UPPER

parse_version() {
  # Grab the first line after the prefix
  local raw_version="$1"
  printf "${raw_version#harlequin, version }" | head -n 1
}
