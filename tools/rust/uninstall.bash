#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/rust/utils.bash"
source "${DOTFILES}/features/uninstall/utils.bash"

# See: https://www.rust-lang.org/tools/install
uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "rustup self uninstall" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/unlink.bash"
