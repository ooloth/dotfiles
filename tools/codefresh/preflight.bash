#!/usr/bin/env bash
set -uo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# Same guard as update.bash: Codefresh is only used on the work laptop, through its Docker image
if ! is_work || ! have docker; then
  exit 0
fi

if ! docker info &>/dev/null; then
  echo "codefresh pulls its CLI image with Docker, and the Docker daemon is not running. Start Docker Desktop: open -a Docker" >&2
  exit 1
fi
