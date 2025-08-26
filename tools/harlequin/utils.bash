#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="harlequin"
export TOOL_UPPER="Harlequin"
export TOOL_COMMAND="harlequin"
export TOOL_PACKAGE="harlequin"
export TOOL_EMOJI="🤡"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="$1"
  local prefix="${TOOL_PACKAGE}, version "

  # Grab everything after the prefix on the first line only
  printf "${raw_version#"${prefix}"}" | head -n 1
}
