#!/usr/bin/env bash
# Example script showing how to use mode-utils.bash for permission management
# This demonstrates the pattern that update scripts can follow

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "$SCRIPT_DIR/core/permissions/utils.bash"
source "$SCRIPT_DIR/bin/lib/dry-run-utils.bash"

echo "🔋 Updating executable permissions"

# Validate environment
if ! validate_permission_environment; then
  exit 1
fi

# Determine if we're in dry run mode
DRY_RUN_MODE="false"
if is_dry_run; then
  DRY_RUN_MODE="true"
  echo ""
  echo "[DRY RUN] Permission update preview mode"
fi

# Update dotfiles script permissions
DOTFILES_DIR="${DOTFILES:-$HOME/Repos/ooloth/dotfiles}"

if update_dotfiles_script_permissions "$DOTFILES_DIR" "$DRY_RUN_MODE"; then
  echo ""
  if [[ "$DRY_RUN_MODE" == "true" ]]; then
    echo "🔍 [DRY RUN] Permission update preview completed"
  else
    echo "🚀 All dotfiles scripts are executable"
  fi
else
  echo "❌ Failed to update script permissions"
  exit 1
fi