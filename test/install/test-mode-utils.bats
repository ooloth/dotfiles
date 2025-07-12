#!/usr/bin/env bats

# Test suite for mode-utils.bash

# Load the mode utilities
load "../../lib/mode-utils.bash"

setup() {
  # Create temporary directory for each test
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  
  # Create test file structure
  mkdir -p "$TEST_TEMP_DIR/bin/install"
  mkdir -p "$TEST_TEMP_DIR/bin/update"
}

teardown() {
  # Clean up temporary directory
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Test is_fd_available
@test "is_fd_available returns true when fd command exists" {
  # Mock command to simulate fd being available
  command() {
    if [[ "$1" == "-v" && "$2" == "fd" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_fd_available
  [ "$status" -eq 0 ]
}

@test "is_fd_available returns false when fd command missing" {
  # Mock command to simulate fd being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "fd" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run is_fd_available
  [ "$status" -ne 0 ]
}

# Test is_find_available
@test "is_find_available returns true when find command exists" {
  # Mock command to simulate find being available
  command() {
    if [[ "$1" == "-v" && "$2" == "find" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_find_available
  [ "$status" -eq 0 ]
}

@test "is_find_available returns false when find command missing" {
  # Mock command to simulate find being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "find" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run is_find_available
  [ "$status" -ne 0 ]
}

# Test is_chmod_available
@test "is_chmod_available returns true when chmod command exists" {
  # Mock command to simulate chmod being available
  command() {
    if [[ "$1" == "-v" && "$2" == "chmod" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_chmod_available
  [ "$status" -eq 0 ]
}

# Test make_file_executable
@test "make_file_executable makes file executable" {
  # Create test file
  local test_file="$TEST_TEMP_DIR/test.sh"
  touch "$test_file"
  chmod 644 "$test_file"
  
  # Mock chmod
  chmod() {
    if [[ "$1" == "+x" ]]; then
      echo "CHMOD: +x $2"
      command chmod +x "$2"
      return 0
    else
      command chmod "$@"
    fi
  }
  
  run make_file_executable "$test_file"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CHMOD: +x $test_file"* ]]
  [[ "$output" == *"✅ Made executable: $test_file"* ]]
}

@test "make_file_executable fails for non-existent file" {
  run make_file_executable "$TEST_TEMP_DIR/nonexistent.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ File does not exist:"* ]]
}

@test "make_file_executable handles chmod failure" {
  # Create test file
  local test_file="$TEST_TEMP_DIR/test.sh"
  touch "$test_file"
  
  # Mock chmod to fail
  chmod() {
    if [[ "$1" == "+x" ]]; then
      return 1
    else
      command chmod "$@"
    fi
  }
  
  run make_file_executable "$test_file"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to make file executable:"* ]]
}

# Test is_file_executable
@test "is_file_executable returns true for executable file" {
  # Create executable test file
  local test_file="$TEST_TEMP_DIR/test.sh"
  touch "$test_file"
  chmod +x "$test_file"
  
  run is_file_executable "$test_file"
  [ "$status" -eq 0 ]
}

@test "is_file_executable returns false for non-executable file" {
  # Create non-executable test file
  local test_file="$TEST_TEMP_DIR/test.sh"
  touch "$test_file"
  chmod 644 "$test_file"
  
  run is_file_executable "$test_file"
  [ "$status" -ne 0 ]
}

# Test find_files_by_extension_fd
@test "find_files_by_extension_fd uses fd to find files" {
  # Mock is_fd_available
  is_fd_available() { return 0; }
  
  # Mock fd command
  fd() {
    if [[ "$2" == "$TEST_TEMP_DIR" && "$4" == "zsh" ]]; then
      echo "$TEST_TEMP_DIR/script1.zsh"
      echo "$TEST_TEMP_DIR/script2.zsh"
    fi
  }
  
  run find_files_by_extension_fd "$TEST_TEMP_DIR" "zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"script1.zsh"* ]]
  [[ "$output" == *"script2.zsh"* ]]
}

@test "find_files_by_extension_fd fails when fd unavailable" {
  # Mock is_fd_available to return false
  is_fd_available() { return 1; }
  
  run find_files_by_extension_fd "$TEST_TEMP_DIR" "zsh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ fd command not available"* ]]
}

# Test find_files_by_extension_find
@test "find_files_by_extension_find uses find to locate files" {
  # Mock is_find_available
  is_find_available() { return 0; }
  
  # Mock find command
  find() {
    if [[ "$1" == "$TEST_TEMP_DIR" && "$3" == "*.zsh" ]]; then
      echo "$TEST_TEMP_DIR/script1.zsh"
      echo "$TEST_TEMP_DIR/script2.zsh"
    fi
  }
  
  run find_files_by_extension_find "$TEST_TEMP_DIR" "zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"script1.zsh"* ]]
  [[ "$output" == *"script2.zsh"* ]]
}

@test "find_files_by_extension_find fails when find unavailable" {
  # Mock is_find_available to return false
  is_find_available() { return 1; }
  
  run find_files_by_extension_find "$TEST_TEMP_DIR" "zsh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ find command not available"* ]]
}

# Test find_files_by_extension
@test "find_files_by_extension prefers fd when available" {
  # Mock fd available
  is_fd_available() { return 0; }
  is_find_available() { return 0; }
  
  # Mock fd command
  fd() {
    echo "FD_RESULT: $*"
  }
  
  # Mock find command (should not be called)
  find() {
    echo "FIND_RESULT: $*"
  }
  
  run find_files_by_extension "$TEST_TEMP_DIR" "zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"FD_RESULT:"* ]]
  [[ "$output" != *"FIND_RESULT:"* ]]
}

@test "find_files_by_extension falls back to find when fd unavailable" {
  # Mock fd unavailable, find available
  is_fd_available() { return 1; }
  is_find_available() { return 0; }
  
  # Mock find command
  find() {
    echo "FIND_FALLBACK: $*"
  }
  
  run find_files_by_extension "$TEST_TEMP_DIR" "zsh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"FIND_FALLBACK:"* ]]
}

@test "find_files_by_extension fails when neither tool available" {
  # Mock both unavailable
  is_fd_available() { return 1; }
  is_find_available() { return 1; }
  
  run find_files_by_extension "$TEST_TEMP_DIR" "zsh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Neither fd nor find command available"* ]]
}

# Test make_extension_executable
@test "make_extension_executable processes files correctly" {
  # Create test files
  touch "$TEST_TEMP_DIR/script1.zsh"
  touch "$TEST_TEMP_DIR/script2.zsh"
  chmod 644 "$TEST_TEMP_DIR/script1.zsh"
  chmod +x "$TEST_TEMP_DIR/script2.zsh"
  
  # Mock dependencies
  is_chmod_available() { return 0; }
  
  # Mock find_files_by_extension
  find_files_by_extension() {
    echo "$TEST_TEMP_DIR/script1.zsh"
    echo "$TEST_TEMP_DIR/script2.zsh"
  }
  
  # Mock chmod
  chmod() {
    if [[ "$1" == "+x" ]]; then
      echo "CHMOD: +x $2"
      return 0
    else
      command chmod "$@"
    fi
  }
  
  run make_extension_executable "$TEST_TEMP_DIR" "zsh" "false"
  [ "$status" -eq 0 ]
  [[ "$output" == *"🔍 Finding .zsh files"* ]]
  [[ "$output" == *"CHMOD: +x $TEST_TEMP_DIR/script1.zsh"* ]]
  [[ "$output" == *"✓ Already executable: $TEST_TEMP_DIR/script2.zsh"* ]]
  [[ "$output" == *"Found 2 .zsh files, processed 2"* ]]
}

@test "make_extension_executable handles dry run mode" {
  # Create test files
  touch "$TEST_TEMP_DIR/script1.zsh"
  touch "$TEST_TEMP_DIR/script2.zsh"
  chmod 644 "$TEST_TEMP_DIR/script1.zsh"
  chmod +x "$TEST_TEMP_DIR/script2.zsh"
  
  # Mock dependencies
  is_chmod_available() { return 0; }
  
  # Mock find_files_by_extension
  find_files_by_extension() {
    echo "$TEST_TEMP_DIR/script1.zsh"
    echo "$TEST_TEMP_DIR/script2.zsh"
  }
  
  run make_extension_executable "$TEST_TEMP_DIR" "zsh" "true"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY RUN] Would make executable: $TEST_TEMP_DIR/script1.zsh"* ]]
  [[ "$output" == *"[DRY RUN] Already executable: $TEST_TEMP_DIR/script2.zsh"* ]]
  [[ "$output" == *"[DRY RUN] File permissions would be updated"* ]]
}

@test "make_extension_executable fails for non-existent directory" {
  run make_extension_executable "$TEST_TEMP_DIR/nonexistent" "zsh" "false"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Directory does not exist:"* ]]
}

# Test update_dotfiles_script_permissions
@test "update_dotfiles_script_permissions processes multiple extensions" {
  # Create bin directory structure
  mkdir -p "$TEST_TEMP_DIR/bin"
  touch "$TEST_TEMP_DIR/bin/script1.zsh"
  touch "$TEST_TEMP_DIR/bin/script2.bash"
  touch "$TEST_TEMP_DIR/bin/script3.sh"
  
  # Mock find_files_by_extension to return different files for different extensions
  find_files_by_extension() {
    local dir="$1"
    local ext="$2"
    
    case "$ext" in
      "zsh")
        echo "$dir/script1.zsh"
        ;;
      "bash")
        echo "$dir/script2.bash"
        ;;
      "sh")
        echo "$dir/script3.sh"
        ;;
    esac
  }
  
  # Mock make_extension_executable
  make_extension_executable() {
    echo "MAKE_EXECUTABLE: $1 $2 $3"
  }
  
  run update_dotfiles_script_permissions "$TEST_TEMP_DIR" "false"
  [ "$status" -eq 0 ]
  [[ "$output" == *"🔋 Updating executable permissions for dotfiles scripts"* ]]
  [[ "$output" == *"Processing .zsh files..."* ]]
  [[ "$output" == *"Processing .bash files..."* ]]
  [[ "$output" == *"Processing .sh files..."* ]]
  [[ "$output" == *"MAKE_EXECUTABLE: $TEST_TEMP_DIR/bin zsh false"* ]]
  [[ "$output" == *"MAKE_EXECUTABLE: $TEST_TEMP_DIR/bin bash false"* ]]
  [[ "$output" == *"MAKE_EXECUTABLE: $TEST_TEMP_DIR/bin sh false"* ]]
}

@test "update_dotfiles_script_permissions fails when bin directory missing" {
  run update_dotfiles_script_permissions "$TEST_TEMP_DIR" "false"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Dotfiles bin directory not found:"* ]]
}

# Test check_file_permissions
@test "check_file_permissions displays file information" {
  # Create test file
  local test_file="$TEST_TEMP_DIR/test.sh"
  touch "$test_file"
  chmod +x "$test_file"
  
  # Mock ls command
  ls() {
    if [[ "$1" == "-l" ]]; then
      echo "-rwxr-xr-x 1 user group 0 Jan 1 12:00 $test_file"
    else
      command ls "$@"
    fi
  }
  
  run check_file_permissions "$test_file"
  [ "$status" -eq 0 ]
  [[ "$output" == *"File: $test_file"* ]]
  [[ "$output" == *"Permissions: -rwxr-xr-x"* ]]
  [[ "$output" == *"Status: ✅ Executable"* ]]
}

@test "check_file_permissions fails for non-existent file" {
  run check_file_permissions "$TEST_TEMP_DIR/nonexistent.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ File does not exist:"* ]]
}

# Test validate_permission_environment
@test "validate_permission_environment succeeds when chmod and fd available" {
  # Mock all commands available
  is_chmod_available() { return 0; }
  is_fd_available() { return 0; }
  is_find_available() { return 0; }
  
  run validate_permission_environment
  [ "$status" -eq 0 ]
  [[ "$output" == *"✅ Using fd for file discovery"* ]]
}

@test "validate_permission_environment uses find fallback when fd unavailable" {
  # Mock chmod and find available, fd unavailable
  is_chmod_available() { return 0; }
  is_fd_available() { return 1; }
  is_find_available() { return 0; }
  
  run validate_permission_environment
  [ "$status" -eq 0 ]
  [[ "$output" == *"⚠️  Using find as fallback"* ]]
}

@test "validate_permission_environment fails when chmod unavailable" {
  # Mock chmod unavailable
  is_chmod_available() { return 1; }
  is_fd_available() { return 0; }
  is_find_available() { return 0; }
  
  run validate_permission_environment
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ chmod command not available"* ]]
}

@test "validate_permission_environment fails when no file finding tools available" {
  # Mock chmod available but no file finding tools
  is_chmod_available() { return 0; }
  is_fd_available() { return 1; }
  is_find_available() { return 1; }
  
  run validate_permission_environment
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Neither fd nor find command available"* ]]
}