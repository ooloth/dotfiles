#!/usr/bin/env bash

# macOS utilities for dotfiles setup

set -euo pipefail

# Check if we're running on macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# Check if softwareupdate command is available
is_softwareupdate_available() {
    command -v softwareupdate >/dev/null 2>&1
}

# Run macOS software update
run_macos_software_update() {
    if ! is_macos; then
        echo "❌ This feature is only available on macOS" >&2
        return 1
    fi
    
    if ! is_softwareupdate_available; then
        echo "❌ softwareupdate command not found" >&2
        return 1
    fi
    
    echo "💻 Running macOS software update..."
    echo "⚠️  This may take a while and will restart your computer"
    echo ""
    
    # Run software update with all options
    # --install: Install updates
    # --all: Install all available updates
    # --restart: Restart if required
    # --agree-to-license: Automatically agree to license
    # --verbose: Show detailed output
    if sudo softwareupdate --install --all --restart --agree-to-license --verbose; then
        echo "✅ macOS software update completed successfully"
        return 0
    else
        local exit_code=$?
        echo "❌ macOS software update failed with exit code: $exit_code" >&2
        return $exit_code
    fi
}