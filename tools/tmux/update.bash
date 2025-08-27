#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/tmux/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

TPM="${TOOL_CONFIG_DIR}/plugins/tpm/bin"

# Install if missing
if [ ! -d "$TPM" ]; then
  source "$DOTFILES/features/install/zsh/tmux.zsh"
fi

update_and_symlink \
  "${TOOL_LOWER}" \
  "${TOOL_UPPER}" \
  "${TOOL_COMMAND}" \
  "${TOOL_EMOJI}" \
  "brew upgrade --formula ${TOOL_PACKAGE} && ${TPM}/clean_plugins && ${TPM}/install_plugins && ${TPM}/update_plugins all" \
  "${DOTFILES}/tools/${TOOL_LOWER}/symlinks/link.bash" \
  "${DOTFILES}/tools/${TOOL_LOWER}/install.bash" \
  "brew list --version ${TOOL_PACKAGE}" \
  "parse_version"

# Reload tmux config automatically if it's running
if pgrep -q tmux; then
  # see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
  printf "\n🔁 Reloading tmux config\n"
  tmux source ~/.config/tmux/tmux.conf
fi
