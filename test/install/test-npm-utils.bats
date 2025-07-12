#!/usr/bin/env bats

# Test suite for npm-utils.bash

# Load the npm utilities
load "../../lib/npm-utils.bash"

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

# Test is_npm_available
@test "is_npm_available returns true when npm command exists" {
  # Mock command to simulate npm being available
  command() {
    if [[ "$1" == "-v" && "$2" == "npm" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_npm_available
  [ "$status" -eq 0 ]
}

@test "is_npm_available returns false when npm command missing" {
  # Mock command to simulate npm being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "npm" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run is_npm_available
  [ "$status" -ne 0 ]
}

# Test is_node_available
@test "is_node_available returns true when node command exists" {
  # Mock command to simulate node being available
  command() {
    if [[ "$1" == "-v" && "$2" == "node" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_node_available
  [ "$status" -eq 0 ]
}

@test "is_node_available returns false when node command missing" {
  # Mock command to simulate node being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "node" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run is_node_available
  [ "$status" -ne 0 ]
}

# Test get_node_version
@test "get_node_version returns version when node available" {
  # Mock node command
  node() {
    if [[ "$1" == "-v" ]]; then
      echo "v18.17.0"
    else
      command node "$@"
    fi
  }
  
  # Mock is_node_available to return true
  is_node_available() { return 0; }
  
  run get_node_version
  [ "$status" -eq 0 ]
  [ "$output" = "v18.17.0" ]
}

@test "get_node_version returns unknown when node unavailable" {
  # Mock is_node_available to return false
  is_node_available() { return 1; }
  
  run get_node_version
  [ "$status" -eq 0 ]
  [ "$output" = "unknown" ]
}

# Test get_installed_packages
@test "get_installed_packages returns package list when npm available" {
  # Mock npm command
  npm() {
    if [[ "$1" == "list" && "$2" == "-g" ]]; then
      echo "npm@9.0.0"
      echo "├── @anthropic-ai/claude-code@1.0.0"
      echo "└── typescript@5.0.0"
    else
      command npm "$@"
    fi
  }
  
  # Mock is_npm_available to return true
  is_npm_available() { return 0; }
  
  run get_installed_packages
  [ "$status" -eq 0 ]
  [[ "$output" == *"@anthropic-ai/claude-code@1.0.0"* ]]
  [[ "$output" == *"typescript@5.0.0"* ]]
}

@test "get_installed_packages returns empty when npm unavailable" {
  # Mock is_npm_available to return false
  is_npm_available() { return 1; }
  
  run get_installed_packages
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

# Test get_outdated_packages
@test "get_outdated_packages returns outdated list when npm available" {
  # Mock npm command
  npm() {
    if [[ "$1" == "outdated" && "$2" == "-g" ]]; then
      echo "typescript  5.0.0   5.1.0   5.1.0"
      echo "npm         9.0.0   9.1.0   9.1.0"
    else
      command npm "$@"
    fi
  }
  
  # Mock is_npm_available to return true
  is_npm_available() { return 0; }
  
  run get_outdated_packages
  [ "$status" -eq 0 ]
  [[ "$output" == *"typescript"* ]]
  [[ "$output" == *"npm"* ]]
}

@test "get_outdated_packages returns empty when npm unavailable" {
  # Mock is_npm_available to return false
  is_npm_available() { return 1; }
  
  run get_outdated_packages
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

# Test is_package_installed
@test "is_package_installed returns true when package is installed" {
  local installed_packages="├── @anthropic-ai/claude-code@1.0.0
└── typescript@5.0.0"
  
  run is_package_installed "typescript" "$installed_packages"
  [ "$status" -eq 0 ]
}

@test "is_package_installed returns false when package not installed" {
  local installed_packages="├── @anthropic-ai/claude-code@1.0.0
└── typescript@5.0.0"
  
  run is_package_installed "eslint" "$installed_packages"
  [ "$status" -ne 0 ]
}

@test "is_package_installed fetches packages when not provided" {
  # Mock get_installed_packages
  get_installed_packages() {
    echo "├── typescript@5.0.0"
  }
  
  run is_package_installed "typescript"
  [ "$status" -eq 0 ]
}

# Test is_package_outdated
@test "is_package_outdated returns true when package is outdated" {
  local outdated_packages="typescript  5.0.0   5.1.0   5.1.0
npm         9.0.0   9.1.0   9.1.0"
  
  run is_package_outdated "typescript" "$outdated_packages"
  [ "$status" -eq 0 ]
}

@test "is_package_outdated returns false when package not outdated" {
  local outdated_packages="npm         9.0.0   9.1.0   9.1.0"
  
  run is_package_outdated "typescript" "$outdated_packages"
  [ "$status" -ne 0 ]
}

@test "is_package_outdated fetches packages when not provided" {
  # Mock get_outdated_packages
  get_outdated_packages() {
    echo "typescript  5.0.0   5.1.0   5.1.0"
  }
  
  run is_package_outdated "typescript"
  [ "$status" -eq 0 ]
}

# Test install_npm_packages
@test "install_npm_packages runs npm install with packages" {
  # Mock npm command
  npm() {
    if [[ "$1" == "install" && "$2" == "-g" ]]; then
      echo "NPM_INSTALL: $*"
      return 0
    else
      command npm "$@"
    fi
  }
  
  run install_npm_packages "typescript" "eslint" "prettier"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing 3 npm packages globally..."* ]]
  [[ "$output" == *"NPM_INSTALL: install -g --loglevel=error typescript eslint prettier"* ]]
}

@test "install_npm_packages handles empty package list" {
  run install_npm_packages
  [ "$status" -eq 0 ]
  [[ "$output" == *"No packages to install"* ]]
}

@test "install_npm_packages handles npm failure" {
  # Mock npm to fail
  npm() {
    return 1
  }
  
  run install_npm_packages "typescript"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to install npm packages"* ]]
}

# Test update_npm_packages
@test "update_npm_packages runs npm install with packages" {
  # Mock npm command
  npm() {
    if [[ "$1" == "install" && "$2" == "-g" ]]; then
      echo "NPM_UPDATE: $*"
      return 0
    else
      command npm "$@"
    fi
  }
  
  run update_npm_packages "typescript" "eslint"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Updating 2 npm packages globally..."* ]]
  [[ "$output" == *"NPM_UPDATE: install -g --loglevel=error typescript eslint"* ]]
}

# Test install_and_update_npm_packages
@test "install_and_update_npm_packages runs npm install with all packages" {
  # Mock npm command
  npm() {
    if [[ "$1" == "install" && "$2" == "-g" ]]; then
      echo "NPM_INSTALL_UPDATE: $*"
      return 0
    else
      command npm "$@"
    fi
  }
  
  run install_and_update_npm_packages "typescript" "eslint" "prettier"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing/updating 3 npm packages globally..."* ]]
  [[ "$output" == *"NPM_INSTALL_UPDATE: install -g --loglevel=error typescript eslint prettier"* ]]
}

# Test analyze_package_requirements
@test "analyze_package_requirements correctly categorizes packages" {
  # Mock functions
  get_installed_packages() {
    echo "├── typescript@5.0.0"
  }
  
  get_outdated_packages() {
    echo "typescript  5.0.0   5.1.0   5.1.0"
  }
  
  run analyze_package_requirements "typescript" "eslint" "prettier"
  [ "$status" -eq 0 ]
  [[ "$output" == *"TO_ADD:eslint prettier"* ]]
  [[ "$output" == *"TO_UPDATE:typescript"* ]]
}

# Test get_general_npm_dependencies
@test "get_general_npm_dependencies returns expected packages" {
  run get_general_npm_dependencies
  [ "$status" -eq 0 ]
  [[ "$output" == *"@anthropic-ai/claude-code"* ]]
  [[ "$output" == *"npm"* ]]
  [[ "$output" == *"npm-check"* ]]
  [[ "$output" == *"trash-cli"* ]]
}

# Test get_neovim_npm_dependencies
@test "get_neovim_npm_dependencies returns expected packages" {
  run get_neovim_npm_dependencies
  [ "$status" -eq 0 ]
  [[ "$output" == *"bash-language-server"* ]]
  [[ "$output" == *"typescript"* ]]
  [[ "$output" == *"neovim"* ]]
}

# Test get_all_npm_dependencies
@test "get_all_npm_dependencies returns general and neovim packages" {
  run get_all_npm_dependencies
  [ "$status" -eq 0 ]
  [[ "$output" == *"@anthropic-ai/claude-code"* ]]
  [[ "$output" == *"typescript"* ]]
  [[ "$output" == *"neovim"* ]]
}

# Test validate_npm_environment
@test "validate_npm_environment succeeds when both node and npm available" {
  # Mock both to be available
  is_node_available() { return 0; }
  is_npm_available() { return 0; }
  
  run validate_npm_environment
  [ "$status" -eq 0 ]
}

@test "validate_npm_environment fails when node unavailable" {
  # Mock node to be unavailable
  is_node_available() { return 1; }
  is_npm_available() { return 0; }
  
  run validate_npm_environment
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Node.js is not available"* ]]
}

@test "validate_npm_environment fails when npm unavailable" {
  # Mock npm to be unavailable
  is_node_available() { return 0; }
  is_npm_available() { return 1; }
  
  run validate_npm_environment
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ npm is not available"* ]]
}