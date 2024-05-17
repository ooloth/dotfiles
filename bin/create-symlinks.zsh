#!/usr/bin/env zsh

# TODO: is the $DOTFILES environment variable available in here?
# local dotfiles=$HOME/Repos/ooloth/dotfiles

# TODO: is the "sl" alias already available in here?
sl() { ln -sfv $1 $2; } # easier symlinking

#########
# KITTY #
#########

# see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/get_layout.py $HOME/.config/kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/pass_keys.py $HOME/.config/kitty