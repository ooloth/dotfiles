#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

config_dir="${HOME}/.config/pi/agent"

symlink "${DOTFILES}/tools/pi/config/extensions" "${config_dir}"
symlink "${DOTFILES}/tools/pi/config/themes" "${config_dir}"
symlink "${DOTFILES}/tools/pi/config/keybindings.json" "${config_dir}"
symlink "${DOTFILES}/tools/pi/config/presets.json" "${config_dir}"
symlink "${DOTFILES}/tools/pi/config/settings.json" "${config_dir}"

# Pi Coding Agent does not support finding the global CLAUDE.md
# See comment from creator: https://github.com/badlogic/pi-mono/issues/692#issuecomment-3745162482
# Use a direct target path because this symlink must be named AGENTS.md (not CLAUDE.md).
agents_md="${DOTFILES}/tools/claude/config/CLAUDE.md"
if [ -L "${config_dir}/AGENTS.md" ] && [ "$(readlink "${config_dir}/AGENTS.md")" = "${agents_md}" ]; then
  printf "✅ AGENTS.md → %s\n" "${config_dir}"
else
  mkdir -p "${config_dir}"
  printf "🔗 "
  ln -fsvw "${agents_md}" "${config_dir}/AGENTS.md"
fi
