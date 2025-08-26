#!/usr/bin/env bash
set -euo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/bash/utils.bash"

HOMECONFIG="${HOME}/.config"
VSCODEUSER="$HOME/Library/Application Support/Code/User"

main() {
  local tool="${1:-}"

  info "🔗 Updating symlinks"

  # Remove broken symlinks first
  for dir in "${HOME}" "${HOMECONFIG}" "${VSCODEUSER}"; do
    remove_broken_symlinks "$dir"
  done

  # If a specific tool is provided as an argument, symlink only that tool's configs
  if [[ ! -z "$tool" ]]; then
    bash "${DOTFILES}/tools/${tool}/symlinks/link.bash"
    return 0
  fi

  # Otherwise, symlinks all tool configs with a link.bash script

  # Find all link.bash files in each tool directory (except @new and @archive) and sort by parent directory name
  update_files=$(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -name "link.bash" -print | sort -t/ -k5)

  # Execute each link.bash file to create the appropriate symlinks
  for file in $update_files; do
    bash "$file"
  done

  debug "🔗 Creating manual symlinks"

  symlink "${DOTFILES}/tools/lazygit/config/config.yml" "${HOMECONFIG}/lazygit"
  symlink "${DOTFILES}/tools/neovim/config/nvim/init.lua" "${HOMECONFIG}/nvim"
  symlink "${DOTFILES}/tools/neovim/config/nvim-ide/init.lua" "${HOMECONFIG}/nvim-ide"
  symlink "${DOTFILES}/tools/neovim/config/nvim-ide/lazy-lock.json" "${HOMECONFIG}/nvim-ide"
  symlink "${DOTFILES}/tools/neovim/config/nvim-kitty-scrollback/init.lua" "${HOMECONFIG}/nvim-kitty-scrollback"
  symlink "${DOTFILES}/tools/node/config/.npmrc" "${HOMECONFIG}/npm"
  symlink "${DOTFILES}/tools/powerlevel10k/config/p10k.zsh" "${HOMECONFIG}/powerlevel10k"
  symlink "${DOTFILES}/tools/sesh/config/sesh.toml" "${HOMECONFIG}/sesh"
  symlink "${DOTFILES}/tools/surfingkeys/config/surfingkeys.js" "${HOMECONFIG}/surfingkeys"
  symlink "${DOTFILES}/tools/tmux/config/battery.sh" "${HOMECONFIG}/tmux"
  symlink "${DOTFILES}/tools/tmux/config/gitmux.conf" "${HOMECONFIG}/tmux"
  symlink "${DOTFILES}/tools/tmux/config/tmux.conf" "${HOMECONFIG}/tmux"
  symlink "${DOTFILES}/tools/tmux/config/tmux.terminfo" "${HOMECONFIG}/tmux"
  symlink "${DOTFILES}/tools/tmux/config/xterm-256color-italic.terminfo" "${HOMECONFIG}/tmux"
  symlink "${DOTFILES}/tools/yazi/config/keymap.toml" "${HOMECONFIG}/yazi"
  symlink "${DOTFILES}/tools/yazi/config/theme.toml" "${HOMECONFIG}/yazi"
  symlink "${DOTFILES}/tools/yazi/config/yazi.toml" "${HOMECONFIG}/yazi"
  symlink "${DOTFILES}/tools/vscode/config/keybindings.json" "${VSCODEUSER}"
  symlink "${DOTFILES}/tools/vscode/config/settings.json" "${VSCODEUSER}"
  symlink "${DOTFILES}/tools/vscode/config/snippets" "${VSCODEUSER}"

  debug "🎉 All symlinks are up to date"
}

main "$@"
