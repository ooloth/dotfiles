#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="neovim"
export TOOL_UPPER="Neovim"
export TOOL_COMMAND="nvim"
export TOOL_PACKAGE="neovim"
export TOOL_EMOJI="🦸"
export TOOL_CONFIG_DIR="${HOME}/.config/nvim"

parse_version() {
  local raw_version="${1}"
  local prefix_brew_formula="${TOOL_PACKAGE} "

  # Grab everything after the prefix
  printf "${raw_version#"${prefix_brew_formula}"}"
}
