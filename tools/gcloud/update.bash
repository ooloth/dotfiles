#!/usr/bin/env bash
set -euo pipefail

# Return early if not installed
if ! have gcloud; then
  return 0
fi

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/gcloud/utils.bash" # source last to avoid env var overrides

update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "${TOOL_COMMAND} components update --quiet" \
  "${TOOL_COMMAND} --version" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash"
