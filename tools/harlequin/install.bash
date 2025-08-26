#!/usr/bin/env bash
set -euo pipefail

tool_lower="harlequin"
tool_upper="Harlequin"

source "${DOTFILES}/tools/${tool_lower}/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

install_and_symlink \
  "${tool_lower}" \
  "${tool_upper}" \
  "🤡" \
  "uv tool install ${tool_lower}" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash" \
  "${tool_lower} --version" \
  "parse_version"
