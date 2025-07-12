#!/usr/bin/env bash
# Configure macOS system settings

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES/lib/settings-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "💻 Configuring macOS system settings"

# Validate environment
if ! validate_macos_environment; then
  exit 1
fi

# Apply settings based on mode
if is_dry_run; then
  echo ""
  echo "[DRY RUN] Would configure the following macOS settings:"
  echo ""
  echo "General Settings:"
  echo "  - Expand save dialog by default"
  echo "  - Enable full keyboard access for all controls"
  echo "  - Enable subpixel font rendering on non-Apple LCDs"
  echo ""
  echo "Finder Settings:"
  echo "  - Show all filename extensions"
  echo "  - Hide hidden files by default"
  echo "  - Use current directory as default search scope"
  echo "  - Show Path bar and Status bar"
  echo "  - Unhide ~/Library folder"
  echo ""
  echo "Safari Settings:"
  echo "  - Enable Safari's debug menu"
else
  # Configure general settings
  if ! configure_general_settings; then
    echo "❌ Failed to configure general settings"
    exit 1
  fi
  
  # Configure Finder settings
  if ! configure_finder_settings; then
    echo "❌ Failed to configure Finder settings"
    exit 1
  fi
  
  # Configure Safari settings
  if ! configure_safari_settings; then
    echo "❌ Failed to configure Safari settings"
    exit 1
  fi
  
  echo ""
  echo "🚀 Done configuring Mac system preferences."
fi