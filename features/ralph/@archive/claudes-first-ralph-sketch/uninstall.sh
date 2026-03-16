#!/usr/bin/env bash

# Ralph uninstallation script
# Removes symlink from ~/.local/bin

set -e

BIN_DIR="$HOME/.local/bin"
SYMLINK_TARGET="$BIN_DIR/ralph"

echo "🗑️  Uninstalling ralph command..."
echo ""

# Check if symlink exists
if [[ -L "$SYMLINK_TARGET" ]]; then
  echo "🔗 Removing symlink: $SYMLINK_TARGET"
  rm "$SYMLINK_TARGET"
  echo ""
  echo "✅ Uninstallation complete!"
elif [[ -e "$SYMLINK_TARGET" ]]; then
  echo "⚠️  $SYMLINK_TARGET exists but is not a symlink"
  echo "   Please remove it manually if needed"
  exit 1
else
  echo "ℹ️  No ralph symlink found at $SYMLINK_TARGET"
  echo "   Nothing to uninstall"
fi

echo ""
echo "To reinstall, run: ./install.sh"
