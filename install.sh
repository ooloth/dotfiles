#!/usr/bin/env zsh
# !/bin/zsh
# !/usr/local/bin/zsh

OS_NAME=$(uname)
COMMAND_LINE_TOOLS="/Library/Developer/CommandLineTools"
# DOTFILES="$HOME/Repos/ooloth/dotfiles"
OH_MY_ZSH="$HOME/.oh-my-zsh"
TEMP_DIR="$HOME/Desktop/temp"
DOTFILES="$TEMP_DIR/dotfiles"

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

# shellcheck disable=SC2154
trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

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

  success "Yup. That's the password. Have your way with this thing.\n"
}

# confirm_names() {
#   printf "\\nEnter a name for your Mac. (Leave blank for default: %s)\\n" "$DEFAULT_COMPUTER_NAME"
#   read -r -p "> " COMPUTER_NAME
  # vared -p "\nAre you ready to restart now? (y/N) " -c key
#   export COMPUTER_NAME=${COMPUTER_NAME:-$DEFAULT_COMPUTER_NAME}

#   printf "\\nEnter a host name for your Mac. (Leave blank for default: %s)\\n" "$DEFAULT_HOST_NAME"
#   read -r -p "> " HOST_NAME
  # vared -p "\nAre you ready to restart now? (y/N) " -c key
#   export HOST_NAME=${HOST_NAME:-$DEFAULT_HOST_NAME}
# }

confirm_plan() {
  info "This installation will set you up by doing this:\n"

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

create_missing_directory() {
  if [ ! -d "$1" ]; then
    echo -e "Creating $1"
    mkdir -p "$1"
  fi
}

clone_temp_dotfiles() {
  create_missing_directory "$TEMP_DIR"

  info "Cloning installation dotfiles."

  git clone "https://github.com/ooloth/dotfiles.git" "$DOTFILES"

  success "\nCloned installation dotfiles to $DOTFILES\n"
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

setup_ssh() {
  title "Setting up SSH"

  info "Generating SSH public/private key pair...\n"
  # silent output, "id_rsa", overwrite existing, no password
  # https://security.stackexchange.com/a/23385
  # https://stackoverflow.com/a/43235320
  ssh-keygen -q -t rsa -b 2048 -N '' <<< ""$'\n'"y" 2>&1 >/dev/null
  # ssh-keygen -q -t rsa -b 2048

  # info "Adding SSH key pair to ssh-agent and Keychain"

  # # https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent
  # eval "$(ssh-agent -s)" # confirm the agent is running (if not, this will start it)

  # # Use SSH config settings that automatically load keys in ssh-agent and store passphrases in Keychain
  # # https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
  # # cp "$DOTFILES/mac-setup/ssh-config" "$HOME/.ssh/config"

  # info "Creating SSH config file"

  # create_missing_directory "$HOME/.ssh"

  # SSH_CONFIG="$HOME/.ssh/config"

  # if [ -f "$SSH_CONFIG" ]; then
  #   printf "SSH config file already exists. Skipping."
  # else
  #   touch "$BACKUP_DIR/ssh-config"
  #   printf "Host *\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentifyFile ~/.ssh/id_rsa" >> "$BACKUP_DIR/ssh-config"
  #   cp "$BACKUP_DIR/ssh-config" "$SSH_CONFIG"
  #   rm "$BACKUP_DIR/ssh-config"

  #   # touch "$SSH_CONFIG"
  #   # printf "Host *\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentifyFile ~/.ssh/id_rsa" >> "$SSH_CONFIG"
  # fi

  # info "Adding keys to ssh-agent and Keychain"

  # # Add SSH private key to ssh-agent and store the passphrase in Keychain
  # ssh-add -K ~/.ssh/id_rsa

  info "Adding public key to GitHub settings (this one's for you!)"

  printf "\nPlease visit https://github.com/settings/ssh/new and log in and enter the following
  public key:\n\n"

  cat "$HOME/.ssh/id_rsa.pub"

  vared -p "Type 'saved' when you've finished saving the key on GitHub. (You'll need it for the next
  step.) " -c word

  if [ ! "$word" == 'saved' ]; then
    printf "Your funeral...\n"
  else
    printf "Good job! Moving on...\n"
  fi

  success "\nDone setting up SSH."
}

# TODO: repurpose for downloading all repos (skipping if they're already there to avoid overwriting
# local changes
clone_dotfiles() {
  # create_missing_directory "$HOME/Repos"
  create_missing_directory "$HOME/Repos/ooloth"

  info "Locating the new dotfiles."

  # Only clone dotfiles if they're missing (don't overwrite local changes!)
  if [ ! -d "$DOTFILES" ]; then
    printf "\n"
    git clone "git@github.com:ooloth/dotfiles.git" "$DOTFILES"
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
  # create_missing_directory "$HOME/.config"

  # printf "\n"
  # info "Creating symlinks in ~/.config..."

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

setup_git() {
  title "Setting up Git"

  defaultName=$(git config user.name)
  defaultEmail=$(git config user.email)
  defaultUser=$(git config github.user)

  vared -p "Name [$defaultName] " -c name
  vared -p "Email [$defaultEmail] " -c email
  vared -p "GitHub username [$defaultUser] " -c user

  git config -f ~/.config/git/config user.name "${name:-$defaultName}"
  git config -f ~/.config/git/config user.email "${email:-$defaultEmail}"
  git config -f ~/.config/git/config github.user "${user:-$defaultUser}"

  success "Done setting up your git credentials."

  # Clone repos
}

setup_homebrew() {
  title "Setting up Homebrew"

# if [ ! -d "${HOME}/bin/" ]; then
#   mkdir "${HOME}/bin"
# fi

  # HOMEBREW_PREFIX="/usr/local"

# if [ -d "$HOMEBREW_PREFIX" ]; then
#   if ! [ -r "$HOMEBREW_PREFIX" ]; then
#     sudo chown -R "${LOGNAME}:admin" "$HOMEBREW_PREFIX"
#   fi
# else
#   sudo mkdir "$HOMEBREW_PREFIX"
#   sudo chflags norestricted "$HOMEBREW_PREFIX"
#   sudo chown -R "${LOGNAME}:admin" "$HOMEBREW_PREFIX"
# fi


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

  info "Updating Homebrew..."
  brew update
  brew upgrade

  success "\nDone setting up Homebrew."
}

setup_terminfo() {
  title "Configuring terminfo"

  info "adding tmux.terminfo"
  tic -x "$DOTFILES/tmux/tmux.terminfo"

  info "adding xterm-256color-italic.terminfo"
  tic -x "$DOTFILES/tmux/xterm-256color-italic.terminfo"

  success "\nDone configuring terminfo settings."
}

set_up_oh_my_zsh() {
  title "Setting up Oh My Zsh..."

  if [ -d "$OH_MY_ZSH" ]; then
    rm -rf "$OH_MY_ZSH"
  fi

  git clone https://github.com/robbyrussell/oh-my-zsh.git "$OH_MY_ZSH"

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

set_up_spaceship_prompt() {
  title "Setting up spaceship prompt..."

  # https://github.com/denysdovhan/spaceship-prompt#installing
  git clone https://github.com/denysdovhan/spaceship-prompt.git "$OH_MY_ZSH/custom/themes/spaceship-prompt"
  ln -s "$OH_MY_ZSH/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$OH_MY_ZSH/custom/themes/spaceship.zsh-theme"

  success "\nDone setting up spaceship prompt."
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

  setup_terminfo
  set_up_oh_my_zsh
  set_up_spaceship_prompt

  success "\nDone configuring shell."
}

# update_zsh_shell() {
#   local shell_path;
#   shell_path="$(command -v zsh)"
#
#   laptop_echo "Changing your shell to zsh ..."
#   if ! grep "$shell_path" /etc/shells > /dev/null 2>&1 ; then
#     laptop_echo "Adding '${shell_path}' to /etc/shells"
#     sudo sh -c "echo ${shell_path} >> /etc/shells"
#   fi
#   sudo chsh -s "$shell_path" "$USER"
# }

set_up_node() {
  title "Installing node"

  fnm install latest && fnm default latest && fnm use latest

  echo "Node --> $(command -v node)"
  node -v

  echo "NPM --> $(command -v npm)"
  npm -v

  success "\nDone installing node."
}

set_up_neovim() {
  title "Setting up neovim"

  info "Installing vim-plug..."
  sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

  warning "TODO: open vim to install plugins, then close"

  # info "Creating viminfo directory for Startify..."
  # create_missing_directory "${HOME}/.vim/files/info"

  success "\nDone setting up neovim."
}

setup_macos() {
  title "Configuring Mac preferences"

  info "Configuring general settings...\n"
  printf "\n"

  printf "Expand save dialog by default\n"
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

  printf "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)\n"
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

  printf "Enable subpixel font rendering on non-Apple LCDs\n"
  defaults write NSGlobalDomain AppleFontSmoothing -int 2

  printf "\n"
  info "Configuring Finder..."

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
  info "Configuring Terminal..."

  printf "only use UTF-8 in Terminal.app\n"
  defaults write com.apple.terminal StringEncodings -array 4

  printf "\n"
  info "Configuring keyboard..."

  printf "Disable press-and-hold for keys in favor of key repeat\n"
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  printf "Set a blazingly fast keyboard repeat rate\n"
  defaults write NSGlobalDomain KeyRepeat -int 1

  printf "Set a shorter Delay until key repeat\n"
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  printf "\n"
  info "Configuring trackpad..."

  printf "Enable tap to click (Trackpad)\n"
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  printf "\n"
  info "Configuring Safari..."

  printf "Enable Safari’s debug menu\n"
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

  # echo "Kill affected applications"

  # for app in Safari Finder Dock Mail SystemUIServer; do killall "$app" >/dev/null 2>&1; done

  success "\nFinished configuring Mac system preferences."
}

set_up_apps() {
  title "Configuring app preferences"

  warning "TODO: configure apps\n"

  success "\nFinished configuring app preferences."
}

suggest_restart() {
  printf "\nTo apply your your preferences, your computer needs to restart.\n"

  vared -p "\nAre you ready to restart now? (y/N) " -c key

  if [[ "$key" = 'y' ]]; then
    printf "Excellent choice. Restarting..."
    sudo shutdown -r now
  else
    printf "No worries! Just remember to restart manually as soon as you can."
  fi
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
    prerequisites && clone_temp_dotfiles && backup
    ;;
  link)
    prerequisites && clone_temp_dotfiles && backup && setup_dotfiles
    ;;
  git)
    prerequisites && clone_temp_dotfiles && backup && setup_ssh && setup_git
    ;;
  homebrew)
    prerequisites && setup_homebrew && suggest_restart
    ;;
  shell)
    prerequisites && clone_temp_dotfiles && backup && setup_shell
    ;;
  macos)
    prerequisites && setup_macos && suggest_restart
    ;;
  all)
    # prerequisites && backup && setup_ssh && setup_dotfiles
    prerequisites && confirm_plan && clone_temp_dotfiles && backup && setup_dotfiles
    setup_ssh
    setup_git
    setup_homebrew
    setup_shell
    set_up_node
    set_up_neovim
    setup_macos
    set_up_apps
    suggest_restart
    goodbye
    ;;
  *)
  echo -e $"\nUsage: $(basename "$0") {backup|link|git|homebrew|shell|macos|all}\n"
  exit 1
  ;;
esac
