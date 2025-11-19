#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="logcli"
export TOOL_UPPER="LogCLI"
export TOOL_COMMAND="logcli"
export TOOL_PACKAGE="logcli"
export TOOL_EMOJI="📊"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
