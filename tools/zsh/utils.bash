#!/usr/bin/env bash
set -euo pipefail

# Check if Zsh is installed and available
zsh_is_installed() {
    local shell_path="/opt/homebrew/bin/zsh"
    [[ -x "$shell_path" ]]
}

# Get the path to the Homebrew Zsh installation
get_zsh_shell_path() {
    echo "/opt/homebrew/bin/zsh"
}

# Check if Zsh is listed in /etc/shells
zsh_in_shells_file() {
    local shell_path="$1"
    grep -q "^${shell_path}$" /etc/shells 2>/dev/null
}

# Add Zsh to /etc/shells if not already present
add_zsh_to_shells() {
    local shell_path="$1"

    if ! zsh_in_shells_file "$shell_path"; then
        echo "📄 Adding '${shell_path}' to /etc/shells"
        echo "$shell_path" | sudo tee -a /etc/shells >/dev/null
        return $?
    fi

    return 0
}

# Check if user's current shell is Zsh
user_shell_is_zsh() {
    local shell_path="$1"
    [[ "$SHELL" == "$shell_path" ]]
}

# Change user's shell to Zsh
change_user_shell_to_zsh() {
    local shell_path="$1"

    if ! user_shell_is_zsh "$shell_path"; then
        echo "🐚 Changing your shell to $shell_path..."
        sudo chsh -s "$shell_path" "$USER"
        return $?
    fi

    return 0
}

# Validate Zsh installation
validate_zsh_installation() {
    local shell_path="$1"
    local has_errors=false

    # Check if Zsh is executable
    if ! [[ -x "$shell_path" ]]; then
        echo "❌ Zsh not found or not executable at $shell_path"
        has_errors=true
    fi

    # Check if Zsh is in /etc/shells
    if ! zsh_in_shells_file "$shell_path"; then
        echo "❌ Zsh not found in /etc/shells"
        has_errors=true
    fi

    # Check if user shell is set to Zsh
    if ! user_shell_is_zsh "$shell_path"; then
        echo "⚠️  User shell not set to Zsh (current: $SHELL)"
        # This is a warning, not an error, as it might require a new session
    fi

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi

    return 0
}

# ============================================================================
# Homebrew Integration Functions
# ============================================================================

# Check if Homebrew is installed
homebrew_is_installed() {
    command -v brew >/dev/null 2>&1
}

# Install Zsh via Homebrew
install_zsh_via_homebrew() {
    if ! homebrew_is_installed; then
        echo "❌ Homebrew is required to install Zsh but is not installed"
        return 1
    fi

    echo "📦 Installing Zsh via Homebrew..."
    brew install zsh
    return $?
}

# ============================================================================
# Configuration Functions
# ============================================================================

# Get the expected path to Zsh configuration directory
get_zsh_config_dir() {
    echo "${DOTFILES:-$HOME/Repos/ooloth/dotfiles}/zsh/config"
}

# Check if Zsh configuration directory exists
zsh_config_exists() {
    local config_dir
    config_dir="$(get_zsh_config_dir)"
    [[ -d "$config_dir" ]]
}

# Validate Zsh configuration setup
validate_zsh_configuration() {
    local config_dir
    config_dir="$(get_zsh_config_dir)"

    if ! zsh_config_exists; then
        echo "❌ Zsh configuration directory not found at $config_dir"
        return 1
    fi

    # Check for essential configuration files
    local essential_files=(
        "aliases.zsh"
        "options.zsh"
        "path.zsh"
        "plugins.zsh"
        "utils.zsh"
        "variables.zsh"
    )

    local missing_files=()
    for file in "${essential_files[@]}"; do
        if [[ ! -f "$config_dir/$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo "⚠️  Missing Zsh configuration files: ${missing_files[*]}"
        # This is a warning, not an error, as some files might be optional
    fi

    return 0
}

# ============================================================================
# Output Functions
# ============================================================================

# Print informational message with consistent formatting
print_info() {
    local message="$1"
    echo "ℹ️  $message"
}

# Print success message with consistent formatting
print_success() {
    local message="$1"
    echo "✅ $message"
}

# Print warning message with consistent formatting
print_warning() {
    local message="$1"
    echo "⚠️  $message"
}

# Print error message with consistent formatting
print_error() {
    local message="$1"
    echo "❌ $message"
}
