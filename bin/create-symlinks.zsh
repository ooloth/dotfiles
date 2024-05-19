#!/usr/bin/env zsh

# In case it helps to redefine these for use during initial laptop setup
local DOTFILES=$HOME/Repos/ooloth/dotfiles
local sl() { ln -sfv "$1" "$2"; }

#########
# KITTY #
#########

sl $DOTFILES/config/kitty/colorscheme $HOME/.config/kitty
sl $DOTFILES/config/kitty/kitty.conf $HOME/.config/kitty
sl $DOTFILES/config/kitty/startup $HOME/.config/kitty

# see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/get_layout.py $HOME/.config/kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/pass_keys.py $HOME/.config/kitty

# set HOSTNAME for kitty startup config swapping
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-414186903
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-434876639
# see: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.startup_session
sl $DOTFILES/macos/kitty.environment.plist $HOME/Library/LaunchAgents

##########
# VSCODE #
##########

sl $DOTFILES/vscode/settings.json "$HOME/Library/Application Support/Code/User"
sl $DOTFILES/vscode/keybindings.json "$HOME/Library/Application Support/Code/User"
sl $DOTFILES/vscode/snippets "$HOME/Library/Application Support/Code/User"

#######
# ZSH #
#######

sl $DOTFILES/.zshenv $HOME
sl $DOTFILES/config/zsh/.zprofile $HOME/.config/zsh
sl $DOTFILES/config/zsh/.zshrc $HOME/.config/zsh
sl $DOTFILES/config/zsh/mu $HOME/.config/zsh