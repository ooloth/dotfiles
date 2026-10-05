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
elif [[ "${DOTFILES_CHECK:-}" == "true" ]]; then
  # Check mode reports, like symlink() does, and never creates or replaces the link
  if [ -L "${config_dir}/AGENTS.md" ]; then
    printf "❌ WRONG TARGET: AGENTS.md → %s (points to: %s)\n" "${config_dir}" \
      "$(readlink "${config_dir}/AGENTS.md")"
  else
    printf "❌ MISSING: AGENTS.md → %s\n" "${config_dir}"
  fi
  exit 1
else
  mkdir -p "${config_dir}"
  printf "🔗 "
  ln -fsvw "${agents_md}" "${config_dir}/AGENTS.md"
fi
