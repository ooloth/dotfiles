#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

# gcloud is only used on the work laptop
if ! is_work || ! have gcloud; then
  exit 0
fi

info "☁️ Updating gcloud"
gcloud components update --quiet
