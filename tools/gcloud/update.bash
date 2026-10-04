#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# gcloud is only used on the work laptop
if ! is_work || ! have gcloud; then
  exit 0
fi

info "☁️ Updating gcloud"
gcloud components update --quiet
