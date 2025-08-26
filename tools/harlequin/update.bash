#!/usr/bin/env bash
set -euo pipefail

tool_lower="harlequin"
tool_upper="Harlequin"

source "${DOTFILES}/tools/${tool_lower}/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

install_or_update \
  "${tool_lower}" \
  "${tool_upper}" \
  "🤡" \
  "uv tool upgrade ${tool_lower}" \
  "${DOTFILES}/tools/${tool_lower}/symlinks/link.bash" \
  "${DOTFILES}/tools/${tool_lower}/install.bash" \
  "${tool_lower} --version" \
  "parse_version"
