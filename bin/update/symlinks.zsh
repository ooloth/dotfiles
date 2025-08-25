#!/usr/bin/env zsh

################
# Dependencies #
################

DOTFILES="${HOME}/Repos/ooloth/dotfiles"
HOMECONFIG="${HOME}/.config"

source "$DOTFILES/zsh/config/aliases.zsh"
source "$DOTFILES/zsh/config/utils.zsh"

symlink() {
  # Both arguments should be absolute paths
  local source_file="$1"
  local target_dir="$2"

  local file_name="$(basename "$source_file")"
  local target_path="$target_dir/$file_name"

  # Check if the target file exists and is a symlink pointing to the correct source file
  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_file" ]; then
    return 0
  fi

  mkdir -p "$target_dir"
  printf "🔗 " # inline prefix for the output of the next line
  ln -fsvw "$source_file" "$target_dir"
}

# TODO: start by removing broken symlinks in each target directory?

info "🔗 Updating symlinks"

#############
# Target: ~ #
#############

symlink "${DOTFILES}/claude/config/agents" "${HOME}/.claude"
symlink "${DOTFILES}/claude/config/CLAUDE.md" "${HOME}/.claude"
symlink "${DOTFILES}/claude/config/commands" "${HOME}/.claude"
symlink "${DOTFILES}/claude/config/settings.json" "${HOME}/.claude"
symlink "${DOTFILES}/zsh/config/.hushlogin" "${HOME}"
symlink "${DOTFILES}/zsh/config/.zshenv" "${HOME}"
symlink "${DOTFILES}/zsh/config/.zshrc" "${HOME}"

#####################
# Target: ~/.config #
#####################

# TODO: recursively symlink any file in [tool}/config (but not /config itself)?
# Or just source {tool}/symlink.bash files that each define their own commands?
symlink "$DOTFILES/gh/config/config.yml" "$HOMECONFIG/gh"
symlink "$DOTFILES/ghostty/config/config" "$HOMECONFIG/ghostty"
symlink "$DOTFILES/git/config/config" "$HOMECONFIG/git"
symlink "$DOTFILES/git/config/config.work" "$HOMECONFIG/git"
symlink "$DOTFILES/k9s/config/aliases.yaml" "$HOMECONFIG/k9s"
symlink "$DOTFILES/k9s/config/config.yaml" "$HOMECONFIG/k9s"
symlink "$DOTFILES/k9s/config/hotkeys.yaml" "$HOMECONFIG/k9s"
symlink "$DOTFILES/k9s/config/skins" "$HOMECONFIG/k9s"
symlink "$DOTFILES/kitty/config/colorscheme" "$HOMECONFIG/kitty"
symlink "$DOTFILES/kitty/config/kitty.conf" "$HOMECONFIG/kitty"
symlink "$DOTFILES/lazydocker/config/config.yml" "$HOMECONFIG/lazydocker"
symlink "$DOTFILES/lazygit/config/config.yml" "$HOMECONFIG/lazygit"
symlink "$DOTFILES/neovim/config/nvim/init.lua" "$HOMECONFIG/nvim"
symlink "$DOTFILES/neovim/config/nvim-ide/init.lua" "$HOMECONFIG/nvim-ide"
symlink "$DOTFILES/neovim/config/nvim-ide/lazy-lock.json" "$HOMECONFIG/nvim-ide"
symlink "$DOTFILES/neovim/config/nvim-kitty-scrollback/init.lua" "$HOMECONFIG/nvim-kitty-scrollback"
symlink "$DOTFILES/node/config/.npmrc" "$HOMECONFIG/npm"
symlink "$DOTFILES/powerlevel10k/config/p10k.zsh" "$HOMECONFIG/powerlevel10k"
symlink "$DOTFILES/sesh/config/sesh.toml" "$HOMECONFIG/sesh"
symlink "$DOTFILES/surfingkeys/config/surfingkeys.js" "$HOMECONFIG/surfingkeys"
symlink "$DOTFILES/tmux/config/battery.sh" "$HOMECONFIG/tmux"
symlink "$DOTFILES/tmux/config/gitmux.conf" "$HOMECONFIG/tmux"
symlink "$DOTFILES/tmux/config/tmux.conf" "$HOMECONFIG/tmux"
symlink "$DOTFILES/tmux/config/tmux.terminfo" "$HOMECONFIG/tmux"
symlink "$DOTFILES/tmux/config/xterm-256color-italic.terminfo" "$HOMECONFIG/tmux"
symlink "$DOTFILES/visidata/config/config.py" "$HOMECONFIG/visidata"
symlink "$DOTFILES/yazi/config/keymap.toml" "$HOMECONFIG/yazi"
symlink "$DOTFILES/yazi/config/theme.toml" "$HOMECONFIG/yazi"
symlink "$DOTFILES/yazi/config/yazi.toml" "$HOMECONFIG/yazi"

# # Find all files at any level under $DOTCONFIG (see: https://github.com/sharkdp/fd)
# fd --type file --hidden . "$DOTCONFIG" | while read file; do
#   local relpath="${file#$DOTCONFIG/}"    # Get the relative path in that follows "$DOTCONFIG/" in $file (which is an absolute path)
#   local dirpath="$(dirname "$relpath")"  # Get the directory path by dropping the file name
#   local targetdir="$HOMECONFIG/$dirpath" # Build the absolute path to the target directory
#
#   symlink "$file" "$targetdir" # Symlink the file to the target directory
# done

#####################
# Target: ~/Library #
#####################

VSCODEUSER="$HOME/Library/Application Support/Code/User"

symlink "$DOTFILES/vscode/config/keybindings.json" "$VSCODEUSER"
symlink "$DOTFILES/vscode/config/settings.json" "$VSCODEUSER"
symlink "$DOTFILES/vscode/config/snippets" "$VSCODEUSER"

printf "🎉 All symlinks are up to date\n"
