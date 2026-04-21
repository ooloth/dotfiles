#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

if ! have gcloud; then
  exit 0
fi

info "☁️ Updating gcloud"
gcloud components update --quiet
