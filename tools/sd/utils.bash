#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="sd"
export TOOL_UPPER="sd"
export TOOL_COMMAND="sd"
export TOOL_PACKAGE="sd"
export TOOL_EMOJI="✂️"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix="${TOOL_PACKAGE} "

  # Everything after the prefix
  printf "${raw_version#"${prefix}"}"
}
