#!/usr/bin/env bash

# Git installation script
# Configures Git global settings and GitHub integration
#
# This script:
# 1. Sets up Git global configuration
# 2. Configures work-specific settings (if on work machine)
# 3. Sets up global Git ignore file
# 4. Validates Git configuration

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
source "$DOTFILES/git/utils.bash"

main() {
    echo "🔧 Installing Git configuration..."
    echo ""

    # Check if Git is available
    if ! command -v git >/dev/null 2>&1; then
        echo "❌ Git is not installed. Please install Git first."
        return 1
    fi

    # Configure Git global settings
    echo "🔧 Configuring Git global settings..."
    local git_config="$DOTFILES/git/config/config"

    if [[ -f "$git_config" ]]; then
        if configure_git_global "$git_config"; then
            echo "✅ Git global configuration applied"
        else
            echo "❌ Failed to configure Git global settings"
            return 1
        fi
    else
        echo "❌ Git config file not found at $git_config"
        return 1
    fi

    # Configure work-specific settings if on work machine
    if [[ "${IS_WORK:-false}" == "true" ]]; then
        echo "🏢 Configuring work-specific Git settings..."
        local work_config="$DOTFILES/git/config/config.work"

        if [[ -f "$work_config" ]]; then
            if configure_git_work "$work_config"; then
                echo "✅ Work-specific Git configuration applied"
            else
                echo "❌ Failed to configure work-specific Git settings"
            fi
        else
            echo "⚠️  Work Git config file not found at $work_config"
        fi
    fi

    # Validate configuration
    echo "🔍 Validating Git configuration..."
    if validate_git_configuration; then
        echo "✅ Git configuration validation passed"
    else
        echo "⚠️  Git configuration validation failed"
    fi

    echo ""
    echo "🔧 Git configuration completed"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
