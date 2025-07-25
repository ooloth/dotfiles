#!/usr/bin/env bats

# Integration tests for zsh installation

setup() {
  # Create temporary directory for each test
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  
  # Save original environment
  export ORIGINAL_DOTFILES="${DOTFILES:-}"
  
  # Set up test environment
  export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
  
  # Create fake dotfiles structure
  mkdir -p "$DOTFILES/lib"
  mkdir -p "$DOTFILES/bin/lib"
  mkdir -p "$DOTFILES/bin/install"
  
  # Copy utilities
  cp "lib/zsh-utils.bash" "$DOTFILES/lib/"
  cp "bin/lib/dry-run-utils.bash" "$DOTFILES/bin/lib/"
  
  # Create mock homebrew script
  cat > "$DOTFILES/bin/install/homebrew.bash" <<'EOF'
#!/usr/bin/env bash
echo "Mock homebrew installation"
mkdir -p /opt/homebrew/bin
touch /opt/homebrew/bin/zsh
chmod +x /opt/homebrew/bin/zsh
EOF
  chmod +x "$DOTFILES/bin/install/homebrew.bash"
}

teardown() {
  # Restore original environment
  if [[ -n "${ORIGINAL_DOTFILES}" ]]; then
    export DOTFILES="$ORIGINAL_DOTFILES"
  else
    unset DOTFILES
  fi
  
  # Clean up temporary directory
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

@test "zsh installation completes when zsh already installed and configured" {
  # Mock commands to simulate already configured state
  
  # Mock test command for zsh binary check
  test() {
    if [[ "$1" == "-x" && "$2" == "/opt/homebrew/bin/zsh" ]]; then
      return 0  # Zsh is installed
    else
      command test "$@"
    fi
  }
  
  # Mock grep for shell registration check
  grep() {
    if [[ "$1" == "-q" ]]; then
      return 0  # Shell is registered
    else
      command grep "$@"
    fi
  }
  
  # Mock dscl for current shell check
  dscl() {
    echo "UserShell: /opt/homebrew/bin/zsh"
  }
  
  # Source and run the installation script
  source "bin/install/zsh.bash"
  
  # The script should complete without errors
  [ "$?" -eq 0 ]
}

@test "zsh installation installs homebrew when zsh missing" {
  # Track installation state
  local homebrew_called=false
  
  # Mock test command
  test() {
    if [[ "$1" == "-x" && "$2" == "/opt/homebrew/bin/zsh" ]]; then
      # Return false first time, true after homebrew installation
      if [[ "$homebrew_called" == "true" ]]; then
        return 0
      else
        return 1
      fi
    else
      command test "$@"
    fi
  }
  
  # Mock source command to track homebrew script execution
  source() {
    if [[ "$1" == *"homebrew.bash" ]]; then
      homebrew_called=true
      echo "Installing Homebrew..."
    else
      command source "$@"
    fi
  }
  
  # Mock other commands
  grep() { return 1; }  # Shell not registered
  sudo() { echo "SUDO: $*"; }
  dscl() { echo "UserShell: /bin/bash"; }
  
  # Run the installation script
  run bash "bin/install/zsh.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Zsh not found"* ]]
  [[ "$output" == *"Installing Homebrew"* ]]
}

@test "zsh installation handles dry run mode" {
  # Set dry run mode
  export DRY_RUN=1
  
  # Mock commands
  test() {
    [[ "$1" == "-x" && "$2" == "/opt/homebrew/bin/zsh" ]] && return 0 || command test "$@"
  }
  grep() { return 1; }  # Shell not registered
  dscl() { echo "UserShell: /bin/bash"; }
  
  # Run the installation script
  run bash "bin/install/zsh.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY RUN] Would add"* ]]
  [[ "$output" == *"[DRY RUN] Would change shell"* ]]
  
  # Verify no actual changes were made
  [[ "$output" != *"SUDO:"* ]]
}

@test "zsh installation adds shell to /etc/shells when needed" {
  # Mock commands
  test() {
    [[ "$1" == "-x" && "$2" == "/opt/homebrew/bin/zsh" ]] && return 0 || command test "$@"
  }
  grep() { return 1; }  # Shell not registered
  dscl() { echo "UserShell: /bin/bash"; }
  sudo() {
    if [[ "$1" == "sh" ]]; then
      echo "Adding shell: $3"
    else
      echo "SUDO: $*"
    fi
  }
  
  # Run the installation script
  run bash "bin/install/zsh.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Adding '/opt/homebrew/bin/zsh' to /etc/shells"* ]]
  [[ "$output" == *"Adding shell:"* ]]
}

@test "zsh installation changes default shell when needed" {
  # Mock commands
  test() {
    [[ "$1" == "-x" && "$2" == "/opt/homebrew/bin/zsh" ]] && return 0 || command test "$@"
  }
  grep() { return 0; }  # Shell already registered
  dscl() { echo "UserShell: /bin/bash"; }
  sudo() {
    if [[ "$1" == "chsh" ]]; then
      echo "Changing shell: $*"
    fi
  }
  
  # Run the installation script
  run bash "bin/install/zsh.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Changing shell to /opt/homebrew/bin/zsh"* ]]
  [[ "$output" == *"Changing shell: chsh"* ]]
}

@test "zsh installation skips changes when already using zsh" {
  # Mock commands to simulate perfect state
  test() {
    [[ "$1" == "-x" && "$2" == "/opt/homebrew/bin/zsh" ]] && return 0 || command test "$@"
  }
  grep() { return 0; }  # Shell registered
  dscl() { echo "UserShell: /opt/homebrew/bin/zsh"; }
  
  # Run the installation script
  run bash "bin/install/zsh.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Already using Zsh as default shell"* ]]
  [[ "$output" == *"already registered in /etc/shells"* ]]
}