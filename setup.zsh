#!/usr/bin/env zsh

export IS_AIR="false"
export IS_MINI="false"
export IS_WORK="true"

export DOTFILES="$HOME/Repos/ooloth/dotfiles"

handle_error() {
  local exit_code="$1"
  local line_number="$2"
  printf "\nError on line $line_number: Command exited with status $exit_code.\n"
  exit "$exit_code"
}

# Trap ERR signals and call handle_error()
trap 'handle_error $? $LINENO' ERR

###########
# CONFIRM #
###########

printf "Welcome to your new Mac!"
printf "This installation will perform the following steps:\n"
printf "1. Confirm this is a Mac\n"
printf "2. Ask you to enter your password\n"
printf "3. Confirm the Command Line Developer Tools are installed\n"
printf "4. Clone ooloth/dotfiles\n"
printf "5. Create your SSH keys\n"
printf "6. Confirm you can SSH to GitHub\n"
printf "7. Install Homebrew\n"
printf "8. Install the packages, casks, App Store apps and VS Code extensions listed in your Brewfile\n"
printf "9. Configure your Mac to use the Homebrew version of Zsh\n"
printf "10. Install rust (if not work computer)\n"
printf "11. Install uv\n"
printf "12. Install the latest version of Node via fnm and set it as the default\n"
printf "13. Install global npm dependencies\n"
printf "14. Install tmux dependencies\n"
printf "15. Install neovim dependencies\n"
printf "16. Install yazi flavors (if not work computer)\n"
printf "17. Symlink your dotfiles to your home and library directories\n"
printf "18. Update macOS system settings\n"

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

# This is a Mac
printf "Confirming this is a Mac."

if [ "$(uname)" != "Darwin" ]; then
  printf "\nOops, it looks like this is a non-UNIX system. This script only works on a Mac.\n\nExiting..."
  exit 1
fi

printf "\nThis is a Mac. But you knew that already.\n"

# You know this Mac's password
printf "Confirming you are authorized to install things on this Mac.\n"

sudo -v
# Keep-alive: update existing `sudo` time stamp until setup has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

printf "\nYup. That's the password.\n"

# The Command Line Tools are installed
printf "\nConfirming the Command Line Tools are installed.\n"

if [ ! -d "$HOME/Library/Developer/CommandLineTools" ]; then
  printf "Apple's command line developer tools must be installed before running this script. Installing now.\n"
  xcode-select --install

  if [ ! -d "$HOME/Library/Developer/CommandLineTools" ]; then
    printf "\nOops, it looks like the Xcode CLI tools are still not installed. Please install and try again.\n"
    exit 1
  else
    printf "\nXcode CLI tools are now installed.\n"
  fi
else
  printf "\nXcode CLI tools are already installed.\n"
fi

##################
# CLONE DOTFILES #
##################

source dotfiles.zsh

###########
# INSTALL #
###########

cd "$DOTFILES/bin/install"
source ssh.zsh
source github.zsh
source homebrew.zsh
source "$DOTFILES/bin/update/homebrew.zsh"
source zsh.zsh
source rust.zsh
source uv.zsh
source node.zsh
source "$DOTFILES/bin/update/npm.zsh"
source tmux.zsh
source neovim.zsh
source yazi.zsh
source content.zsh
source "$DOTFILES/bin/update/symlinks.zsh"
source settings.zsh
# TODO: automate my remaining manual setup steps (e.g. app preferences, etc.)

###################
# SUGGEST RESTART #
###################

source "$DOTFILES/config/zsh/utils.zsh"
info "🎉 Setup complete!"

printf "\nCongratulations! Your Mac is nearly set up.\n\n"
printf "To apply your your preferences, your computer needs to restart.\n\n"

vared -p "Are you ready to restart now (recommended)? (y/N) " -c restart_choice

if [[ "$restart_choice" = 'y' ]]; then
  printf "\nExcellent choice.\n"
  printf "\nRestarting..."
  sudo shutdown -r now
else
  printf "\nNo worries! Your terminal session will now refresh...\n"
  exec -l $SHELL
  printf "\nDone. Enjoy your new Mac!\n"
fi
