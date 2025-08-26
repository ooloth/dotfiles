#!/usr/bin/env bash
set -euo pipefail

# NOTE: node vs npm vs fnm...?
export TOOL_LOWER="npm"
export TOOL_UPPER="npm"
export TOOL_PACKAGE="npm"
export TOOL_EMOJI="📦"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"

  # No edits needed for "npm --version"
  printf "${raw_version}"
}
