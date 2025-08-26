#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

HOMECONFIG="${HOME}/.config"
VSCODEUSER="$HOME/Library/Application Support/Code/User"

info "🔗 Updating symlinks"

##########
# Remove #
##########

for dir in "${HOME}" "${HOMECONFIG}" "${VSCODEUSER}"; do
  remove_broken_symlinks "$dir"
done

##########
# Create #
##########

# TODO: source all tools/{tool}/symlinks/link.bash files

source "${DOTFILES}/tools/zsh/symlinks/link.bash"
source "${DOTFILES}/tools/claude/symlinks/link.bash"

symlink "${DOTFILES}/tools/gh/config/config.yml" "${HOMECONFIG}/gh"
symlink "${DOTFILES}/tools/ghostty/config/config" "${HOMECONFIG}/ghostty"
symlink "${DOTFILES}/tools/git/config/config" "${HOMECONFIG}/git"
symlink "${DOTFILES}/tools/git/config/config.work" "${HOMECONFIG}/git"
symlink "${DOTFILES}/tools/k9s/config/aliases.yaml" "${HOMECONFIG}/k9s"
symlink "${DOTFILES}/tools/k9s/config/config.yaml" "${HOMECONFIG}/k9s"
symlink "${DOTFILES}/tools/k9s/config/hotkeys.yaml" "${HOMECONFIG}/k9s"
symlink "${DOTFILES}/tools/k9s/config/skins" "${HOMECONFIG}/k9s"
symlink "${DOTFILES}/tools/kitty/config/colorscheme" "${HOMECONFIG}/kitty"
symlink "${DOTFILES}/tools/kitty/config/kitty.conf" "${HOMECONFIG}/kitty"
symlink "${DOTFILES}/tools/lazydocker/config/config.yml" "${HOMECONFIG}/lazydocker"
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
symlink "${DOTFILES}/tools/visidata/config/config.py" "${HOMECONFIG}/visidata"
symlink "${DOTFILES}/tools/yazi/config/keymap.toml" "${HOMECONFIG}/yazi"
symlink "${DOTFILES}/tools/yazi/config/theme.toml" "${HOMECONFIG}/yazi"
symlink "${DOTFILES}/tools/yazi/config/yazi.toml" "${HOMECONFIG}/yazi"

symlink "${DOTFILES}/tools/vscode/config/keybindings.json" "${VSCODEUSER}"
symlink "${DOTFILES}/tools/vscode/config/settings.json" "${VSCODEUSER}"
symlink "${DOTFILES}/tools/vscode/config/snippets" "${VSCODEUSER}"

debug "🎉 All symlinks are up to date"
