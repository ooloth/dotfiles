#!/usr/bin/env bash
set -euo pipefail

export TOOL_LOWER="rust"
export TOOL_UPPER="Rust"
export TOOL_COMMAND="rustc" # cargo + rustup are installed too, but rustc is the main command
export TOOL_PACKAGE="rustup"
export TOOL_EMOJI="🦀"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

parse_version() {
  local raw_version="${1}"
  local second_word="$(printf "${raw_version}" | awk '{print $2}')"

  printf "${second_word}"
}
