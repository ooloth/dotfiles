#!/usr/bin/env zsh

export DOTFILES="$HOME/Repos/ooloth/dotfiles"

# Initialize dynamic machine detection
source "$DOTFILES/bin/lib/machine-detection.zsh"
init_machine_detection

# Initialize dry-run mode utilities
source "$DOTFILES/bin/lib/dry-run-utils.zsh"
parse_dry_run_flags "$@"

# Initialize error handling utilities
source "$DOTFILES/bin/lib/error-handling.zsh"

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

printf "\nWelcome to your new Mac! This installation will perform the following steps:\n\n"
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
printf "18. Update macOS system settings\n\n"

vared -p "Sound good? (y/N) " -c key

if [[ ! "$key" == 'y' ]]; then
  printf "\nNo worries! Maybe next time."
  printf "\nExiting..."
  exit 1
else
  printf "\nExcellent! Here we go...\n\n"
fi

#################
# PREREQUISITES #
#################

printf "Verifying prerequisites...\n\n"

# This is a Mac
printf "Confirming this is a Mac...\n"

if [ "$(uname)" != "Darwin" ]; then
  printf "Oops, it looks like this is a non-UNIX system. This script only works on a Mac.\n\nExiting..."
  exit 1
fi

printf "This is a Mac. But you knew that already.\n\n"

# Run comprehensive prerequisite validation
printf "Running comprehensive prerequisite validation...\n\n"

source "$DOTFILES/bin/lib/prerequisite-validation.zsh"
if ! run_prerequisite_validation; then
  printf "\n❌ Prerequisite validation failed. Please address the issues above and try again.\n"
  exit 1
fi

printf "\n✅ All prerequisites validated successfully.\n\n"

# You know this Mac's password
printf "Confirming you are authorized to install things on this Mac...\n\n"

sudo -v
# Keep-alive: update existing `sudo` time stamp until setup has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

printf "Yup. That's the password.\n\n"

# The Command Line Tools are installed
# printf "Confirming the Command Line Tools are installed...\n\n"
#
# if [ ! -d "$HOME/Library/Developer/CommandLineTools" ]; then
#   printf "Apple's command line developer tools must be installed before running this script. Installing now.\n"
#   xcode-select --install
#
#   if [ ! -d "$HOME/Library/Developer/CommandLineTools" ]; then
#     printf "\nOops, it looks like the Xcode CLI tools are still not installed. Please install and try again.\n"
#     exit 1
#   else
#     printf "\nXcode CLI tools are now installed.\n"
#   fi
# else
#   printf "\nXcode CLI tools are already installed.\n"
# fi

##################
# CLONE DOTFILES #
##################

if [ -d "$DOTFILES" ]; then
  printf "📂 Dotfiles are already installed. Pulling latest changes.\n"
  cd "$DOTFILES"
  git pull
else
  # Otherwise, clone via https (will be converted to ssh by install/github.zsh)
  printf "📂 Installing dotfiles"
  mkdir -p "$DOTFILES"
  git clone "https://github.com/ooloth/dotfiles.git" "$DOTFILES"
fi

# # Add all the helpers the install scripts below will reference
# source "$DOTFILES/config/zsh/aliases.zsh"
# source "$DOTFILES/config/zsh/utils.zsh"

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
