#!/usr/bin/env bash
# Utilities for managing NPM packages

set -euo pipefail

# Check if npm is available
is_npm_available() {
  command -v npm >/dev/null 2>&1
}

# Check if node is available
is_node_available() {
  command -v node >/dev/null 2>&1
}

# Get Node.js version
get_node_version() {
  if is_node_available; then
    node -v
  else
    echo "unknown"
  fi
}

# Get list of globally installed packages
get_installed_packages() {
  if is_npm_available; then
    npm list -g --depth=0 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# Get list of outdated global packages
get_outdated_packages() {
  if is_npm_available; then
    npm outdated -g 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# Check if a specific package is installed globally
is_package_installed() {
  local package="$1"
  local installed_packages="${2:-}"
  
  # Get installed packages if not provided
  if [[ -z "$installed_packages" ]]; then
    installed_packages=$(get_installed_packages)
  fi
  
  echo "$installed_packages" | grep -q " ${package}@"
}

# Check if a specific package is outdated
is_package_outdated() {
  local package="$1"
  local outdated_packages="${2:-}"
  
  # Get outdated packages if not provided
  if [[ -z "$outdated_packages" ]]; then
    outdated_packages=$(get_outdated_packages)
  fi
  
  echo "$outdated_packages" | grep -q "^${package}"
}

# Install global npm packages
install_npm_packages() {
  local packages=("$@")
  
  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "No packages to install"
    return 0
  fi
  
  echo "Installing ${#packages[@]} npm packages globally..."
  
  if ! npm install -g --loglevel=error "${packages[@]}"; then
    echo "❌ Failed to install npm packages"
    return 1
  fi
}

# Update global npm packages
update_npm_packages() {
  local packages=("$@")
  
  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "No packages to update"
    return 0
  fi
  
  echo "Updating ${#packages[@]} npm packages globally..."
  
  if ! npm install -g --loglevel=error "${packages[@]}"; then
    echo "❌ Failed to update npm packages"
    return 1
  fi
}

# Install and update npm packages in one operation
install_and_update_npm_packages() {
  local packages=("$@")
  
  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "No packages to install or update"
    return 0
  fi
  
  echo "Installing/updating ${#packages[@]} npm packages globally..."
  
  if ! npm install -g --loglevel=error "${packages[@]}"; then
    echo "❌ Failed to install/update npm packages"
    return 1
  fi
}

# Analyze packages and categorize them as new installations or updates
analyze_package_requirements() {
  local packages=("$@")
  local installed_packages outdated_packages
  
  # Get current state
  installed_packages=$(get_installed_packages)
  outdated_packages=$(get_outdated_packages)
  
  # Initialize arrays for results
  local packages_to_add=()
  local packages_to_update=()
  
  # Analyze each package
  for package in "${packages[@]}"; do
    if ! is_package_installed "$package" "$installed_packages"; then
      packages_to_add+=("$package")
    elif is_package_outdated "$package" "$outdated_packages"; then
      packages_to_update+=("$package")
    fi
  done
  
  # Output results (for capture by calling script)
  if [[ ${#packages_to_add[@]} -gt 0 ]]; then
    echo "TO_ADD:${packages_to_add[*]}"
  fi
  
  if [[ ${#packages_to_update[@]} -gt 0 ]]; then
    echo "TO_UPDATE:${packages_to_update[*]}"
  fi
}

# Get general npm dependencies
get_general_npm_dependencies() {
  local dependencies=(
    "@anthropic-ai/claude-code"
    "npm"
    "npm-check"
    "trash-cli"
  )
  printf '%s\n' "${dependencies[@]}"
}

# Get neovim-related npm dependencies
get_neovim_npm_dependencies() {
  local dependencies=(
    "bash-language-server"
    "cssmodules-language-server"
    "dockerfile-language-server-nodejs"
    "emmet-ls"
    "neovim"
    "pug-lint"
    "svelte-language-server"
    "tree-sitter-cli"
    "typescript"
    "vscode-langservers-extracted"
  )
  printf '%s\n' "${dependencies[@]}"
}

# Get all npm dependencies (general + neovim)
get_all_npm_dependencies() {
  get_general_npm_dependencies
  get_neovim_npm_dependencies
}

# Validate npm environment
validate_npm_environment() {
  if ! is_node_available; then
    echo "❌ Node.js is not available. Please install Node.js first."
    return 1
  fi
  
  if ! is_npm_available; then
    echo "❌ npm is not available. Please install npm first."
    return 1
  fi
}