#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/uninstall/utils.bash"
source "${DOTFILES}/tools/homebrew/utils.bash" # source last to avoid env var overrides

# See: https://docs.brew.sh/FAQ#how-do-i-uninstall-homebrew
# See: https://github.com/homebrew/install?tab=readme-ov-file#uninstall-homebrew
uninstall_and_unlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "NONINTERACTIVE=1 /bin/bash -c $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
