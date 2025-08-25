#!/usr/bin/env bash

# Tmux utility functions for installation and management scripts
# Provides reusable functionality for tmux configuration and plugin management

set -euo pipefail

# ============================================================================
# Configuration and Constants
# ============================================================================

readonly TPM_DIR="$HOME/.config/tmux/plugins/tpm"
readonly TPM_REPO="git@github.com:tmux-plugins/tpm.git"
readonly TMUX_CONFIG="$HOME/.config/tmux/tmux.conf"

# ============================================================================
# Detection Functions
# ============================================================================

# Check if tpm (tmux plugin manager) is installed
tpm_is_installed() {
    [[ -d "$TPM_DIR" && -f "$TPM_DIR/tpm" ]]
}

# Check if tmux is currently running
tmux_is_running() {
    pgrep -q tmux
}

# Check if tmux configuration file exists
tmux_config_exists() {
    [[ -f "$TMUX_CONFIG" ]]
}

# ============================================================================
# Installation Functions
# ============================================================================

# Install tmux plugin manager (tpm)
install_tpm() {
    if tpm_is_installed; then
        echo "🍱 tpm is already installed"
        return 0
    fi

    echo "🍱 Installing tpm..."
    
    # Create plugins directory if it doesn't exist
    local plugins_dir
    plugins_dir="$(dirname "$TPM_DIR")"
    if [[ ! -d "$plugins_dir" ]]; then
        mkdir -p "$plugins_dir"
    fi

    # Clone tpm repository
    if git clone "$TPM_REPO" "$TPM_DIR" >/dev/null 2>&1; then
        echo "✅ tpm cloned successfully"
        return 0
    else
        echo "❌ Failed to clone tpm repository"
        return 1
    fi
}

# Install tmux plugins using tpm
install_tmux_plugins() {
    if ! tpm_is_installed; then
        echo "❌ tpm is not installed"
        return 1
    fi

    local install_script="$TPM_DIR/bin/install_plugins"
    
    if [[ ! -x "$install_script" ]]; then
        echo "❌ tpm install script not found or not executable"
        return 1
    fi

    echo "🔌 Installing tpm plugins..."
    if "$install_script" >/dev/null 2>&1; then
        return 0
    else
        echo "❌ Plugin installation failed"
        return 1
    fi
}

# Update tmux plugins using tpm
update_tmux_plugins() {
    if ! tpm_is_installed; then
        echo "❌ tpm is not installed"
        return 1
    fi

    local update_script="$TPM_DIR/bin/update_plugins"
    
    if [[ ! -x "$update_script" ]]; then
        echo "❌ tpm update script not found or not executable"
        return 1
    fi

    # Update all plugins
    if "$update_script" all >/dev/null 2>&1; then
        return 0
    else
        echo "❌ Plugin update failed"
        return 1
    fi
}

# Clean up unused tmux plugins
cleanup_tmux_plugins() {
    if ! tpm_is_installed; then
        echo "❌ tpm is not installed"
        return 1
    fi

    local clean_script="$TPM_DIR/bin/clean_plugins"
    
    if [[ ! -x "$clean_script" ]]; then
        echo "❌ tpm clean script not found or not executable"
        return 1
    fi

    if "$clean_script" >/dev/null 2>&1; then
        return 0
    else
        echo "❌ Plugin cleanup failed"
        return 1
    fi
}

# ============================================================================
# Configuration Functions
# ============================================================================

# Reload tmux configuration
reload_tmux_config() {
    if ! tmux_config_exists; then
        echo "❌ Tmux config file not found at $TMUX_CONFIG"
        return 1
    fi

    if ! tmux_is_running; then
        echo "⚠️  Tmux is not running, cannot reload config"
        return 1
    fi

    if tmux source "$TMUX_CONFIG" >/dev/null 2>&1; then
        return 0
    else
        echo "❌ Failed to reload tmux configuration"
        return 1
    fi
}

# ============================================================================
# Terminfo Functions (Optional/Legacy)
# ============================================================================

# Install terminfo configurations (disabled by default)
# These may not be needed for modern tmux setups
install_terminfo_configs() {
    local dotfiles="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"
    local tmux_terminfo="$dotfiles/tmux/config/tmux.terminfo"
    local xterm_terminfo="$dotfiles/tmux/config/xterm-256color-italic.terminfo"

    if [[ -f "$tmux_terminfo" ]]; then
        echo "💪 Installing tmux.terminfo..."
        if tic -x "$tmux_terminfo" >/dev/null 2>&1; then
            echo "✅ tmux.terminfo installed"
        else
            echo "❌ Failed to install tmux.terminfo"
            return 1
        fi
    fi

    if [[ -f "$xterm_terminfo" ]]; then
        echo "💪 Installing xterm-256color-italic.terminfo..."
        if tic -x "$xterm_terminfo" >/dev/null 2>&1; then
            echo "✅ xterm-256color-italic.terminfo installed"
        else
            echo "❌ Failed to install xterm-256color-italic.terminfo"
            return 1
        fi
    fi

    return 0
}

# ============================================================================
# Validation Functions
# ============================================================================

# Validate tmux installation and configuration
validate_tmux_installation() {
    local has_errors=false

    # Check if tmux command exists
    if ! command -v tmux >/dev/null 2>&1; then
        echo "❌ tmux command not found"
        has_errors=true
    fi

    # Check if tpm is installed
    if ! tpm_is_installed; then
        echo "❌ tpm is not installed"
        has_errors=true
    fi

    # Check if tmux config exists
    if ! tmux_config_exists; then
        echo "❌ tmux configuration file not found"
        has_errors=true
    fi

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi

    return 0
}
