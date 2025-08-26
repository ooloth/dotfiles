#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="visidata"
export TOOL_UPPER="VisiData"
export TOOL_COMMAND="vd"
export TOOL_PACKAGE="visidata"
export TOOL_EMOJI="📊"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix="saul.pw/${TOOL_UPPER} v"

  # Grab everything after the prefix
  printf "${raw_version#"${prefix}"}"
}
