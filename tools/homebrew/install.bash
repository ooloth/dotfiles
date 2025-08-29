#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/homebrew/utils.bash" # source last to avoid env var overrides

# See: https://brew.sh
# Run as a login shell (non-interactive) so that the script doesn't pause for user input
# Use "arch -arm64" to ensure Apple Silicon version installed: https://github.com/orgs/Homebrew/discussions/417#discussioncomment-2684303
install_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | arch -arm64 /bin/bash --login" \
  "${TOOL_COMMAND} --version" \
  "parse_version"
