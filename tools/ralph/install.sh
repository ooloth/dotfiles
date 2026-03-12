#!/usr/bin/env bash

# Ralph installation script
# Creates symlink in ~/.local/bin so 'ralph' is available system-wide

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_SCRIPT="$SCRIPT_DIR/ralph.sh"
BIN_DIR="$HOME/.local/bin"
SYMLINK_TARGET="$BIN_DIR/ralph"

echo "🔧 Installing ralph command..."
echo ""

# 1. Ensure the bin directory exists
if [[ ! -d "$BIN_DIR" ]]; then
  echo "📁 Creating $BIN_DIR"
  mkdir -p "$BIN_DIR"
else
  echo "✓ $BIN_DIR exists"
fi

# 2. Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo ""
  echo "⚠️  $BIN_DIR is not in your PATH"
  echo ""
  echo "Add this to your ~/.zshrc:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo ""
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
else
  echo "✓ $BIN_DIR is in PATH"
fi

# 3. Make ralph.sh executable
echo "🔐 Making ralph.sh executable"
chmod +x "$RALPH_SCRIPT"

# 4. Create or update symlink
if [[ -L "$SYMLINK_TARGET" ]]; then
  echo "🔗 Updating existing symlink"
  rm "$SYMLINK_TARGET"
elif [[ -e "$SYMLINK_TARGET" ]]; then
  echo "❌ $SYMLINK_TARGET exists but is not a symlink"
  echo "   Please remove it manually and re-run this script"
  exit 1
fi

echo "🔗 Creating symlink: $SYMLINK_TARGET -> $RALPH_SCRIPT"
ln -s "$RALPH_SCRIPT" "$SYMLINK_TARGET"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Usage:"
echo "  1. cd to a project with .ralph/ directory"
echo "  2. Run: ralph"
echo ""
echo "To uninstall:"
echo "  rm $SYMLINK_TARGET"
