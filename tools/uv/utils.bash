#!/usr/bin/env bash

source "${DOTFILES}/tools/bash/utils.bash"

export TOOL_LOWER="uv"
export TOOL_UPPER="uv"
export TOOL_COMMAND="uv"
export TOOL_PACKAGE="uv"
export TOOL_EMOJI="🐍"
export TOOL_CONFIG_DIR="${HOME}/.config/${TOOL_LOWER}"

# See: https://docs.astral.sh/uv/getting-started/installation/
export TOOL_INSTALL_COMMAND="curl -LsSf https://astral.sh/uv/install.sh | sh"

# The work laptop installs uv from an internal installer, whose URL is in private.env. Without it
# there is no install command, rather than the public one the work laptop must not use.
if is_work; then
  if [[ -n "${PRIVATE_UV_INSTALLER_URL:-}" ]]; then
    export TOOL_INSTALL_COMMAND="curl -LsSf ${PRIVATE_UV_INSTALLER_URL} | sh"
  else
    unset TOOL_INSTALL_COMMAND
  fi
fi

parse_version() {
  local raw_version="${1}"
  local second_word="$(printf "${raw_version}" | awk '{print $2}')"

  printf "${second_word}"
}
