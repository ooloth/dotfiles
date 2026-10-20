#!/usr/bin/env bash
set -uo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# TODO: delete this file unless update.bash depends on outside state, such as a daemon or login,
# that would make it fail. `u` runs every preflight.bash before any update and stops if one fails.
# It must only check, never change anything.

# TODO: use the same guard as update.bash, so this runs only where the update does
if ! is_work || ! have docker; then
  exit 0
fi

# TODO: test what the update actually uses, and say which tool needs it and how to fix it
if ! docker info &>/dev/null; then
  echo "{tool} pulls its image with Docker, and the Docker daemon is not running. Start Docker Desktop: open -a Docker" >&2
  exit 1
fi
