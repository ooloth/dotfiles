#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/install/utils.bash"
source "${DOTFILES}/tools/vscode/utils.bash" # source last to avoid env var overrides

# install_and_symlink \
#   "${TOOL_LOWER}" \
#   "${TOOL_UPPER}" \
#   "${TOOL_COMMAND}" \
#   "${TOOL_EMOJI}" \
#   "brew install --cask ${TOOL_PACKAGE}" \
#   "brew list --version ${TOOL_PACKAGE}" \
#   "parse_version" \
#   "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

info "${TOOL_EMOJI} Installing VS Code and its extensions"
brew bundle --file="${DOTFILES}/tools/${TOOL_LOWER}/Brewfile"

debug "🔗 Symlinking VS Code configuration"
bash "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

debug "🚀 ${TOOL_UPPER} is installed"

# debug "📦 Installing extensions from extensions.txt"
# while IFS= read -r extension; do
#   if code --list-extensions | grep -q "${extension}"; then
#     printf "✅ VS Code extension already installed: ${extension}\n"
#   elif code --install-extension "$extension"; then
#     echo "✅ Installed $extension"
#   else
#     echo "❌ Failed to install $extension"
#   fi
# done <"${DOTFILES}/tools/${TOOL_LOWER}/config/extensions.txt"
