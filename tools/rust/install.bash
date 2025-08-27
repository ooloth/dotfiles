#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/rust/utils.bash"
source "${DOTFILES}/features/install/utils.bash"

export CARGO_HOME="${HOME}/.config/cargo"
export RUSTUP_HOME="${HOME}/.config/rustup"

# TODO: confirm cargo and rustup commands work too?
# See: https://www.rust-lang.org/tools/install
# See: https://users.rust-lang.org/t/how-can-i-cleanup-changes-in-profile/67012
# See: https://rust-lang.github.io/rustup/installation/index.html
install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path -y && mkdir -p ~/.zfunc && rustup completions zsh > ~/.zfunc/_rustup" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${TOOL_COMMAND} --version" \
  "parse_version"
