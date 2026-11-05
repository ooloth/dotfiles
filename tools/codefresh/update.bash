#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

# Codefresh is only used on the work laptop, through its Docker image (see bin/codefresh)
if ! is_work || ! have docker; then
  exit 0
fi

info "🍋 Updating codefresh"
docker pull --quiet codefresh/cli
