#!/usr/bin/env bash

# Tmux update script
# Updates tmux plugins and reloads configuration
#
# This script:
# 1. Ensures tpm is installed
# 2. Cleans up old/unused plugins
# 3. Installs any new plugins
# 4. Updates all existing plugins
# 5. Reloads tmux configuration if tmux is running

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
source "$DOTFILES/tmux/utils.bash"

main() {
    echo "✨ Updating tmux dependencies..."
    echo ""

    # Check if tmux is available
    if ! command -v tmux >/dev/null 2>&1; then
        echo "⚠️  Tmux is not installed. Please install tmux first."
        return 1
    fi

    # Ensure tpm is installed
    if ! tpm_is_installed; then
        echo "📦 tpm not found, installing..."
        if install_tpm; then
            echo "✅ tpm installed successfully"
        else
            echo "❌ Failed to install tpm"
            return 1
        fi
    fi

    # Clean up old/unused plugins
    echo "🧹 Cleaning up unused tmux plugins..."
    if cleanup_tmux_plugins; then
        echo "✅ Plugin cleanup completed"
    else
        echo "⚠️  Plugin cleanup completed with warnings"
    fi

    # Install new plugins
    echo "📦 Installing new tmux plugins..."
    if install_tmux_plugins; then
        echo "✅ New plugins installed"
    else
        echo "❌ Failed to install new plugins"
        return 1
    fi

    # Update existing plugins
    echo "🔄 Updating existing tmux plugins..."
    if update_tmux_plugins; then
        echo "✅ Plugins updated successfully"
    else
        echo "❌ Failed to update plugins"
        return 1
    fi

    # Reload tmux configuration if tmux is running
    if tmux_is_running; then
        echo "🔁 Reloading tmux configuration..."
        if reload_tmux_config; then
            echo "✅ Tmux configuration reloaded"
        else
            echo "⚠️  Failed to reload tmux configuration"
        fi
    else
        echo "💡 Tmux is not running - configuration will be loaded on next start"
    fi

    echo ""
    echo "✨ Tmux update completed"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
