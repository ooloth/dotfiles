#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

info "☁️ Uninstalling Google Cloud SDK"
trash "${HOME}/google-cloud-sdk"
trash "${HOME}/.config/gcloud"
