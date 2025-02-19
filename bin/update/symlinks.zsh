#!/usr/bin/env zsh

################
# Dependencies #
################

DOTFILES="$HOME/Repos/ooloth/dotfiles"
DOTCONFIG="$DOTFILES/config"
HOMECONFIG="$HOME/.config"

source "$DOTCONFIG/zsh/aliases.zsh"
source "$DOTCONFIG/zsh/utils.zsh"

maybe_symlink() {
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
  ln -sfv "$source_file" "$target_dir"
}

# TODO: start by removing broken symlinks in each target directory?

info "🔗 Updating symlinks"

#############
# Target: ~ #
#############

maybe_symlink "$DOTFILES/.hushlogin" "$HOME"
maybe_symlink "$DOTFILES/.zshenv" "$HOME"

#####################
# Target: ~/.config #
#####################

# Find all files at any level under $DOTCONFIG (see: https://github.com/sharkdp/fd)
fd --type file --hidden . "$DOTCONFIG" | while read file; do
  local relpath="${file#$DOTCONFIG/}"    # Get the relative path in that follows "$DOTCONFIG/" in $file (which is an absolute path)
  local dirpath="$(dirname "$relpath")"  # Get the directory path by dropping the file name
  local targetdir="$HOMECONFIG/$dirpath" # Build the absolute path to the target directory

  maybe_symlink "$file" "$targetdir" # Symlink the file to the target directory
done

# Lazy-lock.json files (from home -> dotfiles instead of dotfiles -> home)
maybe_symlink "$HOMECONFIG/nvim-ide/lazy-lock.json" "$DOTFILES/config/nvim-ide"

yazi_flavors="$HOME/Repos/yazi-rs/flavors"

if [ ! -d "$yazi_flavors" ]; then
  source "$DOTFILES/bin/install/yazi.zsh"
else
  # see: https://github.com/yazi-rs/flavors/tree/main/catppuccin-mocha.yazi
  maybe_symlink "$yazi_flavors/catppuccin-mocha.yazi" "$HOMECONFIG/yazi/flavors"
fi

#####################
# Target: ~/Library #
#####################

VSCODEUSER="$HOME/Library/Application Support/Code/User"

maybe_symlink "$DOTFILES/library/vscode/settings.json" "$VSCODEUSER"
maybe_symlink "$DOTFILES/library/vscode/keybindings.json" "$VSCODEUSER"
maybe_symlink "$DOTFILES/library/vscode/snippets" "$VSCODEUSER"

printf "\n🚀 All dotfiles symlinks are up to date.\n"
