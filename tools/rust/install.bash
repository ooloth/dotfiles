#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/rust/utils.bash"
source "${DOTFILES}/tools/rust/shell/variables.bash"
source "${DOTFILES}/features/install/utils.bash"

# See: https://www.rust-lang.org/tools/install
install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${TOOL_COMMAND} --version" \
  "parse_version"
