#!/usr/bin/env bash
set -euo pipefail

tool_lower="uv"
tool_upper="uv"

source "${DOTFILES}/tools/${tool_lower}/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

# See: https://docs.astral.sh/uv/getting-started/installation/
install_and_symlink \
  "${tool_lower}" \
  "${tool_upper}" \
  "🐍" \
  "curl -LsSf https://astral.sh/uv/install.sh | sh" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash" \
  "${tool_lower} --version" \
  "parse_version"
