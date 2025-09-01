#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/vscode/utils.bash" # source last to avoid env var overrides

# update_and_symlink \
#   "${TOOL_LOWER}" \
#   "${TOOL_UPPER}" \
#   "${TOOL_COMMAND}" \
#   "${TOOL_EMOJI}" \
#   "brew upgrade --formula ${TOOL_PACKAGE}" \
#   "brew list --version ${TOOL_PACKAGE}" \
#   "parse_version" \
#   "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
#   "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

info "${TOOL_EMOJI} Updating VS Code and its extensions"
brew bundle --file="${DOTFILES}/tools/${TOOL_LOWER}/Brewfile"

debug "📦 Symlinking VS Code configuration"
bash "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

debug "🚀 ${TOOL_UPPER} is up-to-date"
