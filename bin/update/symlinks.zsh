#!/usr/bin/env zsh

################
# Dependencies #
################

DOTFILES="$HOME/Repos/ooloth/dotfiles"
DOTCONFIG="$DOTFILES/config"
HOMECONFIG="$HOME/.config"

source "$DOTCONFIG/zsh/utils.zsh"

maybe_symlink() {
  # Both arguments should be absolute paths
  local source_file="$1"
  local target_dir="$2"

  local file_name="$(basename "$source_file")"
  local target_path="$target_dir/$file_name"

  # Check if the target file exists and is a symlink pointing to the correct source file
  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_file" ]; then
    echo "Skipping $file_name (already exists as a symlink at $target_path)"
    return 0
  fi

  mkdir -p "$target_dir";
  ln -sfv "$source_file" "$target_dir";
}

# TODO: start by removing broken symlinks in each target directory?

#############
# Target: ~ #
#############

info "🔗 Creating symlinks in ~/"

maybe_symlink "$DOTFILES/.hushlogin" "$HOME"
maybe_symlink "$DOTFILES/.zshenv" "$HOME"

#####################
# Target: ~/.config #
#####################

info "🔗 Creating symlinks in ~/.config"

# Find all files at any level under $DOTCONFIG (see: https://github.com/sharkdp/fd)
fd --type file --hidden . "$DOTCONFIG" | while read file; do
  local relpath="${file#$DOTCONFIG/}"; # Get the relative path in that follows "$DOTCONFIG/" in $file (which is an absolute path)
  local dirpath="$(dirname "$relpath")"; # Get the directory path by dropping the file name
  local targetdir="$HOMECONFIG/$dirpath"; # Build the absolute path to the target directory
  # local targetpath="$targetdir/$(basename "$relpath")" # Build the absolute path to the target file

  # # Check if the target path exists and is a symlink pointing to the correct file
  # if [ -L "$targetpath" ] && [ "$(readlink "$targetpath")" = "$file" ]; then
  #   echo "Skipping $(basename $relpath) (already exists as a symlink at $targetpath)"
  #   continue
  # fi

  # mkdir -p "$targetdir"; # Create the target directory (if it doesn't exist)
  maybe_symlink "$file" "$targetdir"; # Symlink the file to the target directory
done

vim_kitty_navigator="$HOME/Repos/knubie/vim-kitty-navigator"
yazi_flavors="$HOME/Repos/yazi-rs/flavors"

if [ ! -d "$vim_kitty_navigator" ]; then
  source "$DOTFILES/bin/install/neovim.zsh"
else
  # see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
  maybe_symlink "$vim_kitty_navigator/get_layout.py" "$HOMECONFIG/kitty"
  maybe_symlink "$vim_kitty_navigator/pass_keys.py" "$HOMECONFIG/kitty"
fi

if [ ! -d "$yazi_flavors" ]; then
  source "$DOTFILES/bin/install/yazi.zsh"
else
  # see: https://github.com/yazi-rs/flavors/tree/main/catppuccin-mocha.yazi
  maybe_symlink "$yazi_flavors/catppuccin-mocha.yazi" "$HOMECONFIG/yazi/flavors"
fi

#####################
# Target: ~/Library #
#####################

info "🔗 Creating symlinks in ~/Library"

LAUNCHAGENTS="$HOME/Library/LaunchAgents"
VSCODEUSER="$HOME/Library/Application Support/Code/User"

# Set HOSTNAME environment variable for device-specific kitty startup sessions
# see: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.startup_session
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-414186903
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-434876639
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-2119054786
# see: https://derivative.ca/UserGuide/MacOS_Environment_Variables
mkdir -p "$LAUNCHAGENTS"
maybe_symlink "$DOTFILES/library/kitty/kitty.environment.plist" "$LAUNCHAGENTS"

mkdir -p "$VSCODEUSER"
maybe_symlink "$DOTFILES/library/vscode/settings.json" "$VSCODEUSER"
maybe_symlink "$DOTFILES/library/vscode/keybindings.json" "$VSCODEUSER"
maybe_symlink "$DOTFILES/library/vscode/snippets" "$VSCODEUSER"
