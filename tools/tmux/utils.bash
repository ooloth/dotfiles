#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="tmux"
export TOOL_UPPER="Tmux"
export TOOL_COMMAND="tmux"
export TOOL_PACKAGE="tmux"
export TOOL_EMOJI="🪟"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

export TPM_DIR="${TOOL_CONFIG_DIR}/plugins/tpm"
export TPM="${TPM_DIR}/bin"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
