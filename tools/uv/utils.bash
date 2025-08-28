#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

export TOOL_LOWER="uv"
export TOOL_UPPER="uv"
export TOOL_COMMAND="uv"
export TOOL_PACKAGE="uv"
export TOOL_EMOJI="🐍"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

# See: https://docs.astral.sh/uv/getting-started/installation/
export TOOL_INSTALL_COMMAND="curl -LsSf https://astral.sh/uv/install.sh | sh"

if is_work; then
  debug "⚠️ Using work's custom ${TOOL_LOWER} install command"
  # See: https://python.prod.rxrx.io/UV-Adoption-Guide
  export TOOL_INSTALL_COMMAND="curl -LsSf https://python.prod.rxrx.io/rxrx-setup-uv.sh | sh"
fi

parse_version() {
  local raw_version="${1}"
  local second_word="$(printf "${raw_version}" | awk '{print $2}')"

  printf "${second_word}"
}
