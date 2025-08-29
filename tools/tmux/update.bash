#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/features/update/utils.bash"
source "${DOTFILES}/tools/bash/utils.bash"
source "${DOTFILES}/tools/homebrew/utils.bash"
source "${DOTFILES}/tools/tmux/utils.bash"

# Update tmux + tpm + all tpm plugins
update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew upgrade --formula ${TOOL_PACKAGE} " \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash"

debug "📦 Updating homebrew dependencies"
for formula in "${TOOL_HOMEBREW_DEPENDENCIES[@]}"; do
  ensure_brew_formula_updated "${formula}"
done

debug "📦 Updating tpm plugins"
"${TPM}/clean_plugins"
"${TPM}/install_plugins"
"${TPM}/update_plugins" all

# Reload tmux if it's running
if pgrep -q tmux; then
  # see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
  debug "🔁 Reloading ${TOOL_LOWER}"
  tmux source "${TOOL_CONFIG_DIR}/tmux.conf"
fi

debug "🚀 All ${TOOL_UPPER} dependencies are up-to-date"
