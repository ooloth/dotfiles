#!/usr/bin/env bats

# Integration tests for npm utilities usage

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
  
  # Copy utilities
  cp "lib/npm-utils.bash" "$DOTFILES/lib/"
  cp "example-npm-update.bash" "$DOTFILES/"
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

@test "example npm update script runs successfully when environment valid" {
  # Mock environment validation and commands
  command() {
    if [[ "$1" == "-v" && ("$2" == "node" || "$2" == "npm") ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  node() {
    if [[ "$1" == "-v" ]]; then
      echo "v18.17.0"
    fi
  }
  
  npm() {
    case "$1" in
      "list")
        echo "├── typescript@5.0.0"
        ;;
      "outdated")
        echo "npm  9.0.0  9.1.0  9.1.0"
        ;;
      "install")
        echo "Installed packages: $*"
        return 0
        ;;
    esac
  }
  
  run bash "$DOTFILES/example-npm-update.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"✨ Updating Node v18.17.0 global dependencies"* ]]
  [[ "$output" == *"Checking"* ]]
  [[ "$output" == *"packages for updates"* ]]
}

@test "example npm update script fails when node unavailable" {
  # Mock node to be unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "node" ]]; then
      return 1
    elif [[ "$1" == "-v" && "$2" == "npm" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run bash "$DOTFILES/example-npm-update.bash"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Node.js is not available"* ]]
}

@test "example npm update script reports packages correctly" {
  # Mock environment and commands
  command() {
    if [[ "$1" == "-v" && ("$2" == "node" || "$2" == "npm") ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  node() {
    echo "v18.17.0"
  }
  
  npm() {
    case "$1" in
      "list")
        echo "├── npm@9.0.0"
        echo "├── typescript@5.0.0"
        ;;
      "outdated")
        echo "npm  9.0.0  9.1.0  9.1.0"
        ;;
      "install")
        echo "NPM_INSTALL: $*"
        return 0
        ;;
    esac
  }
  
  run bash "$DOTFILES/example-npm-update.bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"📦 Installing @anthropic-ai/claude-code"* ]]
  [[ "$output" == *"🚀 Updating npm"* ]]
  [[ "$output" == *"NPM_INSTALL:"* ]]
  [[ "$output" == *"🎉 All npm packages are installed and up to date."* ]]
}