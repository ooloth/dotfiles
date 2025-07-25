#!/usr/bin/env bash
# Example script showing how to use macos-utils.bash for system updates
# This demonstrates the pattern that update scripts can follow

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "$SCRIPT_DIR/lib/macos-utils.bash"

echo "💻 Updating macOS software (after password, don't cancel!)"

# Display system information
echo ""
echo "Current system information:"
get_system_info
echo ""

# Validate environment
validation_result=0
validate_macos_update_environment || validation_result=$?

case $validation_result in
  0)
    echo "✅ Environment validated for macOS updates"
    ;;
  1)
    echo "❌ Environment validation failed"
    exit 1
    ;;
  2)
    echo "⏭️  Skipping macOS updates due to work machine policy"
    exit 0
    ;;
esac

# Check admin privileges
if ! has_admin_privileges; then
  echo "❌ Admin privileges required for system updates"
  exit 1
fi

# Display warning about potential restart
warn_about_restart

# Check for available updates
echo "Checking for available updates..."
if ! check_software_updates; then
  echo "❌ Failed to check for updates"
  exit 1
fi

echo ""
echo "Proceeding with software update installation..."

# Install updates with restart
if install_software_updates "true"; then
  echo ""
  echo "✅ macOS software updates completed successfully"
  
  # Check if restart is needed
  if needs_restart_for_updates; then
    echo "🔄 System restart may be required to complete updates"
  fi
else
  echo "❌ Failed to install macOS software updates"
  exit 1
fi