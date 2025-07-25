#!/usr/bin/env bash
# Install and configure Zsh shell

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES/lib/zsh-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "🐚 Configuring zsh shell"

# Use the Homebrew version of Zsh
SHELL_PATH="/opt/homebrew/bin/zsh"

# Check if Zsh is installed
if ! is_homebrew_zsh_installed; then
  echo ""
  echo "❌ Zsh not found at ${SHELL_PATH}. Installing Zsh via Homebrew..."
  
  # Run homebrew installation
  if [[ -f "$SCRIPT_DIR/homebrew.bash" ]]; then
    source "$SCRIPT_DIR/homebrew.bash"
  else
    echo "❌ Homebrew installation script not found"
    exit 1
  fi
  
  # Check if Zsh is now installed
  if ! is_homebrew_zsh_installed; then
    echo ""
    echo "❌ Failed to install Zsh. Please try again."
    exit 1
  else
    echo ""
    echo "✅ Zsh installed successfully."
  fi
fi

# Add Zsh to /etc/shells if not already present
echo ""
if ! is_shell_registered "$SHELL_PATH"; then
  if is_dry_run; then
    echo "[DRY RUN] Would add '${SHELL_PATH}' to /etc/shells"
  else
    add_shell_to_etc_shells "$SHELL_PATH"
  fi
else
  echo "✅ Zsh already registered in /etc/shells"
fi

# Change user's shell to Zsh if not already using it
echo ""
if ! is_user_using_shell "$SHELL_PATH"; then
  if is_dry_run; then
    echo "[DRY RUN] Would change shell to $SHELL_PATH"
  else
    change_user_shell "$SHELL_PATH"
  fi
else
  echo "✅ Already using Zsh as default shell"
fi

echo ""
echo "🚀 Done configuring zsh shell."