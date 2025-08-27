#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/rust/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

# See: https://www.rust-lang.org/tools/install
update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "rustup update" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "rustc --version" \
  "parse_version"
