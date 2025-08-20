#!/usr/bin/env bash

# Yazi update script
# Updates yazi flavors repository to get latest themes
#
# This script:
# 1. Checks if running on work machine (skips if so)
# 2. Ensures yazi flavors repository is installed
# 3. Updates the flavors repository from upstream
# 4. Validates the update was successful

set -euo pipefail

# Configuration
DOTFILES="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

# Load utilities
# shellcheck source=yazi/utils.bash
source "$DOTFILES/yazi/utils.bash"

# Load machine detection
# shellcheck source=@common/detection/machine.bash
source "$DOTFILES/@common/detection/machine.bash"

main() {
    echo "📂 Updating yazi flavors..."
    echo ""

    # Skip on work machines
    if is_work_machine; then
        echo "⏭️  Skipping yazi update on work machine"
        echo ""
        return 0
    fi

    # Check if yazi flavors are installed
    if ! is_yazi_flavors_installed; then
        echo "❌ Yazi flavors not installed."
        echo "   Installing flavors first..."
        echo ""

        # Install the flavors repository
        if install_yazi_flavors; then
            echo "✅ Yazi flavors installed successfully"
        else
            echo "❌ Failed to install yazi flavors"
            return 1
        fi

        echo ""
    else
        echo "✅ Yazi flavors repository found"
    fi

    # Update the flavors repository
    local flavors_path
    flavors_path=$(get_yazi_flavors_path)

    echo "🔄 Updating yazi flavors from upstream..."

    # Check if it's a git repository
    if [[ ! -d "$flavors_path/.git" ]]; then
        echo "❌ Flavors directory is not a git repository: $flavors_path"
        echo "   You may need to reinstall: rm -rf '$flavors_path' && ./yazi/install.bash"
        return 1
    fi

    # Save current directory and change to flavors repo
    local original_dir
    original_dir=$(pwd)

    if ! cd "$flavors_path"; then
        echo "❌ Failed to change to flavors directory: $flavors_path"
        return 1
    fi

    # Ensure we're on the main branch
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
        echo "⚠️  Currently on branch '$current_branch', switching to main..."
        if ! git checkout main 2>/dev/null && ! git checkout master 2>/dev/null; then
            echo "❌ Failed to switch to main branch"
            cd "$original_dir"
            return 1
        fi
    fi

    # Pull latest changes
    if git pull --ff-only; then
        echo "✅ Yazi flavors updated successfully"
    else
        echo "❌ Failed to update yazi flavors"
        cd "$original_dir"
        return 1
    fi

    # Return to original directory
    cd "$original_dir"

    # Validate the update
    local expected_theme="catppuccin-mocha.yazi"
    if [[ -d "$flavors_path/$expected_theme" ]]; then
        echo "✅ Expected theme validated: $expected_theme"
    else
        echo "⚠️  Expected theme not found after update: $expected_theme"
        echo "   The update completed but the expected theme may have been moved or renamed"
    fi

    echo ""
    echo "🎉 Yazi flavors update completed"
    echo ""
    echo "Updated repository: $flavors_path"
    echo ""
    echo "Next steps:"
    echo "  - Restart yazi to see any new themes"
    echo "  - Check ~/.config/yazi/flavors symlink is still valid"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

