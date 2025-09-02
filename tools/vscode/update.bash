#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/vscode/utils.bash" # source last to avoid env var overrides

info "${TOOL_EMOJI} Updating VS Code and its extensions"
brew bundle --file="${DOTFILES}/tools/${TOOL_LOWER}/Brewfile"

debug "📦 Symlinking VS Code configuration"
bash "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

debug "🚀 ${TOOL_UPPER} is up-to-date"
