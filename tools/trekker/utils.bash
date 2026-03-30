#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="trekker"
export TOOL_UPPER="Trekker"
export TOOL_COMMAND="trekker"
export TOOL_PACKAGE="@obsfx/trekker"
export TOOL_EMOJI="📋"

parse_version() {
  local raw_version="${1}"

  # Output is bare semver (e.g. "1.10.2")
  printf "${raw_version}"
}
