#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/uv/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

# See: https://docs.astral.sh/uv/getting-started/installation/
install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "curl -LsSf https://astral.sh/uv/install.sh | sh" \
  "${TOOL_PACKAGE} --version" \
  "parse_version" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash"
