#!/usr/bin/env zsh

local DOTFILES=$HOME/Repos/ooloth/dotfiles
local DOTCONFIG=$DOTFILES/config
local HOMECONFIG=$HOME/.config


local sl() { ln -sfv "$1" "$2"; }

#####
# ~ #
#####


sl $DOTFILES/.hushlogin $HOME
sl $DOTFILES/.zshenv $HOME

#############
# ~/.config #
#############


# Find absolute paths to all files at any level under $DOTCONFIG (see: https://github.com/sharkdp/fd)
fd --type file . $DOTCONFIG | while read file; do
  # Get the file path relative to $DOTCONFIG (i.e. isolate the substring that follows $DOTCONFIG/ in the absolute $file path)
  local relpath=${file#$DOTCONFIG/}

  # Get the path to the directory from the relative file path (i.e. remove the file name from $relpath)
  local dirpath=$(dirname "$relpath")

  # Create the target directory at same path relative to $HOMECONFIG if it doesn't exist
  mkdir -p "$HOMECONFIG/$dirpath"

  # Symlink the file to same path relative to $HOMECONFIG
  sl "$file" "$HOMECONFIG/$dirpath"
done

# TODO: clone first if missing?
# see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/get_layout.py $HOMECONFIG/kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/pass_keys.py $HOMECONFIG/kitty

# TODO: clone yazi flavors repo elsewhere and symlink to ~ from there?
# sl $DOTCONFIG/yazi/flavors $HOMECONFIG/yazi

#############
# ~/Library #
#############

local LAUNCHAGENTS="$HOME/Library/LaunchAgents"
local VSCODEUSER="$HOME/Library/Application Support/Code/User"

# set HOSTNAME for kitty startup config swapping
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-414186903
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-434876639
# see: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.startup_session
sl $DOTFILES/macos/kitty.environment.plist $LAUNCHAGENTS

sl $DOTFILES/vscode/settings.json $VSCODEUSER
sl $DOTFILES/vscode/keybindings.json $VSCODEUSER
sl $DOTFILES/vscode/snippets $VSCODEUSER