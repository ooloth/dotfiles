#!/usr/bin/env bash

# Neovim utility functions for installation scripts
# Provides reusable functionality for working with Neovim configuration

set -euo pipefail

# Check if a command exists
# Args: command_name - name of the command to check
# Returns: 0 if exists, 1 if not found
command_exists() {
    local command_name="$1"
    
    if [[ -z "$command_name" ]]; then
        echo "Command name is required" >&2
        return 1
    fi
    
    if command -v "$command_name" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check if Neovim is installed
# Returns: 0 if installed, 1 if not installed
is_neovim_installed() {
    if command_exists nvim; then
        return 0
    else
        return 1
    fi
}

# Get current Neovim version
# Returns: version string on success, 1 on failure
get_neovim_version() {
    if command_exists nvim; then
        if nvim --version 2>/dev/null | head -n 1; then
            return 0
        fi
    fi
    
    echo "Neovim not installed" >&2
    return 1
}

# Check if Neovim config repository is installed
# Returns: 0 if installed, 1 if not installed
is_neovim_config_installed() {
    local config_dir="$HOME/Repos/ooloth/config.nvim"
    
    if [[ -d "$config_dir" && -d "$config_dir/.git" ]]; then
        return 0
    else
        return 1
    fi
}

# Validate Neovim configuration directory
# Returns: 0 if valid, 1 if issues detected
validate_neovim_config() {
    local config_dir="$HOME/Repos/ooloth/config.nvim"
    
    if [[ ! -d "$config_dir" ]]; then
        echo "Neovim config directory not found: $config_dir" >&2
        return 1
    fi
    
    if [[ ! -d "$config_dir/.git" ]]; then
        echo "Neovim config directory is not a git repository: $config_dir" >&2
        return 1
    fi
    
    if [[ ! -f "$config_dir/init.lua" ]]; then
        echo "Neovim config init.lua not found: $config_dir/init.lua" >&2
        return 1
    fi
    
    echo "Neovim config directory is valid: $config_dir"
    return 0
}

# Clone Neovim configuration repository
# Returns: 0 on success, 1 on failure
clone_neovim_config() {
    local repo="ooloth/config.nvim"
    local local_repo="$HOME/Repos/$repo"
    
    echo "📂 Installing config.nvim repository..."
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$local_repo")"
    
    # Clone the repository
    if git clone "git@github.com:$repo.git" "$local_repo"; then
        echo "✅ config.nvim repository cloned successfully"
        return 0
    else
        echo "❌ Failed to clone config.nvim repository" >&2
        return 1
    fi
}

# Restore Neovim plugins from lockfile using Lazy
# Returns: 0 on success, 1 on failure
restore_neovim_plugins() {
    echo "📂 Installing Lazy plugin versions from lazy-lock.json..."
    
    # Check if Neovim is available
    if ! command_exists nvim; then
        echo "❌ Neovim not found, cannot restore plugins" >&2
        return 1
    fi
    
    # Restore plugins using headless Neovim
    if NVIM_APPNAME=nvim-ide nvim --headless "+Lazy! restore" +qa; then
        echo "✅ Neovim plugins restored successfully"
        return 0
    else
        echo "❌ Failed to restore Neovim plugins" >&2
        return 1
    fi
}

# Install language server for a specific language
# Args: language - language name, package_manager - npm/brew/cargo, package_name - package to install
# Returns: 0 on success, 1 on failure
install_language_server() {
    local language="$1"
    local package_manager="$2"
    local package_name="$3"
    
    if [[ -z "$language" || -z "$package_manager" || -z "$package_name" ]]; then
        echo "install_language_server requires: language, package_manager, package_name" >&2
        return 1
    fi
    
    echo "Installing $language language server: $package_name"
    
    case "$package_manager" in
        npm)
            if command_exists npm; then
                npm install -g "$package_name"
            else
                echo "❌ npm not found, cannot install $package_name" >&2
                return 1
            fi
            ;;
        brew)
            if command_exists brew; then
                brew install "$package_name"
            else
                echo "❌ brew not found, cannot install $package_name" >&2
                return 1
            fi
            ;;
        cargo)
            if command_exists cargo; then
                cargo install "$package_name"
            else
                echo "❌ cargo not found, cannot install $package_name" >&2
                return 1
            fi
            ;;
        *)
            echo "❌ Unsupported package manager: $package_manager" >&2
            return 1
            ;;
    esac
}

# Install multiple language servers from a configuration
# This function installs all the LSP servers needed for Neovim
# Returns: 0 on success, 1 on failure
install_neovim_language_servers() {
    echo "🧃 Installing Neovim language servers, linters and formatters..."
    
    local failed_installs=()
    
    # Helper function to try install and track failures
    try_install() {
        local description="$1"
        local package_manager="$2"
        local package_name="$3"
        
        echo "Installing $description..."
        if install_language_server "$description" "$package_manager" "$package_name"; then
            echo "✅ $description installed successfully"
        else
            echo "❌ Failed to install $description"
            failed_installs+=("$description")
        fi
    }
    
    # Astro
    try_install "Astro" "npm" "@astrojs/language-server"
    
    # Bash
    try_install "shellcheck" "brew" "shellcheck"
    try_install "shfmt" "brew" "shfmt"
    try_install "Bash Language Server" "npm" "bash-language-server"
    
    # CSS
    try_install "VS Code Language Servers" "npm" "vscode-langservers-extracted"
    try_install "CSS Variables Language Server" "npm" "css-variables-language-server"
    try_install "CSS Modules Language Server" "npm" "cssmodules-language-server"
    try_install "Tailwind CSS Language Server" "npm" "@tailwindcss/language-server"
    
    # HTML/XML
    try_install "tidy-html5" "brew" "tidy-html5"
    try_install "Prettier" "npm" "prettier"
    
    # JSON (already installed with vscode-langservers-extracted above)
    
    # Lua
    try_install "Lua Language Server" "brew" "lua-language-server"
    try_install "StyLua" "brew" "stylua"
    
    # Markdown / MDX
    try_install "Marksman" "brew" "marksman"
    try_install "MDX Language Service" "npm" "@mdx-js/language-service"
    
    # Python
    try_install "BasedPyright" "brew" "basedpyright"
    try_install "Ruff" "brew" "ruff"
    
    # Terraform
    if ! brew tap | grep -q "hashicorp/tap"; then
        echo "Adding hashicorp/tap..."
        brew tap hashicorp/tap
    fi
    try_install "Terraform" "brew" "hashicorp/tap/terraform"
    try_install "Terraform Language Server" "brew" "hashicorp/tap/terraform-ls"
    try_install "TFLint" "brew" "tflint"
    
    # TOML
    try_install "Taplo CLI" "cargo" "--features lsp --locked taplo-cli"
    
    # TypeScript / JavaScript
    try_install "TypeScript" "npm" "typescript"
    try_install "TypeScript Language Server" "npm" "typescript-language-server"
    
    # Vue
    try_install "Vue Language Server" "npm" "vls"
    
    # YAML
    try_install "YAML Language Server" "npm" "yaml-language-server"
    
    # Report results
    if [[ ${#failed_installs[@]} -eq 0 ]]; then
        echo "✅ All language servers installed successfully"
        return 0
    else
        echo "⚠️  Some language servers failed to install:"
        printf '  - %s\n' "${failed_installs[@]}"
        return 1
    fi
}

# Update Neovim plugins and language servers
# Returns: 0 on success, 1 on failure
update_neovim() {
    echo "🧃 Updating Neovim configuration and dependencies..."
    
    # Update language servers
    if install_neovim_language_servers; then
        echo "✅ Language servers updated successfully"
    else
        echo "⚠️  Some language server updates failed"
    fi
    
    # Restore plugins from lockfile
    if restore_neovim_plugins; then
        echo "✅ Neovim plugins restored successfully"
        return 0
    else
        echo "❌ Failed to restore Neovim plugins"
        return 1
    fi
}

# Validate complete Neovim installation
# Returns: 0 if everything is working, 1 if issues detected
validate_neovim_installation() {
    local issues=()
    
    # Check if Neovim is installed
    if ! is_neovim_installed; then
        issues+=("Neovim is not installed")
    else
        echo "✅ Neovim is installed"
        
        # Get and display version
        local version
        if version=$(get_neovim_version); then
            echo "📦 Neovim version: $version"
        fi
    fi
    
    # Check if config is installed and valid
    if ! is_neovim_config_installed; then
        issues+=("Neovim config repository is not installed")
    elif ! validate_neovim_config; then
        issues+=("Neovim config repository is invalid")
    else
        echo "✅ Neovim config repository is properly installed"
    fi
    
    # Report results
    if [[ ${#issues[@]} -eq 0 ]]; then
        echo "✅ Neovim installation validation passed"
        return 0
    else
        echo "❌ Neovim installation validation failed:"
        printf '  - %s\n' "${issues[@]}"
        return 1
    fi
}