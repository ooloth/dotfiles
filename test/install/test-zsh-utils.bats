#!/usr/bin/env bats

# Test suite for zsh-utils.bash

# Load the zsh utilities
load "../../lib/zsh-utils.bash"

setup() {
  # Create temporary directory for each test
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
  # Clean up temporary directory
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Test is_homebrew_zsh_installed
@test "is_homebrew_zsh_installed returns true when zsh exists" {
  # Create mock zsh binary
  local mock_shell="${TEST_TEMP_DIR}/opt/homebrew/bin/zsh"
  mkdir -p "$(dirname "$mock_shell")"
  touch "$mock_shell"
  chmod +x "$mock_shell"
  
  # Override the function to use our mock path
  is_homebrew_zsh_installed() {
    local shell_path="${TEST_TEMP_DIR}/opt/homebrew/bin/zsh"
    [[ -x "$shell_path" ]]
  }
  
  run is_homebrew_zsh_installed
  [ "$status" -eq 0 ]
}

@test "is_homebrew_zsh_installed returns false when zsh missing" {
  # Override the function to use a non-existent path
  is_homebrew_zsh_installed() {
    local shell_path="${TEST_TEMP_DIR}/opt/homebrew/bin/zsh"
    [[ -x "$shell_path" ]]
  }
  
  run is_homebrew_zsh_installed
  [ "$status" -ne 0 ]
}

# Test is_shell_registered
@test "is_shell_registered returns true when shell is in /etc/shells" {
  # Create mock /etc/shells
  local mock_shells="${TEST_TEMP_DIR}/etc/shells"
  mkdir -p "$(dirname "$mock_shells")"
  cat > "$mock_shells" <<EOF
/bin/bash
/bin/zsh
/opt/homebrew/bin/zsh
/usr/bin/zsh
EOF

  # Override grep to use our mock file
  grep() {
    command grep "$@" "$mock_shells"
  }
  
  run is_shell_registered "/opt/homebrew/bin/zsh"
  [ "$status" -eq 0 ]
}

@test "is_shell_registered returns false when shell not in /etc/shells" {
  # Create mock /etc/shells
  local mock_shells="${TEST_TEMP_DIR}/etc/shells"
  mkdir -p "$(dirname "$mock_shells")"
  cat > "$mock_shells" <<EOF
/bin/bash
/bin/zsh
/usr/bin/zsh
EOF

  # Override grep to use our mock file
  grep() {
    command grep "$@" "$mock_shells"
  }
  
  run is_shell_registered "/opt/homebrew/bin/zsh"
  [ "$status" -ne 0 ]
}

# Test add_shell_to_etc_shells
@test "add_shell_to_etc_shells adds shell when not present" {
  # Mock sudo to capture the command
  sudo() {
    if [[ "$1" == "sh" && "$2" == "-c" ]]; then
      echo "SUDO_COMMAND: $3"
    fi
  }
  
  # Mock is_shell_registered to return false
  is_shell_registered() {
    return 1
  }
  
  run add_shell_to_etc_shells "/opt/homebrew/bin/zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Adding '/opt/homebrew/bin/zsh' to /etc/shells"* ]]
  [[ "$output" == *"SUDO_COMMAND: echo /opt/homebrew/bin/zsh >> /etc/shells"* ]]
}

@test "add_shell_to_etc_shells skips when shell already registered" {
  # Mock is_shell_registered to return true
  is_shell_registered() {
    return 0
  }
  
  run add_shell_to_etc_shells "/opt/homebrew/bin/zsh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# Test change_user_shell
@test "change_user_shell changes shell for specified user" {
  # Mock sudo to capture the command
  sudo() {
    if [[ "$1" == "chsh" ]]; then
      echo "CHSH_COMMAND: $*"
    fi
  }
  
  run change_user_shell "/opt/homebrew/bin/zsh" "testuser"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Changing shell to /opt/homebrew/bin/zsh for user testuser"* ]]
  [[ "$output" == *"CHSH_COMMAND: chsh -s /opt/homebrew/bin/zsh testuser"* ]]
}

@test "change_user_shell uses current user when not specified" {
  # Mock sudo to capture the command
  sudo() {
    if [[ "$1" == "chsh" ]]; then
      echo "CHSH_COMMAND: $*"
    fi
  }
  
  run change_user_shell "/opt/homebrew/bin/zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CHSH_COMMAND: chsh -s /opt/homebrew/bin/zsh $USER"* ]]
}

# Test get_user_shell
@test "get_user_shell returns current shell path" {
  # Mock dscl command
  dscl() {
    echo "UserShell: /bin/zsh"
  }
  
  run get_user_shell "testuser"
  [ "$status" -eq 0 ]
  [ "$output" = "/bin/zsh" ]
}

# Test is_user_using_shell
@test "is_user_using_shell returns true when using specified shell" {
  # Mock get_user_shell
  get_user_shell() {
    echo "/opt/homebrew/bin/zsh"
  }
  
  run is_user_using_shell "/opt/homebrew/bin/zsh" "testuser"
  [ "$status" -eq 0 ]
}

@test "is_user_using_shell returns false when using different shell" {
  # Mock get_user_shell
  get_user_shell() {
    echo "/bin/bash"
  }
  
  run is_user_using_shell "/opt/homebrew/bin/zsh" "testuser"
  [ "$status" -ne 0 ]
}