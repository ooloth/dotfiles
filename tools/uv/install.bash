#!/usr/bin/env bash
set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$SCRIPT_DIR/utils.bash"
source "$DOTFILES/features/common/errors.bash"

main() {
    echo "⚡️ Setting up UV (Python package manager)"
    echo ""

    # Check if UV is already installed
    if is_uv_installed; then
        local version
        version=$(get_uv_version)
        echo "✅ UV is already installed: $version"
        return 0
    fi

    # Install UV
    echo "📦 UV not found, installing..."
    if ! install_uv; then
        echo "❌ Failed to install UV"
        exit 1
    fi

    # Verify installation
    echo ""
    echo "🧪 Verifying installation..."
    if is_uv_installed; then
        local version
        version=$(get_uv_version)
        echo "✅ UV installation verified: $version"
    else
        echo "❌ UV installation verification failed"
        exit 1
    fi

    echo ""
    echo "🎉 UV setup complete!"
}

# Run main function
main "$@"
