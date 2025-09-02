#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/uninstall/utils.bash"
source "${DOTFILES}/tools/gcloud/utils.bash" # source last to avoid env var overrides

uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "trash ${HOME}/google-cloud-sdk && trash ${HOME}/.config/gcloud"
