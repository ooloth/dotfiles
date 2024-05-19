#!/usr/bin/env zsh

# In case it helps to redefine these for use during initial laptop setup
local DOTFILES=$HOME/Repos/ooloth/dotfiles
local sl() { ln -sfv "$1" "$2"; }

#########
# KITTY #
#########

# see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/get_layout.py $HOME/.config/kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/pass_keys.py $HOME/.config/kitty

# set HOSTNAME for kitty startup config swapping
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-414186903
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-434876639
# see: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.startup_session
sl $DOTFILES/macos/kitty.environment.plist $HOME/Library/LaunchAgents

#######
# ZSH #
#######

sl $DOTFILES/config/zsh/.zprofile $HOME/.config/zsh
sl $DOTFILES/config/zsh/.zshrc $HOME/.config/zsh
sl $DOTFILES/config/zsh/mu $HOME/.config/zsh