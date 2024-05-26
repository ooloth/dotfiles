#!/usr/bin/env zsh

DOTFILES="$HOME/Repos/ooloth/dotfiles"

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
  echo -e "\n\n${COLOR_PURPLE}$1${COLOR_NONE}"
  echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"
}

error() {
  echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
  exit 1
}

warning() {
  echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
  echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
  echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

confirm_consent() {
  title "Welcome to your new Mac!"

  info "This installation will perform the following steps:\n"

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
}

confirm_macos() {
  title "Verifying prerequisites"

  info "Confirming this is a Mac."

  local os=$(uname)
  if [ "$os" != "Darwin" ]; then
    error "\nOops, it looks like this is a non-UNIX system. This script only works on a Mac.\n\nExiting..."
  fi

  success "\nThis is definitely a Mac. But you knew that already.\n"
}

confirm_command_line_tools() {
  info "Confirming the Xcode CLI tools are installed."

  if [ ! -d "$HOME/Library/Developer/CommanLineTools" ]; then
    # TODO: is there a way to install these automatically and continue?
    error "Apple's command line developer tools must be installed before running this script. To install them, run 'xcode-select --install' from the terminal and then follow the prompts. Once the command line tools have been installed, you can try running this script again."
  fi

  success "\nNice! That's usually the hard part.\n"
}

authenticate() {
  info "Confirming you are authorized to install things on this Mac.\n"

  sudo -v
  # Keep-alive: update existing `sudo` time stamp until setup has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  set -e

  success "Yup. That's the password. Have your way with this thing."
}

run_checks() {
  confirm_macos
  confirm_command_line_tools
  authenticate
}

set_up_ssh_keys() {
  source "$DOTFILES/bin/install/ssh.zsh"
}

set_up_ssh_to_github() {
  source "$DOTFILES/bin/install/github.zsh"
}

clone_dotfiles() {
  title "Locating dotfiles"

  # Only clone dotfiles if they're missing (don't overwrite local changes!)
  if [ ! -d "$DOTFILES" ]; then
    info "Cloning a fresh copy of dotfiles"

    mkdir -p "$HOME/Repos/ooloth"

    printf "\n"
    info "If you're asked if you want to continue connecting, type 'yes'...\n"

    git clone "git@github.com:ooloth/dotfiles.git" "$DOTFILES"

    success "\nCloned new dotfiles to $DOTFILES"
  else
    success "Found dotfiles in $DOTFILES."
  fi
}

backup_config() {
  DATE_STAMP=$(date +"%F-%H-%M-%S")
  BACKUP_DIR=$HOME/Desktop/dotfiles-backup-$DATE_STAMP

  title "Backing up current dotfiles"

  info "Creating backup directory at $BACKUP_DIR"

  mkdir -p "$BACKUP_DIR"

  # Copy ~/.zshenv to backup folder
  if [ -d "$HOME/.config" ]; then
    info "Backing up ~/.config"
    cp -R "$HOME/.config" "$BACKUP_DIR"
  fi

  # Copy ~/.config folder to backup folder
  if [ -d "$HOME/.config" ]; then
    info "Backing up ~/.config"
    cp -R "$HOME/.config" "$BACKUP_DIR"
  fi

  # Back up ~/.ssh folder
  if [ -d "$HOME/.ssh" ]; then
    info "Backing up ~/.ssh"
    cp -R "$HOME/.ssh" "$BACKUP_DIR"
  fi

  success "\nDone backing up your old dotfiles."
}

create_symlinks() {
  source "$DOTFILES/bin/update/symlinks.zsh"
}

set_up_homebrew() {
  source "$DOTFILES/bin/install/homebrew.zsh"
  source "$DOTFILES/bin/update/homebrew.zsh"
}

set_up_zsh() {
  source "$DOTFILES/bin/install/zsh.zsh"
}

set_up_rust() {
  source "$DOTFILES/bin/install/rust.zsh"
}

set_up_node() {
  source "$DOTFILES/bin/install/node.zsh"
  source "$DOTFILES/bin/update/npm.zsh"
}

set_up_tmux() {
  source "$DOTFILES/bin/install/tpm.zsh"
  source "$DOTFILES/bin/update/tpm.zsh"
}

set_up_neovim() {
  source "$DOTFILES/bin/install/neovim.zsh"
}

set_up_yazi() {
  source "$DOTFILES/bin/install/yazi.zsh"
}

configure_macos() {
  title "Configuring Mac preferences"

  info "Configuring general settings...\n"

  printf "Expand save dialog by default\n"
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

  printf "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)\n"
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

  printf "Enable subpixel font rendering on non-Apple LCDs\n"
  defaults write NSGlobalDomain AppleFontSmoothing -int 2

  printf "\n"
  info "Configuring Finder...\n"

  printf "Show all filename extensions\n"
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  printf "Show hidden files by default\n"
  defaults write com.apple.Finder AppleShowAllFiles -bool false

  printf "Use current directory as default search scope in Finder\n"
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

  printf "Show Path bar in Finder\n"
  defaults write com.apple.finder ShowPathbar -bool true

  printf "Show Status bar in Finder\n"
  defaults write com.apple.finder ShowStatusBar -bool true

  printf "Show the ~/Library folder in Finder\n"
  chflags nohidden ~/Library

  printf "\n"
  info "Configuring Safari...\n"

  printf "Enable Safari’s debug menu\n"
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

  # echo "Kill affected applications"

  # for app in Safari Finder Dock Mail SystemUIServer; do killall "$app" >/dev/null 2>&1; done

  success "\nFinished configuring Mac system preferences."
}

configure_apps() {
  title "Configuring app preferences"

  warning "TODO: configure apps"

  success "\nFinished configuring app preferences."
}

suggest_restart() {
  title "Congratulations! Your Mac is nearly set up"

  info "To apply your your preferences, your computer needs to restart.\n\n"

  vared -p "Are you ready to restart now (recommended)? (y/N) " -c restart_choice

  if [[ "$restart_choice" = 'y' ]]; then
    printf "\nExcellent choice. When you're back, remember to complete the manual follow-up steps in the README.\n"
    printf "\nRestarting..."
    sudo shutdown -r now
  else
    printf "\nNo worries! Your terminal session will now refresh...\n"
    exec -l $SHELL

    success "\nDone. Enjoy your new Mac!\n"
  fi
}

confirm_consent \
  && run_checks \
  && set_up_ssh_keys \
  && set_up_ssh_to_github \
  && clone_dotfiles \
  && backup_config \
  && create_symlinks \
  && set_up_homebrew \
  && set_up_zsh \
  && set_up_rust \
  && set_up_node \
  && set_up_tmux \
  && set_up_neovim \
  && set_up_yazi \
  && configure_macos \
  && configure_apps \
  && suggest_restart
