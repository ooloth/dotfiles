#!/usr/bin/env bash
# Install and configure Yazi file manager flavors

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES/lib/yazi-utils.bash"
source "$DOTFILES/bin/lib/machine-detection.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

# Initialize machine detection if not already done
if [[ -z "${MACHINE:-}" ]]; then
  init_machine_detection
fi

# Skip installation on work machines
if [[ "${IS_WORK:-false}" == "true" ]]; then
  echo "⏭️  Skipping yazi flavors installation on work machine"
  exit 0
fi

# Configuration
REPO_URL="git@github.com:yazi-rs/flavors.git"
REPO_PATH="$(get_yazi_flavors_path)"
THEME="catppuccin-mocha.yazi"

# Check if already installed
if is_yazi_flavors_installed "$REPO_PATH"; then
  echo ""
  echo "📂 yazi flavors are already installed"
  exit 0
fi

# Clone flavors repository
echo ""
if is_dry_run; then
  echo "[DRY RUN] Would clone yazi flavors repository to $REPO_PATH"
  echo "[DRY RUN] Would create symlink for $THEME theme"
else
  # Clone the repository
  if ! clone_yazi_flavors "$REPO_URL" "$REPO_PATH"; then
    echo "❌ Failed to install yazi flavors"
    exit 1
  fi
  
  # Set up theme symlink
  if ! setup_yazi_theme_symlink "$REPO_PATH" "$HOME/.config/yazi/flavors" "$THEME"; then
    echo "❌ Failed to set up yazi theme symlink"
    exit 1
  fi
  
  echo ""
  echo "✅ yazi flavors installed successfully"
fi