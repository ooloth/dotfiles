#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/bash/utils.bash"

# Skip entirely on machines without gcloud installed (e.g. personal laptop)
if ! have gcloud; then
  exit 0
fi

info "☁️ Checking gcloud authentication"

if timeout 5 gcloud auth application-default print-access-token &>/dev/null; then
  debug "✅ gcloud credentials are valid"
else
  warn "⚠️ gcloud reauthentication needed — run: gca"
  exit 1
fi
