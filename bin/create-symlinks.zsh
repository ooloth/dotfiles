#!/usr/bin/env zsh

local dotfiles=$HOME/Repos/ooloth/dotfiles

# -s: symbolic - create a symbolic link (not a hard link)
# -f: force - if the target file already exists, then unlink it so that the link may occur
# -v: verbose - print file names as they are processed
sl() { ln -sfv $1 $2; } # easier symlinking

#########
# KITTY #
#########

# see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/get_layout.py $HOME/.config/kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/pass_keys.py $HOME/.config/kitty