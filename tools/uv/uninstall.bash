#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/uv/utils.bash"
source "${DOTFILES}/features/uninstall/utils.bash"

# See: https://docs.astral.sh/uv/getting-started/installation/#uninstallation
uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "uv cache clean && rm -r $(uv python dir) && rm -r $(uv tool dir) && rm ${HOME}/.local/bin/uv ${HOME}/.local/bin/uvx" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/unlink.bash"
