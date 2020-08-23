#!/usr/bin/env bash

OS_NAME=$(uname)
COMMAND_LINE_TOOLS="/Library/Developer/CommandLineTools"
DOTFILES="$HOME/Repos/ooloth/dotfiles"

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
  echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
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

go_home() {
  info "Moving to home directory."

  cd "$HOME"

  success "Ahh. So fresh and so clean.\n"
}

confirm_macos() {
  title "Verifying prerequisites"

  go_home # helps for some reason

  info "Confirming this is a Mac."

  if [ "$OS_NAME" != "Darwin" ]; then
    error "\nOops, it looks like this is a non-UNIX system. This script only works on a Mac.\n\nExiting..."
  fi

  success "This is definitely a Mac. But you knew that already.\n"
}

confirm_command_line_tools() {
  info "Confirming the Xcode CLI tools are installed."

  if [ ! -d "$COMMAND_LINE_TOOLS" ]; then
    error "Apple's command line developer tools must be installed before running this script.  To install them, run 'xcode-select --install' from the terminal and then follow the prompts. Once the command line tools have been installed, you can try running this script again."
  fi

  success "Nice! That's usually the hard part.\n"
}

authenticate() {
  info "Authenticating you are a verified Installer Of Things on this Mac."

  sudo -v
  # Keep-alive: update existing `sudo` time stamp until setup has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  set -e

  success "Yup. That's the password. Have your way with this thing."
}

confirm_plan() {
  info "This installation will set you up by doing this:\n"

  printf "1. Back up any existing dotfiles in your home folder\n"
  printf "2. Find your new dotfiles and symlink them where they need to be\n"
  printf "3. TBD...\n"

  read -r -p "Sound good? (y/N) " -n 1 REPLY

  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    printf "\nExcellent! Here we go..."
  else
    printf "\nNo worries! Maybe next time."
    # printf "\nExiting..."
    # exit 1
  fi
}

get_linkables() {
  find -H "$DOTFILES" -maxdepth 3 -name '*.symlink'
}

backup() {
  DATE_STAMP=$(date +"%F-%H-%M-%S")
  BACKUP_DIR=$HOME/Desktop/dotfiles-backup-$DATE_STAMP

  title "Backing up current dotfiles"

  info "Creating backup directory at $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"

  # Copy root-level dotfiles to backup folders
  for file in $(get_linkables); do
    filename=".$(basename "$file" '.symlink')"
    target="$HOME/$filename"
    if [ -f "$target" ]; then
      info "Backing up $filename"
      cp "$target" "$BACKUP_DIR"
    fi
  done

  # Copy ~/.config folder dotfiles to backup folder
  if [ -d "$HOME/.config" ]; then
    info "Backing up ~/.config"
    cp -R "$HOME/.config" "$BACKUP_DIR"
  fi

  # Back up ~/.ssh folder
  if [ -d "$HOME/.ssh" ]; then
    info "Backing up ~/.ssh"
    cp -R "$HOME/.ssh" "$BACKUP_DIR"
  fi

  # Back up ~/.terminfo folder
  if [ -d "$HOME/.terminfo" ]; then
    info "Backing up ~/.terminfo"
    cp -R "$HOME/.terminfo" "$BACKUP_DIR"
  fi

  success "\nDone backing up your smelly old dotfiles."
}

create_missing_directory() {
  if [ ! -d "$1" ]; then
    echo -e "Creating $1"
    mkdir -p "$1"
  fi
}

clone_dotfiles() {
  create_missing_directory "$HOME/Repos"
  create_missing_directory "$HOME/Repos/ooloth"

  info "Locating the new dotfiles."

  # Only clone dotfiles if they're missing (don't overwrite local changes!)
  if [ ! -d "$DOTFILES" ]; then
    printf "\n"
    git clone "https://github.com/ooloth/dotfiles.git" "$DOTFILES"
    printf "\n"
    success "Cloned new dotfiles to $DOTFILES\n"
  else
    success "Found dotfiles in $DOTFILES\n"
  fi
}

setup_symlinks() {
  info "Creating symlinks in ~/..."

  # Symlink root-level files
  for file in $(get_linkables) ; do
    target="$HOME/.$(basename "$file" '.symlink')"
    ln -sfv "$file" "$target"
  done

  # Create ~/.config if it doesn't exist
  create_missing_directory "$HOME/.config"

  printf "\n"
  info "Creating symlinks in ~/.config..."

  # Symlink .config subfolder files and folders
  config_subfolders=$(find "$DOTFILES/config"/* -maxdepth 0 2>/dev/null)
  for config_subfolder in $config_subfolders; do
    # Create .config subfolder if it's missing
    home_config_subfolder="$HOME/.config/$(basename "$config_subfolder")"
    create_missing_directory "$home_config_subfolder"

    # Get the files inside the subfolder
    config_files=$(find "$config_subfolder"/* -maxdepth 0 2>/dev/null)

    # Symlink the files themselves (not the folders, which apps also modify)
    for config_file in $config_files; do
      target="$HOME/.config/$(basename "$config_subfolder")/$(basename "$config_file")"
      ln -sfv "$config_file" "$target"
    done
  done

  success "\nDone symlinking new dotfiles to the home folder."
}

setup_dotfiles() {
  title "Installing new dotfiles"

  clone_dotfiles && setup_symlinks
}

# setup_git() {
#   title "Setting up Git"

#   defaultName=$(git config user.name)
#   defaultEmail=$(git config user.email)
#   defaultUser=$(git config github.user)

#   read -rp "Name [$defaultName] " name
#   read -rp "Email [$defaultEmail] " email
#   read -rp "Github username [$defaultUser] " github

#   git config -f ~/.config/git/config user.name "${name:-$defaultName}"
#   git config -f ~/.config/git/config user.email "${email:-$defaultEmail}"
#   git config -f ~/.config/git/config github.user "${github:-$defaultGithub}"

#   git config --global credential.helper "osxkeychain"

#   success "Done setting up your git credentials."
# }

setup_ssh() {
  title "Setting up SSH"

  info "Generating SSH public/private key pair."
  # silent output, "id_rsa", overwrite existing, no password
  # https://security.stackexchange.com/a/23385
  # https://stackoverflow.com/a/43235320
   ssh-keygen -q -t rsa -b 2048 -N '' <<< ""$'\n'"y" 2>&1 >/dev/null
  # ssh-keygen -q -t rsa -b 2048

  Info "Adding SSH key pair to ssh-agent and Keychain"

  # https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent
  eval "$(ssh-agent -s)" # confirm the agent is running (if not, this will start it)

  # Use SSH config settings that automatically load keys in ssh-agent and store passphrases in Keychain
  # https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
  cp "$DOTFILES/mac-setup/ssh-config" "$HOME/.ssh/config"

  # Add SSH private key to ssh-agent and store the passphrase in Keychain
  ssh-add -K ~/.ssh/id_rsa

  printf "\nPlease visit https://github.com/settings/ssh/new and log in and enter the following public key:\n"
  printf "https://github.com/settings/ssh/new\n"

  cat "$HOME/.ssh/id_rsa.pub"

  printf "\n"
  read -pr "Press [Enter] when you've finished saving the key on GitHub. (You'll test if it worked
  after this installation has finished)..."

  success "\nDone setting up SSH."
}

function setup_terminfo() {
  title "Configuring terminfo"

  info "adding tmux.terminfo"
  tic -x "$DOTFILES/tmux/tmux.terminfo"

  info "adding xterm-256color-italic.terminfo"
  tic -x "$DOTFILES/tmux/xterm-256color-italic.terminfo"

  success "\nDone configuring terminfo settings."
}

setup_shell() {
  title "Configuring shell"

  [[ -n "$(command -v brew)" ]] && zsh_path="$(brew --prefix)/bin/zsh" || zsh_path="$(which zsh)"
  if ! grep "$zsh_path" /etc/shells; then
    info "Adding $zsh_path to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells
  fi

  if [[ "$SHELL" != "$zsh_path" ]]; then
    chsh -s "$zsh_path"
    info "Default shell changed to $zsh_path"
  fi

  success "Done configuring shell."
}

set_up_oh_my_zsh() {
  title "Setting up Oh My Zsh..."

  if [ -d "${HOME}/.oh-my-zsh" ]; then
    rm -rf "${HOME}/.oh-my-zsh"
  fi

  git clone https://github.com/robbyrussell/oh-my-zsh.git "${HOME}/.oh-my-zsh"

  if [ -d /usr/local/share/zsh ]; then
    info "Setting permissions for /usr/local/share/zsh..."
    sudo chmod -R 755 /usr/local/share/zsh
  fi

  if [ -d /usr/local/share/zsh/site-functions ]; then
    info "Setting permissions for /usr/local/share/zsh/site-functions..."
    sudo chmod -R 755 /usr/local/share/zsh/site-functions
  fi

  success "\nDone setting up Oh My Zsh."
}

setup_homebrew() {
  title "Setting up Homebrew"

  if test ! "$(command -v brew)"; then
    info "Homebrew not installed. Installing."
    # Run as a login shell (non-interactive) so that the script doesn't pause for user input
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash --login
  fi

  # Install brew dependencies from Brewfile
  brew bundle --file="$DOTFILES/mac-setup/Brewfile"

  # Install fzf
  echo -e
  title "Installing fzf"
  "$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
}

set_up_neovim() {
  title "Setting up neovim"

  info "Installing vim-plug..."
  sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

  printf "TODO: set up neovim\n"
}

setup_macos() {
  title "Configuring Mac preferences"

  info "Configuring general settings..."
  printf "\n"

  printf "Expand save dialog by default"
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

  printf "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

  printf "Enable subpixel font rendering on non-Apple LCDs"
  defaults write NSGlobalDomain AppleFontSmoothing -int 2

  printf "\n"
  info "Configuring Finder..."

  echo "Show all filename extensions"
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  echo "Show hidden files by default"
  defaults write com.apple.Finder AppleShowAllFiles -bool false

  echo "Use current directory as default search scope in Finder"
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

  echo "Show Path bar in Finder"
  defaults write com.apple.finder ShowPathbar -bool true

  echo "Show Status bar in Finder"
  defaults write com.apple.finder ShowStatusBar -bool true

  echo "Show the ~/Library folder in Finder"
  chflags nohidden ~/Library

  printf "\n"
  info "Configuring Terminal..."

  echo "only use UTF-8 in Terminal.app"
  defaults write com.apple.terminal StringEncodings -array 4

  printf "\n"
  info "Configuring keyboard..."

  echo "Disable press-and-hold for keys in favor of key repeat"
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  echo "Set a blazingly fast keyboard repeat rate"
  defaults write NSGlobalDomain KeyRepeat -int 1

  echo "Set a shorter Delay until key repeat"
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  printf "\n"
  info "Configuring trackpad..."

  echo "Enable tap to click (Trackpad)"
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  printf "\n"
  info "Configuring Safari..."

  echo "Enable Safari’s debug menu"
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

  # echo "Kill affected applications"

  # for app in Safari Finder Dock Mail SystemUIServer; do killall "$app" >/dev/null 2>&1; done

  success "\nFinished configuring Mac system and app preferences."
}

set_up_apps() {
  title "Configuring Mac preferences"

  printf "TODO: configure apps\n"
}

suggest_restart() {
  printf "\nTo apply your your preferences, your computer needs to restart.\n"
  # read -p -r "\nAre you ready to restart now? (y/N) " -n 1
  # echo
  # if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  #   printf "Excellent choice. Restarting..."
  #   sudo shutdown -r now
  # else
  #   printf "No worries! Just remember to restart manually as soon as you can."
  # fi
}

prerequisites() {
  confirm_macos
  confirm_command_line_tools
  authenticate
}

goodbye() {
  success "\nDone."
}

case "$1" in
  backup)
    prerequisites && backup
    ;;
  link)
    prerequisites && backup && setup_dotfiles
    ;;
  git)
    prerequisites && backup && setup_git
    ;;
  homebrew)
    prerequisites && setup_homebrew && suggest_restart
    ;;
  shell)
    prerequisites && backup && setup_shell
    ;;
  terminfo)
    prerequisites && setup_terminfo
    ;;
  macos)
    prerequisites && setup_macos && suggest_restart
    ;;
  all)
    prerequisites && confirm_plan && backup && setup_dotfiles
    setup_terminfo
    setup_shell
    set_up_oh_my_zsh
    # setup_git
    # setup_ssh
    setup_homebrew
    set_up_neovim
    setup_macos
    set_up_apps
    suggest_restart
    goodbye
    ;;
  *)
  echo -e $"\nUsage: $(basename "$0") {backup|link|git|homebrew|shell|terminfo|macos|all}\n"
  exit 1
  ;;
esac
