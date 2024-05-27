#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

###########
# CONFIRM #
###########

printf "Welcome to your new Mac!"

printf "This installation will perform the following steps:\n"

printf "1. Back up any existing dotfiles in your home folder\n"
printf "2. Find your new dotfiles and symlink them where they need to be\n"
printf "3. TBD...\n\n"

vared -p "Sound good? (y/N) " -c key

if [[ ! "$key" == 'y' ]]; then
  printf "\nNo worries! Maybe next time."
  printf "\nExiting..."
  exit 1
else
  printf "\nExcellent! Here we go...\n"
fi

#################
# PREREQUISITES #
#################

printf "Verifying prerequisites"

printf "Confirming this is a Mac."

if [ "$(uname)" != "Darwin" ]; then
  printf "\nOops, it looks like this is a non-UNIX system. This script only works on a Mac.\n\nExiting..."
  exit 1
fi

printf "\nThis is definitely a Mac. But you knew that already.\n"

printf "Confirming the Xcode CLI tools are installed."

if [ ! -d "$HOME/Library/Developer/CommanLineTools" ]; then
  # TODO: is there a way to install these automatically and continue?
  printf "Apple's command line developer tools must be installed before running this script. To install them, run 'xcode-select --install' from the terminal and then follow the prompts. Once the command line tools have been installed, you can try running this script again."
  exit 1
fi

printf "\nNice! That's usually the hard part.\n"

################
# AUTHENTICATE #
################

printf "Confirming you are authorized to install things on this Mac.\n"

sudo -v
# Keep-alive: update existing `sudo` time stamp until setup has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
set -e

printf "Yup. That's the password. Have your way with this thing."

##################
# CLONE DOTFILES #
##################

# NOTE: can't source local files before cloning dotfiles
# TODO: change dotfiles remote to ssh later
# Check if the repository is already cloned
if [ ! -d "$DOTFILES" ]; then
  echo "Cloning repository into $DOTFILES..."
  git clone https://github.com/ooloth/dotfiles.git "$DOTFILES"
else
  echo "✅ Dotfiles already cloned into $DOTFILES."
fi

###########
# INSTALL #
###########

cd "$DOTFILES/bin/install"

source ssh.zsh
source github.zsh
# TODO: move later?
source "$DOTFILES/bin/update/symlinks.zsh"
source homebrew.zsh
source "$DOTFILES/bin/update/homebrew.zsh"
source zsh.zsh
source rust.zsh
source node.zsh
source "$DOTFILES/bin/update/npm.zsh"
source tmux.zsh
source neovim.zsh
source yazi.zsh
source settings.zsh
# TODO: configure individual app preferences

###################
# SUGGEST RESTART #
###################

source "$DOTFILES/config/zsh/banners.zsh"
info "🎉 Setup complete!"

printf "\nCongratulations! Your Mac is nearly set up.\n"

printf "\nTo apply your your preferences, your computer needs to restart.\n\n"

vared -p "Are you ready to restart now (recommended)? (y/N) " -c restart_choice

if [[ "$restart_choice" = 'y' ]]; then
  printf "\nExcellent choice. When you're back, remember to complete the manual follow-up steps in the README.\n"
  printf "\nRestarting..."
  sudo shutdown -r now
else
  printf "\nNo worries! Your terminal session will now refresh...\n"
  exec -l $SHELL
  printf "\nDone. Enjoy your new Mac!\n"
fi