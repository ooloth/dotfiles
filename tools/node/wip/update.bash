#!/usr/bin/env bash

# Node.js update script
# Updates Node.js to the latest version and updates global npm packages
#
# This script:
# 1. Updates Node.js to the latest version via fnm
# 2. Updates global npm packages
# 3. Manages npm package installations for general and Neovim dependencies

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
# shellcheck source=node/utils.bash
source "${DOTFILES}/tools/node/utils.bash"

# Global npm packages to maintain
# General dependencies for development
declare -a GENERAL_DEPENDENCIES=(
    "@anthropic-ai/claude-code"
    "npm"
    "npm-check"
    "trash-cli"
)

# Neovim-specific language servers and tools
declare -a NEOVIM_DEPENDENCIES=(
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

# Check if a specific npm package is installed globally
# Args: package_name - name of the package to check
# Returns: 0 if installed, 1 if not installed
is_npm_package_installed() {
    local package_name="$1"
    
    if [[ -z "$package_name" ]]; then
        echo "Package name is required" >&2
        return 1
    fi
    
    # Get list of installed packages
    local installed_packages
    if installed_packages=$(npm list -g --depth=0 2>/dev/null); then
        if echo "$installed_packages" | grep -q " ${package_name}@"; then
            return 0
        fi
    fi
    
    return 1
}

# Check if a specific npm package is outdated
# Args: package_name - name of the package to check
# Returns: 0 if outdated, 1 if up to date or not installed
is_npm_package_outdated() {
    local package_name="$1"
    
    if [[ -z "$package_name" ]]; then
        echo "Package name is required" >&2
        return 1
    fi
    
    # Get list of outdated packages
    local outdated_packages
    if outdated_packages=$(npm outdated -g 2>/dev/null); then
        if echo "$outdated_packages" | grep -q "^${package_name}"; then
            return 0
        fi
    fi
    
    return 1
}

# Update Node.js to the latest version
update_node_version() {
    echo "🔍 Checking for Node.js updates..."
    
    # Get current and latest versions
    local current_version latest_version
    current_version=$(get_current_node_version 2>/dev/null || echo "none")
    
    if ! latest_version=$(get_latest_node_version); then
        echo "❌ Failed to determine latest Node.js version"
        return 1
    fi
    
    echo "📦 Current Node.js version: $current_version"
    echo "📦 Latest Node.js version: $latest_version"
    
    # Check if already on latest version
    if is_node_version_installed "$latest_version"; then
        echo "✅ Already running the latest Node.js version ($latest_version)"
        return 0
    fi
    
    # Install the latest version
    echo "📦 Installing Node.js $latest_version..."
    if install_node_version "$latest_version"; then
        echo "✅ Node.js $latest_version installed successfully"
    else
        echo "❌ Failed to install Node.js $latest_version"
        return 1
    fi
    
    # Set as default and activate
    if set_default_node_version "$latest_version" && activate_node_version "$latest_version"; then
        echo "✅ Node.js $latest_version set as default and activated"
    else
        echo "❌ Failed to set Node.js $latest_version as default"
        return 1
    fi
    
    return 0
}

# Update global npm packages
update_npm_packages() {
    echo "✨ Updating Node.js global dependencies..."
    
    # Check if npm is available
    if ! command -v npm >/dev/null 2>&1; then
        echo "❌ npm is not available"
        return 1
    fi
    
    # Get current Node.js version for display
    local node_version
    node_version=$(get_current_node_version 2>/dev/null || echo "unknown")
    echo "✨ Updating Node.js $node_version global dependencies"
    
    # Combine all packages
    local -a all_packages=("${GENERAL_DEPENDENCIES[@]}" "${NEOVIM_DEPENDENCIES[@]}")
    
    # Track packages to add and update
    local -a packages_to_add=()
    local -a packages_to_update=()
    
    # Check each package
    for package in "${all_packages[@]}"; do
        if ! is_npm_package_installed "$package"; then
            packages_to_add+=("$package")
        elif is_npm_package_outdated "$package"; then
            packages_to_update+=("$package")
        fi
    done
    
    # Display what will be done
    echo ""
    for package in "${packages_to_add[@]}"; do
        printf "📦 Installing %s\n" "$package"
    done
    
    for package in "${packages_to_update[@]}"; do
        printf "🚀 Updating %s\n" "$package"
    done
    
    # Install/update packages if needed
    if [[ ${#packages_to_add[@]} -gt 0 ]] || [[ ${#packages_to_update[@]} -gt 0 ]]; then
        # Combine arrays for single npm install command
        local -a packages_to_install=("${packages_to_add[@]}" "${packages_to_update[@]}")
        
        echo ""
        echo "📦 Running npm install for ${#packages_to_install[@]} packages..."
        
        # Use -g for global and --loglevel=error to reduce noise
        if npm install -g --loglevel=error "${packages_to_install[@]}"; then
            echo "✅ npm packages updated successfully"
        else
            echo "❌ Failed to update some npm packages"
            return 1
        fi
    else
        echo "✅ All npm packages are already up to date"
    fi
    
    return 0
}

main() {
    echo "🦀 Updating Node.js and npm packages..."
    echo ""
    
    # Check if fnm is available
    if ! command -v fnm >/dev/null 2>&1; then
        echo "❌ fnm (Fast Node Manager) is not installed."
        echo "   Please install fnm first or run the Node.js installation script"
        return 1
    fi
    
    # Update Node.js version
    if update_node_version; then
        echo "✅ Node.js update completed"
    else
        echo "❌ Node.js update failed"
        return 1
    fi
    
    echo ""
    
    # Update npm packages
    if update_npm_packages; then
        echo "✅ npm packages update completed"
    else
        echo "❌ npm packages update failed"
        return 1
    fi
    
    echo ""
    echo "🎉 All Node.js updates completed successfully"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
