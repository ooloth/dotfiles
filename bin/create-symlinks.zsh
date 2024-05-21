#!/usr/bin/env zsh

local DOTFILES="$HOME/Repos/ooloth/dotfiles"
local DOTCONFIG="$DOTFILES/config"
local HOMECONFIG="$HOME/.config"

sl() { ln -sfv "$1" "$2"; }

# TODO: start by removing broken symlinks in each target directory?

#############
# Target: ~ #
#############

sl "$DOTFILES/.hushlogin" "$HOME"
sl "$DOTFILES/.zshenv" "$HOME"

#####################
# Target: ~/.config #
#####################

# Find all files at any level under $DOTCONFIG (see: https://github.com/sharkdp/fd)
fd --type file --hidden . "$DOTCONFIG" | while read file; do
  local relpath="${file#$DOTCONFIG/}"; # Get the relative path that follows "$DOTCONFIG/"
  local dirpath="$(dirname "$relpath")"; # Get the directory path by dropping the file name
  local targetdir="$HOMECONFIG/$dirpath"; # Build the absolute path to the target directory
  mkdir -p "$targetdir"; # Create the target directory (if it doesn't exist)
  sl "$file" "$targetdir"; # Symlink the file to the target directory
done

clone_and_symlink() {
  local repo="$1"
  local relpath="$2"
  local target="$3"

  if [ ! -d "$HOME/Repos/$repo" ]; then
    mkdir -p "$HOME/Repos/$repo"
    git clone "git@github.com:$repo.git" "$HOME/Repos/$repo"
  fi

  sl "$HOME/Repos/$repo/$relpath" "$target"
}

# see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
clone_and_symlink "knubie/vim-kitty-navigator" "get_layout.py" "$HOMECONFIG/kitty"
clone_and_symlink "knubie/vim-kitty-navigator" "pass_keys.py" "$HOMECONFIG/kitty"

# see: https://github.com/yazi-rs/flavors/tree/main/catppuccin-mocha.yazi
clone_and_symlink "yazi-rs/flavors" "catppuccin-mocha.yazi" "$HOMECONFIG/yazi/flavors"

#####################
# Target: ~/Library #
#####################

local LAUNCHAGENTS="$HOME/Library/LaunchAgents"
local VSCODEUSER="$HOME/Library/Application Support/Code/User"

# Set HOSTNAME environment variable for device-specific kitty startup sessions
# see: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.startup_session
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-414186903
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-434876639
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-2119054786
# see: https://derivative.ca/UserGuide/MacOS_Environment_Variables
mkdir -p "$LAUNCHAGENTS"
sl "$DOTFILES/macos/kitty.environment.plist" "$LAUNCHAGENTS"

mkdir -p "$VSCODEUSER"
sl "$DOTFILES/vscode/settings.json" "$VSCODEUSER"
sl "$DOTFILES/vscode/keybindings.json" "$VSCODEUSER"
sl "$DOTFILES/vscode/snippets" "$VSCODEUSER"