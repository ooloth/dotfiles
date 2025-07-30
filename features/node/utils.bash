#!/usr/bin/env bash

# Node.js utility functions for installation scripts
# Provides reusable functionality for working with Node.js via fnm

set -euo pipefail

# Validate that fnm is properly installed and functional
# Returns: 0 if working properly, 1 if issues detected
validate_fnm_installation() {
    if ! command -v fnm >/dev/null 2>&1; then
        echo "fnm binary not found"
        return 1
    fi
    
    # Test that fnm can execute basic commands
    if ! fnm --version >/dev/null 2>&1; then
        echo "fnm binary found but not functional"
        return 1
    fi
    
    echo "fnm installation is functional"
    return 0
}

# Get the latest available Node.js version from fnm
# Returns: version string (e.g., "v20.10.0") on success, 1 on failure
get_latest_node_version() {
    if ! command -v fnm >/dev/null 2>&1; then
        echo "fnm not available" >&2
        return 1
    fi
    
    # Get the latest version using fnm ls-remote
    local latest_version
    if latest_version=$(fnm ls-remote 2>/dev/null | tail -n 1 | tr -d '[:space:]'); then
        if [[ -n "$latest_version" ]]; then
            echo "$latest_version"
            return 0
        fi
    fi
    
    echo "Failed to get latest Node.js version" >&2
    return 1
}

# Check if a specific Node.js version is installed via fnm
# Args: version - Node.js version to check (e.g., "v20.10.0")
# Returns: 0 if installed, 1 if not installed
is_node_version_installed() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo "Node.js version is required" >&2
        return 1
    fi
    
    if ! command -v fnm >/dev/null 2>&1; then
        echo "fnm not available" >&2
        return 1
    fi
    
    # Use fnm ls to check if version is installed
    local installed_versions
    if installed_versions=$(fnm ls 2>/dev/null); then
        if echo "$installed_versions" | grep -q "$version"; then
            return 0
        fi
    fi
    
    return 1
}

# Install a specific Node.js version via fnm with corepack enabled
# Args: version - Node.js version to install (e.g., "v20.10.0")
# Returns: 0 on success, 1 on failure
install_node_version() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo "Node.js version is required" >&2
        return 1
    fi
    
    if ! command -v fnm >/dev/null 2>&1; then
        echo "fnm not available" >&2
        return 1
    fi
    
    # Install the version with corepack enabled
    if fnm install "$version" --corepack-enabled 2>/dev/null; then
        return 0
    else
        echo "Failed to install Node.js $version" >&2
        return 1
    fi
}

# Set a specific Node.js version as the default
# Args: version - Node.js version to set as default (e.g., "v20.10.0")
# Returns: 0 on success, 1 on failure
set_default_node_version() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo "Node.js version is required" >&2
        return 1
    fi
    
    if ! command -v fnm >/dev/null 2>&1; then
        echo "fnm not available" >&2
        return 1
    fi
    
    # Set the version as default
    if fnm default "$version" 2>/dev/null; then
        return 0
    else
        echo "Failed to set Node.js $version as default" >&2
        return 1
    fi
}

# Activate a specific Node.js version in the current shell
# Args: version - Node.js version to activate (e.g., "v20.10.0")
# Returns: 0 on success, 1 on failure
activate_node_version() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo "Node.js version is required" >&2
        return 1
    fi
    
    if ! command -v fnm >/dev/null 2>&1; then
        echo "fnm not available" >&2
        return 1
    fi
    
    # Use the specified version
    if fnm use "$version" 2>/dev/null; then
        return 0
    else
        echo "Failed to activate Node.js $version" >&2
        return 1
    fi
}

# Validate that Node.js is properly installed and functional
# Returns: 0 if working properly, 1 if issues detected
validate_node_installation() {
    if ! command -v node >/dev/null 2>&1; then
        echo "Node.js binary not found"
        return 1
    fi
    
    # Test that node can execute and show version
    local node_version
    if node_version=$(node --version 2>/dev/null); then
        echo "Node.js is functional: $node_version"
        return 0
    else
        echo "Node.js binary found but not functional"
        return 1
    fi
}

# Get the currently active Node.js version
# Returns: version string on success, 1 on failure
get_current_node_version() {
    if command -v node >/dev/null 2>&1; then
        if node --version 2>/dev/null; then
            return 0
        fi
    fi
    
    echo "No active Node.js version" >&2
    return 1
}

# List all installed Node.js versions via fnm
# Returns: 0 on success, 1 on failure
list_installed_node_versions() {
    if ! command -v fnm >/dev/null 2>&1; then
        echo "fnm not available" >&2
        return 1
    fi
    
    if fnm ls 2>/dev/null; then
        return 0
    else
        echo "Failed to list installed Node.js versions" >&2
        return 1
    fi
}

# Get fnm version information
# Returns: 0 if fnm is available and version retrieved, 1 otherwise
get_fnm_version() {
    if command -v fnm >/dev/null 2>&1; then
        fnm --version 2>/dev/null
        return 0
    else
        echo "fnm not available"
        return 1
    fi
}

# Check if npm is available
is_npm_available() {
    command -v npm >/dev/null 2>&1
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
    if ! validate_node_installation >/dev/null 2>&1; then
        echo "❌ Node.js is not available. Please install Node.js first."
        return 1
    fi
    
    if ! is_npm_available; then
        echo "❌ npm is not available. Please install npm first."
        return 1
    fi
    
    echo "✅ npm environment is valid"
    return 0
}