#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/tmux/utils.bash"
source "${DOTFILES}/features/update/utils.bash"

# # Install tpm if missing
# if [ ! -d "$TPM_DIR" ]; then
#   git clone "git@github.com:tmux-plugins/tpm.git" "${TPM_DIR}"
# fi

# Update tmux + tpm + all tpm plugins
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

# Reload tmux if it's running
if pgrep -q tmux; then
  # see: https://github.com/tmux-plugins/tpm?tab=readme-ov-file#installation
  printf "\n🔁 Reloading tmux\n"
  tmux source ~/.config/tmux/tmux.conf
fi
